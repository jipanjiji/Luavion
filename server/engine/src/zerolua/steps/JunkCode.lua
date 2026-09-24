-- This Script is Part of the Zero Impact Obfuscator
--
-- JunkCode.lua
--
-- This Script provides an Obfuscation Step that dynamically injects dead code and junk variables.

local Step = require("zerolua.step");
local Ast = require("zerolua.ast");
local Scope = require("zerolua.scope");
local visitast = require("zerolua.visitast");
local RandomStrings = require("zerolua.randomStrings");

local JunkCode = Step:extend();
JunkCode.Description = "This Step dynamically injects junk variables, mathematical expressions, and fake conditional statements to disrupt AI models and decompilers.";
JunkCode.Name = "Junk Code Injection";

JunkCode.SettingsDescriptor = {
	Intensity = {
		name = "Intensity",
		description = "Percentage of statements to inject junk code after (0.0 to 1.0)",
		type = "number",
		default = 0.2,
		min = 0,
		max = 1,
	}
}

function JunkCode:init(_) end

local function generateJunkExpr(scope)
	local choices = {
		function() -- Multi-term affine addition
			return Ast.AddExpression(
				Ast.MulExpression(Ast.NumberExpression(math.random(2, 20)), Ast.NumberExpression(math.random(3, 15))),
				Ast.NumberExpression(math.random(1, 50))
			)
		end,
		function() -- Multi-term subtraction
			return Ast.SubExpression(
				Ast.NumberExpression(math.random(500, 2000)),
				Ast.MulExpression(Ast.NumberExpression(math.random(2, 10)), Ast.NumberExpression(math.random(5, 25)))
			)
		end,
		function() -- Multi-term multiplication
			return Ast.MulExpression(
				Ast.AddExpression(Ast.NumberExpression(math.random(2, 12)), Ast.NumberExpression(math.random(1, 8))),
				Ast.NumberExpression(math.random(2, 9))
			)
		end,
		function() -- Table constructor expression with dynamic random key
			return Ast.TableConstructorExpression({
				Ast.KeyedTableEntry(Ast.StringExpression(RandomStrings.randomString(math.random(6, 10))), Ast.NumberExpression(math.random(100, 999)))
			})
		end
	}
	return choices[math.random(#choices)]()
end

local function generateOpaqueFalseCond()
	local randK = math.random(13, 89)
	local choice = math.random(1, 3)
	if choice == 1 then
		-- ((randK * 2) % 2) == 1  [Always false: even number mod 2 is 0]
		local mul2 = Ast.MulExpression(Ast.NumberExpression(randK), Ast.NumberExpression(2))
		local mod2 = Ast.ModExpression(mul2, Ast.NumberExpression(2))
		return Ast.EqualsExpression(mod2, Ast.NumberExpression(1))
	elseif choice == 2 then
		-- (randK + 10) < randK  [Always false]
		local add10 = Ast.AddExpression(Ast.NumberExpression(randK), Ast.NumberExpression(10))
		return Ast.LessThanExpression(add10, Ast.NumberExpression(randK))
	else
		-- (randK * randK) < 0  [Always false]
		local mulSelf = Ast.MulExpression(Ast.NumberExpression(randK), Ast.NumberExpression(randK))
		return Ast.LessThanExpression(mulSelf, Ast.NumberExpression(0))
	end
end

function JunkCode:apply(ast)
	visitast(ast, nil, function(node, data)
		if node.__do_not_touch then return end
		if node.kind == Ast.AstKind.Block then
			local statements = node.statements
			local newStatements = {}
			for i = 1, #statements do
				local statement = statements[i]
				table.insert(newStatements, statement)
				
				-- Inject junk statement based on intensity
				local isTerminal = (statement.kind == Ast.AstKind.ReturnStatement or statement.kind == Ast.AstKind.BreakStatement)
				if math.random() <= self.Intensity and not isTerminal and i < #statements then
					local scope = node.scope
					local junkType = math.random(1, 3)
					
					if junkType == 1 then
						-- Type 1: local _junk = expression
						local junkVarId = scope:addVariable()
						local junkExpr = generateJunkExpr(scope)
						local junkDecl = Ast.LocalVariableDeclaration(scope, {junkVarId}, {junkExpr})
						junkDecl.__do_not_touch = true
						table.insert(newStatements, junkDecl)
					elseif junkType == 2 then
						-- Type 2: an isolated fake "if false then local _junk = expr end" statement with dynamic condition
						local cond = generateOpaqueFalseCond()
						local bodyScope = Scope:new(scope)
						local junkVarId = bodyScope:addVariable()
						local junkExpr = generateJunkExpr(bodyScope)
						local body = Ast.Block({
							Ast.LocalVariableDeclaration(bodyScope, {junkVarId}, {junkExpr})
						}, bodyScope)
						body.__do_not_touch = true
						local junkIf = Ast.IfStatement(cond, body)
						junkIf.__do_not_touch = true
						table.insert(newStatements, junkIf)
					elseif junkType == 3 then
						-- Type 3: a complete fake "if false then" statement with dynamic condition
						local cond = generateOpaqueFalseCond()
						local bodyScope = Scope:new(scope)
						
						local dummyId = bodyScope:addVariable()
						local dummyDecl = Ast.LocalVariableDeclaration(bodyScope, {dummyId}, {generateJunkExpr(bodyScope)})
						dummyDecl.__do_not_touch = true
						
						local body = Ast.Block({dummyDecl}, bodyScope)
						body.__do_not_touch = true
						local junkIf = Ast.IfStatement(cond, body)
						junkIf.__do_not_touch = true
						table.insert(newStatements, junkIf)
					end
				end
			end
			node.statements = newStatements
		end
	end)
end

return JunkCode;
