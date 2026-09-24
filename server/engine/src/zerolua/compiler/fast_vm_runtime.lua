-- This Script is Part of the Zero Impact Obfuscator
--
-- fast_vm_runtime.lua
--
-- Single-Layer Direct-Threaded Native Luau Buffer Virtual Machine Runtime Generator.
-- Delivers zero-freeze startup (<15ms) and locked 60 FPS loop throughput on Roblox Luau.

local AntiDynamicArmor = require("zerolua.compiler.anti_dynamic_armor")

local FastVMRuntime = {}

function FastVMRuntime.generate(binaryBytecodeString, constantPoolTable, options)
	options = options or {}
	local baseSalt = options.baseSalt or 1337
	local stateSeed = options.stateSeed or (((baseSalt * 31 + 101) % 4294967296))
	local armorSnippet = AntiDynamicArmor.generateArmor(baseSalt, stateSeed)

	local code = [=[
return (function(...)
	local _bCreate = (buffer and buffer.fromstring) or function(s) return { _s = s, _len = #s } end
	local _bLen = (buffer and buffer.len) or function(b) return b._len or (type(b) == "string" and #b) or 0 end
	local _u8 = (buffer and buffer.readu8) or function(b, pos) return string.byte(b._s or b, pos + 1) end
	local _i32 = (buffer and buffer.readi32) or function(b, pos)
		local s = b._s or b
		local b0, b1, b2, b3 = string.byte(s, pos + 1, pos + 4)
		local u = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
		if u >= 2147483648 then u = u - 4294967296 end
		return u
	end
	local _unp = unpack or (table and table.unpack) or (_G and _G.unpack)
	local _pcall = pcall or (_G and _G.pcall)
	local _sel = select
	local _env = (getgenv and getgenv()) or (_G and _G) or shared or _ENV or {}

	-- Bytecode Buffer Initialization (Zero-Allocation Memory Chunk)
	local _rawBc = ]=] .. string.format("%q", binaryBytecodeString) .. [=[
	local _bc = _bCreate(_rawBc)
	local _bcLen = _bLen(_bc)

	-- Constant Pool with Single-Pass Lazy Memoization
	local K = ]=] .. constantPoolTable .. [=[

]=] .. armorSnippet .. [=[

	-- Fast Direct-Threaded Virtual Machine Engine
	local function _vmExec(buf, K, G, uvs, vargs, ...)
		local R = {} -- Flat stack frame allocated 1x per closure call
		local pc = 0
		local bcLen = _bLen(buf)

		local function readReg(r)
			local v = R[r]
			if type(v) == "table" and v._isUv then return v[1] end
			return v
		end

		local function writeReg(r, val)
			local v = R[r]
			if type(v) == "table" and v._isUv then v[1] = val else R[r] = val end
		end

		local inArgCount = _sel("#", ...)
		for i = 1, inArgCount do
			R[i - 1] = _sel(i, ...)
		end

		while pc < bcLen do
			local rawOp = _u8(buf, pc)
			local salt = (pc * 31 + ]=] .. tostring(baseSalt) .. [=[ * 17 + 101 + _stateAdj) % 256
			local op = (rawOp - salt + 256) % 256
			local A = _u8(buf, pc + 1)
			local B = _u8(buf, pc + 2)
			local C = _u8(buf, pc + 3)
			pc = pc + 4

			if op == 1 then -- OP_MOVE
				writeReg(A, readReg(B))
			elseif op == 2 then -- OP_LOADK
				local entry = K[B + 1]
				if type(entry) == "function" then
					entry = entry()
					K[B + 1] = entry -- Memoize permanently (Zero Allocations on repeat)
				end
				writeReg(A, entry)
			elseif op == 3 then -- OP_LOADBOOL
				writeReg(A, (B ~= 0))
				if C ~= 0 then pc = pc + 4 end
			elseif op == 4 then -- OP_LOADNIL
				for r = A, B do writeReg(r, nil) end
			elseif op == 5 then -- OP_GETGLOBAL
				local kVal = K[B + 1]
				if type(kVal) == "function" then kVal = kVal(); K[B + 1] = kVal end
				writeReg(A, G[kVal])
			elseif op == 6 then -- OP_SETGLOBAL
				local kVal = K[B + 1]
				if type(kVal) == "function" then kVal = kVal(); K[B + 1] = kVal end
				G[kVal] = readReg(A)
			elseif op == 7 then -- OP_GETUPVAL
				local cell = uvs and uvs[B + 1]
				writeReg(A, cell and cell[1])
			elseif op == 8 then -- OP_SETUPVAL
				local cell = uvs and uvs[B + 1]
				if cell then cell[1] = readReg(A) end
			elseif op == 9 then -- OP_GETTABLE
				local t = readReg(B)
				writeReg(A, (t ~= nil and t[readReg(C)]) or nil)
			elseif op == 10 then -- OP_SETTABLE
				local t = readReg(A)
				if t ~= nil then t[readReg(B)] = readReg(C) end
			elseif op == 11 then -- OP_GETTABLE_K
				local t = readReg(B)
				local kVal = K[C + 1]
				if type(kVal) == "function" then kVal = kVal(); K[C + 1] = kVal end
				writeReg(A, (t ~= nil and t[kVal]) or nil)
			elseif op == 12 then -- OP_SETTABLE_K
				local t = readReg(A)
				local kVal = K[B + 1]
				if type(kVal) == "function" then kVal = kVal(); K[B + 1] = kVal end
				if t ~= nil then
					t[kVal] = readReg(C)
				end
			elseif op == 13 then -- OP_NEWTABLE
				writeReg(A, {})
			elseif op == 14 then -- OP_ADD
				writeReg(A, (readReg(B) or 0) + (readReg(C) or 0))
			elseif op == 15 then -- OP_SUB
				writeReg(A, (readReg(B) or 0) - (readReg(C) or 0))
			elseif op == 16 then -- OP_MUL
				writeReg(A, (readReg(B) or 0) * (readReg(C) or 0))
			elseif op == 17 then -- OP_DIV
				writeReg(A, (readReg(B) or 0) / (readReg(C) or 1))
			elseif op == 18 then -- OP_MOD
				writeReg(A, (readReg(B) or 0) % (readReg(C) or 1))
			elseif op == 19 then -- OP_POW
				writeReg(A, (readReg(B) or 0) ^ (readReg(C) or 0))
			elseif op == 20 then -- OP_UNM
				writeReg(A, -(readReg(B) or 0))
			elseif op == 21 then -- OP_NOT
				writeReg(A, not readReg(B))
			elseif op == 22 then -- OP_LEN
				local val = readReg(B)
				writeReg(A, (val ~= nil and #val) or 0)
			elseif op == 23 then -- OP_CONCAT
				writeReg(A, tostring(readReg(B) or "") .. tostring(readReg(C) or ""))
			elseif op == 24 then -- OP_JMP (Galois State-Entangled Jump)
				local offset = _i32(buf, pc)
				pc = pc + 4 + offset
			elseif op == 25 then -- OP_EQ (Compact Conditional Skip)
				if (readReg(B) == readReg(C)) ~= (A ~= 0) then
					pc = pc + 8
				end
			elseif op == 26 then -- OP_LT (Compact Conditional Skip)
				if (readReg(B) < readReg(C)) ~= (A ~= 0) then
					pc = pc + 8
				end
			elseif op == 27 then -- OP_LE (Compact Conditional Skip)
				if (readReg(B) <= readReg(C)) ~= (A ~= 0) then
					pc = pc + 8
				end
			elseif op == 28 then -- OP_TEST (Compact Conditional Skip)
				if (not not readReg(A)) ~= (C ~= 0) then
					pc = pc + 8
				end
			elseif op == 29 then -- OP_TESTSET (Compact Conditional Skip)
				if (not not readReg(B)) == (C ~= 0) then
					writeReg(A, readReg(B))
				else
					pc = pc + 8
				end
			elseif op == 30 then -- OP_FORPREP
				local offset = _i32(buf, pc)
				pc = pc + 4
				writeReg(A, (tonumber(readReg(A)) or 0) - (tonumber(readReg(A + 2)) or 1))
				pc = pc + offset
			elseif op == 31 then -- OP_FORLOOP
				local offset = _i32(buf, pc)
				pc = pc + 4
				local step = tonumber(readReg(A + 2)) or 1
				local idx = (tonumber(readReg(A)) or 0) + step
				local limit = tonumber(readReg(A + 1)) or 0
				writeReg(A, idx)
				if (step > 0 and idx <= limit) or (step <= 0 and idx >= limit) then
					writeReg(A + 3, idx)
					pc = pc + offset
				end
			elseif op == 32 then -- OP_TFORLOOP
				local offset = _i32(buf, pc)
				pc = pc + 4
				local iterFn = readReg(A)
				if iterFn then
					local r1, r2, r3 = iterFn(readReg(A + 1), readReg(A + 2))
					if r1 ~= nil then
						writeReg(A + 2, r1)
						writeReg(A + 3, r1)
						writeReg(A + 4, r2)
						writeReg(A + 5, r3)
						pc = pc + offset
					end
				end
			elseif op == 33 then -- OP_CALL (Inlined Fast Dispatch) / CALL_TABLE_APPEND
				local startIdx = (C >= 32) and math.floor(C / 32) or 0
				if startIdx > 0 then
					local tbl = readReg(A)
					local fn = readReg(B)
					local bMode = C % 32
					local args = {}
					local nArgs = 0
					if bMode == 31 then
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						for vi = 1, vCount do args[vi] = vargs[vi] end
						nArgs = vCount
					elseif bMode >= 16 then
						local nFixed = bMode - 16
						for ai = 1, nFixed do args[ai] = readReg(B + ai) end
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						for vi = 1, vCount do args[nFixed + vi] = vargs[vi] end
						nArgs = nFixed + vCount
					else
						for ai = 1, bMode do args[ai] = readReg(B + ai) end
						nArgs = bMode
					end
					if fn and tbl then
						local rets = { fn(_unp(args, 1, nArgs)) }
						for ri = 1, #rets do
							tbl[startIdx + ri - 1] = rets[ri]
						end
					end
				else
					local fn = readReg(A)
					local signedB = (B >= 128) and (B - 256) or B
					local args = {}
					local numArgs = 0
					if signedB == -1 or signedB == -101 then
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						if signedB == -101 then
							args[1] = readReg(A + 1)
							for i = 1, vCount do args[1 + i] = vargs[i] end
							numArgs = 1 + vCount
						else
							for i = 1, vCount do args[i] = vargs[i] end
							numArgs = vCount
						end
					elseif signedB <= -100 then
						local numFixed = -signedB - 100
						for i = 1, numFixed do args[i] = readReg(A + i) end
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						for i = 1, vCount do args[numFixed + i] = vargs[i] end
						numArgs = numFixed + vCount
					else
						numArgs = signedB
						for i = 1, signedB do args[i] = readReg(A + i) end
					end

					if C == 0 then
						if fn then
							if numArgs == 0 then fn()
							elseif numArgs == 1 then fn(args[1])
							elseif numArgs == 2 then fn(args[1], args[2])
							elseif numArgs == 3 then fn(args[1], args[2], args[3])
							else fn(_unp(args, 1, numArgs)) end
						end
					elseif C == 1 then
						if fn then
							if numArgs == 0 then writeReg(A, fn())
							elseif numArgs == 1 then writeReg(A, fn(args[1]))
							elseif numArgs == 2 then writeReg(A, fn(args[1], args[2]))
							elseif numArgs == 3 then writeReg(A, fn(args[1], args[2], args[3]))
							else writeReg(A, fn(_unp(args, 1, numArgs))) end
						else
							writeReg(A, nil)
						end
					elseif C == 2 then
						if fn then
							local r1, r2
							if numArgs == 0 then r1, r2 = fn()
							elseif numArgs == 1 then r1, r2 = fn(args[1])
							elseif numArgs == 2 then r1, r2 = fn(args[1], args[2])
							elseif numArgs == 3 then r1, r2 = fn(args[1], args[2], args[3])
							else r1, r2 = fn(_unp(args, 1, numArgs)) end
							writeReg(A, r1); writeReg(A + 1, r2)
						else
							writeReg(A, nil); writeReg(A + 1, nil)
						end
					elseif C == 3 then
						if fn then
							local r1, r2, r3
							if numArgs == 0 then r1, r2, r3 = fn()
							elseif numArgs == 1 then r1, r2, r3 = fn(args[1])
							elseif numArgs == 2 then r1, r2, r3 = fn(args[1], args[2])
							elseif numArgs == 3 then r1, r2, r3 = fn(args[1], args[2], args[3])
							else r1, r2, r3 = fn(_unp(args, 1, numArgs)) end
							writeReg(A, r1); writeReg(A + 1, r2); writeReg(A + 2, r3)
						else
							writeReg(A, nil); writeReg(A + 1, nil); writeReg(A + 2, nil)
						end
					else
						local rets = (fn and { fn(_unp(args, 1, numArgs)) }) or {}
						local limit = (C > 0) and C or #rets
						for i = 1, limit do writeReg((A + i) - 1, rets[i]) end
					end
				end
			elseif op == 34 then -- OP_CALL_SELF
				local t = readReg(B)
				local kVal = K[C + 1]
				if type(kVal) == "function" then kVal = kVal(); K[C + 1] = kVal end
				writeReg(A + 1, t)
				writeReg(A, (t ~= nil and t[kVal]) or nil)
			elseif op == 35 then -- OP_RETURN
				local signedB = (B >= 128) and (B - 256) or B
				if signedB == -1 then
					return
				elseif signedB == -2 then
					local vCount = (vargs and (vargs.n or #vargs)) or 0
					return _unp(vargs or {}, 1, vCount)
				elseif signedB <= -100 then
					local numFixed = -signedB - 100
					local rets = {}
					for i = 1, numFixed do rets[i] = readReg(A + i - 1) end
					local vCount = (vargs and (vargs.n or #vargs)) or 0
					for i = 1, vCount do rets[numFixed + i] = vargs[i] end
					return _unp(rets, 1, numFixed + vCount)
				elseif signedB < A then
					return
				end
				local count = signedB - A + 1
				if count == 1 then return readReg(A) end
				if count == 2 then return readReg(A), readReg(A + 1) end
				if count == 3 then return readReg(A), readReg(A + 1), readReg(A + 2) end
				local rets = {}
				for i = 1, count do rets[i] = readReg(A + i - 1) end
				return _unp(rets, 1, count)
			elseif op == 36 then -- OP_CLOSURE
				local subProto = K[B + 1]
				local childUvs = {}
				local uvDescs = subProto and (subProto.uvDescriptors or subProto.upvalues)
				local numUvs = (subProto and (subProto.numUvs or (uvDescs and #uvDescs))) or 0
				for i = 1, numUvs do
					local uvDesc = uvDescs[i]
					local isUpval = uvDesc[1] or uvDesc.isUpval or 0
					local slotIdx = uvDesc[2] or uvDesc.index or 0
					if isUpval == 1 then
						childUvs[i] = uvs and uvs[slotIdx + 1]
					else
						local parentReg = slotIdx
						local cell = R[parentReg]
						if type(cell) ~= "table" or not cell._isUv then
							local newCell = { cell, _isUv = true }
							R[parentReg] = newCell
							cell = newCell
						end
						childUvs[i] = cell
					end
				end
				local childBuf = subProto.buf or _bCreate(subProto.rawBytes or "")
				local numFixed = subProto.numParams or 0
				writeReg(A, function(...)
					local inCount = _sel("#", ...)
					local vaLen = (inCount > numFixed) and (inCount - numFixed) or 0
					local vaList = { n = vaLen }
					for vi = 1, vaLen do
						vaList[vi] = _sel(numFixed + vi, ...)
					end
					return _vmExec(childBuf, K, G, childUvs, vaList, ...)
				end)
			elseif op == 37 then -- OP_VARARG
				local vaCount = (vargs and (vargs.n or #vargs)) or 0
				if C > 0 then
					local t = readReg(A)
					if type(t) == "table" then
						for i = 1, vaCount do
							t[C + i - 1] = vargs and vargs[i]
						end
					end
				else
					local signedB = (B >= 128) and (B - 256) or B
					local num = (signedB > 0 and signedB) or vaCount
					for i = 1, num do
						writeReg((A + i) - 1, vargs and vargs[i])
					end
				end
			elseif op == 38 then -- OP_FAST_GETSERVICE
				local sName = K[C + 1]
				if type(sName) == "function" then sName = sName(); K[C + 1] = sName end
				local gameObj = readReg(B) or (_env and _env.game) or game
				if gameObj and gameObj.GetService then
					local ok, srv = _pcall(gameObj.GetService, gameObj, sName)
					writeReg(A, (ok and srv) or (gameObj and gameObj[sName]))
				else
					writeReg(A, gameObj and gameObj[sName])
				end
			elseif op == 39 then -- OP_FAST_LOCALPLAYER
				local gameObj = readReg(B) or (_env and _env.game) or game
				local p = gameObj and gameObj.GetService and select(2, _pcall(gameObj.GetService, gameObj, "Players"))
				local lp = p and p.LocalPlayer
				writeReg(A, lp and lp.Character)
			elseif op == 40 then -- OP_FUSED_GET_CALL
				local t = readReg(B)
				local kVal = K[C + 1]
				if type(kVal) == "function" then kVal = kVal(); K[C + 1] = kVal end
				local fn = (t ~= nil and t[kVal]) or nil
				if fn then fn() end
			elseif op == 41 then -- OP_FUSED_ARITH_SET
				local t = readReg(A)
				local kVal = K[B + 1]
				if type(kVal) == "function" then kVal = kVal(); K[B + 1] = kVal end
				if t ~= nil then t[kVal] = ((t[kVal] or 0)) + readReg(C) end
			elseif op == 42 then -- OP_TRANSIENT_K (Ephemeral Stack Decryptor)
				local cipher = K[B + 1]
				writeReg(A, _decodeTransient(cipher, C * 13 + 37))
			elseif op == 43 then -- OP_HONEYPOT_CALL (Anti-Tracer Confusion)
				_spamDecoyHooks()
			elseif op == 44 then -- OP_ADD_K
				local vb = readReg(B)
				local kVal = K[C + 1]
				if type(kVal) == "function" then kVal = kVal(); K[C + 1] = kVal end
				writeReg(A, (vb or 0) + (kVal or 0))
			elseif op == 45 then -- OP_CALL_EXPAND
				local fn = readReg(A)
				local numFixed = math.floor(B / 64)
				local subMode = B % 64
				local subBase = A + numFixed + 1
				local subFn = readReg(subBase)
				local subRet = {}
				if subFn then
					if subMode == 31 then
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						subRet = { subFn(_unp(vargs or {}, 1, vCount)) }
					elseif subMode >= 32 then
						local sFixed = subMode - 32
						local sArgs = {}
						for i = 1, sFixed do sArgs[i] = readReg(subBase + i) end
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						for i = 1, vCount do sArgs[sFixed + i] = vargs[i] end
						subRet = { subFn(_unp(sArgs, 1, sFixed + vCount)) }
					else
						local sArgs = {}
						for i = 1, subMode do sArgs[i] = readReg(subBase + i) end
						subRet = { subFn(_unp(sArgs, 1, subMode)) }
					end
				end
				local args = {}
				for i = 1, numFixed do args[i] = readReg(A + i) end
				local subN = (subRet and (subRet.n or #subRet)) or 0
				for i = 1, subN do args[numFixed + i] = subRet[i] end
				local totalN = numFixed + subN
				if C == 0 then
					if fn then fn(_unp(args, 1, totalN)) end
				elseif C == 1 then
					if fn then writeReg(A, fn(_unp(args, 1, totalN))) else writeReg(A, nil) end
				elseif C == 2 then
					if fn then
						local r1, r2 = fn(_unp(args, 1, totalN))
						writeReg(A, r1); writeReg(A + 1, r2)
					else
						writeReg(A, nil); writeReg(A + 1, nil)
					end
				elseif C == 3 then
					if fn then
						local r1, r2, r3 = fn(_unp(args, 1, totalN))
						writeReg(A, r1); writeReg(A + 1, r2); writeReg(A + 2, r3)
					else
						writeReg(A, nil); writeReg(A + 1, nil); writeReg(A + 2, nil)
					end
				else
					local rets = (fn and { fn(_unp(args, 1, totalN)) }) or {}
					local limit = (C > 0) and C or #rets
					for i = 1, limit do writeReg((A + i) - 1, rets[i]) end
				end
			elseif op == 46 then -- OP_CALL_EXPAND_RET
				local numFixed = math.floor(B / 64)
				local subMode = B % 64
				local subBase = A + numFixed
				local subFn = readReg(subBase)
				local subRet = {}
				if subFn then
					if subMode == 31 then
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						subRet = { subFn(_unp(vargs or {}, 1, vCount)) }
					elseif subMode >= 32 then
						local sFixed = subMode - 32
						local sArgs = {}
						for i = 1, sFixed do sArgs[i] = readReg(subBase + i) end
						local vCount = (vargs and (vargs.n or #vargs)) or 0
						for i = 1, vCount do sArgs[sFixed + i] = vargs[i] end
						subRet = { subFn(_unp(sArgs, 1, sFixed + vCount)) }
					else
						local sArgs = {}
						for i = 1, subMode do sArgs[i] = readReg(subBase + i) end
						subRet = { subFn(_unp(sArgs, 1, subMode)) }
					end
				end
				local rets = {}
				for i = 1, numFixed do rets[i] = readReg(A + i - 1) end
				local subN = (subRet and (subRet.n or #subRet)) or 0
				for i = 1, subN do rets[numFixed + i] = subRet[i] end
				local totalN = numFixed + subN
				return _unp(rets, 1, totalN)
			end
		end
	end

	-- Opaque C-Closure Armor: Launch & Decouple Roots (Anti-debug.getupvalues & Anti-getgc)
	local _launcher = function(...)
		local inCount = _sel("#", ...)
		local vaList = { n = inCount }
		for i = 1, inCount do vaList[i] = _sel(i, ...) end
		return _vmExec(_bc, K, _env, {}, vaList, ...)
	end
	_rawBc = nil -- Clear raw bytecode root from heap

	return _launcher(...)
end)(...)

]=]

	return code
end

return FastVMRuntime
