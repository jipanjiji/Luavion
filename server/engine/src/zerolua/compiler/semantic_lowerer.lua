-- This Script is Part of the Zero Lua Obfuscator v4.0
--
-- semantic_lowerer.lua
--
-- Lowers Semantic IR into Polymorphic, Multi-Node Micro-Code Execution Graphs.
-- Emits variable-length opaque combinator tuples [mop, dst, s1, s2, pa, pb] with ZERO semantic metadata.
-- Destroys 1:1 opcode-to-micro-node mappings by using dynamic recipe generation.

local MicroISA = require("zerolua.compiler.micro_isa")
local GraphSynthesizer = require("zerolua.compiler.graph_synthesizer")

local SemanticLowerer = {}

function SemanticLowerer.new(profile, rng)
	local self = setmetatable({}, { __index = SemanticLowerer })
	self.profile = profile or {}
	self.rng = rng
	self.salt = (profile and profile.protoSalt) or 1337
	self.synthesizer = GraphSynthesizer.new(rng, profile)
	return self
end

function SemanticLowerer:lowerOp(opName, A, B, C, regionId)
	A = A or 0
	B = B or 0
	C = C or 0

	local recipe = self.synthesizer:synthesize({ op = opName, a = A, b = B, c = C, regionId = regionId })
	if recipe and #recipe > 0 then
		return recipe
	end

	error("ZeroLua Semantic Invariant Violation: Failed to synthesize micro-graph for opcode '" .. tostring(opName) .. "' (fail-closed)", 0)
end

return SemanticLowerer
