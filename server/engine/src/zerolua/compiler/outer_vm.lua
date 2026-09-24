-- This Script is Part of the Zero Lua Obfuscator v3.2
--
-- outer_vm.lua
--
-- Outer Virtual Machine Interpreter Specification for Zero Lua v3.2.
-- Decodes the Outer Instruction Stream and orchestrates region execution.
-- ZERO high-level semantic operations exist in this layer.

local OuterVM = {}

OuterVM.OP_ROUTE_REGION   = 1
OuterVM.OP_JUMP_REGION    = 2
OuterVM.OP_BRANCH_REGION  = 3
OuterVM.OP_LOOP_REGION    = 4
OuterVM.OP_RETURN_REGION  = 5
OuterVM.OP_CONTINUE_REGION = 6
OuterVM.OP_RESOLVE_TARGET  = 7
OuterVM.OP_COMMIT_STATE    = 8
OuterVM.OP_INDIRECT_DISPATCH = 9

function OuterVM.resolveNextRegion(currentRegion, continuationToken, stateVal, resolverDomain, stateCommitment)
	resolverDomain = resolverDomain or 1337
	local comm = (stateCommitment or 0) % 65536
	local base = ((currentRegion or 1) * 31 + (continuationToken or 0) * 17 + (stateVal or 0) * 13 + comm * 19) % 65536
	local salt = (resolverDomain % 256 + (comm % 256) * 7) % 256
	if comm == 0 then
		salt = resolverDomain % 256
	end
	return (base + salt) % 65536
end

function OuterVM.generateTransitionSnippet(v_currReg, v_contTok, v_vmState, resolverDomain, v_stateCommitment)
	resolverDomain = resolverDomain or 1337
	if v_stateCommitment then
		return "((((" .. tostring(v_currReg) .. " * 31 + " .. tostring(v_contTok) .. " * 17 + " .. tostring(v_vmState) .. " * 13 + (" .. tostring(v_stateCommitment) .. " % 65536) * 19) % 65536) + ((" .. tostring(resolverDomain) .. " % 256 + (" .. tostring(v_stateCommitment) .. " % 256) * 7) % 256)) % 65536)"
	end
	return "(((" .. tostring(v_currReg) .. " * 31 + " .. tostring(v_contTok) .. " * 17 + " .. tostring(v_vmState) .. " * 13) % 65536 + " .. tostring(resolverDomain % 256) .. ") % 65536)"
end

function OuterVM.decodeNextTarget(token, currentRegion, stateVal, resolverDomain, stateCommitment)
	resolverDomain = resolverDomain or 1337
	local comm = (stateCommitment or 0) % 65536
	local salt = (resolverDomain % 256 + (comm % 256) * 7) % 256
	if comm == 0 then
		salt = resolverDomain % 256
	end
	local base = ((token or 0) - salt + 65536) % 65536
	local raw = (base - (currentRegion or 1) * 31 - (stateVal or 0) * 13 - comm * 19)
	local normRaw = (raw % 65536 + 65536) % 65536
	return (normRaw * 61681) % 65536
end

function OuterVM.generateDecodeSnippet(v_resTok, v_currReg, v_vmState, resolverDomain, v_stateCommitment)
	resolverDomain = resolverDomain or 1337
	local saltExpr
	if v_stateCommitment then
		saltExpr = "((" .. tostring(resolverDomain) .. " % 256 + (" .. tostring(v_stateCommitment) .. " % 256) * 7) % 256)"
		return "(((((" .. tostring(v_resTok) .. " - " .. saltExpr .. " + 65536) % 65536) - ((" .. tostring(v_currReg) .. " * 31 + " .. tostring(v_vmState) .. " * 13 + (" .. tostring(v_stateCommitment) .. " % 65536) * 19) % 65536) + 6553600) % 65536) * 61681) % 65536"
	else
		saltExpr = tostring(resolverDomain % 256)
		return "(((((" .. tostring(v_resTok) .. " - " .. saltExpr .. " + 65536) % 65536) - ((" .. tostring(v_currReg) .. " * 31 + " .. tostring(v_vmState) .. " * 13) % 65536) + 6553600) % 65536) * 61681) % 65536"
	end
end

function OuterVM.resolveContinuation(currentRegion, outcome, vmState, resolverDomain)
	if outcome == OuterVM.OP_RETURN_REGION or outcome == 5 then
		return 5, 0
	end
	local targetId = 0
	if outcome == OuterVM.OP_CONTINUE_REGION or outcome == 6 then
		targetId = (currentRegion and currentRegion.nextId) or 0
	elseif outcome == OuterVM.OP_BRANCH_REGION or outcome == 3 or outcome == OuterVM.OP_LOOP_REGION or outcome == 4 then
		targetId = (currentRegion and currentRegion.jumpId) or 0
	end
	if not targetId or targetId <= 0 then
		error("", 0)
	end
	local comm = (currentRegion and currentRegion.commitment) or 0
	local contTok = (outcome * 8192 + targetId) % 65536
	local regId = (currentRegion and currentRegion.id) or 1
	local resTok = OuterVM.resolveNextRegion(regId, contTok, vmState, resolverDomain, comm)
	local decTok = OuterVM.decodeNextTarget(resTok, regId, vmState, resolverDomain, comm)
	local decOutcome = math.floor(decTok / 8192)
	local decTarget = decTok % 8192
	if decOutcome ~= outcome or decTarget ~= targetId then
		error("", 0)
	end
	return decOutcome, decTarget
end

return OuterVM

