-- This Script is Part of the Zero Lua Obfuscator v3.3
--
-- graph_lowerer.lua
--
-- Lowers high-level Micro-Graphs into opaque combinator tuple streams for Zero Lua v3.3.
-- Completely destroys any trace of semantic strings, recipe names, and raw op identifiers.

local GraphLowerer = {}

function GraphLowerer.new(profile, rng)
	local self = setmetatable({}, { __index = GraphLowerer })
	self.profile = profile or {}
	self.rng = rng
	return self
end

function GraphLowerer:lowerGraph(microGraph)
	local loweredNodes = {}
	local nodes = microGraph.nodes or {}

	for i, node in ipairs(nodes) do
		-- Pack into flat numeric tuple: [comb, dst, s1, s2, paramA, paramB]
		local comb = node.comb or (type(node[1]) == "number" and node[1]) or 1
		local dst = node.dst or node.dstState or (type(node[2]) == "number" and node[2]) or 0
		local s1 = node.s1 or node.src or node.srcState or (type(node[3]) == "number" and node[3]) or 0
		local s2 = node.s2 or node.kIdx or (type(node[4]) == "number" and node[4]) or 0
		local pA = node.paramA or (type(node[5]) == "number" and node[5]) or 0
		local pB = node.paramB or (type(node[6]) == "number" and node[6]) or 0

		table.insert(loweredNodes, { comb, dst, s1, s2, pA, pB })
	end

	return {
		strategy = microGraph.strategy or 1,
		nodes = loweredNodes
	}
end

return GraphLowerer
