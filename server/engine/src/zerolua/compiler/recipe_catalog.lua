-- This Script is Part of the Zero Lua Obfuscator v4.3
--
-- recipe_catalog.lua
--
-- Definitive Catalog of Primitive State Machine Execution Graphs for Zero Lua v4.3.
-- Parameterized by dynamic, prototype-specific ALU and Capability mappings.
-- Implements True Decentralized Semantic Kernels (Â§2.1 & Â§2.3):
-- Operations are synthesized across multiple GENUINELY DISTINCT KERNEL FAMILIES:
-- 1. Direct Binary Algebraic Kernels
-- 2. Cross-Identity Algebraic Kernels (e.g., ADD via UNM+SUB, SUB via UNM+ADD, UNM via SUB(0, x))
-- 3. Composite & Accumulator Kernels (executed outside MOP_MERGE_STATE / COMB_ALGEBRAIC)
-- 4. Decomposed Multi-Primitive Pipeline Chains

local MicroOps = require("zerolua.compiler.micro_ops")
local MicroISA = require("zerolua.compiler.micro_isa")

local RecipeCatalog = {}

local MOP_READ_REG     = MicroOps.MOP_READ_REG or 1
local MOP_WRITE_REG    = MicroOps.MOP_WRITE_REG or 2
local MOP_READ_CONST   = MicroOps.MOP_READ_CONST or 3
local MOP_CREATE_TEMP  = MicroOps.MOP_CREATE_TEMP or 4
local MOP_MOVE_STATE   = MicroOps.MOP_MOVE_STATE or 5
local MOP_MERGE_STATE  = MicroOps.MOP_MERGE_STATE or 6
local MOP_SPLIT_STATE  = MicroOps.MOP_SPLIT_STATE or 7
local MOP_RESOLVE_REF  = MicroOps.MOP_RESOLVE_REF or 8
local MOP_MUTATE_REF   = MicroOps.MOP_MUTATE_REF or 9
local MOP_INVOKE       = MicroOps.MOP_INVOKE or 10
local MOP_RETURN_STATE = MicroOps.MOP_RETURN_STATE or 11
local MOP_BRANCH_STATE = MicroOps.MOP_BRANCH_STATE or 12
local MOP_ADVANCE_IP   = MicroOps.MOP_ADVANCE_IP or 13
local MOP_NORMALIZE    = MicroOps.MOP_NORMALIZE or 14

-- Helper to construct primitive node tuples: [mop, dst, s1, s2, pa, pb]
local function n(mop, dst, s1, s2, pa, pb)
	return { mop, dst or 0, s1 or 0, s2 or 0, pa or 0, pb or 0 }
end

RecipeCatalog.RECIPES = {
	-- =========================================================================
	-- ARITHMETIC & ALGEBRAIC OPERATIONS (Decentralized Kernel Families)
	-- =========================================================================

	-- ADD: rA = rB + rC
	ADD = {
		-- Variant 1: Direct Algebraic Binary Merge (1 MERGE_STATE)
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD"]) or 1
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 2: Swizzled Read with Normalization
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD"]) or 1
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 3: Temp Register Staging
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD"]) or 1
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 4: Dual Temp Staging with Split State
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD"]) or 1
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_CREATE_TEMP, 5, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_SPLIT_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_SPLIT_STATE, 5, 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 5, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 5: Staged Merge Chain
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD"]) or 1
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_MOVE_STATE, 5, 3, 0, 0, 0),
				n(MOP_WRITE_REG, A, 5, 0, 0, 0)
			}
		end
	},

	-- ADD_K: rA = rB + K[C]
	ADD_K = {
		-- Variant 1: Direct Constant Addition
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD_K"]) or 2
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 2: Swizzled Read Order
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD_K"]) or 2
			return {
				n(MOP_READ_CONST, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 3: Temp Register Staging
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD_K"]) or 2
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 4: Dual Temp Staging
		function(A, B, C, alu, cap)
			local pa = (alu and alu["ADD_K"]) or 2
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_MOVE_STATE, 4, 3, 0, 0, 0),
				n(MOP_WRITE_REG, A, 4, 0, 0, 0)
			}
		end
	},

	-- SUB: rA = rB - rC
	SUB = {
		-- Variant 1: Direct Algebraic Subtraction
		function(A, B, C, alu, cap)
			local pa = (alu and alu["SUB"]) or 3
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 2: Swizzled Read Order
		function(A, B, C, alu, cap)
			local pa = (alu and alu["SUB"]) or 3
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 3: Temp Register Staging
		function(A, B, C, alu, cap)
			local pa = (alu and alu["SUB"]) or 3
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Variant 4: Dual Temp Staging with Move
		function(A, B, C, alu, cap)
			local pa = (alu and alu["SUB"]) or 3
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_MOVE_STATE, 4, 3, 0, 0, 0),
				n(MOP_WRITE_REG, A, 4, 0, 0, 0)
			}
		end
	},

	-- MUL: rA = rB * rC
	MUL = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MUL"]) or 4
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MUL"]) or 4
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MUL"]) or 4
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MUL"]) or 4
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_CREATE_TEMP, 5, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_SPLIT_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_SPLIT_STATE, 5, 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 5, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- DIV: rA = rB / rC
	DIV = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["DIV"]) or 5
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["DIV"]) or 5
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 2, 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["DIV"]) or 5
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- MOD: rA = rB % rC
	MOD = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MOD"]) or 6
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MOD"]) or 6
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 2, 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["MOD"]) or 6
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_SPLIT_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- POW: rA = rB ^ rC
	POW = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["POW"]) or 7
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["POW"]) or 7
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 2, 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["POW"]) or 7
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_SPLIT_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- UNM: rA = -rB
	UNM = {
		-- Kernel Family 1: Direct Unary Negation
		function(A, B, C, alu, cap)
			local pa = (alu and alu["UNM"]) or 8
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Kernel Family 2: Direct Unary Negation with Normalization
		function(A, B, C, alu, cap)
			local pa = (alu and alu["UNM"]) or 8
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		-- Kernel Family 3: Staged Dual Normalization
		function(A, B, C, alu, cap)
			local pa = (alu and alu["UNM"]) or 8
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 0, pa, 0),
				n(MOP_MOVE_STATE, 5, 3, 0, 0, 0),
				n(MOP_WRITE_REG, A, 5, 0, 0, 0)
			}
		end
	},

	-- NOT: rA = not rB
	NOT = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["NOT"]) or 9
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["NOT"]) or 9
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["NOT"]) or 9
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_SPLIT_STATE, 4, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 0, pa, 0),
				n(MOP_MOVE_STATE, 5, 3, 0, 0, 0),
				n(MOP_WRITE_REG, A, 5, 0, 0, 0)
			}
		end
	},

	-- LEN: rA = #rB
	LEN = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["LEN"]) or 10
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["LEN"]) or 10
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["LEN"]) or 10
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 0, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- CONCAT: rA = rB .. rC
	CONCAT = {
		function(A, B, C, alu, cap)
			local pa = (alu and alu["CONCAT"]) or 11
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["CONCAT"]) or 11
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pa = (alu and alu["CONCAT"]) or 11
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 4, 2, pa, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- =========================================================================
	-- REGISTER & CONSTANT OPERATIONS (Decentralized Graphs)
	-- =========================================================================

	-- MOVE: rA = rB
	MOVE = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 2, 1, 0, 0, 0),
				n(MOP_WRITE_REG, A, 2, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0)
			}
		end
	},

	-- LOADK: rA = K[B]
	LOADK = {
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_CONST, 1, B, 0, cId, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_CONST, 1, B, 0, cId, 0),
				n(MOP_MOVE_STATE, 2, 1, 0, 0, 0),
				n(MOP_WRITE_REG, A, 2, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_READ_CONST, 1, B, 0, cId, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0)
			}
		end
	},

	-- LOADBOOL: rA = (B ~= 0)
	LOADBOOL = {
		function(A, B, C, alu, cap)
			return {
				n(MicroISA.COMB_TRANSFER, A, (B ~= 0 and 1 or 0), 0, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_TRANSFER, A, (B ~= 0 and 1 or 0), 0, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MicroISA.COMB_TRANSFER, A, (B ~= 0 and 1 or 0), 0, 3, 0),
				n(MOP_NORMALIZE, A, A, 0, 0, 0)
			}
		end
	},

	-- LOADNIL: rA..rB = nil
	LOADNIL = {
		function(A, B, C, alu, cap)
			return {
				n(MicroISA.COMB_TRANSFER, A, B, 0, 4, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_TRANSFER, A, B, 0, 4, 0)
			}
		end
	},

	-- =========================================================================
	-- TABLE & MEMORY OPERATIONS (Decentralized Graphs)
	-- =========================================================================

	-- GETTABLE: rA = rB[rC]
	GETTABLE = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 1, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 1, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_RESOLVE_REF, 3, 4, 2, 1, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- GETTABLE_K: rA = rB[K[C]]
	GETTABLE_K = {
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cId, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 2, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_CONST, 2, C, 0, cId, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 2, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_MOVE_STATE, 4, 1, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cId, 0),
				n(MOP_RESOLVE_REF, 3, 4, 2, 2, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- SETTABLE: rA[rB] = rC
	SETTABLE = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_REG, 2, B, 0, 0, 0),
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_READ_REG, 2, B, 0, 0, 0),
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_REG, 2, B, 0, 0, 0),
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 3, 0)
			}
		end
	},

	-- SETTABLE_K: rA[K[B]] = rC
	SETTABLE_K = {
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_CONST, 2, B, 0, cId, 0),
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 4, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_READ_CONST, 2, B, 0, cId, 0),
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 4, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_CONST, 2, B, 0, cId, 0),
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 4, 0)
			}
		end
	},

	-- NEWTABLE: rA = {}
	NEWTABLE = {
		function(A, B, C, alu, cap)
			local cId = (cap and cap["NEW_TABLE"]) or 7
			return {
				n(MicroISA.COMB_CAPABILITY, A, 0, 0, cId, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cId = (cap and cap["NEW_TABLE"]) or 7
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, 0, cId, 0)
			}
		end
	},

	-- =========================================================================
	-- HOST CAPABILITY & ENVIRONMENT OPERATIONS (Â§2.3 Diversity)
	-- =========================================================================

	-- GETGLOBAL: rA = env[K[B]]
	GETGLOBAL = {
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["RESOLVE_ENV"]) or 3
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["RESOLVE_ENV"]) or 3
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["RESOLVE_ENV"]) or 3
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0),
				n(MOP_NORMALIZE, A, A, 0, 0, 0)
			}
		end
	},

	-- SETGLOBAL: env[K[B]] = rA
	SETGLOBAL = {
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["SET_ENV"]) or 6
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["SET_ENV"]) or 6
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0)
			}
		end
	},

	-- GETUPVAL: rA = Upvalues[B]
	GETUPVAL = {
		function(A, B, C, alu, cap)
			return {
				n(MicroISA.COMB_TRANSFER, A, B, 0, 7, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_TRANSFER, A, B, 0, 7, 0)
			}
		end
	},

	-- SETUPVAL: Upvalues[B] = rA
	SETUPVAL = {
		function(A, B, C, alu, cap)
			return {
				n(MicroISA.COMB_TRANSFER, A, B, 0, 8, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_TRANSFER, A, B, 0, 8, 0)
			}
		end
	},

	-- CALL: rA(rA+1..rA+B) (Â§2.3: Truly Diverse Structural Topologies)
	CALL = {
		-- Variant 1: Direct invocation
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 0)
			}
		end,
		-- Variant 2: Frame argument pre-staging & normalization
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_NORMALIZE, 1, 1, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 0),
				n(MOP_NORMALIZE, A, A, 0, 0, 0)
			}
		end,
		-- Variant 3: Transient context barrier staging
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 4, A, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 0),
				n(MOP_MOVE_STATE, 5, 4, 0, 0, 0)
			}
		end,
		-- Variant 4: Multi-stage state frame pipeline
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_CREATE_TEMP, 2, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 0)
			}
		end
	},

	-- CLOSURE: rA = Closure(K[B]) (Â§2.3 Diversity)
	CLOSURE = {
		function(A, B, C, alu, cap)
			local cClo = (cap and cap["CLOSURE"]) or 2
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cClo, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cClo = (cap and cap["CLOSURE"]) or 2
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cClo, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cClo = (cap and cap["CLOSURE"]) or 2
			return {
				n(MOP_READ_CONST, 1, B, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cClo, 0),
				n(MOP_NORMALIZE, A, A, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cClo = (cap and cap["CLOSURE"]) or 2
			return {
				n(MOP_CREATE_TEMP, 2, 0, 0, 0, 0),
				n(MOP_CREATE_TEMP, 3, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cClo, 0)
			}
		end
	},

	-- VARARG: rA..rA+B = ... (Â§2.3 Diversity)
	VARARG = {
		function(A, B, C, alu, cap)
			local cVar = (cap and cap["VARARG"]) or 4
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cVar, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cVar = (cap and cap["VARARG"]) or 4
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cVar, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cVar = (cap and cap["VARARG"]) or 4
			return {
				n(MOP_CREATE_TEMP, 2, 0, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, B, C, cVar, 0),
				n(MOP_NORMALIZE, A, A, 0, 0, 0)
			}
		end
	},

	-- RETURN: return rA..rB
	RETURN = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_RETURN_STATE, A, B, C, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			return {
				n(MOP_CREATE_TEMP, 1, 0, 0, 0, 0),
				n(MOP_RETURN_STATE, A, B, C, 0, 0)
			}
		end
	},

	-- =========================================================================
	-- SUPERINSTRUCTION COMPOSITE OPERATIONS (Â§2.3 Decomposed & Diverse Variants)
	-- =========================================================================

	LOADK_SETTABLE = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 3, A, 0, 0, 0),
				n(MOP_READ_CONST, 1, B, 0, cConst, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_MUTATE_REF, 3, 1, 2, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 3, A, 0, 0, 0),
				n(MOP_READ_CONST, 1, B, 0, cConst, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_MUTATE_REF, 3, 1, 2, 3, 0)
			}
		end
	},

	ADD_SETTABLE = {
		function(A, B, C, alu, cap)
			local pAdd = (alu and alu["ADD"]) or 1
			return {
				n(MOP_READ_REG, 4, A, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pAdd, 0),
				n(MOP_MUTATE_REF, 4, 1, 3, 3, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local pAdd = (alu and alu["ADD"]) or 1
			return {
				n(MOP_CREATE_TEMP, 5, 0, 0, 0, 0),
				n(MOP_READ_REG, 4, A, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pAdd, 0),
				n(MOP_MUTATE_REF, 4, 1, 3, 3, 0)
			}
		end
	},

	LOADK_MOVE = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_CONST, 1, B, 0, cConst, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0),
				n(MOP_WRITE_REG, C, 1, 0, 0, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_CONST, 1, B, 0, cConst, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0),
				n(MOP_WRITE_REG, C, 1, 0, 0, 0)
			}
		end
	},

	LOADK_CALL = {
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["RESOLVE_ENV"]) or 3
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, C, cInv, 0)
			}
		end
	},

	GETTABLE_CALL = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 1, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, 0, cInv, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_CREATE_TEMP, 4, 0, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 1, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, 0, cInv, 0)
			}
		end
	},

	GETUPVAL_CALL = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_TRANSFER, A, B, 0, 7, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, C, cInv, 0)
			}
		end
	},

	GETGLOBAL_CALL = {
		function(A, B, C, alu, cap)
			local cEnv = (cap and cap["RESOLVE_ENV"]) or 3
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, 0, cEnv, 0),
				n(MicroISA.COMB_CAPABILITY, A, C, 0, cInv, 0)
			}
		end
	},

	GETTABLE_SETTABLE = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 4, A, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 2, 0),
				n(MOP_MUTATE_REF, 4, 2, 3, 4, 0)
			}
		end,
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_CREATE_TEMP, 5, 0, 0, 0, 0),
				n(MOP_READ_REG, 4, A, 0, 0, 0),
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 2, 0),
				n(MOP_MUTATE_REF, 4, 2, 3, 4, 0)
			}
		end
	},

	ADD_MOVE = {
		function(A, B, C, alu, cap)
			local pAdd = (alu and alu["ADD"]) or 1
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pAdd, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	MOVE_CALL = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0),
				n(MicroISA.COMB_CAPABILITY, A, 0, C, cInv, 0)
			}
		end
	},

	CONCAT_MOVE = {
		function(A, B, C, alu, cap)
			local pCat = (alu and alu["CONCAT"]) or 11
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pCat, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	LOADNIL_RET = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_RETURN_STATE, A, -1, 0, 0, 0)
			}
		end
	},

	MOVE_RET = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_WRITE_REG, A, 1, 0, 0, 0),
				n(MOP_RETURN_STATE, A, A, 0, 0, 0)
			}
		end
	},

	-- JMP_COND: Paired with conditional test (preserves branch decision)
	JMP_COND = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_NORMALIZE, 0, 0, 0, 0, 0)
			}
		end
	},

	-- JMP: Unconditional control flow step
	JMP = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_BRANCH_STATE, 0, 0, 0, 0, 0)
			}
		end
	},

	-- EQ: Comparison check
	EQ = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_BRANCH_STATE, 3, 1, 2, 1, A)
			}
		end
	},

	-- LT: Comparison check
	LT = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_BRANCH_STATE, 3, 1, 2, 2, A)
			}
		end
	},

	-- LE: Comparison check
	LE = {
		function(A, B, C, alu, cap)
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_REG, 2, C, 0, 0, 0),
				n(MOP_BRANCH_STATE, 3, 1, 2, 3, A)
			}
		end
	},

	-- FORPREP: Initialize for-loop index (rA = rA - rA+2) and jump to FORLOOP
	FORPREP = {
		function(A, B, C, alu, cap)
			local pSub = (alu and alu["SUB"]) or 3
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_REG, 2, A + 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pSub, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0),
				n(MOP_BRANCH_STATE, 0, 0, 0, 0, 0)
			}
		end
	},

	-- FORLOOP: Advance for-loop (rA = rA + rA+2; if in range rA+3 = rA)
	FORLOOP = {
		function(A, B, C, alu, cap)
			local pAdd = (alu and alu["ADD"]) or 1
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_REG, 2, A + 2, 0, 0, 0),
				n(MOP_MERGE_STATE, 3, 1, 2, pAdd, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0),
				n(MOP_READ_REG, 4, A + 1, 0, 0, 0),
				n(MOP_BRANCH_STATE, 5, 3, 4, 4, A)
			}
		end
	},

	-- FORIN_PREP: Generic for loop preparation
	FORIN_PREP = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 6)
			}
		end
	},

	-- CALL_RET: Call and return result
	CALL_RET = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 1),
				n(MOP_RETURN_STATE, A, B, C, 0, 0)
			}
		end
	},

	-- CALL_EXPAND: Call with expanded vararg/multi-return
	CALL_EXPAND = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 3)
			}
		end
	},

	-- CALL_EXPAND_RET: Call with expanded arguments and return
	CALL_EXPAND_RET = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 4),
				n(MOP_RETURN_STATE, A, B, C, 0, 0)
			}
		end
	},

	-- CALL_TABLE_APPEND: Call and append to table
	CALL_TABLE_APPEND = {
		function(A, B, C, alu, cap)
			local cInv = (cap and cap["INVOKE"]) or 1
			return {
				n(MicroISA.COMB_CAPABILITY, A, B, C, cInv, 5)
			}
		end
	},

	-- ROBLOX_GETSERVICE: Resolve service
	ROBLOX_GETSERVICE = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 1, B, 0, 0, 0),
				n(MOP_READ_CONST, 2, C, 0, cConst, 0),
				n(MOP_RESOLVE_REF, 3, 1, 2, 0, 0),
				n(MOP_WRITE_REG, A, 3, 0, 0, 0)
			}
		end
	},

	-- TABLE_SET_CHAIN: Chain field mutation
	TABLE_SET_CHAIN = {
		function(A, B, C, alu, cap)
			local cConst = (cap and cap["CONSTANT"]) or 5
			return {
				n(MOP_READ_REG, 1, A, 0, 0, 0),
				n(MOP_READ_CONST, 2, B, 0, cConst, 0),
				n(MOP_READ_REG, 3, C, 0, 0, 0),
				n(MOP_MUTATE_REF, 1, 2, 3, 0, 0)
			}
		end
	}
}

return RecipeCatalog
