-- This Script is Part of the Zero Lua Obfuscator v3.1
--
-- graph_templates.lua
--
-- Polymorphic Micro-Graph Execution Templates for Zero Lua v3.1.
-- Provides multiple structural graph recipes per semantic family (ADD, SUB, GETTABLE, CALL, etc.)
-- ensuring identical high-level logic yields divergent execution topologies.

local MicroOps = require("zerolua.compiler.micro_ops")

local GraphTemplates = {}

-- Arithmetic Templates
GraphTemplates.ARITHMETIC = {
	[1] = function(recipe, dst, src1, src2)
		return {
			{ mop = MicroOps.MOP_READ_REG, src = src1, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = src2, dstState = 2 },
			{ mop = MicroOps.MOP_MERGE_STATE, s1 = 1, s2 = 2, dstState = 3, recipe = recipe },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 3, dst = dst }
		}
	end,
	[2] = function(recipe, dst, src1, src2)
		return {
			{ mop = MicroOps.MOP_READ_REG, src = src2, dstState = 2 },
			{ mop = MicroOps.MOP_CREATE_TEMP, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = src1, dstState = 1 },
			{ mop = MicroOps.MOP_MERGE_STATE, s1 = 1, s2 = 2, dstState = 3, recipe = recipe },
			{ mop = MicroOps.MOP_NORMALIZE, srcState = 3, dstState = 3 },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 3, dst = dst }
		}
	end,
	[3] = function(recipe, dst, src1, src2)
		return {
			{ mop = MicroOps.MOP_CREATE_TEMP, dstState = 1 },
			{ mop = MicroOps.MOP_CREATE_TEMP, dstState = 2 },
			{ mop = MicroOps.MOP_READ_REG, src = src1, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = src2, dstState = 2 },
			{ mop = MicroOps.MOP_MERGE_STATE, s1 = 1, s2 = 2, dstState = 1, recipe = recipe },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 1, dst = dst }
		}
	end,
	[4] = function(recipe, dst, src1, src2)
		return {
			{ mop = MicroOps.MOP_READ_REG, src = src1, dstState = 1 },
			{ mop = MicroOps.MOP_NORMALIZE, srcState = 1, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = src2, dstState = 2 },
			{ mop = MicroOps.MOP_NORMALIZE, srcState = 2, dstState = 2 },
			{ mop = MicroOps.MOP_MERGE_STATE, s1 = 1, s2 = 2, dstState = 3, recipe = recipe },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 3, dst = dst }
		}
	end,
}

-- Table Access Templates
GraphTemplates.GETTABLE = {
	[1] = function(dst, tbl, key)
		return {
			{ mop = MicroOps.MOP_READ_REG, src = tbl, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = key, dstState = 2 },
			{ mop = MicroOps.MOP_RESOLVE_REF, tblState = 1, keyState = 2, dstState = 3 },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 3, dst = dst }
		}
	end,
	[2] = function(dst, tbl, key)
		return {
			{ mop = MicroOps.MOP_CREATE_TEMP, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = tbl, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = key, dstState = 2 },
			{ mop = MicroOps.MOP_RESOLVE_REF, tblState = 1, keyState = 2, dstState = 1 },
			{ mop = MicroOps.MOP_WRITE_REG, srcState = 1, dst = dst }
		}
	end,
}

GraphTemplates.SETTABLE = {
	[1] = function(tbl, key, val)
		return {
			{ mop = MicroOps.MOP_READ_REG, src = tbl, dstState = 1 },
			{ mop = MicroOps.MOP_READ_REG, src = key, dstState = 2 },
			{ mop = MicroOps.MOP_READ_REG, src = val, dstState = 3 },
			{ mop = MicroOps.MOP_MUTATE_REF, tblState = 1, keyState = 2, valState = 3 }
		}
	end,
}

function GraphTemplates.getArithmeticTemplate(strategy, recipe, dst, src1, src2)
	local tmpl = GraphTemplates.ARITHMETIC[strategy] or GraphTemplates.ARITHMETIC[1]
	return tmpl(recipe, dst, src1, src2)
end

function GraphTemplates.getTableReadTemplate(strategy, dst, tbl, key)
	local tmpl = GraphTemplates.GETTABLE[strategy] or GraphTemplates.GETTABLE[1]
	return tmpl(dst, tbl, key)
end

function GraphTemplates.getTableWriteTemplate(strategy, tbl, key, val)
	local tmpl = GraphTemplates.SETTABLE[strategy] or GraphTemplates.SETTABLE[1]
	return tmpl(tbl, key, val)
end

return GraphTemplates
