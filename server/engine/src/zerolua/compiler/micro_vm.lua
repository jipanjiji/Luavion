-- This Script is Part of the Zero Lua Obfuscator v4.1
--
-- micro_vm.lua
--
-- Primitive Micro-Op State Engine for Zero Lua v4.1.
-- Executes sequences of primitive micro-nodes driving state-machine transitions
-- with dynamic, polymorphic ALU & capability mappings per prototype.

local MicroISA = require("zerolua.compiler.micro_isa")
local MicroOps = require("zerolua.compiler.micro_ops")

local MicroVM = {}

function MicroVM.executeMicroStream(microNodes, bank, regMul, regOffset, K, env, uvs, va, hostBridge, outerFn, aluMap, capMap, microOpMap)
	if _G and _G.__SABOTAGE_MICRO_VM then
		error("", 0)
	end
	if not microNodes or #microNodes == 0 then return end

	local _S = {}

	local function _rRead(r)
		local p = (r * regMul + regOffset + 1)
		local cell = bank[p]
		if type(cell) == "table" and cell._uvTag then return cell[1] end
		return cell and cell[1]
	end

	local function _rWrite(r, v)
		local p = (r * regMul + regOffset + 1)
		local cell = bank[p]
		if type(cell) == "table" and cell._uvTag then
			cell[1] = v
		elseif not cell then
			bank[p] = { v }
		else
			cell[1] = v
		end
	end

	local constCap      = (capMap and capMap["CONSTANT"]) or 5
	local invokeCap     = (capMap and capMap["INVOKE"]) or 1
	local closureCap    = (capMap and capMap["CLOSURE"]) or 2
	local resolveEnvCap = (capMap and capMap["RESOLVE_ENV"]) or 3
	local varargCap     = (capMap and capMap["VARARG"]) or 4
	local setEnvCap     = (capMap and capMap["SET_ENV"]) or 6
	local newTableCap   = (capMap and capMap["NEW_TABLE"]) or 7
	local retState = nil

	local mop1  = (microOpMap and microOpMap[1]) or 1
	local mop2  = (microOpMap and microOpMap[2]) or 2
	local mop3  = (microOpMap and microOpMap[3]) or 3
	local mop4  = (microOpMap and microOpMap[4]) or 4
	local mop5  = (microOpMap and microOpMap[5]) or 5
	local mop6  = (microOpMap and microOpMap[6]) or 6
	local mop7  = (microOpMap and microOpMap[7]) or 7
	local mop8  = (microOpMap and microOpMap[8]) or 8
	local mop9  = (microOpMap and microOpMap[9]) or 9
	local mop10 = (microOpMap and microOpMap[10]) or 10
	local mop11 = (microOpMap and microOpMap[11]) or 11
	local mop12 = (microOpMap and microOpMap[12]) or 12
	local mop14 = (microOpMap and microOpMap[14]) or 14

	for _, node in ipairs(microNodes or {}) do
		local mop = (type(node) == "table" and node[1]) or mop1
		local dst = (type(node) == "table" and node[2]) or 0
		local s1  = (type(node) == "table" and node[3]) or 0
		local s2  = (type(node) == "table" and node[4]) or 0
		local pa  = (type(node) == "table" and node[5]) or 0
		local pb  = (type(node) == "table" and node[6]) or 0

		if mop == mop1 then -- MOP_READ_REG or COMB_TRANSFER
			if pa == 3 then -- LOADBOOL
				_rWrite(dst, s1 ~= 0)
			elseif pa == 4 then -- LOADNIL
				for _r = dst, s1 do _rWrite(_r, nil) end
			elseif pa == 7 then -- GETUPVAL
				local cell = uvs and uvs[s1 + 1]
				_rWrite(dst, cell and cell[1])
			elseif pa == 8 then -- SETUPVAL
				local cell = uvs and uvs[s1 + 1]
				if cell then cell[1] = _rRead(dst) end
			else
				_S[dst] = _rRead(s1)
			end
		elseif mop == mop2 then -- MOP_WRITE_REG: Write state slot into register bank
			_rWrite(dst, _S[s1])
		elseif mop == mop3 then -- MOP_READ_CONST: Read constant fragment into state slot
			local kIdx = (s1 + s2 * 256) + 1
			_S[dst] = hostBridge(constCap, K, kIdx)
		elseif mop == mop4 then -- MOP_CREATE_TEMP or COMB_CAPABILITY
			if pa > 0 then
				if pa == invokeCap then -- CAP_INVOKE
					local res = hostBridge(invokeCap, dst, s1, s2, bank, regMul, regOffset, va, pb)
					if res and res.isRet then
						retState = res
						break
					end
				elseif pa == closureCap then -- CAP_CLOSURE
					hostBridge(closureCap, dst, s1, s2, bank, regMul, regOffset, va, pb)
				elseif pa == resolveEnvCap then -- CAP_RESOLVE_ENV
					local kIdx = (s1 + s2 * 256) + 1
					local kVal = hostBridge(constCap, K, kIdx)
					local gv = hostBridge(resolveEnvCap, env, kVal)
					_rWrite(dst, gv)
				elseif pa == varargCap then -- CAP_VARARG
					hostBridge(varargCap, dst, s1, s2, bank, regMul, regOffset, va, pb)
				elseif pa == constCap then -- CAP_CONSTANT
					local kIdx = (s1 + s2 * 256) + 1
					_S[dst] = hostBridge(constCap, K, kIdx)
				elseif pa == setEnvCap then -- CAP_SET_ENV
					local kIdx = (s1 + s2 * 256) + 1
					local kVal = hostBridge(constCap, K, kIdx)
					local val = _rRead(dst)
					hostBridge(setEnvCap, env, kVal, val)
				elseif pa == newTableCap then -- CAP_NEW_TABLE
					_rWrite(dst, {})
				end
			else
				_S[dst] = nil
			end
		elseif mop == mop5 then -- MOP_MOVE_STATE: State slot transfer
			_S[dst] = _S[s1]
		elseif mop == mop6 then -- MOP_MERGE_STATE: Dynamic algebraic merge
			local b = _S[s1]
			local c = (s2 > 0 and _S[s2]) or 0
			local kernel = aluMap and aluMap[pa]
			local res
			if type(kernel) == "function" then
				res = kernel(b, c)
			elseif type(kernel) == "string" then
				if kernel == "ADD" or kernel == "ADD_K" then
					res = (type(b) == "number" and type(c) == "number") and (b - (-c)) or (b + c)
				elseif kernel == "SUB" then res = b - c
				elseif kernel == "MUL" then res = b * c
				elseif kernel == "DIV" then res = b / c
				elseif kernel == "MOD" then res = b % c
				elseif kernel == "POW" then res = b ^ c
				elseif kernel == "UNM" then res = -b
				elseif kernel == "NOT" then res = (b == nil or b == false)
				elseif kernel == "LEN" then res = (b ~= nil and #b) or 0
				elseif kernel == "CONCAT" then res = tostring(b or "") .. tostring(c or "")
				else error("", 0) end
			else
				error("", 0)
			end
			_S[dst] = res
		elseif mop == mop7 then -- MOP_SPLIT_STATE: Transfer between slots
			_S[dst] = _S[s1]
		elseif mop == mop8 then -- MOP_RESOLVE_REF: Dynamic Table Indexing
			local tbl = _S[s1]
			local key = _S[s2]
			_S[dst] = tbl[key]
		elseif mop == mop9 then -- MOP_MUTATE_REF: Table Mutation
			local tbl = _S[dst]
			local key = _S[s1]
			local val = _S[s2]
			tbl[key] = val
		elseif mop == mop10 then -- MOP_INVOKE: Host Invocation
			local res = hostBridge(invokeCap, dst, s1, s2, bank, regMul, regOffset, va, pb)
			if res and res.isRet then
				retState = res
				break
			end
		elseif mop == mop11 then -- MOP_RETURN_STATE: Frame Unwinding
			retState = { isRet = true, opA = dst, opB = s1, opC = s2 }
			break
		elseif mop == mop12 then -- MOP_BRANCH_STATE: Condition Evaluation
			local cond = false
			if pa == 0 then
				cond = true
			elseif pa == 4 then
				local idx = _S[s1]
				local limit = _S[s2]
				local step = _rRead(pb + 2)
				cond = (step > 0 and idx <= limit) or (step <= 0 and idx >= limit)
				if cond then _rWrite(pb + 3, idx) end
			else
				local b = _S[s1]
				local c = _S[s2]
				local matched = false
				if pa == 1 then matched = (b == c)
				elseif pa == 2 then matched = (b < c)
				elseif pa == 3 then matched = (b <= c) end
				cond = (matched == (pb ~= 0))
			end
			_S[dst] = cond
			retState = { branchTaken = cond }
		elseif mop == mop14 then -- MOP_NORMALIZE: Normalize state cell
			_S[dst] = _S[s1]
		end
	end

	if _G and _G.__ZERO_PROF then
		local _zp = _G.__ZERO_PROF
		_zp.microVmExecutions = (_zp.microVmExecutions or 0) + 1
		_zp.microOpsExecuted = (_zp.microOpsExecuted or 0) + #microNodes
	end

	return retState
end

function MicroVM.generateRuntimeMicroVM(isProduction, readBankName, writeBankName, microOpMap)
	local rBank = readBankName or "_readBank"
	local wBank = writeBankName or "_writeBank"

	local mop1  = (microOpMap and microOpMap[1]) or 1
	local mop2  = (microOpMap and microOpMap[2]) or 2
	local mop3  = (microOpMap and microOpMap[3]) or 3
	local mop4  = (microOpMap and microOpMap[4]) or 4
	local mop5  = (microOpMap and microOpMap[5]) or 5
	local mop6  = (microOpMap and microOpMap[6]) or 6
	local mop7  = (microOpMap and microOpMap[7]) or 7
	local mop8  = (microOpMap and microOpMap[8]) or 8
	local mop9  = (microOpMap and microOpMap[9]) or 9
	local mop10 = (microOpMap and microOpMap[10]) or 10
	local mop11 = (microOpMap and microOpMap[11]) or 11
	local mop12 = (microOpMap and microOpMap[12]) or 12
	local mop14 = (microOpMap and microOpMap[14]) or 14

	local profSnippet = [=[
		local _sc = (string and string.char) or string.char
		local _kProf = _sc(95,95,90,69,82,79,95,80,82,79,70)
		if _G and _G[_kProf] then
			local _zp = _G[_kProf]
			local _kMVE = _sc(109,105,99,114,111,86,109,69,120,101,99,117,116,105,111,110,115)
			local _kMOE = _sc(109,105,99,114,111,79,112,115,69,120,101,99,117,116,101,100)
			_zp[_kMVE] = (_zp[_kMVE] or 0) + 1
			_zp[_kMOE] = (_zp[_kMOE] or 0) + #microNodes
		end
]=]
	local sabotageHook = [=[
		local _sc = (string and string.char) or string.char
		local _kSabMicro = _sc(95,95,83,65,66,79,84,65,71,69,95,77,73,67,82,79,95,86,77)
		if _G and _G[_kSabMicro] then
			error(_sc(102,97,105,108,45,99,108,111,115,101,100), 0)
		end
]=]
	return [=[(function(microNodes, bank, regMap, uvTag, K, env, uvs, va, hostBridge, aluMap, capMap, v_synthStr, currentRegion, frameScratch)
]=] .. sabotageHook .. [=[
		if not microNodes or #microNodes == 0 then return end

		local _S = frameScratch or {}
		local retState = nil
		local _rawget = rawget
		local _rawset = rawset
		local _type = type

		local constCap      = (capMap and capMap[5]) or 5
		local invokeCap     = (capMap and capMap[1]) or 1
		local closureCap    = (capMap and capMap[2]) or 2
		local resolveEnvCap = (capMap and capMap[3]) or 3
		local varargCap     = (capMap and capMap[4]) or 4
		local setEnvCap     = (capMap and capMap[6]) or 6
		local newTableCap   = (capMap and capMap[7]) or 7
		local _cKey = (currentRegion and currentRegion[12]) or 13
		local _rId = (currentRegion and currentRegion[1]) or 1
		local _mA = ((_cKey % 7) * 2 + 1)
		local _mB = (_cKey * 3 + _rId * 5) % 16
		local _invA = (_mA == 1 and 1) or (_mA == 3 and 11) or (_mA == 5 and 13) or (_mA == 7 and 7) or (_mA == 9 and 9) or (_mA == 11 and 3) or (_mA == 13 and 5) or 15

		for _ni = 1, #microNodes do
			local node = microNodes[_ni]
			local mop = node[1] or ]=] .. tostring(mop1) .. [=[;
			local dst = node[2] or 0
			local s1  = node[3] or 0
			local s2  = node[4] or 0
			local pa  = node[5] or 0
			local pb  = node[6] or 0

			if mop == ]=] .. tostring(mop1) .. [=[ then
				if pa == 3 then
					]=] .. wBank .. [=[(bank, regMap, uvTag, dst, s1 ~= 0)
				elseif pa == 4 then
					for _r = dst, s1 do ]=] .. wBank .. [=[(bank, regMap, uvTag, _r, nil) end
				elseif pa == 7 then
					local cell = uvs and uvs[s1 + 1]
					]=] .. wBank .. [=[(bank, regMap, uvTag, dst, cell and cell[1])
				elseif pa == 8 then
					local cell = uvs and uvs[s1 + 1]
					if cell then _rawset(cell, 1, ]=] .. rBank .. [=[(bank, regMap, uvTag, dst)) end
				else
					_S[dst] = ]=] .. rBank .. [=[(bank, regMap, uvTag, s1)
				end
			elseif mop == ]=] .. tostring(mop2) .. [=[ then
				]=] .. wBank .. [=[(bank, regMap, uvTag, dst, _S[s1])
			elseif mop == ]=] .. tostring(mop3) .. [=[ then
				local kIdx = (s1 + s2 * 256) + 1
				local _cNonce = (_rId * 1013 + _ni * 31 + _cKey * 17 + 5381) % 65536
				local val = hostBridge(constCap, K, kIdx, _rId, _ni, _cNonce)
				_S[dst] = val
			elseif mop == ]=] .. tostring(mop4) .. [=[ then
				if pa > 0 then
					if pa == invokeCap then
						local res = hostBridge(invokeCap, dst, s1, s2, bank, regMap, uvTag, va, pb)
						if res and res[1] then
							retState = res
							break
						end
					elseif pa == closureCap then
						hostBridge(closureCap, dst, s1, s2, bank, regMap, uvTag, va, pb)
					elseif pa == resolveEnvCap then
						local kIdx = (s1 + s2 * 256) + 1
						local _cNonce = (_rId * 1013 + _ni * 31 + _cKey * 17 + 5381) % 65536
						local kVal = hostBridge(constCap, K, kIdx, _rId, _ni, _cNonce)
						local gv = hostBridge(resolveEnvCap, env, kVal)
						]=] .. wBank .. [=[(bank, regMap, uvTag, dst, gv)
					elseif pa == varargCap then
						hostBridge(varargCap, dst, s1, s2, bank, regMap, uvTag, va, pb)
					elseif pa == constCap then
						local kIdx = (s1 + s2 * 256) + 1
						local _cNonce = (_rId * 1013 + _ni * 31 + _cKey * 17 + 5381) % 65536
						local val = hostBridge(constCap, K, kIdx, _rId, _ni, _cNonce)
						_S[dst] = val
					elseif pa == setEnvCap then
						local kIdx = (s1 + s2 * 256) + 1
						local _cNonce = (_rId * 1013 + _ni * 31 + _cKey * 17 + 5381) % 65536
						local kVal = hostBridge(constCap, K, kIdx, _rId, _ni, _cNonce)
						local val = ]=] .. rBank .. [=[(bank, regMap, uvTag, dst)
						hostBridge(setEnvCap, env, kVal, val)
					elseif pa == newTableCap then
						hostBridge(newTableCap, dst, 0, 0, bank, regMap, uvTag)
					end
				else
					_S[dst] = nil
				end
			elseif mop == ]=] .. tostring(mop5) .. [=[ then
				_S[dst] = _S[s1]
			elseif mop == ]=] .. tostring(mop6) .. [=[ then
				local b = _S[s1]
				local c = (s2 > 0 and _S[s2]) or 0
				local kernel = (currentRegion and currentRegion[9] and currentRegion[9][pa]) or (aluMap and aluMap[pa])
				if kernel then
					_S[dst] = kernel(b, c)
				else
					error("", 0)
				end
			elseif mop == ]=] .. tostring(mop7) .. [=[ then
				_S[dst] = _S[s1]
			elseif mop == ]=] .. tostring(mop8) .. [=[ then
				local tbl = _S[s1]
				local key = _S[s2]
				_S[dst] = tbl[key]
			elseif mop == ]=] .. tostring(mop9) .. [=[ then
				local tbl = _S[dst]
				local key = _S[s1]
				local val = _S[s2]
				tbl[key] = val
			elseif mop == ]=] .. tostring(mop10) .. [=[ then
				local res = hostBridge(invokeCap, dst, s1, s2, bank, regMap, uvTag, va, pb)
				if res and res[1] then
					retState = res
					break
				end
			elseif mop == ]=] .. tostring(mop11) .. [=[ then
				retState = { true, false, dst, s1, s2 }
				break
			elseif mop == ]=] .. tostring(mop12) .. [=[ then
				local cond = false
				if pa == 0 then
					cond = true
				elseif pa == 4 then
					local idx = _S[s1]
					local limit = _S[s2]
					local step = ]=] .. rBank .. [=[(bank, regMap, uvTag, pb + 2)
					cond = (step > 0 and idx <= limit) or (step <= 0 and idx >= limit)
					if cond then ]=] .. wBank .. [=[(bank, regMap, uvTag, pb + 3, idx) end
				else
					local b = _S[s1]
					local c = _S[s2]
					local matched = false
					if pa == 1 then matched = (b == c)
					elseif pa == 2 then matched = (b < c)
					elseif pa == 3 then matched = (b <= c) end
					cond = (matched == (pb ~= 0))
				end
				_S[dst] = cond
				retState = { false, cond }
			elseif mop == ]=] .. tostring(mop14) .. [=[ then
				_S[dst] = _S[s1]
			end
		end
]=] .. profSnippet .. [=[
		return retState
	end)]=]
end

return MicroVM
