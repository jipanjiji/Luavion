-- This Script is Part of the Zero Impact Obfuscator
--
-- MathStringEscape.lua
--
-- Converts string literals into randomized string.char(((byte+rnd)-rnd), ...) AST expressions (Wynfuscate style).

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")
local Ast = require("zerolua.ast")

local MathStringEscape = Step:extend()
MathStringEscape.Description = "Converts strings into randomized Math Subtraction string.char expressions (Wynfuscate style)."
MathStringEscape.Name = "Math String Escape"

MathStringEscape.SettingsDescriptor = {}

function MathStringEscape:init(_) end

function MathStringEscape:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local scope = ast.body.scope
	local charVar = scope:addVariable()

	-- Inject string.char helper at top of AST body
	local helperCode = [[
do
	local gEnv = (_ENV or _G or {});
	local strChar = (string and string.char) or (gEnv and gEnv.string and gEnv.string.char) or string.char;
	_MATH_CHAR = function(...)
		if strChar then
			return strChar(...)
		end
		return ""
	end
end
]]

	local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(helperCode);
	local doStat = parsed.body.statements[1];

	doStat.body.scope:setParent(ast.body.scope);

	visitast(parsed, nil, function(node, data)
		if node.kind == Ast.AstKind.AssignmentVariable or node.kind == Ast.AstKind.VariableExpression then
			if node.scope:getVariableName(node.id) == "_MATH_CHAR" then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(scope, charVar);
				node.scope = scope;
				node.id = charVar;
			end
		end
		node.__do_not_touch = true;
	end)

	visitast(ast, nil, function(node, data)
		if node.kind == Ast.AstKind.StringExpression then
			if node.__do_not_touch or node.__math_escaped or node.__semantic_preserve or node.__preserve_metamethod_dispatch then
				return node
			end
			if data and data.parent and data.parent.kind == Ast.AstKind.KeyedTableEntry and data.key == "key" then
				return node
			end

			-- Apply Wynfuscate-style Subtraction Math Char Expressions for strings between 1 and 32 chars
			if #node.value >= 1 and #node.value <= 32 then
				local args = {}
				for i = 1, #node.value do
					local byteVal = string.byte(node.value, i)
					local rnd = math.random(15, 120)
					local sum = byteVal + rnd

					local subExpr = Ast.SubExpression(
						Ast.NumberExpression(sum),
						Ast.NumberExpression(rnd)
					)
					subExpr.__do_not_touch = true
					table.insert(args, subExpr)
				end

				local varNode = Ast.VariableExpression(scope, charVar)
				varNode.__do_not_touch = true
				varNode.__ignoreProxifyLocals = true
				local callNode = Ast.FunctionCallExpression(varNode, args)
				callNode.__do_not_touch = true
				node.__math_escaped = true
				return callNode
			end
		end
	end)

	table.insert(ast.body.statements, 1, doStat);
	local localDecl = Ast.LocalVariableDeclaration(scope, { charVar }, {});
	localDecl.__do_not_touch = true;
	table.insert(ast.body.statements, 1, localDecl);

	return ast
end

return MathStringEscape
