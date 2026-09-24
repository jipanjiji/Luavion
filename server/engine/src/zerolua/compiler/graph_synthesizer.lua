-- This Script is Part of the Zero Lua Obfuscator v4.3
--
-- graph_synthesizer.lua
--
-- Unified Micro-Graph Synthesizer for Zero Lua v4.3.
-- Integrates Semantic IR lowering with RecipeGenerator across decentralized kernel families (Â§2.1 & Â§2.2).
-- Ensures identical IR nodes yield divergent execution topologies without redundant uncoordinated random layers.

local SemanticIR = require("zerolua.compiler.semantic_ir")
local RecipeGenerator = require("zerolua.compiler.recipe_generator")

local GraphSynthesizer = {}

local OP_TO_NAME = {
	[SemanticIR.IR_MOVE] = "MOVE",
	[SemanticIR.IR_LOADK] = "LOADK",
	[SemanticIR.IR_ADD] = "ADD",
	[SemanticIR.IR_SUB] = "SUB",
	[SemanticIR.IR_MUL] = "MUL",
	[SemanticIR.IR_DIV] = "DIV",
	[SemanticIR.IR_MOD] = "MOD",
	[SemanticIR.IR_POW] = "POW",
	[SemanticIR.IR_UNM] = "UNM",
	[SemanticIR.IR_NOT] = "NOT",
	[SemanticIR.IR_LEN] = "LEN",
	[SemanticIR.IR_CONCAT] = "CONCAT",
	[SemanticIR.IR_GETTABLE] = "GETTABLE",
	[SemanticIR.IR_SETTABLE] = "SETTABLE",
	[SemanticIR.IR_NEWTABLE] = "NEWTABLE",
	[SemanticIR.IR_GETGLOBAL] = "GETGLOBAL",
	[SemanticIR.IR_SETGLOBAL] = "SETGLOBAL",
	[SemanticIR.IR_CALL] = "CALL",
	[SemanticIR.IR_RETURN] = "RETURN",
	[SemanticIR.IR_CLOSURE] = "CLOSURE",
	[SemanticIR.IR_VARARG] = "VARARG",
}

function GraphSynthesizer.new(rng, profile)
	local self = setmetatable({}, { __index = GraphSynthesizer })
	self.rng = rng
	self.profile = profile or {}
	self.generator = RecipeGenerator.new(profile, profile and profile.keyMaterial)
	return self
end

function GraphSynthesizer:synthesize(irNode)
	local op = irNode.op
	local a = irNode.a or 0
	local b = irNode.b or 0
	local c = irNode.c or 0
	local opName = (type(op) == "string" and op) or OP_TO_NAME[op] or "MOVE"
	local baseOpName = opName:match("^(.*)_ALT$") or opName

	return self.generator:generateRecipe(baseOpName, a, b, c, irNode.regionId)
end

return GraphSynthesizer
