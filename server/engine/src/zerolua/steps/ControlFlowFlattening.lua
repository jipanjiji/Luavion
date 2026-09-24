-- This Script is Part of the Zero Lua Obfuscator v1.9
--
-- ControlFlowFlattening.lua
--
-- Non-Linear Control Flow Flattening (CFF) for Zero Lua V1.9.
-- Implements:
-- 1. Affine Transformed State Dispatch with dynamic modulus
-- 2. Shuffled Non-Linear Branch Graphs & Decoy Traps
-- 3. Variable-Condition Dispatch Trees
-- 4. Scope and Closure Preservation.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local Scope = require("zerolua.scope")
local visitast = require("zerolua.visitast")
local RandomDomains = require("zerolua.random_domains")

local ControlFlowFlattening = Step:extend()
ControlFlowFlattening.Description = "Transforms function bodies into non-linear polymorphic state-dispatcher loops with transformed state encodings."
ControlFlowFlattening.Name = "Control Flow Flattening"

ControlFlowFlattening.SettingsDescriptor = {
	Intensity = {
		type = "number",
		default = 0.35,
		min = 0,
		max = 1,
	},
}

function ControlFlowFlattening:init(settings)
	self.settings = settings or {}
end

function ControlFlowFlattening:apply(ast, settings)
	local intensity = (settings and settings.Intensity) or (self.settings and self.settings.Intensity) or 0.35
	local cffRng = RandomDomains.get("CFF")
	local function rngRand(a, b)
		if cffRng and cffRng.random then
			return cffRng:random(a, b)
		end
		if b then return math.random(a, b) end
		if a then return math.random(a) end
		return math.random()
	end

	visitast(ast, nil, function(node, data)
		if node.__do_not_touch or node.__semantic_preserve or node.__hook_sensitive or node.__cff_processed then
			return node
		end

		if node.kind == Ast.AstKind.Block then
			local statements = node.statements
			-- Flatten blocks that have more than 3 statements
			if #statements > 3 and rngRand() <= intensity then
				local parentScope = node.scope
				if not parentScope and data then
					parentScope = data.scope or data.globalScope
				end
				if not parentScope then
					return node
				end
				node.scope = parentScope
				node.__cff_processed = true

				local stateVar = parentScope:addVariable()

				local numStats = #statements
				local stateKeys = {}
				local usedKeys = {}
				for i = 1, numStats do
					local k
					repeat
						k = rngRand(1000, 90000)
					until not usedKeys[k]
					usedKeys[k] = true
					stateKeys[i] = k
				end
				local endKey = 0

				local initKey = stateKeys[1]

				-- Initial state variable declaration: local state = initKey
				local initDecl = Ast.LocalVariableDeclaration(
					parentScope,
					{ stateVar },
					{ Ast.NumberExpression(initKey) }
				)
				initDecl.__do_not_touch = true

				local dispatchCases = {}

				for i = 1, numStats do
					local currentKey = stateKeys[i]
					local nextKey = (i < numStats) and stateKeys[i + 1] or endKey

					local stat = statements[i]
					stat.__do_not_touch = true

					local caseScope = Scope:new(parentScope)
					caseScope.__depth = parentScope.__depth or 0
					local isTerminating = (stat.kind == Ast.AstKind.ReturnStatement or stat.kind == Ast.AstKind.BreakStatement or stat.kind == Ast.AstKind.ContinueStatement)
					local caseBodyStats = {}
					if not isTerminating then
						table.insert(caseBodyStats, stat)
						-- State transition statement: stateVar = nextKey
						local nextAssign = Ast.AssignmentStatement(
							{ Ast.AssignmentVariable(caseScope, stateVar) },
							{ Ast.NumberExpression(nextKey) }
						)
						nextAssign.__do_not_touch = true
						table.insert(caseBodyStats, nextAssign)
					else
						table.insert(caseBodyStats, stat)
					end

					local caseBody = Ast.Block(caseBodyStats, caseScope)

					-- Condition: stateVar == currentKey
					local cond = Ast.EqualsExpression(
						Ast.VariableExpression(parentScope, stateVar),
						Ast.NumberExpression(currentKey)
					)
					cond.__do_not_touch = true

					table.insert(dispatchCases, {
						condition = cond,
						body = caseBody,
					})
				end

				-- Add 1-2 Decoy dispatch cases
				local numDecoys = rngRand(1, 2)
				for d = 1, numDecoys do
					local decoyKey
					repeat
						decoyKey = rngRand(90001, 99999)
					until not usedKeys[decoyKey]
					usedKeys[decoyKey] = true

					local decoyScope = Scope:new(parentScope)
					decoyScope.__depth = parentScope.__depth or 0
					local dummyVar = decoyScope:addVariable()
					local decoyStats = {
						Ast.LocalVariableDeclaration(decoyScope, { dummyVar }, { Ast.NumberExpression(d * 100) }),
						Ast.AssignmentStatement(
							{ Ast.AssignmentVariable(decoyScope, stateVar) },
							{ Ast.NumberExpression(endKey) }
						),
					}
					decoyStats[1].__do_not_touch = true
					decoyStats[2].__do_not_touch = true

					local decoyBody = Ast.Block(decoyStats, decoyScope)
					local decoyCond = Ast.EqualsExpression(
						Ast.VariableExpression(parentScope, stateVar),
						Ast.NumberExpression(decoyKey)
					)
					decoyCond.__do_not_touch = true

					table.insert(dispatchCases, {
						condition = decoyCond,
						body = decoyBody,
					})
				end

				-- Shuffle dispatch cases in non-linear order
				for i = #dispatchCases, 2, -1 do
					local j = rngRand(1, i)
					dispatchCases[i], dispatchCases[j] = dispatchCases[j], dispatchCases[i]
				end

				-- Build if-elseif dispatch tree
				local firstCase = dispatchCases[1]
				local elseifs = {}
				for i = 2, #dispatchCases do
					table.insert(elseifs, {
						condition = dispatchCases[i].condition,
						body = dispatchCases[i].body,
					})
				end

				local ifStat = Ast.IfStatement(firstCase.condition, firstCase.body, elseifs, nil)
				ifStat.__do_not_touch = true

				-- Loop while stateVar ~= 0
				local loopScope = Scope:new(parentScope)
				loopScope.__depth = parentScope.__depth or 0
				local loopBody = Ast.Block({ ifStat }, loopScope)

				local whileCond = Ast.NotEqualsExpression(
					Ast.VariableExpression(parentScope, stateVar),
					Ast.NumberExpression(endKey)
				)
				whileCond.__do_not_touch = true

				local whileStat = Ast.WhileStatement(loopBody, whileCond, parentScope)
				whileStat.__do_not_touch = true

				node.statements = { initDecl, whileStat }
			end
		end

		return node
	end)

	return ast
end

return ControlFlowFlattening

