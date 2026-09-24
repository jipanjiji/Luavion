-- This Script is Part of the Zero Lua Obfuscator v4.0
--
-- micro_ops.lua
--
-- Primitive State Machine Operations & Contextual Fusion Engine for Zero Lua v4.0.
-- High-level operations are decomposed into primitive state-transition nodes.
-- Superinstructions are produced by context-dependent micro-op sequence fusion.

local MicroOps = {}

-- Primitive State Machine Micro-Nodes:
MicroOps.MOP_READ_REG           = 1   -- Read register value into execution state slot
MicroOps.MOP_WRITE_REG          = 2   -- Write state slot into physical register bank
MicroOps.MOP_READ_CONST         = 3   -- Read context-bound constant fragment
MicroOps.MOP_CREATE_TEMP        = 4   -- Allocate and initialize transient state cell
MicroOps.MOP_MOVE_STATE         = 5   -- Copy or transfer value between state slots
MicroOps.MOP_MERGE_STATE        = 6   -- Combine two state slots with dynamic algebraic kernel
MicroOps.MOP_SPLIT_STATE        = 7   -- Unpack multi-value state into sequential slots
MicroOps.MOP_RESOLVE_REF        = 8   -- Lookup environment/table reference token
MicroOps.MOP_MUTATE_REF         = 9   -- Write to resolved table/global slot
MicroOps.MOP_INVOKE             = 10  -- Execute call frame transition with arguments
MicroOps.MOP_RETURN_STATE       = 11  -- Construct and return multi-value result state
MicroOps.MOP_BRANCH_STATE       = 12  -- Evaluate condition and mutate instruction pointer
MicroOps.MOP_ADVANCE_IP         = 13  -- Step instruction pointer to next sequence node
MicroOps.MOP_NORMALIZE          = 14  -- Normalize temporary state types

-- Superinstruction synthesis helper per profile
function MicroOps.getProfileSuperinstructions(profileLevel, rng)
	local superOps = {}
	if profileLevel == "SAFE" then
		return superOps
	end

	local pool = {
		"LOADK_MOVE", "LOADK_CALL", "GETTABLE_CALL",
		"MOVE_RET", "GETGLOBAL_CALL", "GETTABLE_SETTABLE", "ADD_MOVE",
		"LOADK_SETTABLE", "ADD_SETTABLE", "MOVE_CALL", "GETUPVAL_CALL",
		"LOADNIL_RET", "CONCAT_MOVE", "ROBLOX_GETSERVICE",
		"ROBLOX_GET_LOCAL_CHAR", "TABLE_SET_CHAIN", "CALL_TABLE_APPEND"
	}

	local count = (profileLevel == "EXTREME" or profileLevel == "MAXIMUM" or profileLevel == "Zero Lua") and 10
		or (profileLevel == "HARD" and 7)
		or (profileLevel == "STRONG" and 5)
		or 3

	local shuffled = {}
	for _, name in ipairs(pool) do table.insert(shuffled, name) end
	for i = #shuffled, 2, -1 do
		local j = (rng and rng:random(1, i)) or math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	for i = 1, math.min(count, #shuffled) do
		table.insert(superOps, shuffled[i])
	end

	return superOps
end

-- Contextual Fusion Generator:
-- Detects adjacent primitive pairs (e.g. READ_CONST + WRITE_REG, MERGE + WRITE_REG) and fusses them on-the-fly
function MicroOps.fuseNodes(nodes, seed)
	if not nodes or #nodes < 2 then return nodes end
	local fused = {}
	local i = 1
	local fuseSalt = seed or 1337

	while i <= #nodes do
		local n1 = nodes[i]
		local n2 = nodes[i + 1]

		if n2 and n1[1] == MicroOps.MOP_READ_REG and n2[1] == MicroOps.MOP_WRITE_REG and n1[2] == n2[3] and (fuseSalt % 2 == 0) then
			-- Direct Reg Transfer Fusion
			table.insert(fused, { MicroOps.MOP_MOVE_STATE, n2[2], n1[3], 0, 0, 0 })
			i = i + 2
		else
			table.insert(fused, n1)
			i = i + 1
		end
	end

	return fused
end

return MicroOps
