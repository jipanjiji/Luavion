-- This Script is Part of the Zero Impact Obfuscator
--
-- Base85Encoder.lua
--
-- Base85 Custom Dynamic Alphabet Stream Encoder for String Constants.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")
local Ast = require("zerolua.ast")
local util = require("zerolua.util")

local Base85Encoder = Step:extend()
Base85Encoder.Description = "Base85 Custom Dynamic Alphabet Stream Encoder."
Base85Encoder.Name = "Base85 Encoder"

Base85Encoder.SettingsDescriptor = {}

function Base85Encoder:init(_) end

-- Standard 85 ASCII printable characters to be dynamically shuffled per build
local BASE_CHARS = {}
do
	for i = 33, 126 do
		local ch = string.char(i)
		if ch ~= "\\" and ch ~= '"' and ch ~= "'" and ch ~= "`" then
			if #BASE_CHARS < 85 then
				table.insert(BASE_CHARS, ch)
			end
		end
	end
end

local function generateRandomAlphabet()
	local chars = {}
	for i, v in ipairs(BASE_CHARS) do
		chars[i] = v
	end
	return table.concat(util.shuffle(chars))
end

local function encodeBase85(str, alphabet)
	local floor = math.floor
	local len = #str
	local out = {}
	local idx = 1
	while idx <= len do
		local rem = len - idx + 1
		local count = rem >= 4 and 4 or rem
		local b1 = string.byte(str, idx) or 0
		local b2 = string.byte(str, idx + 1) or 0
		local b3 = string.byte(str, idx + 2) or 0
		local b4 = string.byte(str, idx + 3) or 0
		idx = idx + count

		local acc = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
		local chars = {}
		for i = 5, 1, -1 do
			local code = (acc % 85) + 1
			chars[i] = string.sub(alphabet, code, code)
			acc = floor(acc / 85)
		end

		table.insert(out, table.concat(chars, "", 1, count + 1))
	end
	return table.concat(out)
end

function Base85Encoder:apply(ast, pipeline)
	if pipeline.PrettyPrint then
		return ast
	end

	local dynamicAlphabet = generateRandomAlphabet()
	local scope = ast.body.scope;
	local decVar = scope:addVariable();

	-- Inject Base85 Decoder Runtime Helper at the top of the AST with dynamic alphabet
	local decoderCode = [[
do
	local _gEnv = (getfenv and getfenv()) or _ENV or _G or {};
	local _strByte = (string and string.byte) or (_gEnv.string and _gEnv.string.byte);
	local _strChar = (string and string.char) or (_gEnv.string and _gEnv.string.char);
	local _tblConcat = (table and table.concat) or (_gEnv.table and _gEnv.table.concat);
	local _floor = (math and math.floor) or (_gEnv.math and _gEnv.math.floor) or function(n) return n - (n % 1) end;

	local _alpha = "]] .. dynamicAlphabet .. [[";
	local _lookup = {};
	local _b85Cache = {};
	if _strByte then
		for i = 1, #_alpha do
			_lookup[_strByte(_alpha, i)] = i - 1;
		end
	end

	B85DEC = function(encoded)
		if type(encoded) ~= "string" then return encoded end
		local _cached = _b85Cache[encoded];
		if _cached ~= nil then return _cached end
		if not _strByte or not _strChar or not _tblConcat then return encoded end
		local len = #encoded;
		local out = {};
		local outIdx = 1;
		local idx = 1;

		while idx <= len do
			local rem = len - idx + 1;
			local count = rem >= 5 and 5 or rem;
			if count < 2 then break end;
			local acc = 0;
			for j = 0, count - 1 do
				local b = _strByte(encoded, idx + j);
				acc = acc * 85 + (_lookup[b] or 0);
			end
			for j = count, 4 do
				acc = acc * 85 + 84;
			end
			idx = idx + count;

			local b1 = _floor(acc / 16777216) % 256;
			local b2 = _floor(acc / 65536) % 256;
			local b3 = _floor(acc / 256) % 256;
			local b4 = acc % 256;

			if count >= 2 then out[outIdx] = _strChar(b1); outIdx = outIdx + 1 end
			if count >= 3 then out[outIdx] = _strChar(b2); outIdx = outIdx + 1 end
			if count >= 4 then out[outIdx] = _strChar(b3); outIdx = outIdx + 1 end
			if count == 5 then out[outIdx] = _strChar(b4); outIdx = outIdx + 1 end
		end
		local _res = _tblConcat(out);
		_b85Cache[encoded] = _res;
		return _res;
	end
end
]]

	local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(decoderCode);
	local doStat = parsed.body.statements[1];

	doStat.body.scope:setParent(ast.body.scope);

	visitast(parsed, nil, function(node, data)
		if node.kind == Ast.AstKind.AssignmentVariable or node.kind == Ast.AstKind.VariableExpression then
			if node.scope:getVariableName(node.id) == "B85DEC" then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(scope, decVar);
				node.scope = scope;
				node.id = decVar;
			end
		end
		node.__do_not_touch = true;
	end)

	-- Transform StringExpressions into Base85 Encoded Calls using dynamic alphabet
	visitast(ast, nil, function(node, data)
		if node.kind == Ast.AstKind.StringExpression then
			if node.__do_not_touch or node.__semantic_preserve or node.__preserve_metamethod_dispatch then
				return node;
			end
			if data and data.parent and data.parent.kind == Ast.AstKind.KeyedTableEntry and data.key == "key" then
				return node;
			end
			if #node.value < 3 then
				return node;
			end

			local encodedStr = encodeBase85(node.value, dynamicAlphabet);
			local encStrNode = Ast.StringExpression(encodedStr);
			encStrNode.__do_not_touch = true;

			local varNode = Ast.VariableExpression(scope, decVar);
			varNode.__do_not_touch = true;
			varNode.__ignoreProxifyLocals = true;

			local callNode = Ast.FunctionCallExpression(varNode, {
				encStrNode
			});
			callNode.__do_not_touch = true;
			return callNode;
		end
	end)

	table.insert(ast.body.statements, 1, doStat);
	local localDecl = Ast.LocalVariableDeclaration(scope, { decVar }, {});
	localDecl.__do_not_touch = true;
	table.insert(ast.body.statements, 1, localDecl);

	return ast;
end

return Base85Encoder;
