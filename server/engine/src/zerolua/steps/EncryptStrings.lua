-- This Script is Part of the Zero Lua Obfuscator v1.9
--
-- EncryptStrings.lua
--
-- Decentralized Ephemeral String Protection for Zero Lua V1.9.
-- Eliminates universal decryption oracles and global plaintext string caches.
-- Strings are decrypted on-demand with ephemeral lifespans directly at consumption sites.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")
local util = require("zerolua.util")
local RandomDomains = require("zerolua.random_domains")
local AstKind = Ast.AstKind

local EncryptStrings = Step:extend()
EncryptStrings.Description = "Encrypts strings with ephemeral contextual decryption without global plaintext caching or universal oracles."
EncryptStrings.Name = "Encrypt Strings"

EncryptStrings.SettingsDescriptor = {}

function EncryptStrings:init(_) end

function EncryptStrings:CreateEncryptionService()
	local strRng = RandomDomains.get("STRINGS")
	local function rngRand(a, b)
		if strRng and strRng.random then
			return strRng:random(a, b)
		end
		if b then return math.random(a, b) end
		if a then return math.random(a) end
		return math.random()
	end

	local usedSeeds = {}
	local secret_key_8 = rngRand(1, 255)
	local salt_mult = rngRand(3, 17) * 2 + 1
	local salt_add = rngRand(11, 79)

	local floor = math.floor
	local state = 0
	local prev_values = {}

	local function set_seed(seed_val)
		state = seed_val % 4294967296
		prev_values = {}
	end

	local function gen_seed()
		local seed
		repeat
			seed = rngRand(1000, 2147483640)
		until not usedSeeds[seed]
		usedSeeds[seed] = true
		return seed
	end

	local function get_next_pseudo_random_byte()
		if #prev_values == 0 then
			local low = (state % 65536) * 1664525
			local high = floor(state / 65536) * 1664525
			state = (low + (high % 65536) * 65536 + 1013904223) % 4294967296

			local rnd = state
			local b1 = rnd % 256
			local b2 = floor(rnd / 256) % 256
			local b3 = floor(rnd / 65536) % 256
			local b4 = floor(rnd / 16777216) % 256
			prev_values = { b1, b2, b3, b4 }
		end
		return table.remove(prev_values) or 0
	end

	local function encrypt(str)
		local seed = gen_seed()
		set_seed(seed)
		local len = string.len(str)
		local out = {}
		local prevVal = (secret_key_8 * salt_mult + salt_add) % 256
		for i = 1, len do
			local byte = string.byte(str, i)
			local enc = (byte - (get_next_pseudo_random_byte() + prevVal)) % 256
			out[i] = string.format("%02X", enc)
			prevVal = byte
		end
		return table.concat(out), seed
	end

	local function genCode(fnVarName)
		local code = [[
do
	local _CACHE = {}
	local _sChar = (string and string.char) or string.char
	local _sByte = (string and string.byte) or string.byte
	local _tUnpack = unpack or (table and table.unpack) or table.unpack
	local _tNum = tonumber
	local _fl = (math and math.floor) or math.floor or function(n) return n - (n % 1) end

	]] .. fnVarName .. [[ = function(str, seed)
		local key = seed or str
		local cached = _CACHE[key]
		if cached then return cached end
		if type(str) ~= "string" then return str or "" end
		local len = #str
		if len == 0 then return "" end

		seed = (_tNum(seed) or 0) % 4294967296
		local state = seed
		local b1, b2, b3, b4 = 0, 0, 0, 0
		local rndIdx = 4
		local prevVal = (]] .. tostring(secret_key_8) .. [[ * ]] .. tostring(salt_mult) .. [[ + ]] .. tostring(salt_add) .. [[) % 256
		local parts = {}
		local pIdx = 1

		for i = 1, len, 2 do
			if rndIdx >= 4 then
				local low = (state % 65536) * 1664525
				local high = _fl(state / 65536) * 1664525
				state = (low + (high % 65536) * 65536 + 1013904223) % 4294967296
				local rnd = state
				b1 = rnd % 256
				b2 = _fl(rnd / 256) % 256
				b3 = _fl(rnd / 65536) % 256
				b4 = _fl(rnd / 16777216) % 256
				rndIdx = 0
			end
			local rndByte = (rndIdx == 0 and b4) or (rndIdx == 1 and b3) or (rndIdx == 2 and b2) or b1
			rndIdx = rndIdx + 1

			local c1 = _sByte(str, i) or 48
			local c2 = _sByte(str, i + 1) or 48
			local h1 = (c1 >= 97 and (c1 - 87)) or (c1 >= 65 and (c1 - 55)) or (c1 - 48)
			local h2 = (c2 >= 97 and (c2 - 87)) or (c2 >= 65 and (c2 - 55)) or (c2 - 48)
			local encByte = (h1 * 16 + h2) % 256

			prevVal = (encByte + rndByte + prevVal) % 256
			parts[pIdx] = prevVal
			pIdx = pIdx + 1
		end

		local outLen = pIdx - 1
		local res
		if outLen <= 1000 then
			res = _sChar(_tUnpack(parts, 1, outLen))
		else
			local chunks = {}
			local cIdx = 1
			for i = 1, outLen, 1000 do
				local j = i + 999
				if j > outLen then j = outLen end
				chunks[cIdx] = _sChar(_tUnpack(parts, i, j))
				cIdx = cIdx + 1
			end
			local _tConcat = (table and table.concat) or table.concat
			res = _tConcat(chunks)
		end

		_CACHE[key] = res
		return res
	end
end]]
		return code
	end

	return {
		encrypt = encrypt,
		secret_key_8 = secret_key_8,
		genCode = genCode,
	}
end

function EncryptStrings:apply(ast, _)
	local Encryptor = self:CreateEncryptionService()
	local scope = ast.body.scope
	local decryptVar = scope:addVariable()
	local strRng = RandomDomains.get("STRINGS")
	local fnVarName = "__z_dec_" .. tostring((strRng and strRng:random(1000, 9999)) or 4321)
	local code = Encryptor.genCode(fnVarName)
	local newAst = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(code)
	local doStat = newAst.body.statements[1]

	doStat.body.scope:setParent(ast.body.scope)

	visitast(newAst, nil, function(node, data)
		if (node.kind == AstKind.AssignmentVariable or node.kind == AstKind.VariableExpression) then
			if (node.scope:getVariableName(node.id) == fnVarName) then
				data.scope:removeReferenceToHigherScope(node.scope, node.id)
				data.scope:addReferenceToHigherScope(scope, decryptVar)
				node.scope = scope
				node.id = decryptVar
			end
		end
		node.__do_not_touch = true
	end)

	visitast(ast, nil, function(node, data)
		if (node.kind == AstKind.StringExpression) then
			if node.__do_not_touch or node.__semantic_preserve or node.__preserve_metamethod_dispatch then
				return node
			end
			if data and data.parent and (data.parent.kind == AstKind.KeyedTableEntry and data.key == "key"
				or ((data.parent.kind == AstKind.IndexExpression or data.parent.kind == AstKind.AssignmentIndexing) and data.key == "index")) then
				return node
			end
			local encrypted, seed = Encryptor.encrypt(node.value)
			local encStrNode = Ast.StringExpression(encrypted)
			encStrNode.__do_not_touch = true
			local seedNode = Ast.NumberExpression(seed)
			seedNode.__do_not_touch = true

			local varNode = Ast.VariableExpression(scope, decryptVar)
			varNode.__do_not_touch = true
			varNode.__ignoreProxifyLocals = true

			local callExpr = Ast.FunctionCallExpression(varNode, {
				encStrNode, seedNode,
			})
			callExpr.__do_not_touch = true
			return callExpr
		end
	end)

	-- Protect string literals inside doStat from downstream steps
	visitast(doStat, nil, function(node)
		if node.kind == AstKind.StringExpression then
			node.__do_not_touch = true
		end
	end)

	-- Insert to Main Ast
	table.insert(ast.body.statements, 1, doStat)
	local localDecl = Ast.LocalVariableDeclaration(scope, { decryptVar }, {})
	localDecl.__do_not_touch = true
	table.insert(ast.body.statements, 1, localDecl)
	return ast
end

return EncryptStrings

