-- This Script is Part of the Zero Lua Obfuscator v1.9
--
-- OpaquePredicates.lua
--
-- Non-Trivial Mathematical Invariant Injection Step for Zero Lua V1.9.
-- Injects opaque branch conditions based on number theory and algebraic invariants
-- to disrupt static control flow analysis and symbolic execution.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local visitast = require("zerolua.visitast")
local Scope = require("zerolua.scope")
local RandomDomains = require("zerolua.random_domains")

local OpaquePredicates = Step:extend()
OpaquePredicates.Description = "Injects non-trivial mathematical invariants to create dead-end symbolic execution branches."
OpaquePredicates.Name = "Opaque Predicates"

OpaquePredicates.SettingsDescriptor = {
	Intensity = {
		type = "number",
		default = 0.15,
		min = 0,
		max = 1,
	},
}

function OpaquePredicates:init(_) end

local function generateInvariantCondition(rng)
	local choice = (rng and rng:random(1, 14)) or math.random(1, 14)
	local randX = (rng and rng:random(11, 99)) or math.random(11, 99)
	local exprX = Ast.NumberExpression(randX)

	if choice == 1 then
		-- (x * (x + 1)) % 2 == 0  [Consecutive integer product parity]
		local exprXPlus1 = Ast.AddExpression(exprX, Ast.NumberExpression(1))
		local mulExpr = Ast.MulExpression(exprX, exprXPlus1)
		local modExpr = Ast.ModExpression(mulExpr, Ast.NumberExpression(2))
		return Ast.EqualsExpression(modExpr, Ast.NumberExpression(0))
	elseif choice == 2 then
		-- (x ^ 2 + c) > 0  [Strict positive square residue]
		local randC = (rng and rng:random(1, 47)) or math.random(1, 47)
		local powExpr = Ast.PowExpression(exprX, Ast.NumberExpression(2))
		local addExpr = Ast.AddExpression(powExpr, Ast.NumberExpression(randC))
		return Ast.GreaterThanExpression(addExpr, Ast.NumberExpression(0))
	elseif choice == 3 then
		-- ((x * 4 + 2) % 4) == 2  [Modular congruence invariant]
		local mul4 = Ast.MulExpression(exprX, Ast.NumberExpression(4))
		local add2 = Ast.AddExpression(mul4, Ast.NumberExpression(2))
		local mod4 = Ast.ModExpression(add2, Ast.NumberExpression(4))
		return Ast.EqualsExpression(mod4, Ast.NumberExpression(2))
	elseif choice == 4 then
		-- ((x * 6 + 3) % 3) == 0  [Linear divisor invariant]
		local mul6 = Ast.MulExpression(exprX, Ast.NumberExpression(6))
		local add3 = Ast.AddExpression(mul6, Ast.NumberExpression(3))
		local mod3 = Ast.ModExpression(add3, Ast.NumberExpression(3))
		return Ast.EqualsExpression(mod3, Ast.NumberExpression(0))
	elseif choice == 5 then
		-- (x ^ 2 + x + 2) % 2 == 0  [Quadratic polynomial parity]
		local pow2 = Ast.PowExpression(exprX, Ast.NumberExpression(2))
		local addX = Ast.AddExpression(pow2, exprX)
		local add2 = Ast.AddExpression(addX, Ast.NumberExpression(2))
		local mod2 = Ast.ModExpression(add2, Ast.NumberExpression(2))
		return Ast.EqualsExpression(mod2, Ast.NumberExpression(0))
	elseif choice == 6 then
		-- (x * x) % 4 ~= 2  [Quadratic residue non-congruence invariant]
		local mulSelf = Ast.MulExpression(exprX, exprX)
		local mod4 = Ast.ModExpression(mulSelf, Ast.NumberExpression(4))
		return Ast.NotEqualsExpression(mod4, Ast.NumberExpression(2))
	elseif choice == 7 then
		-- (x * (x + 1) * (x + 2)) % 3 == 0  [Consecutive triplet product divisor invariant]
		local x1 = Ast.AddExpression(exprX, Ast.NumberExpression(1))
		local x2 = Ast.AddExpression(exprX, Ast.NumberExpression(2))
		local m1 = Ast.MulExpression(exprX, x1)
		local m2 = Ast.MulExpression(m1, x2)
		local mod3 = Ast.ModExpression(m2, Ast.NumberExpression(3))
		return Ast.EqualsExpression(mod3, Ast.NumberExpression(0))
	elseif choice == 8 then
		-- (x * x + c) >= c  [Quadratic lower bound]
		local randC = (rng and rng:random(3, 97)) or math.random(3, 97)
		local mulSelf = Ast.MulExpression(exprX, exprX)
		local addC = Ast.AddExpression(mulSelf, Ast.NumberExpression(randC))
		return Ast.GreaterThanOrEqualsExpression(addC, Ast.NumberExpression(randC))
	elseif choice == 9 then
		-- ((x ^ 3 - x) % 3) == 0  [Fermat's Little Theorem for p=3]
		local cube = Ast.MulExpression(Ast.MulExpression(exprX, exprX), exprX)
		local diff = Ast.SubExpression(cube, exprX)
		local mod3 = Ast.ModExpression(diff, Ast.NumberExpression(3))
		return Ast.EqualsExpression(mod3, Ast.NumberExpression(0))
	elseif choice == 10 then
		-- ((x ^ 5 - x) % 5) == 0  [Fermat's Little Theorem for p=5]
		local quad = Ast.MulExpression(Ast.MulExpression(exprX, exprX), Ast.MulExpression(exprX, exprX))
		local p5 = Ast.MulExpression(quad, exprX)
		local diff = Ast.SubExpression(p5, exprX)
		local mod5 = Ast.ModExpression(diff, Ast.NumberExpression(5))
		return Ast.EqualsExpression(mod5, Ast.NumberExpression(0))
	elseif choice == 11 then
		-- (x * x) % 3 ~= 2  [Quadratic Non-Residue modulo 3]
		local mulSelf = Ast.MulExpression(exprX, exprX)
		local mod3 = Ast.ModExpression(mulSelf, Ast.NumberExpression(3))
		return Ast.NotEqualsExpression(mod3, Ast.NumberExpression(2))
	elseif choice == 12 then
		-- (x * x) % 5 ~= 2  [Quadratic Non-Residue modulo 5]
		local mulSelf = Ast.MulExpression(exprX, exprX)
		local mod5 = Ast.ModExpression(mulSelf, Ast.NumberExpression(5))
		return Ast.NotEqualsExpression(mod5, Ast.NumberExpression(2))
	elseif choice == 13 then
		-- (x ^ 4 + x ^ 2 + 1) > 0  [Strictly positive definite biquadratic polynomial]
		local x2 = Ast.MulExpression(exprX, exprX)
		local x4 = Ast.MulExpression(x2, x2)
		local poly = Ast.AddExpression(Ast.AddExpression(x4, x2), Ast.NumberExpression(1))
		return Ast.GreaterThanExpression(poly, Ast.NumberExpression(0))
	else
		-- ((x * (x ^ 2 + 5)) % 6) == 0  [Modular cubic parity invariant]
		local x2 = Ast.MulExpression(exprX, exprX)
		local x2Plus5 = Ast.AddExpression(x2, Ast.NumberExpression(5))
		local prod = Ast.MulExpression(exprX, x2Plus5)
		local mod6 = Ast.ModExpression(prod, Ast.NumberExpression(6))
		return Ast.EqualsExpression(mod6, Ast.NumberExpression(0))
	end
end

function OpaquePredicates:apply(ast, settings)
	local intensity = (settings and settings.Intensity) or self.SettingsDescriptor.Intensity.default
	local rng = RandomDomains.get("OBFUSCATION")

	visitast(ast, nil, function(node, data)
		if node.__do_not_touch then return end
		if node.kind == Ast.AstKind.Block then
			local statements = node.statements
			local newStatements = {}
			local scope = node.scope

			for i = 1, #statements do
				local statement = statements[i]
				local randVal = (rng and rng:random()) or math.random()
				local isTerminal = (statement.kind == Ast.AstKind.ReturnStatement or statement.kind == Ast.AstKind.BreakStatement)
				local isDecl = (statement.kind == Ast.AstKind.LocalVariableDeclaration or statement.kind == Ast.AstKind.FunctionDeclaration or statement.kind == Ast.AstKind.LocalFunctionDeclaration)

				if randVal <= intensity and not isDecl and not isTerminal and not statement.__do_not_touch then
					local cond = generateInvariantCondition(rng)
					local bodyScope = Scope:new(scope)
					local elseScope = Scope:new(scope)
					local bodyBlock = Ast.Block({ statement }, bodyScope)
					local r1 = (rng and rng:random(11, 89)) or math.random(11, 89)
					local r2 = (rng and rng:random(3, 19)) or math.random(3, 19)
					local r3 = (rng and rng:random(5, 41)) or math.random(5, 41)
					local decoyVar = elseScope:addVariable()
					local decoyValue = Ast.AddExpression(Ast.MulExpression(Ast.NumberExpression(r1), Ast.NumberExpression(r2)), Ast.NumberExpression(r3))
					local decoyDecl = Ast.LocalVariableDeclaration(elseScope, { decoyVar }, { decoyValue })
					local elseBlock = Ast.Block({ decoyDecl }, elseScope)
					local opaqueIf = Ast.IfStatement(cond, bodyBlock, {}, elseBlock)
					opaqueIf.__do_not_touch = true
					table.insert(newStatements, opaqueIf)
				else
					table.insert(newStatements, statement)
					if not isTerminal and i < #statements and randVal <= (intensity * 0.5) then
						local cond = generateInvariantCondition(rng)
						local bodyScope = Scope:new(scope)
						local dummyVar = bodyScope:addVariable()
						local rA = (rng and rng:random(12, 59)) or math.random(12, 59)
						local rB = (rng and rng:random(2, 17)) or math.random(2, 17)
						local dummyValue = Ast.SubExpression(Ast.MulExpression(Ast.NumberExpression(rA), Ast.NumberExpression(rB)), Ast.NumberExpression(rA * rB))
						local dummyDecl = Ast.LocalVariableDeclaration(bodyScope, { dummyVar }, { dummyValue })
						local body = Ast.Block({ dummyDecl }, bodyScope)
						local opaqueIf = Ast.IfStatement(cond, body)
						opaqueIf.__do_not_touch = true
						table.insert(newStatements, opaqueIf)
					end
				end
			end
			node.statements = newStatements
		end
	end)
	return ast
end

return OpaquePredicates

