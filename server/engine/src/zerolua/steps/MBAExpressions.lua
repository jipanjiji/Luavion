-- This Script is Part of the Zero Lua Obfuscator v1.9
--
-- MBAExpressions.lua
--
-- Mixed Boolean-Arithmetic (MBA) Transformation Step for Zero Lua V1.9.
-- Transforms arithmetic expressions and boolean logic into non-canonicalizable
-- equivalent algebraic forms while preserving 100% Lua/LuaU semantics.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local visitast = require("zerolua.visitast")
local RandomDomains = require("zerolua.random_domains")
local AstKind = Ast.AstKind

local MBAExpressions = Step:extend()
MBAExpressions.Description = "Transforms numeric operations and boolean logic into non-canonicalizable Mixed Boolean-Arithmetic (MBA) equations."
MBAExpressions.Name = "MBA Expressions"

MBAExpressions.SettingsDescriptor = {
	Intensity = {
		type = "number",
		default = 0.35,
		min = 0,
		max = 1,
	},
}

function MBAExpressions:init(_) end

local function isSideEffectFree(node)
	if not node then return false end
	local k = node.kind
	if k == AstKind.NumberExpression then
		return true
	end

	if k == AstKind.AddExpression or
	   k == AstKind.SubExpression or
	   k == AstKind.MulExpression or
	   k == AstKind.DivExpression or
	   k == AstKind.ModExpression or
	   k == AstKind.PowExpression then
		return isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs)
	end

	return false
end

function MBAExpressions:apply(ast, settings)
	local intensity = (settings and settings.Intensity) or self.SettingsDescriptor.Intensity.default
	local rng = RandomDomains.get("OBFUSCATION")

	visitast(ast, nil, function(node, data)
		if not node or node.__do_not_touch or node.__mba_transformed then
			return node
		end

		local randVal = (rng and rng:random()) or math.random()
		if randVal > intensity then
			return node
		end

		local k = node.kind

		-- Arithmetic Add: a + b
		if k == AstKind.AddExpression then
			if isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs) then
				local isNum = (node.lhs.kind == AstKind.NumberExpression or node.rhs.kind == AstKind.NumberExpression)
				local choice = (rng and rng:random(1, 4)) or math.random(1, 4)
				local res
				if isNum and choice == 1 then
					-- (a - b) + (2 * b)
					local diff = Ast.SubExpression(node.lhs, node.rhs)
					local doubleRhs = Ast.MulExpression(node.rhs, Ast.NumberExpression(2))
					res = Ast.AddExpression(diff, doubleRhs)
				elseif isNum and choice == 2 then
					-- (2 * a - a) + b
					local doubleLhs = Ast.MulExpression(node.lhs, Ast.NumberExpression(2))
					local subLhs = Ast.SubExpression(doubleLhs, node.lhs)
					res = Ast.AddExpression(subLhs, node.rhs)
				elseif choice == 3 or not isNum then
					-- (a - b) + b + b
					local diff = Ast.SubExpression(node.lhs, node.rhs)
					local addB = Ast.AddExpression(diff, node.rhs)
					res = Ast.AddExpression(addB, node.rhs)
				else
					-- (a + b + b) - b
					local sum1 = Ast.AddExpression(node.lhs, node.rhs)
					local sum2 = Ast.AddExpression(sum1, node.rhs)
					res = Ast.SubExpression(sum2, node.rhs)
				end
				res.__do_not_touch = true
				res.__mba_transformed = true
				return res
			end
		end

		-- Arithmetic Sub: a - b
		if k == AstKind.SubExpression then
			if isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs) then
				local isNum = (node.lhs.kind == AstKind.NumberExpression or node.rhs.kind == AstKind.NumberExpression)
				local choice = (rng and rng:random(1, 4)) or math.random(1, 4)
				local res
				if isNum and choice == 1 then
					-- (a + b) - (2 * b)
					local sum = Ast.AddExpression(node.lhs, node.rhs)
					local doubleRhs = Ast.MulExpression(node.rhs, Ast.NumberExpression(2))
					res = Ast.SubExpression(sum, doubleRhs)
				elseif isNum and choice == 2 then
					-- (2 * a) - (a + b)
					local doubleLhs = Ast.MulExpression(node.lhs, Ast.NumberExpression(2))
					local sum = Ast.AddExpression(node.lhs, node.rhs)
					res = Ast.SubExpression(doubleLhs, sum)
				elseif choice == 3 or not isNum then
					-- (a + b) - b - b
					local sum = Ast.AddExpression(node.lhs, node.rhs)
					local sub1 = Ast.SubExpression(sum, node.rhs)
					res = Ast.SubExpression(sub1, node.rhs)
				else
					-- (a - b - b) + b
					local sub1 = Ast.SubExpression(node.lhs, node.rhs)
					local sub2 = Ast.SubExpression(sub1, node.rhs)
					res = Ast.AddExpression(sub2, node.rhs)
				end
				res.__do_not_touch = true
				res.__mba_transformed = true
				return res
			end
		end

		-- Arithmetic Mul: a * b
		if k == AstKind.MulExpression then
			if isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs) then
				local choice = (rng and rng:random(1, 3)) or math.random(1, 3)
				local res
				if choice == 1 then
					-- (a * (b + 1)) - a
					local bPlus1 = Ast.AddExpression(node.rhs, Ast.NumberExpression(1))
					local mul = Ast.MulExpression(node.lhs, bPlus1)
					res = Ast.SubExpression(mul, node.lhs)
				elseif choice == 2 then
					-- (a * (b + 2)) - (2 * a)
					local bPlus2 = Ast.AddExpression(node.rhs, Ast.NumberExpression(2))
					local mul = Ast.MulExpression(node.lhs, bPlus2)
					local a2 = Ast.MulExpression(Ast.NumberExpression(2), node.lhs)
					res = Ast.SubExpression(mul, a2)
				else
					-- ((2 * a) * b) - (a * b)
					local a2 = Ast.MulExpression(Ast.NumberExpression(2), node.lhs)
					local mul1 = Ast.MulExpression(a2, node.rhs)
					local mul2 = Ast.MulExpression(node.lhs, node.rhs)
					res = Ast.SubExpression(mul1, mul2)
				end
				res.__do_not_touch = true
				res.__mba_transformed = true
				return res
			end
		end



		-- Boolean Equals: a == b => not (a ~= b)
		if k == AstKind.EqualsExpression then
			if isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs) then
				local notEq = Ast.NotEqualsExpression(node.lhs, node.rhs)
				local res = Ast.NotExpression(notEq)
				res.__do_not_touch = true
				res.__mba_transformed = true
				return res
			end
		end

		-- Boolean NotEquals: a ~= b => not (a == b)
		if k == AstKind.NotEqualsExpression then
			if isSideEffectFree(node.lhs) and isSideEffectFree(node.rhs) then
				local eq = Ast.EqualsExpression(node.lhs, node.rhs)
				local res = Ast.NotExpression(eq)
				res.__do_not_touch = true
				res.__mba_transformed = true
				return res
			end
		end
	end)

	return ast
end

return MBAExpressions

