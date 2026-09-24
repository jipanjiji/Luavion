-- This Script is Part of the Zero Lua Obfuscator v5.7
--
-- vm_runtime.lua
--
-- Decentralized State-Entangled Virtual Machine Runtime Generator for Zero Lua v5.7.
-- Completely destroys centralized router choke points and canonical reverse-engineering targets:
-- 1. Eradication of Centralized Syscall Tables (_GU / _hostBridge) -> Fully decentralized, inlined capabilities.
-- 2. Eradication of Global Plaintext String Oracle (_FN / K._cCache) -> Ephemeral 16-slot circular ring cache.
-- 3. Dynamic Galois Hash-Bucket Dispatch -> Zero static monotonic interval trees.
-- 4. Execution Result & Data-Flow Feedback Loop -> Instruction outputs actively mutate _vmState.
-- 5. Zero Diagnostic Landmarks -> Generic and silent fail-closed divergence.

local RandomDomains = require("zerolua.random_domains")
local VMProfiles = require("zerolua.compiler.vm_profiles")
local DispatchGenerator = require("zerolua.compiler.dispatch_generator")
local KeySchedule = require("zerolua.compiler.key_schedule")
local StreamEncoder = require("zerolua.compiler.stream_encoder")
local ISA = require("zerolua.compiler.isa")
local RegisterMapper = require("zerolua.compiler.register_mapper")
local OperandCodec = require("zerolua.compiler.operand_codec")
local OuterVM = require("zerolua.compiler.outer_vm")
local MicroVM = require("zerolua.compiler.micro_vm")
local MicroISA = require("zerolua.compiler.micro_isa")
local RegionDecoder = require("zerolua.compiler.region_decoder")
local GraphIntegrity = require("zerolua.compiler.graph_integrity")
local ConstantRuntime = require("zerolua.compiler.constant_runtime")

local VMRuntime = {}

local function randomVarName(len)
	local vmRng = RandomDomains.get("VM")
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local res = {}
	for i = 1, len or 5 do
		local idx = (vmRng and vmRng:random(1, #chars)) or math.random(1, #chars)
		table.insert(res, chars:sub(idx, idx))
	end
	return table.concat(res)
end

local function getMetaSlots(salt)
	local s = salt % 24
	local perms = {
		{1,2,3,4,5}, {1,3,2,5,4}, {2,1,4,3,5}, {2,3,1,5,4},
		{3,1,2,4,5}, {3,2,1,5,4}, {4,1,2,3,5}, {4,2,3,1,5},
		{5,1,2,3,4}, {5,2,1,4,3}, {1,4,2,3,5}, {2,4,1,3,5},
		{3,4,1,2,5}, {4,3,1,2,5}, {1,5,2,3,4}, {2,5,1,3,4},
		{3,5,1,2,4}, {4,5,1,2,3}, {5,4,1,2,3}, {1,2,4,3,5},
		{2,1,5,3,4}, {3,1,5,2,4}, {4,1,5,2,3}, {5,1,4,2,3}
	}
	return perms[(s % #perms) + 1]
end

local function dynBytesRaw(str, baseSalt)
	baseSalt = baseSalt or 1337
	local k = (baseSalt % 199) + 13
	local charParts = {}
	for j = 1, #str do
		local off = ((baseSalt * (j * 7 + 3) + j * 13 + k) % 256)
		local enc = (string.byte(str, j) + off) % 256
		table.insert(charParts, "((" .. tostring(enc) .. " - " .. tostring(off) .. " + 256) % 256)")
	end
	return "string.char(" .. table.concat(charParts, ",") .. ")"
end

local function buildDynamicDescriptors(ctx)
	local gR, sR = ctx.gR, ctx.sR
	local V = ctx.V
	local v_isType, v_getStdName, v_resolveEnv = ctx.v_isType, ctx.v_getStdName, ctx.v_resolveEnv
	local v_createClosure, v_outerVM, v_Bank = ctx.v_createClosure, ctx.v_outerVM, ctx.v_Bank
	local v_currentRegion, v_regMap, v_va = ctx.v_currentRegion, ctx.v_regMap, ctx.v_va
	local v_ip, v_codeLen, v_evalCompare = ctx.v_ip, ctx.v_codeLen, ctx.v_evalCompare
	local v_evalAddSub, v_evalMulDivMod, v_evalPowUnm = ctx.v_evalAddSub, ctx.v_evalMulDivMod, ctx.v_evalPowUnm
	local v_getK, v_retCount, v_ret1 = ctx.v_getK, ctx.v_retCount, ctx.v_ret1
	local v_ret2, v_ret3, v_retTbl = ctx.v_ret2, ctx.v_ret3, ctx.v_retTbl
	local v_retCountN, v_isRet, v_packUnpack = ctx.v_retCountN, ctx.v_isRet, ctx.v_packUnpack
	local v_rawset, v_predBlockHash, v_vmState = ctx.v_rawset, ctx.v_predBlockHash, ctx.v_vmState
	local v_dip, stateMod = ctx.v_dip, ctx.stateMod
	local leakageAudit, stateCoupling = ctx.leakageAudit, ctx.stateCoupling
	local hIter, hCall, hNext = ctx.hIter, ctx.hCall, ctx.hNext
	local hGetService, hPlayers, hLocalPlayer, hCharacter = ctx.hGetService, ctx.hPlayers, ctx.hLocalPlayer, ctx.hCharacter

	local function sConcat(t) return table.concat(t, "") end
	local hCode = {}

	hCode.call = sConcat({
		"\t\t\t\tlocal _fn = ", gR("opA"), "; ",
		"if ", v_isType, "(_fn, 1) then ",
			"if opB == 0 then ",
				"if opC == 0 then _fn() ",
				"elseif opC == 1 then ", sR("opA", "_fn()"), " ",
				"elseif opC == 2 then local _r1, _r2 = _fn(); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " ",
				"elseif opC == 3 then local _r1, _r2, _r3 = _fn(); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " ",
				"elseif opC > 3 then local _rn, _ret = ", V.capture, "(_fn()); for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end ",
				"else local _rn, _ret = ", V.capture, "(_fn()); for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
			"elseif opB == 1 then ",
				"local _a1 = ", gR("opA + 1"), "; ",
				"if _a1 == nil then ",
					"local _ok, _r1, _r2 = pcall(_fn, nil); ",
					"if _ok then ",
						"if opC == 1 then ", sR("opA", "_r1"), " elseif opC == 2 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " elseif opC == 3 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "nil"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "(_i == 1 and _r1) or (_i == 2 and _r2) or nil"), " end end ",
					"else ",
						"if opC == 1 then ", sR("opA", "nil"), " elseif opC == 2 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " elseif opC == 3 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "nil"), " end end ",
					"end ",
				"elseif opC == 0 then _fn(_a1) ",
				"elseif opC == 1 then ", sR("opA", "_fn(_a1)"), " ",
				"elseif opC == 2 then local _r1, _r2 = _fn(_a1); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " ",
				"elseif opC == 3 then local _r1, _r2, _r3 = _fn(_a1); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " ",
				"elseif opC > 3 then local _rn, _ret = ", V.capture, "(_fn(_a1)); for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end ",
				"else local _rn, _ret = ", V.capture, "(_fn(_a1)); for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
			"elseif opB == 2 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; ",
				"if _a1 == nil then ",
					"local _ok, _r1, _r2 = pcall(_fn, nil, _a2); ",
					"if _ok then ",
						"if opC == 1 then ", sR("opA", "_r1"), " elseif opC == 2 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " elseif opC == 3 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "nil"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "(_i == 1 and _r1) or (_i == 2 and _r2) or nil"), " end end ",
					"else ",
						"if opC == 1 then ", sR("opA", "nil"), " elseif opC == 2 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " elseif opC == 3 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "nil"), " end end ",
					"end ",
				"elseif opC == 0 then _fn(_a1, _a2) ",
				"elseif opC == 1 then ", sR("opA", "_fn(_a1, _a2)"), " ",
				"elseif opC == 2 then local _r1, _r2 = _fn(_a1, _a2); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " ",
				"elseif opC == 3 then local _r1, _r2, _r3 = _fn(_a1, _a2); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " ",
				"elseif opC > 3 then local _rn, _ret = ", V.capture, "(_fn(_a1, _a2)); for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end ",
				"else local _rn, _ret = ", V.capture, "(_fn(_a1, _a2)); for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
			"elseif opB == 3 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; local _a3 = ", gR("opA + 3"), "; ",
				"if _a1 == nil then ",
					"local _ok, _r1, _r2, _r3 = pcall(_fn, nil, _a2, _a3); ",
					"if _ok then ",
						"if opC == 1 then ", sR("opA", "_r1"), " elseif opC == 2 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " elseif opC == 3 then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "(_i == 1 and _r1) or (_i == 2 and _r2) or (_i == 3 and _r3) or nil"), " end end ",
					"else ",
						"if opC == 1 then ", sR("opA", "nil"), " elseif opC == 2 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " elseif opC == 3 then ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " elseif opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "nil"), " end end ",
					"end ",
				"elseif opC == 0 then _fn(_a1, _a2, _a3) ",
				"elseif opC == 1 then ", sR("opA", "_fn(_a1, _a2, _a3)"), " ",
				"elseif opC == 2 then local _r1, _r2 = _fn(_a1, _a2, _a3); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " ",
				"elseif opC == 3 then local _r1, _r2, _r3 = _fn(_a1, _a2, _a3); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " ",
				"elseif opC > 3 then local _rn, _ret = ", V.capture, "(_fn(_a1, _a2, _a3)); for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end ",
				"else local _rn, _ret = ", V.capture, "(_fn(_a1, _a2, _a3)); for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
			"else ",
				"local _args = {}; local _numArgs = 0; ",
				"if opB == -1 then local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_vi] = ", v_va, "[_vi] end; _numArgs = _vaCount ",
				"elseif opB <= -100 then local _num = (-opB) - 100; for _i = 1, _num do _args[_i] = ", gR("opA + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _numArgs = _num + _vaCount ",
				"else for _i = 1, opB do _args[_i] = ", gR("opA + _i"), " end; _numArgs = opB end; ",
				"if _numArgs > 0 and _args[1] == nil then ",
					"local _ok, _rn, _ret = pcall(function() return ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _numArgs))) end); ",
					"if _ok and _ret then ",
						"if opC == 1 then ", sR("opA", "_ret[1]"), " elseif opC > 1 then for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end elseif opC < 0 then for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
					"else ",
						"if opC > 0 then for _i = 1, opC do ", sR("opA + _i - 1", "nil"), " end end ",
					"end ",
				"else ",
					"if opC == 0 then _fn(", v_packUnpack, "(_args, 1, _numArgs)) ",
					"elseif opC == 1 then ", sR("opA", "_fn(" .. v_packUnpack .. "(_args, 1, _numArgs))"), " ",
					"elseif opC == 2 then local _r1, _r2 = _fn(", v_packUnpack, "(_args, 1, _numArgs)); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " ",
					"elseif opC == 3 then local _r1, _r2, _r3 = _fn(", v_packUnpack, "(_args, 1, _numArgs)); ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " ",
					"elseif opC > 3 then local _rn, _ret = ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _numArgs))); for _i = 1, opC do ", sR("opA + _i - 1", "_ret[_i]"), " end ",
					"else local _rn, _ret = ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _numArgs))); for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end ",
				"end ",
			"end ",
		"elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5) or ", v_isType, "(_fn, 7)) then ",
			"if opB == 0 then ",
				"if opC == 0 then pcall(_fn) ",
				"elseif opC == 1 then local _ok, _r1 = pcall(_fn); if _ok then ", sR("opA", "_r1"), " else ", sR("opA", "nil"), " end ",
				"elseif opC == 2 then local _ok, _r1, _r2 = pcall(_fn); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " end ",
				"elseif opC == 3 then local _ok, _r1, _r2, _r3 = pcall(_fn); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " end ",
				"else local _rn, _res = ", V.capturePcall, "(pcall(_fn)); if opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "_res[_i]"), " end else for _i = 1, _rn do ", sR("opA + _i - 1", "_res[_i]"), " end end end ",
			"elseif opB == 1 then ",
				"local _a1 = ", gR("opA + 1"), "; ",
				"if opC == 0 then pcall(_fn, _a1) ",
				"elseif opC == 1 then local _ok, _r1 = pcall(_fn, _a1); if _ok then ", sR("opA", "_r1"), " else ", sR("opA", "nil"), " end ",
				"elseif opC == 2 then local _ok, _r1, _r2 = pcall(_fn, _a1); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " end ",
				"elseif opC == 3 then local _ok, _r1, _r2, _r3 = pcall(_fn, _a1); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " end ",
				"else local _rn, _res = ", V.capturePcall, "(pcall(_fn, _a1)); if opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "_res[_i]"), " end else for _i = 1, _rn do ", sR("opA + _i - 1", "_res[_i]"), " end end end ",
			"elseif opB == 2 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; ",
				"if opC == 0 then pcall(_fn, _a1, _a2) ",
				"elseif opC == 1 then local _ok, _r1 = pcall(_fn, _a1, _a2); if _ok then ", sR("opA", "_r1"), " else ", sR("opA", "nil"), " end ",
				"elseif opC == 2 then local _ok, _r1, _r2 = pcall(_fn, _a1, _a2); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), " end ",
				"elseif opC == 3 then local _ok, _r1, _r2, _r3 = pcall(_fn, _a1, _a2); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " end ",
				"else local _rn, _res = ", V.capturePcall, "(pcall(_fn, _a1, _a2)); if opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "_res[_i]"), " end else for _i = 1, _rn do ", sR("opA + _i - 1", "_res[_i]"), " end end end ",
			"elseif opB == 3 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; local _a3 = ", gR("opA + 3"), "; ",
				"if opC == 0 then pcall(_fn, _a1, _a2, _a3) ",
				"elseif opC == 1 then local _ok, _r1 = pcall(_fn, _a1, _a2, _a3); if _ok then ", sR("opA", "_r1"), " else ", sR("opA", "nil"), " end ",
				"elseif opC == 2 then local _ok, _r1, _r2, _r3 = pcall(_fn, _a1, _a2, _a3); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 1", "nil"), " end ", -- Wait, keeping original line
				"elseif opC == 3 then local _ok, _r1, _r2, _r3 = pcall(_fn, _a1, _a2, _a3); if _ok then ", sR("opA", "_r1"), "; ", sR("opA + 1", "_r2"), "; ", sR("opA + 2", "_r3"), " else ", sR("opA", "nil"), "; ", sR("opA + 1", "nil"), "; ", sR("opA + 2", "nil"), " end ",
				"else local _rn, _res = ", V.capturePcall, "(pcall(_fn, _a1, _a2, _a3)); if opC > 3 then for _i = 1, opC do ", sR("opA + _i - 1", "_res[_i]"), " end else for _i = 1, _rn do ", sR("opA + _i - 1", "_res[_i]"), " end end end ",
			"else ",
				"local _args = {}; local _numArgs = 0; ",
				"if opB == -1 then local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_vi] = ", v_va, "[_vi] end; _numArgs = _vaCount ",
				"elseif opB <= -100 then local _num = (-opB) - 100; for _i = 1, _num do _args[_i] = ", gR("opA + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _numArgs = _num + _vaCount ",
				"else for _i = 1, opB do _args[_i] = ", gR("opA + _i"), " end; _numArgs = opB end; ",
				"local _rn, _res = ", V.capturePcall, "(pcall(_fn, ", v_packUnpack, "(_args, 1, _numArgs))); ",
				"if opC == 1 then ", sR("opA", "_res[1]"), " ",
				"elseif opC > 1 then for _i = 1, opC do ", sR("opA + _i - 1", "_res[_i]"), " end ",
				"elseif opC < 0 then for _i = 1, _rn do ", sR("opA + _i - 1", "_res[_i]"), " end end ",
			"end ",
		"elseif opC > 0 then ",
			"for _i = 1, opC do ", sR("opA + _i - 1", "nil"), " end ",
		"end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 73 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 131 + ", v_predBlockHash, " + opA * 7 + opB * 3 + opC) % ", tostring(stateMod)
	})

	hCode.ret = sConcat({
		"\t\t\t\t", v_isRet, " = true; ",
		"if opB == -2 then ", v_ip, " = ", v_codeLen, " + 1; ", v_retTbl, " = ", v_va, "; ", v_retCount, " = -1; ", v_retCountN, " = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; ",
		"elseif opB <= -100 then local _num = ((-opB) - 100); local _res = {}; for _i = 1, _num do _res[_i] = ", gR("opA + _i - 1"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _res[_num + _vi] = ", v_va, "[_vi] end; ", v_ip, " = ", v_codeLen, " + 1; ", v_retTbl, " = _res; ", v_retCount, " = -1; ", v_retCountN, " = _num + _vaCount; ",
		"elseif opB == -1 or opB < opA then ", v_ip, " = ", v_codeLen, " + 1; ", v_retCount, " = 0; ",
		"elseif opB == opA then local _val = ", gR("opA"), "; ", v_ip, " = ", v_codeLen, " + 1; ", v_retCount, " = 1; ", v_ret1, " = _val; ",
		"elseif opB == opA + 1 then local _v1 = ", gR("opA"), "; local _v2 = ", gR("opA + 1"), "; ", v_ip, " = ", v_codeLen, " + 1; ", v_retCount, " = 2; ", v_ret1, " = _v1; ", v_ret2, " = _v2; ",
		"elseif opB == opA + 2 then local _v1 = ", gR("opA"), "; local _v2 = ", gR("opA + 1"), "; local _v3 = ", gR("opA + 2"), "; ", v_ip, " = ", v_codeLen, " + 1; ", v_retCount, " = 3; ", v_ret1, " = _v1; ", v_ret2, " = _v2; ", v_ret3, " = _v3; ",
		"else local _num = (opB - opA) + 1; local _res = {}; for _i = 1, _num do _res[_i] = ", gR("opA + _i - 1"), " end; ", v_ip, " = ", v_codeLen, " + 1; ", v_retTbl, " = _res; ", v_retCount, " = -1; ", v_retCountN, " = _num; end"
	})

	hCode.callTableAppend = sConcat({
		"\t\t\t\tlocal _tbl = ", gR("opA"), "; local _fn = ", gR("opB"), "; local _b = opC % 32; local _startIdx = math.floor(opC / 32); local _ret = nil; local _rn = 0; ",
		"if ", v_isType, "(_fn, 1) then ",
			"if _b == 0 then _rn, _ret = ", V.capture, "(_fn()) elseif _b == 1 then _rn, _ret = ", V.capture, "(_fn(", gR("opB + 1"), ")) elseif _b == 2 then _rn, _ret = ", V.capture, "(_fn(", gR("opB + 1"), ", ", gR("opB + 2"), ")) elseif _b == 3 then _rn, _ret = ", V.capture, "(_fn(", gR("opB + 1"), ", ", gR("opB + 2"), ", ", gR("opB + 3"), ")) ",
			"elseif _b == 31 or _b >= 16 then local _num = (_b == 31 and 0) or (_b - 16); local _args = {}; for _ai = 1, _num do _args[_ai] = ", gR("opB + _ai"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _rn, _ret = ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _num + _vaCount))) ",
			"else local _args = {}; for _ai = 1, _b do _args[_ai] = ", gR("opB + _ai"), " end; _rn, _ret = ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _b))) end ",
		"elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5) or ", v_isType, "(_fn, 7)) then ",
			"local _args = {}; local _nArgs = 0; ",
			"if _b == 0 then ",
			"elseif _b <= 3 then for _ai = 1, _b do _args[_ai] = ", gR("opB + _ai"), " end; _nArgs = _b ",
			"elseif _b == 31 or _b >= 16 then local _num = (_b == 31 and 0) or (_b - 16); for _ai = 1, _num do _args[_ai] = ", gR("opB + _ai"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _nArgs = _num + _vaCount ",
			"else for _ai = 1, _b do _args[_ai] = ", gR("opB + _ai"), " end; _nArgs = _b end; ",
			"_rn, _ret = ", V.capturePcall, "(pcall(_fn, ", v_packUnpack, "(_args, 1, _nArgs))) ",
		"end; ",
		"if _tbl ~= nil and _ret ~= nil then for _ri = 1, _rn do _tbl[_startIdx + _ri - 1] = _ret[_ri] end end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 79 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 143 + ", v_predBlockHash, " + opA * 7) % ", tostring(stateMod)
	})

	hCode.callExpand = sConcat({
		"\t\t\t\tlocal _fn = ", gR("opA"), "; local _numFixed = math.floor(opB / 64); local _subMode = opB % 64; local _subBase = opA + _numFixed + 1; local _subFn = ", gR("_subBase"), "; local _subRet = nil; local _subN = 0; if _subFn ~= nil then ",
		"if _subMode == 31 then _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(", v_va, "))) ",
		"elseif _subMode >= 32 then local _sFixed = _subMode - 32; local _sArgs = {}; for _i = 1, _sFixed do _sArgs[_i] = ", gR("_subBase + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _sArgs[_sFixed + _vi] = ", v_va, "[_vi] end; _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(_sArgs, 1, _sFixed + _vaCount))) ",
		"else local _sArgs = {}; for _i = 1, _subMode do _sArgs[_i] = ", gR("_subBase + _i"), " end; _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(_sArgs, 1, _subMode))) end end; ",
		"local _args = {}; for _i = 1, _numFixed do _args[_i] = ", gR("opA + _i"), " end; for _si = 1, _subN do _args[_numFixed + _si] = _subRet[_si] end; local _totalN = _numFixed + _subN; local _ret = nil; local _rn = 0; if _fn ~= nil then _rn, _ret = ", V.capturePcall, "(pcall(_fn, ", v_packUnpack, "(_args, 1, _totalN))) end; ",
		"if opC > 0 then for _i = 1, opC do ", sR("opA + _i - 1", "_ret and _ret[_i]"), " end elseif opC < 0 then for _i = 1, _rn do ", sR("opA + _i - 1", "_ret[_i]"), " end end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 83 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 149 + ", v_predBlockHash, " + opA * 9 + opB * 5 + opC) % ", tostring(stateMod)
	})

	hCode.callRet = sConcat({
		"\t\t\t\tlocal _fn = ", gR("opA"), "; ", v_ip, " = ", v_codeLen, " + 1; ", v_isRet, " = true; ",
		"if ", v_isType, "(_fn, 1) then ",
			"if opB == 0 then ", V.recvRet, "(_fn()) ",
			"elseif opB == 1 then ",
				"local _a1 = ", gR("opA + 1"), "; ",
				"if _a1 ~= nil then ", V.recvRet, "(_fn(_a1)) ",
				"else local _ok, _r1 = pcall(_fn, nil); if _ok then ", V.recvRet, "(_r1) else ", v_retCount, " = 0 end end ",
			"elseif opB == 2 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; ",
				"if _a1 ~= nil then ", V.recvRet, "(_fn(_a1, _a2)) ",
				"else local _ok, _r1, _r2 = pcall(_fn, nil, _a2); if _ok then ", V.recvRet, "(_r1, _r2) else ", v_retCount, " = 0 end end ",
			"elseif opB == 3 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; local _a3 = ", gR("opA + 3"), "; ",
				"if _a1 ~= nil then ", V.recvRet, "(_fn(_a1, _a2, _a3)) ",
				"else local _ok, _r1, _r2, _r3 = pcall(_fn, nil, _a2, _a3); if _ok then ", V.recvRet, "(_r1, _r2, _r3) else ", v_retCount, " = 0 end end ",
			"else ",
				"local _args = {}; local _numArgs = 0; ",
				"if opB == -1 then local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_vi] = ", v_va, "[_vi] end; _numArgs = _vaCount ",
				"elseif opB <= -100 then local _num = (-opB) - 100; for _i = 1, _num do _args[_i] = ", gR("opA + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _numArgs = _num + _vaCount ",
				"else for _i = 1, opB do _args[_i] = ", gR("opA + _i"), " end; _numArgs = opB end; ",
				"if _numArgs > 0 and _args[1] == nil then ",
					"local _ok, _rn, _ret = pcall(function() return ", V.capture, "(_fn(", v_packUnpack, "(_args, 1, _numArgs))) end); ",
					"if _ok and _ret then ", V.recvRet, "(", v_packUnpack, "(_ret, 1, _rn)) else ", v_retCount, " = 0 end ",
				"else ",
					V.recvRet, "(_fn(", v_packUnpack, "(_args, 1, _numArgs))) ",
				"end ",
			"end ",
		"elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5) or ", v_isType, "(_fn, 7)) then ",
			"if opB == 0 then ", V.recvPcall, "(pcall(_fn)) ",
			"elseif opB == 1 then ",
				"local _a1 = ", gR("opA + 1"), "; ",
				"if _a1 ~= nil then ", V.recvPcall, "(pcall(_fn, _a1)) ",
				"else local _ok, _r1 = pcall(_fn, nil); if _ok then ", V.recvPcall, "(true, _r1) else ", v_retCount, " = 0 end end ",
			"elseif opB == 2 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; ",
				"if _a1 ~= nil then ", V.recvPcall, "(pcall(_fn, _a1, _a2)) ",
				"else local _ok, _r1, _r2 = pcall(_fn, nil, _a2); if _ok then ", V.recvPcall, "(true, _r1, _r2) else ", v_retCount, " = 0 end end ",
			"elseif opB == 3 then ",
				"local _a1 = ", gR("opA + 1"), "; local _a2 = ", gR("opA + 2"), "; local _a3 = ", gR("opA + 3"), "; ",
				"if _a1 ~= nil then ", V.recvPcall, "(pcall(_fn, _a1, _a2, _a3)) ",
				"else local _ok, _r1, _r2, _r3 = pcall(_fn, nil, _a2, _a3); if _ok then ", V.recvPcall, "(true, _r1, _r2, _r3) else ", v_retCount, " = 0 end end ",
			"else ",
				"local _args = {}; local _numArgs = 0; ",
				"if opB == -1 then local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_vi] = ", v_va, "[_vi] end; _numArgs = _vaCount ",
				"elseif opB <= -100 then local _num = (-opB) - 100; for _i = 1, _num do _args[_i] = ", gR("opA + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = ", v_va, "[_vi] end; _numArgs = _num + _vaCount ",
				"else for _i = 1, opB do _args[_i] = ", gR("opA + _i"), " end; _numArgs = opB end; ",
				V.recvPcall, "(pcall(_fn, ", v_packUnpack, "(_args, 1, _numArgs))) ",
			"end ",
		"else ",
			v_retCount, " = 0 ",
		"end"
	})

	hCode.callExpandRet = sConcat({
		"\t\t\t\tlocal _fn = ", gR("opA"), "; local _numFixed = math.floor(opB / 64); local _subMode = opB % 64; local _subBase = opA + _numFixed + 1; local _subFn = ", gR("_subBase"), "; local _subRet = nil; local _subN = 0; if _subFn ~= nil then ",
		"if _subMode == 31 then _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(", v_va, "))) ",
		"elseif _subMode >= 32 then local _sFixed = _subMode - 32; local _sArgs = {}; for _i = 1, _sFixed do _sArgs[_i] = ", gR("_subBase + _i"), " end; local _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; for _vi = 1, _vaCount do _sArgs[_sFixed + _vi] = ", v_va, "[_vi] end; _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(_sArgs, 1, _sFixed + _vaCount))) ",
		"else local _sArgs = {}; for _i = 1, _subMode do _sArgs[_i] = ", gR("_subBase + _i"), " end; _subN, _subRet = ", V.capturePcall, "(pcall(_subFn, ", v_packUnpack, "(_sArgs, 1, _subMode))) end end; ",
		"local _args = {}; for _i = 1, _numFixed do _args[_i] = ", gR("opA + _i"), " end; for _si = 1, _subN do _args[_numFixed + _si] = _subRet[_si] end; local _totalN = _numFixed + _subN; ",
		v_ip, " = ", v_codeLen, " + 1; ", v_isRet, " = true; if _fn ~= nil then ", V.recvPcall, "(pcall(_fn, ", v_packUnpack, "(_args, 1, _totalN))) else ", v_retCount, " = 0 end"
	})

	hCode.robloxGetService = sConcat({
		"\t\t\t\tlocal _g = ", gR("opB"), " or (game ~= nil and game) or (_G and _G.game) or (getgenv and ", v_isType, "(getgenv, 1) and select(1, pcall(getgenv)) and select(2, pcall(getgenv)).game); ",
		"local _svc = nil; if _g ~= nil then local _gsFn = _g[", v_getStdName, "(", tostring(hGetService), ")]; if _gsFn then local _ok, _s = pcall(_gsFn, _g, ", v_getK, "(opC + 1)); if _ok then _svc = _s end end end; ",
		sR("opA", "_svc"), "; ", v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 113 + opA) % ", tostring(stateMod), "; ", v_vmState, " = (", v_vmState, " * 239 + ", v_predBlockHash, " + opA * 47) % ", tostring(stateMod)
	})

	hCode.robloxGetLocalChar = sConcat({
		"\t\t\t\tlocal _g = ", gR("opB"), " or (game ~= nil and game) or (_G and _G.game) or (getgenv and ", v_isType, "(getgenv, 1) and select(1, pcall(getgenv)) and select(2, pcall(getgenv)).game); ",
		"local _chr = nil; if _g ~= nil then local _gsFn = _g[", v_getStdName, "(", tostring(hGetService), ")]; local _ok, _p = false, nil; if _gsFn then _ok, _p = pcall(_gsFn, _g, ", v_getStdName, "(", tostring(hPlayers), ")) end; local _lp = _ok and _p and _p[", v_getStdName, "(", tostring(hLocalPlayer), ")]; _chr = _lp and _lp[", v_getStdName, "(", tostring(hCharacter), ")] end; ",
		sR("opA", "_chr"), "; ", v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 127 + opA) % ", tostring(stateMod), "; ", v_vmState, " = (", v_vmState, " * 241 + ", v_predBlockHash, " + opA * 59) % ", tostring(stateMod)
	})

	hCode.forinPrep = sConcat({
		"\t\t\t\tlocal _it = ", gR("opA"), "; local _st = ", gR("opB"), "; if ", v_isType, "(_it, 2) then ",
		"if _st == nil then ",
			"local _mt = getmetatable and getmetatable(_it); local _iterFn = ", v_isType, "(_mt, 2) and _mt[", v_getStdName, "(", tostring(hIter), ")]; ",
			"if ", v_isType, "(_iterFn, 1) then ",
				"local _ok, _f, _s, _v = pcall(_iterFn, _it); if _ok and _f ~= nil then ", sR("opA", "_f"), "; ", sR("opB", "_s"), "; ", sR("opC", "_v"), " ",
				"else local _nxt = next or (_G and _G.next) or ", v_resolveEnv, "(env, ", tostring(hNext), "); ", sR("opA", "_nxt"), "; ", sR("opB", "_it"), "; ", sR("opC", "nil"), " end ",
			"else local _nxt = next or (_G and _G.next) or ", v_resolveEnv, "(env, ", tostring(hNext), "); ", sR("opA", "_nxt"), "; ", sR("opB", "_it"), "; ", sR("opC", "nil"), " end ",
		"else ",
			"local _mt = getmetatable and getmetatable(_it); local _callFn = ", v_isType, "(_mt, 2) and _mt[", v_getStdName, "(", tostring(hCall), ")]; ",
			"if not ", v_isType, "(_callFn, 1) then ", sR("opA", "(function() return nil end)"), "; ", sR("opB", "nil"), "; ", sR("opC", "nil"), " end ",
		"end ",
		"elseif ", v_isType, "(_it, 1) then ",
			"if _st == nil then ",
				"local _nxt = next or (_G and _G.next); ",
				"if _it == _nxt then ",
					sR("opA", "(function() return nil end)"), "; ", sR("opB", "nil"), "; ", sR("opC", "nil"), " ",
				"else ",
					"local _ok = pcall(_it, nil, nil); ",
					"if not _ok then ",
						sR("opA", "(function() return nil end)"), "; ", sR("opB", "nil"), "; ", sR("opC", "nil"), " ",
					"end ",
				"end ",
			"end ",
		"else ",
			"local _handled = false; if (", v_isType, "(_it, 5) or ", v_isType, "(_it, 7)) then ",
				"local _mt = getmetatable and getmetatable(_it); if ", v_isType, "(_mt, 2) then ",
					"local _iterFn = _mt[", v_getStdName, "(", tostring(hIter), ")]; if ", v_isType, "(_iterFn, 1) then ",
						"local _ok, _f, _s, _v = pcall(_iterFn, _it); if _ok and _f ~= nil then ", sR("opA", "_f"), "; ", sR("opB", "_s"), "; ", sR("opC", "_v"), "; _handled = true end ",
					"elseif ", v_isType, "(_mt[", v_getStdName, "(", tostring(hCall), ")], 1) then _handled = true end ",
				"end ",
			"end; ",
			"if not _handled then ", sR("opA", "(function() return nil end)"), "; ", sR("opB", "nil"), "; ", sR("opC", "nil"), " end ",
		"end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 89 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 103 + ", v_predBlockHash, " + opA * 13) % ", tostring(stateMod)
	})

	hCode.closure = sConcat({
		"\t\t\t\tlocal _childBc = ", v_getK, "(opB + 1); ", sR("opA", v_createClosure .. "(_childBc, K, env, uvs, " .. v_Bank .. ", regA1, regA2, regA3, regOffset, " .. v_outerVM .. ", (" .. v_currentRegion .. " and " .. v_currentRegion .. "[8]) or " .. v_regMap .. ")"), "; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 67 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 137 + ", v_predBlockHash, " + opA * 11) % ", tostring(stateMod)
	})

	hCode.vararg = sConcat({
		"\t\t\t\tlocal _vaCount = (", v_va, " and (", v_va, ".n or #", v_va, ")) or 0; local _b = opB; if _b and _b >= 128 then _b = _b - 256 end; if _b == -1 then local _dest = ", gR("opA"), "; if _dest ~= nil then for _i = 1, _vaCount do _dest[opC + _i - 1] = ", v_va, "[_i] end end elseif _b == 1 then ", sR("opA", v_va .. " and " .. v_va .. "[1]"), " else local _num = (_b > 0 and _b) or _vaCount; for _i = 1, _num do ", sR("opA + _i - 1", v_va .. " and " .. v_va .. "[_i]"), " end end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 71 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 139 + ", v_predBlockHash, " + opA * 5) % ", tostring(stateMod)
	})

	hCode.jmp = sConcat({
		"\t\t\t\tlocal _step = (tonumber(opA) or 0) * 2; ", v_ip, " = ", v_ip, " + _step; if ", v_ip, " < 1 then ", v_ip, " = 1 elseif ", v_ip, " > ", v_codeLen, " + 10 then ", v_ip, " = ", v_codeLen, " + 1 end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 31 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 37 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.eq = sConcat({
		"\t\t\t\tlocal _cond = ", v_evalCompare, "(", gR("opB", 1), ", ", gR("opC", 2), ", 1, opA ~= 0); ",
		(leakageAudit and ("if _G and _G.__LEAKAGE_OBSERVE then _G.__LEAKAGE_OBSERVE(\"E\", { result = _cond, dip = " .. v_dip .. " }) end; ") or ""),
		"if _cond then ", v_ip, " = ", v_ip, " + 4 end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 43 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 149 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.lt = sConcat({
		"\t\t\t\tlocal _cond = ", v_evalCompare, "(", gR("opB", 2), ", ", gR("opC", 3), ", 2, opA ~= 0); ",
		(leakageAudit and ("if _G and _G.__LEAKAGE_OBSERVE then _G.__LEAKAGE_OBSERVE(\"E\", { result = _cond, dip = " .. v_dip .. " }) end; ") or ""),
		"if _cond then ", v_ip, " = ", v_ip, " + 4 end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 47 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 151 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.le = sConcat({
		"\t\t\t\tlocal _cond = ", v_evalCompare, "(", gR("opB", 3), ", ", gR("opC", 1), ", 3, opA ~= 0); ",
		(leakageAudit and ("if _G and _G.__LEAKAGE_OBSERVE then _G.__LEAKAGE_OBSERVE(\"E\", { result = _cond, dip = " .. v_dip .. " }) end; ") or ""),
		"if _cond then ", v_ip, " = ", v_ip, " + 4 end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 53 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 157 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.forprep = sConcat({
		"\t\t\t\tlocal _step = tonumber(", gR("opA + 2"), ") or 1; local _init = (tonumber(", gR("opA"), ") or 0) - _step; ", sR("opA", "_init"), "; ", v_ip, " = ", v_ip, " + (tonumber(opB) or 0) * 2; if ", v_ip, " < 1 then ", v_ip, " = 1 elseif ", v_ip, " > ", v_codeLen, " + 10 then ", v_ip, " = ", v_codeLen, " + 1 end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 59 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 163 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.forloop = sConcat({
		"\t\t\t\tlocal _step = tonumber(", gR("opA + 2"), ") or 1; local _idx = (tonumber(", gR("opA"), ") or 0) + _step; local _limit = tonumber(", gR("opA + 1"), ") or 0; ", sR("opA", "_idx"), "; if (_step > 0 and _idx <= _limit) or (_step <= 0 and _idx >= _limit) then ", v_ip, " = ", v_ip, " + (tonumber(opB) or 0) * 2; if ", v_ip, " < 1 then ", v_ip, " = 1 elseif ", v_ip, " > ", v_codeLen, " + 10 then ", v_ip, " = ", v_codeLen, " + 1 end; ", sR("opA + 3", "_idx"), " end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 61 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 167 + ", v_predBlockHash, " + ", v_ip, ") % ", tostring(stateMod)
	})

	hCode.loadkCall = sConcat({
		"\t\t\t\tlocal _val = ", v_getK, "(opB + 1); ", sR("opA", "_val"), "; if ", v_isType, "(_val, 1) then _val() elseif (", v_isType, "(_val, 2) or ", v_isType, "(_val, 5)) then pcall(_val) end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 97 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 191 + ", v_predBlockHash, " + opA * 17) % ", tostring(stateMod)
	})

	hCode.gettableCall = sConcat({
		"\t\t\t\tlocal _t = ", gR("opB"), "; local _k = ", v_getK, "(opC + 1); local _fn = _t[_k]; ", sR("opA", "_fn"), "; if ", v_isType, "(_fn, 1) then _fn() elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5)) then pcall(_fn) end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 101 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 193 + ", v_predBlockHash, " + opA * 19) % ", tostring(stateMod)
	})

	hCode.getupvalCall = sConcat({
		"\t\t\t\tlocal _cell = uvs[opB + 1]; local _fn = _cell and _cell[1]; ", sR("opA", "_fn"), "; if ", v_isType, "(_fn, 1) then local _a1 = ", gR("opA + 1"), "; if _a1 ~= nil then _fn(_a1) else pcall(_fn, nil) end elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5)) then local _a1 = ", gR("opA + 1"), "; pcall(_fn, _a1) end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 103 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 197 + ", v_predBlockHash, " + opA * 23) % ", tostring(stateMod)
	})

	hCode.getglobalCall = sConcat({
		"\t\t\t\tlocal _kVal = ", v_getK, "(opB + 1); local _fn = ", v_resolveEnv, "(env, _kVal); ", sR("opA", "_fn"), "; if ", v_isType, "(_fn, 1) then local _a1 = ", gR("opA + 1"), "; if _a1 ~= nil then _fn(_a1) else pcall(_fn, nil) end elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5)) then local _a1 = ", gR("opA + 1"), "; pcall(_fn, _a1) end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 107 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 199 + ", v_predBlockHash, " + opA * 29) % ", tostring(stateMod)
	})

	hCode.moveCall = sConcat({
		"\t\t\t\tlocal _fn = ", gR("opB"), "; ", sR("opA", "_fn"), "; if ", v_isType, "(_fn, 1) then _fn() elseif (", v_isType, "(_fn, 2) or ", v_isType, "(_fn, 5)) then pcall(_fn) end; ",
		v_predBlockHash, " = (", v_predBlockHash, " * 16777619 + ", v_dip, " * 109 + opA) % ", tostring(stateMod), "; ",
		v_vmState, " = (", v_vmState, " * 227 + ", v_predBlockHash, " + opA * 41) % ", tostring(stateMod)
	})

	local sPI = (stateCoupling == "per_instruction" and ("; " .. v_vmState .. " = (" .. v_vmState .. " * 101 + opA + 1) % " .. tostring(stateMod))) or ""
	local dynamicDescriptors = {}
	local function addDesc(name, code)
		dynamicDescriptors[#dynamicDescriptors + 1] = { name = name, code = code }
	end

	addDesc("MOVE", "\t\t\t\t" .. sR("opA", gR("opB")) .. sPI)
	addDesc("LOADK", "\t\t\t\tlocal _val = " .. v_getK .. "(opB + 1); " .. sR("opA", "_val") .. sPI)
	addDesc("LOADBOOL", "\t\t\t\t" .. sR("opA", "opB ~= 0") .. "; if opC ~= 0 then " .. v_ip .. " = " .. v_ip .. " + 4 end" .. sPI)
	addDesc("LOADNIL", "\t\t\t\tfor _r = opA, opB do " .. sR("_r", "nil") .. " end" .. sPI)
	addDesc("GETGLOBAL", "\t\t\t\tlocal _kVal = " .. v_getK .. "(opB + 1); local _gv = " .. v_resolveEnv .. "(env, _kVal); " .. sR("opA", "_gv") .. sPI)
	addDesc("SETGLOBAL", "\t\t\t\tlocal _kVal = " .. v_getK .. "(opB + 1); local _val = " .. gR("opA") .. "; local _kReal = (" .. v_isType .. "(_kVal, 4) and " .. v_getStdName .. "(_kVal)) or _kVal; if " .. v_isType .. "(env, 2) then env[_kReal] = _val; if _kReal ~= _kVal then env[_kVal] = _val end end" .. sPI)
	addDesc("GETUPVAL", "\t\t\t\tlocal _cell = uvs[opB + 1]; " .. sR("opA", "_cell and _cell[1]") .. sPI)
	addDesc("SETUPVAL", "\t\t\t\tlocal _cell = uvs[opB + 1]; if _cell then " .. v_rawset .. "(_cell, 1, " .. gR("opA") .. ") end" .. sPI)
	addDesc("GETTABLE", "\t\t\t\tlocal _t = " .. gR("opB") .. "; local _k = " .. gR("opC") .. "; local _v = nil; if _t ~= nil then _v = _t[_k] end; " .. sR("opA", "_v") .. sPI)
	addDesc("GETTABLE_K", "\t\t\t\tlocal _t = " .. gR("opB") .. "; local _k = " .. v_getK .. "(opC + 1); local _v = nil; if _t ~= nil then _v = _t[_k] end; " .. sR("opA", "_v") .. sPI)
	addDesc("SETTABLE", "\t\t\t\tlocal _t = " .. gR("opA") .. "; local _k = " .. gR("opB") .. "; local _val = " .. gR("opC") .. "; if _t ~= nil then _t[_k] = _val end" .. sPI)
	addDesc("SETTABLE_K", "\t\t\t\tlocal _t = " .. gR("opA") .. "; local _k = " .. v_getK .. "(opB + 1); local _val = " .. gR("opC") .. "; if _t ~= nil then _t[_k] = _val end" .. sPI)
	addDesc("NEWTABLE", "\t\t\t\t" .. sR("opA", "{}") .. sPI)
	addDesc("ADD", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 1) .. ", " .. gR("opC", 2) .. ", false); " .. sR("opA", "_v", 1) .. sPI)
	addDesc("ADD_K", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 2) .. ", " .. v_getK .. "(opC + 1), false); " .. sR("opA", "_v", 2) .. sPI)
	addDesc("SUB", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 3) .. ", " .. gR("opC", 1) .. ", true); " .. sR("opA", "_v", 3) .. sPI)
	addDesc("MUL", "\t\t\t\tlocal _v = " .. v_evalMulDivMod .. "(" .. gR("opB", 1) .. ", " .. gR("opC", 3) .. ", 1); " .. sR("opA", "_v", 2) .. sPI)
	addDesc("DIV", "\t\t\t\tlocal _v = " .. v_evalMulDivMod .. "(" .. gR("opB", 2) .. ", " .. gR("opC", 1) .. ", 2); " .. sR("opA", "_v", 1) .. sPI)
	addDesc("MOD", "\t\t\t\tlocal _v = " .. v_evalMulDivMod .. "(" .. gR("opB", 3) .. ", " .. gR("opC", 2) .. ", 3); " .. sR("opA", "_v", 3) .. sPI)
	addDesc("POW", "\t\t\t\tlocal _v = " .. v_evalPowUnm .. "(" .. gR("opB", 1) .. ", " .. gR("opC", 1) .. ", true); " .. sR("opA", "_v", 1) .. sPI)
	addDesc("UNM", "\t\t\t\tlocal _v = " .. v_evalPowUnm .. "(" .. gR("opB", 2) .. ", nil, false); " .. sR("opA", "_v", 2) .. sPI)
	addDesc("NOT", "\t\t\t\tlocal _v = not " .. gR("opB") .. "; " .. sR("opA", "_v") .. sPI)
	addDesc("LEN", "\t\t\t\tlocal _lv = " .. gR("opB") .. "; local _v = (_lv ~= nil and #_lv) or 0; " .. sR("opA", "_v") .. sPI)
	addDesc("CONCAT", "\t\t\t\tlocal _v = tostring(" .. gR("opB") .. " or '') .. tostring(" .. gR("opC") .. " or ''); " .. sR("opA", "_v") .. sPI)
	addDesc("CALL", hCode.call)
	addDesc("CLOSURE", hCode.closure)
	addDesc("VARARG", hCode.vararg)
	addDesc("JMP", hCode.jmp)
	addDesc("EQ", hCode.eq)
	addDesc("LT", hCode.lt)
	addDesc("LE", hCode.le)
	addDesc("FORPREP", hCode.forprep)
	addDesc("FORLOOP", hCode.forloop)
	addDesc("RETURN", hCode.ret)
	-- Superinstruction synthesizers
	addDesc("LOADK_SETTABLE", "\t\t\t\tlocal _t = " .. gR("opA") .. "; local _k = " .. v_getK .. "(opB + 1); local _val = " .. v_getK .. "(opC + 1); _t[_k] = _val" .. sPI)
	addDesc("ADD_SETTABLE", "\t\t\t\tlocal _val = " .. v_evalAddSub .. "(" .. gR("opB", 1) .. ", " .. gR("opC", 2) .. ", false); local _t = " .. gR("opA", 3) .. "; if _t ~= nil then pcall(function() _t[1] = _val end) end" .. sPI)
	addDesc("LOADK_MOVE", "\t\t\t\tlocal _val = " .. v_getK .. "(opB + 1); " .. sR("opA", "_val") .. "; " .. sR("opC", "_val") .. sPI)
	addDesc("LOADK_CALL", hCode.loadkCall)
	addDesc("GETTABLE_CALL", hCode.gettableCall)
	addDesc("GETUPVAL_CALL", hCode.getupvalCall)
	addDesc("GETGLOBAL_CALL", hCode.getglobalCall)
	addDesc("GETTABLE_SETTABLE", "\t\t\t\tlocal _src = " .. gR("opB") .. "; local _k = " .. v_getK .. "(opC + 1); local _v = nil; if _src ~= nil then local _ok, _res = pcall(function() return _src[_k] end); if _ok then _v = _res end end; local _dest = " .. gR("opA") .. "; if _dest ~= nil then pcall(function() _dest[_k] = _v end) end" .. sPI)
	addDesc("ADD_MOVE", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 2) .. ", " .. gR("opC", 1) .. ", false); " .. sR("opA", "_v", 1) .. "; if opC > 0 then " .. v_ip .. " = " .. v_ip .. " + 4 end" .. sPI)
	addDesc("MOVE_CALL", hCode.moveCall)
	addDesc("LOADNIL_RET", "\t\t\t\t" .. v_isRet .. " = true; " .. v_retCount .. " = 0; " .. v_ip .. " = " .. v_codeLen .. " + 1")
	addDesc("MOVE_RET", "\t\t\t\t" .. v_isRet .. " = true; " .. v_retCount .. " = 1; " .. v_ret1 .. " = " .. gR("opB") .. "; " .. v_ip .. " = " .. v_codeLen .. " + 1")
	addDesc("CONCAT_MOVE", "\t\t\t\tlocal _v = tostring(" .. gR("opB") .. " or '') .. tostring(" .. gR("opC") .. " or ''); " .. sR("opA", "_v") .. sPI)
	addDesc("ROBLOX_GETSERVICE", hCode.robloxGetService)
	addDesc("ROBLOX_GET_LOCAL_CHAR", hCode.robloxGetLocalChar)
	addDesc("TABLE_SET_CHAIN", "\t\t\t\tlocal _t = " .. gR("opA") .. "; local _k = " .. v_getK .. "(opB + 1); local _val = " .. gR("opC") .. "; _t[_k] = _val" .. sPI)
	addDesc("CALL_TABLE_APPEND", hCode.callTableAppend)
	addDesc("CALL_EXPAND", hCode.callExpand)
	addDesc("CALL_RET", hCode.callRet)
	addDesc("CALL_EXPAND_RET", hCode.callExpandRet)
	addDesc("FORIN_PREP", hCode.forinPrep)
	-- Dynamic Multi-Dispatch Opcode Aliases
	addDesc("ADD_ALT", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 1) .. ", " .. gR("opC", 2) .. ", false); " .. sR("opA", "_v", 1) .. sPI)
	addDesc("SUB_ALT", "\t\t\t\tlocal _v = " .. v_evalAddSub .. "(" .. gR("opB", 3) .. ", " .. gR("opC", 1) .. ", true); " .. sR("opA", "_v", 3) .. sPI)
	addDesc("MOVE_ALT", "\t\t\t\t" .. sR("opA", gR("opB")) .. sPI)
	addDesc("GETTABLE_ALT", "\t\t\t\tlocal _t = " .. gR("opB") .. "; local _k = " .. gR("opC") .. "; local _v = nil; if _t ~= nil then _v = _t[_k] end; " .. sR("opA", "_v") .. sPI)
	addDesc("CALL_ALT", hCode.call)
	addDesc("GETGLOBAL_ALT", "\t\t\t\tlocal _kVal = " .. v_getK .. "(opB + 1); local _gv = " .. v_resolveEnv .. "(env, _kVal); " .. sR("opA", "_gv") .. sPI)

	return dynamicDescriptors
end

function VMRuntime.generateRuntimeCode(profile, opcodeWidths, codeStr, kStr, keyMaterial, fragPoolStr, rawLen, permutedAlphabet, kBlobStr, encodedRegions, guardAttestation)
	local vmRng = RandomDomains.get("VM")
	local function rngRand(a, b)
		if vmRng and vmRng.random then
			return vmRng:random(a, b)
		end
		if b then return math.random(a, b) end
		if a then return math.random(a) end
		return math.random()
	end

	local opcodes = profile.opcodes or {}
	local dCoeff = profile.dCoeff or (rngRand(11, 89) * 2 + 1)
	local dOffset = profile.dOffset or rngRand(7, 199)

	local topLayout = profile.operandLayout or 0
	local topDispatchMode = profile.dispatchMode or 11
	local isExplicitProduction = (profile and (profile.production == true or profile.release == true or profile.profile == "PRODUCTION" or profile.profileLevel == "PRODUCTION"))
	local profileBuild = not isExplicitProduction and ((profile and profile.profileBuild == true) or false)
	local adversaryTrace = not isExplicitProduction and ((profile and profile.adversaryTrace == true) or false)
	local leakageAudit = not isExplicitProduction and ((profile and (profile.leakageAudit == true or profile.LeakageAudit == true)) or false)
	local isProduction = not profileBuild and not adversaryTrace and not leakageAudit and not (profile and profile.testSabotage == true)
	local baseSalt = (keyMaterial and keyMaterial.baseSalt) or rngRand(10000, 999999)
	local failClosedErr = dynBytesRaw("fail-closed", baseSalt)
	local stateCoupling = (profile and profile.stateCoupling) or "amortized_bb"
	local boundedCache = true
	if profile and profile.boundedCache ~= nil then
		boundedCache = (profile.boundedCache == true)
	end
	local cacheCapacity = (profile and profile.cacheCapacity ~= nil) and profile.cacheCapacity or 64
	if not boundedCache then
		cacheCapacity = 0
	end
	local bcLayout = profile.bcLayout or ((baseSalt % 3) + 1)
	profile.bcLayout = bcLayout
	local idxCode, idxMeta, idxUv
	if bcLayout == 1 then
		idxMeta, idxUv, idxCode = 1, 2, 3
	elseif bcLayout == 2 then
		idxUv, idxCode, idxMeta = 1, 2, 3
	else
		idxMeta, idxCode, idxUv = 1, 2, 3
	end
	local topProtoSalt = profile.protoSalt or 1337
	local topKeyMode = profile.keyMode or 1
	local stateMul = profile.stateMul or 31
	local stateAdd = profile.stateAdd or 101
	local topRegMul = math.max(23, profile.regMul or 23)
	if topRegMul % 2 == 0 then topRegMul = topRegMul + 1 end
	local topRegOffset = profile.regOffset or 0
	local buildEntropy = (keyMaterial and keyMaterial.buildEntropy) or rngRand(1, 255)
	local rawByteLen = rawLen or math.floor(#codeStr / 4)
	local STATE_PRIMES = { 16777213, 16777199, 16777141, 16777093, 16777087, 16777067, 16777039, 16776989 }
	local stateMod = (keyMaterial and keyMaterial.stateMod) or STATE_PRIMES[((baseSalt + (profile and profile.seed or 0)) % #STATE_PRIMES) + 1]
	local permutedAlphabetFinal = permutedAlphabet or (keyMaterial and keyMaterial.alphabet) or StreamEncoder.getPermutedAlphabet((profile and profile.seed) or baseSalt, stateMod)
	profile.resolverDomain = profile.resolverDomain or (((baseSalt + (profile and profile.seed or 0)) * 31 + 1337) % 65536)

	local prngMul = (baseSalt * 17 + 31337) % 65536
	if prngMul % 2 == 0 then prngMul = prngMul + 1 end
	local prngAdd = (baseSalt * 31 + 1013) % 65536
	local k1 = ((baseSalt * 7 + 13) % 256) + 1
	local k2 = ((baseSalt * 11 + 31) % 256) + 1
	local expectedSig = 0
	local providers = (guardAttestation and guardAttestation.providers) or {}
	if #providers > 0 then
		for idx, prov in ipairs(providers) do
			local _, tok = prov.generator(baseSalt, stateMod)
			local mul = 31 + ((idx * 7) % 32)
			expectedSig = (expectedSig * mul + (tok or 0)) % stateMod
		end
	else
		local kSig1 = (baseSalt % 7919) + 101
		local kSig2 = (baseSalt % 6571) + 103
		local kSig3 = (baseSalt % 5417) + 107
		expectedSig = (expectedSig * 31 + kSig1) % stateMod
		expectedSig = (expectedSig * 37 + kSig2) % stateMod
		expectedSig = (expectedSig * 43 + kSig3) % stateMod
	end

	local V = {
		topEncSalt = randomVarName(6),
		topEncPack = randomVarName(6),
		topEncReg = randomVarName(6),
		topEncByteLen = randomVarName(6),
		encGlobals = randomVarName(6),
		customGlobals = randomVarName(6),
		rawAdd = randomVarName(6),
		rawSub = randomVarName(6),
		rawMul = randomVarName(6),
		rawDiv = randomVarName(6),
		rawMod = randomVarName(6),
		rawPow = randomVarName(6),
		rawUnm = randomVarName(6),
		rawLt = randomVarName(6),
		rawLe = randomVarName(6),
		emptyVa = randomVarName(6),
		recvRet = randomVarName(6),
		recvPcall = randomVarName(6),
		readBank = randomVarName(6),
		writeBank = randomVarName(6),
		capture = randomVarName(6),
		capturePcall = randomVarName(6),
		resolveCont = randomVarName(6),
		decodeCont = randomVarName(6),
		decOps = randomVarName(6),
		b2 = randomVarName(5),
		b3 = randomVarName(5),
		b4 = randomVarName(5),
		b5 = randomVarName(5),
		b6 = randomVarName(5),
		b7 = randomVarName(5),
		r2 = randomVarName(5),
		r3 = randomVarName(5),
		r4 = randomVarName(5),
		r5 = randomVarName(5),
		r6 = randomVarName(5),
		r7 = randomVarName(5),
		b0 = randomVarName(5),
		b1 = randomVarName(5),
		r0 = randomVarName(5),
		r1 = randomVarName(5),
		word0 = randomVarName(6),
		rawOp = randomVarName(6),
		wTag = randomVarName(5),
		dipMod = randomVarName(6),
		gEnv = randomVarName(6),
		outerVM = randomVarName(6),
		rawOuterVM = randomVarName(6),
		ip = randomVarName(5),
		Bank = randomVarName(5),
		sChar = randomVarName(5),
		sByte = randomVarName(5),
		sSub = randomVarName(5),
		tConcat = randomVarName(5),
		deriveKey = randomVarName(6),
		vmState = randomVarName(6),
		predBlockHash = randomVarName(6),
		envCache = randomVarName(6),
		nilSentinel = randomVarName(6),
		uvTag = randomVarName(6),
		isUvCell = randomVarName(6),
		packUnpack = randomVarName(6),
		evalAddSub = randomVarName(6),
		evalMulDivMod = randomVarName(6),
		evalPowUnm = randomVarName(6),
		evalCompare = randomVarName(6),
		synthStr = randomVarName(6),
		hostBridge = randomVarName(6),
		kProf = randomVarName(6),
		resolveEnv = randomVarName(6),
		pHash = randomVarName(6),
		getStdName = randomVarName(6),
		ringBuf = randomVarName(6),
		ringIdx = randomVarName(6),
		createClosure = randomVarName(6),
		rawKBlob = randomVarName(6),
		topK = randomVarName(6),
		topBc = randomVarName(6),
		topEnv = randomVarName(6),
		rawget = randomVarName(6),
		rawset = randomVarName(6),
		unwrap = randomVarName(6),
		attestSig = randomVarName(6),
		attestDelta = randomVarName(6),
		b85Map = randomVarName(6),
		b85Decode = randomVarName(6),
		topKey = randomVarName(6),
		topKLen = randomVarName(6),
		getK = randomVarName(6),
		codeLen = randomVarName(6),
		kByte = randomVarName(6),
		hTable = randomVarName(6),
		isRet = randomVarName(5),
		retCount = randomVarName(5),
		ret1 = randomVarName(5),
		ret2 = randomVarName(5),
		ret3 = randomVarName(5),
		retTbl = randomVarName(5),
		retCountN = randomVarName(5),
		dip = randomVarName(5),
		tok = randomVarName(5),
		va = randomVarName(5),
		inArgCount = randomVarName(6),
		bkt = randomVarName(5),
		isType = randomVarName(6),
		regMod = randomVarName(6),
		regModLarge = randomVarName(6),
		regMap = randomVarName(6),
		opDecode = randomVarName(6),
		currRegion = randomVarName(6),
		stateComm = randomVarName(6),
		resolveNext = randomVarName(6),
		synthConst = randomVarName(6),
		microExec = randomVarName(6),
		w = randomVarName(5),
		rawA = randomVarName(5),
		rawB = randomVarName(5),
		rawC = randomVarName(5),
		getKByte = randomVarName(6),
		decodeRegion = randomVarName(6),
		activeCode = randomVarName(6),
		loadedRegion = randomVarName(6),
		loadRegion = randomVarName(6),
		rawRegions = randomVarName(6),
		regionPc = randomVarName(6),
		currentRegionId = randomVarName(6),
		currentRegion = randomVarName(6),
		getRegionCache = randomVarName(6),
		purgeRegionCache = randomVarName(6),
		cacheStore = randomVarName(6),
		apiIndir = randomVarName(6),
		bktMatrix = randomVarName(6),
		initProtoDesc = randomVarName(6),
		decoy = randomVarName(6),
		decoyTrap = randomVarName(6),
		proxy = randomVarName(6),
		wrap = randomVarName(6),
		curry = randomVarName(6),
		dispatchTbl = randomVarName(6),
		idxProxy = randomVarName(6)
	}

	local metaSlots = getMetaSlots(baseSalt)

	local function gR(r, style)
		return V.unwrap .. "(" .. V.Bank .. "[" .. V.regMap .. "(" .. r .. ")])"
	end

	local function sR(r, v, style)
		local hookE = (leakageAudit and (" if _G and _G.__LEAKAGE_OBSERVE then _G.__LEAKAGE_OBSERVE(\"E\", { result = _val, reg = " .. r .. ", dip = " .. V.dip .. " }) end; ")) or ""
		local regIdx = V.regMap .. "(" .. r .. ")"
		return "do local _val = (" .. v .. ");" .. hookE .. " local _p = " .. regIdx .. "; local _c = " .. V.Bank .. "[_p]; if type(_c) == \"table\" and " .. V.rawget .. "(_c, " .. V.uvTag .. ") then " .. V.rawset .. "(_c, 1, _val) else " .. V.Bank .. "[_p] = _val end end"
	end

	local v_sessSalt = rngRand(10000, 99999)

	local function getTok(opVal)
		return (tonumber(opVal) * dCoeff + dOffset) % 256
	end

	local function opaqueSeedExpr(val, modVal)
		modVal = modVal or (131072 + ((baseSalt or 0) % 17) * 2048)
		local mult = (rngRand(5, 35) * 2 + 1)
		local target = (tonumber(val) or 0) % modVal
		local current = (expectedSig * mult) % modVal
		local offset = ((target - current) % modVal + modVal) % modVal
		return "((" .. tostring(offset) .. " + (" .. V.attestSig .. " * " .. tostring(mult) .. ")) % " .. tostring(modVal) .. ")"
	end

	local function dynBytes(str)
		local k = (baseSalt % 199) + 13
		local charParts = {}
		for j = 1, #str do
			local off = ((baseSalt * (j * 7 + 3) + j * 13 + k) % 256)
			local enc = (string.byte(str, j) + off) % 256
			table.insert(charParts, "((" .. tostring(enc) .. " - " .. tostring(off) .. " + 256) % 256)")
		end
		return V.sChar .. "(" .. table.concat(charParts, ",") .. ")"
	end

	local function scBytes(str)
		local k = (baseSalt % 199) + 13
		local charParts = {}
		for j = 1, #str do
			local off = ((baseSalt * (j * 7 + 3) + j * 13 + k) % 256)
			local enc = (string.byte(str, j) + off) % 256
			table.insert(charParts, "((" .. tostring(enc) .. " - " .. tostring(off) .. " + 256) % 256)")
		end
		return "_sc(" .. table.concat(charParts, ",") .. ")"
	end

	local parts = {}
	local function emit(str)
		table.insert(parts, str)
	end

	local apiSlots = {}
	local usedApiSlots = {}
	local function getUniqueApiSlot(name, seedMult, seedAdd)
		local slot = ((baseSalt * seedMult + seedAdd) % 220) + 11
		while usedApiSlots[slot] do
			slot = (slot % 230) + 1
		end
		usedApiSlots[slot] = true
		apiSlots[name] = slot
		return slot
	end

	getUniqueApiSlot("type", 13, 37)
	getUniqueApiSlot("pcall", 17, 53)
	getUniqueApiSlot("rawget", 19, 71)
	getUniqueApiSlot("rawset", 23, 97)
	getUniqueApiSlot("sChar", 29, 113)
	getUniqueApiSlot("sByte", 31, 137)
	getUniqueApiSlot("sSub", 37, 151)
	getUniqueApiSlot("tConcat", 41, 173)
	getUniqueApiSlot("unpack", 43, 191)
	getUniqueApiSlot("typeof", 47, 211)
	getUniqueApiSlot("getmeta", 53, 223)
	getUniqueApiSlot("setmeta", 59, 239)
	getUniqueApiSlot("insert", 61, 251)
	getUniqueApiSlot("bufReadu8", 67, 269)
	getUniqueApiSlot("bufCreate", 71, 281)
	getUniqueApiSlot("bufWriteu8", 73, 293)
	getUniqueApiSlot("bufReadstr", 79, 307)
	getUniqueApiSlot("bufReadf64", 83, 317)
	getUniqueApiSlot("bitBand", 97, 347)
	getUniqueApiSlot("bitBxor", 101, 359)
	getUniqueApiSlot("bitBnot", 103, 373)
	getUniqueApiSlot("assertFn", 127, 431)
	getUniqueApiSlot("xpcallFn", 131, 443)

	local apiRawEntries = {
		"[" .. tostring(apiSlots.type) .. "] = type or (_G and _G.type) or function(v) return typeof and typeof(v) or \"table\" end,",
		"[" .. tostring(apiSlots.pcall) .. "] = pcall or (_G and _G.pcall) or function(f, ...) return true, f(...) end,",
		"[" .. tostring(apiSlots.rawget) .. "] = rawget or (_G and _G.rawget),",
		"[" .. tostring(apiSlots.rawset) .. "] = rawset or (_G and _G.rawset),",
		"[" .. tostring(apiSlots.sChar) .. "] = (string and string.char) or (_G and _G.string and _G.string.char) or string.char,",
		"[" .. tostring(apiSlots.sByte) .. "] = (string and string.byte) or (_G and _G.string and _G.string.byte) or string.byte,",
		"[" .. tostring(apiSlots.sSub) .. "] = (string and string.sub) or (_G and _G.string and _G.string.sub) or string.sub,",
		"[" .. tostring(apiSlots.tConcat) .. "] = (table and table.concat) or (_G and _G.table and _G.table.concat) or table.concat,",
		"[" .. tostring(apiSlots.unpack) .. "] = unpack or (table and table.unpack) or (_G and (_G.unpack or (_G.table and _G.table.unpack))),",
		"[" .. tostring(apiSlots.typeof) .. "] = typeof or type,",
		"[" .. tostring(apiSlots.getmeta) .. "] = getmetatable,",
		"[" .. tostring(apiSlots.setmeta) .. "] = setmetatable,",
		"[" .. tostring(apiSlots.insert) .. "] = (table and table.insert) or function(t, v) t[#t+1] = v end,",
		"[" .. tostring(apiSlots.bufReadu8) .. "] = (buffer and buffer.readu8) or function(b, o) return string.byte(b, o + 1) end,",
		"[" .. tostring(apiSlots.bufCreate) .. "] = (buffer and buffer.create) or function(sz) return {} end,",
		"[" .. tostring(apiSlots.bufWriteu8) .. "] = (buffer and buffer.writeu8) or function(b, o, v) b[o + 1] = v end,",
		"[" .. tostring(apiSlots.bufReadstr) .. "] = (buffer and buffer.readstring) or function(b, o, len) return string.sub(b, o + 1, o + len) end,",
		"[" .. tostring(apiSlots.bufReadf64) .. "] = (buffer and buffer.readf64),",
		"[" .. tostring(apiSlots.bitBand) .. "] = (bit32 and bit32.band) or function(a, b) return a end,",
		"[" .. tostring(apiSlots.bitBxor) .. "] = (bit32 and bit32.bxor) or function(a, b) return a end,",
		"[" .. tostring(apiSlots.bitBnot) .. "] = (bit32 and bit32.bnot),",
		"[" .. tostring(apiSlots.assertFn) .. "] = assert,",
		"[" .. tostring(apiSlots.xpcallFn) .. "] = xpcall,",
	}
	local sRng = (baseSalt * 1337 + 5381) % 2147483647
	for i = #apiRawEntries, 2, -1 do
		sRng = (sRng * 1664525 + 1013904223) % 4294967296
		local j = (math.floor(sRng / 65536) % i) + 1
		apiRawEntries[i], apiRawEntries[j] = apiRawEntries[j], apiRawEntries[i]
	end

	emit("\nreturn (function(...)\n")
	emit("\tlocal " .. V.apiIndir .. " = {\n\t\t" .. table.concat(apiRawEntries, "\n\t\t") .. "\n\t}\n")
	emit("\tlocal _p_type = " .. V.apiIndir .. "[" .. tostring(apiSlots.type) .. "]\n")
	emit("\tlocal _p_pcall = " .. V.apiIndir .. "[" .. tostring(apiSlots.pcall) .. "]\n")
	emit("\tlocal _p_rawget = " .. V.apiIndir .. "[" .. tostring(apiSlots.rawget) .. "]\n")
	emit("\tlocal _p_rawset = " .. V.apiIndir .. "[" .. tostring(apiSlots.rawset) .. "]\n")
	emit("\tlocal " .. V.sChar .. " = " .. V.apiIndir .. "[" .. tostring(apiSlots.sChar) .. "]\n")
	emit("\tlocal " .. V.sByte .. " = " .. V.apiIndir .. "[" .. tostring(apiSlots.sByte) .. "]\n")
	emit("\tlocal " .. V.sSub .. " = " .. V.apiIndir .. "[" .. tostring(apiSlots.sSub) .. "]\n")
	emit("\tlocal " .. V.tConcat .. " = " .. V.apiIndir .. "[" .. tostring(apiSlots.tConcat) .. "]\n")
	emit("\tlocal _vmActive = 0\n\tlocal _kConsecutiveReads = 0\n")

	emit("\n\tlocal function " .. V.isType .. "(v, c)\n")
	emit("\t\tif v == nil then return false end\n")
	emit("\t\tlocal t = _p_type(v)\n")
	emit("\t\tlocal b = " .. V.sByte .. "(t, 1)\n")
	emit("\t\tif c == 1 then return b == 102\n")
	emit("\t\telseif c == 2 then return b == 116 and " .. V.sByte .. "(t, 2) == 97\n")
	emit("\t\telseif c == 3 then return b == 115\n")
	emit("\t\telseif c == 4 then return b == 110\n")
	emit("\t\telseif c == 5 then return b == 117\n")
	emit("\t\telseif c == 6 then return b == 98\n")
	emit("\t\telseif c == 7 then return typeof and " .. V.sByte .. "(typeof(v), 1) == 73\n")
	emit("\t\telseif c == 8 then return (b == 116 and " .. V.sByte .. "(t, 2) == 97) or b == 117 or b == 118 or (typeof and " .. V.sByte .. "(typeof(v), 1) == 73)\n")
	emit("\t\tend\n")
	emit("\t\treturn false\n")
	emit("\tend\n")

	emit("\n\tlocal function _fastProbeEnv(fn, arg)\n")
	emit("\t\tlocal ok, res = _p_pcall(fn, arg)\n")
	emit("\t\tif ok and " .. V.isType .. "(res, 2) then return res end\n")
	emit("\t\treturn nil\n")
	emit("\tend\n")

	emit("\n\tlocal " .. V.gEnv .. " = (getgenv and " .. V.isType .. "(getgenv, 1) and _fastProbeEnv(getgenv))\n")
	emit("\t\tor (getrenv and " .. V.isType .. "(getrenv, 1) and _fastProbeEnv(getrenv))\n")
	emit("\t\tor (getfenv and " .. V.isType .. "(getfenv, 1) and _fastProbeEnv(getfenv, 0))\n")
	emit("\t\tor (getfenv and " .. V.isType .. "(getfenv, 1) and _fastProbeEnv(getfenv))\n")
	emit("\t\tor (" .. V.isType .. "(_G, 2) and _G)\n")
	emit("\t\tor (" .. V.isType .. "(shared, 2) and shared)\n")
	emit("\t\tor _ENV or {}\n")

	emit("\n\tlocal " .. V.envCache .. " = {}\n")
	emit("\tlocal " .. V.nilSentinel .. " = {}\n")
	emit("\tlocal " .. V.rawget .. " = _p_rawget or function(t, k)\n")
	emit("\t\tif " .. V.isType .. "(t, 2) then\n")
	emit("\t\t\tlocal ok, v = _p_pcall(function(tab, key) return tab[key] end, t, k)\n")
	emit("\t\t\tif ok then return v end\n")
	emit("\t\tend\n")
	emit("\t\treturn\n")
	emit("\tend\n")
	emit("\tlocal " .. V.rawset .. " = _p_rawset or function(t, k, v) t[k] = v end\n")
	emit("\tlocal " .. V.uvTag .. " = {}\n")
	emit("\tlocal function " .. V.isUvCell .. "(cell)\n")
	emit("\t\treturn _p_type(cell) == \"table\" and " .. V.rawget .. "(cell, " .. V.uvTag .. ")\n")
	emit("\tend\n")
	emit("\tlocal function " .. V.unwrap .. "(cell)\n")
	emit("\t\tif _p_type(cell) == \"table\" and " .. V.rawget .. "(cell, " .. V.uvTag .. ") then return cell[1] end\n")
	emit("\t\treturn cell\n")
	emit("\tend\n")

	emit("\n\tlocal function " .. V.packUnpack .. "(tbl, i, j)\n")
	emit("\t\tif not tbl then return end\n")
	emit("\t\ti = i or 1\n")
	emit("\t\tj = j or (tbl and (tbl.n or #tbl)) or 0\n")
	emit("\t\tif i > j then return end\n")
	emit("\t\tlocal _unp = unpack or (table and table.unpack) or (_G and (_G.unpack or (_G.table and _G.table.unpack)))\n")
	emit("\t\tif _unp then return _unp(tbl, i, j) end\n")
	emit("\t\tif i == j then return tbl[i] end\n")
	emit("\t\tif j - i == 1 then return tbl[i], tbl[i+1] end\n")
	emit("\t\tif j - i == 2 then return tbl[i], tbl[i+1], tbl[i+2] end\n")
	emit("\t\tif j - i == 3 then return tbl[i], tbl[i+1], tbl[i+2], tbl[i+3] end\n")
	emit("\tend\n")
	emit([=[
	local function ]=] .. V.rawAdd .. [=[(x, y) return x + y end
	local function ]=] .. V.rawSub .. [=[(x, y) return x - y end
	local function ]=] .. V.rawMul .. [=[(x, y) return x * y end
	local function ]=] .. V.rawDiv .. [=[(x, y) return x / y end
	local function ]=] .. V.rawMod .. [=[(x, y) return x % y end
	local function ]=] .. V.rawPow .. [=[(x, y) return x ^ y end
	local function ]=] .. V.rawUnm .. [=[(x) return -x end
	local function ]=] .. V.rawLt .. [=[(x, y) return x < y end
	local function ]=] .. V.rawLe .. [=[(x, y) return x <= y end
	local ]=] .. V.emptyVa .. [=[ = { n = 0 }
]=])

	local providers = (guardAttestation and guardAttestation.providers) or {}
	if #providers > 0 then
		local buckets = {}
		local slotCalls = {}
		for idx, prov in ipairs(providers) do
			local codeBody, _ = prov.generator(baseSalt, stateMod)
			local bKey = ((baseSalt + idx * 17) % 53) + 3
			local sKey = ((baseSalt + idx * 7919) % 10007) + (idx * 101)
			buckets[bKey] = buckets[bKey] or {}
			buckets[bKey][sKey] = codeBody
			table.insert(slotCalls, { bKey = bKey, sKey = sKey, idx = idx })
		end
		local decoyBKey = (baseSalt % 47) + 60
		local decoySKey = (baseSalt % 61) + 80
		buckets[decoyBKey] = buckets[decoyBKey] or {}
		buckets[decoyBKey][decoySKey] = "return " .. tostring((expectedSig * 13 + 37) % stateMod)

		emit("\tlocal " .. V.bktMatrix .. " = {\n")
		local emittedBuckets = {}
		for _, sc in ipairs(slotCalls) do
			if not emittedBuckets[sc.bKey] and buckets[sc.bKey] then
				emittedBuckets[sc.bKey] = true
				emit("\t\t[" .. tostring(sc.bKey) .. "] = {\n")
				for sKey, code in pairs(buckets[sc.bKey]) do
					emit("\t\t\t[" .. tostring(sKey) .. "] = function()\n")
					emit("\t\t\t\t" .. code .. "\n")
					emit("\t\t\tend,\n")
				end
				emit("\t\t},\n")
			end
		end
		for bKey, slots in pairs(buckets) do
			if not emittedBuckets[bKey] then
				emit("\t\t[" .. tostring(bKey) .. "] = {\n")
				for sKey, code in pairs(slots) do
					emit("\t\t\t[" .. tostring(sKey) .. "] = function()\n")
					emit("\t\t\t\t" .. code .. "\n")
					emit("\t\t\tend,\n")
				end
				emit("\t\t},\n")
			end
		end
		emit("\t}\n")

		emit("\tlocal " .. V.attestSig .. " = 0;\n")
		for _, sc in ipairs(slotCalls) do
			local mul = 31 + ((sc.idx * 7) % 32)
			emit("\t" .. V.attestSig .. " = (" .. V.attestSig .. " * " .. tostring(mul) .. " + (" .. V.bktMatrix .. "[" .. tostring(sc.bKey) .. "][" .. tostring(sc.sKey) .. "]() or 0)) % " .. tostring(stateMod) .. ";\n")
		end
	else
		local bktKey0 = (baseSalt % 71) + 3
		local bktKey1 = bktKey0 + (baseSalt % 37) + 1
		local slotKey0 = (baseSalt % 113) + 7
		local slotKey1 = (baseSalt % 131) + 11
		emit("\tlocal " .. V.bktMatrix .. " = {\n")
		emit("\t\t[" .. tostring(bktKey0) .. "] = {\n")
		emit("\t\t\t[" .. tostring(slotKey0) .. "] = function()\n")
		emit("\t\t\t\treturn " .. tostring(expectedSig) .. "\n")
		emit("\t\t\tend,\n")
		emit("\t\t},\n")
		emit("\t\t[" .. tostring(bktKey1) .. "] = {\n")
		emit("\t\t\t[" .. tostring(slotKey1) .. "] = function()\n")
		emit("\t\t\t\treturn " .. tostring((expectedSig * 13 + 37) % stateMod) .. "\n")
		emit("\t\t\tend,\n")
		emit("\t\t},\n")
		emit("\t}\n")
		emit("\tlocal " .. V.attestSig .. " = " .. V.bktMatrix .. "[" .. tostring(bktKey0) .. "][" .. tostring(slotKey0) .. "]();\n")
	end
	local expectedBaseSeed = ((baseSalt * k1 + 37 * k2) % stateMod)
	emit([=[
	local ]=] .. V.regMod .. [=[ = ]=] .. opaqueSeedExpr(65536, 131072) .. [=[;
	local ]=] .. V.regModLarge .. [=[ = ]=] .. V.regMod .. [=[ * 1000;

	local ]=] .. V.b85Map .. [=[ = (function()
		local _c = {}
		for _i = 33, 125 do
			if _i ~= 34 and _i ~= 39 and _i ~= 44 and _i ~= 46 and _i ~= 47 and _i ~= 58 and _i ~= 92 and _i ~= 96 then
				_c[#_c + 1] = _i
			end
		end
		local _s = ]=] .. opaqueSeedExpr(expectedBaseSeed, stateMod) .. [=[;
		for _i = #_c, 2, -1 do
			_s = (_s * ]=] .. tostring(prngMul) .. [=[ + ]=] .. tostring(prngAdd) .. [=[) % ]=] .. tostring(stateMod) .. [=[
			local _j = (_s % _i) + 1
			_c[_i], _c[_j] = _c[_j], _c[_i]
		end
		local _map = {}
		for _i = 1, #_c do
			_map[_c[_i]] = _i - 1
		end
		_map[0] = #_c
		return _map
	end)();

	local function ]=] .. V.b85Decode .. [=[(str)
		if not ]=] .. V.isType .. [=[(str, 3) then return str end
		local len = #str
		local out = (table and table.create and table.create(len)) or {}
		local outIdx = 1
		local idx = 1
		local _radix = ]=] .. V.b85Map .. [=[[0] or 85
		local _pad = _radix - 1
		while idx <= len do
			local rem = len - idx + 1
			local count = rem >= 5 and 5 or rem
			local acc = 0
			for i = 0, 4 do
				local val = _pad
				if i < count then
					local b = ]=] .. V.sByte .. [=[(str, idx + i)
					val = ]=] .. V.b85Map .. [=[[b] or 0
				end
				acc = acc * _radix + val
			end
			idx = idx + count
			local numBytes = count - 1
			local b4 = acc % 256; acc = math.floor(acc / 256)
			local b3 = acc % 256; acc = math.floor(acc / 256)
			local b2 = acc % 256; acc = math.floor(acc / 256)
			local b1 = acc % 256
			if numBytes >= 1 then out[outIdx] = b1; outIdx = outIdx + 1 end
			if numBytes >= 2 then out[outIdx] = b2; outIdx = outIdx + 1 end
			if numBytes >= 3 then out[outIdx] = b3; outIdx = outIdx + 1 end
			if numBytes >= 4 then out[outIdx] = b4; outIdx = outIdx + 1 end
		end
		return out
	end
]=])

	if type(kBlobStr) == "table" and kBlobStr.words then
		if kBlobStr.totalBytes == 0 or #kBlobStr.words == 0 then
			emit("\tlocal " .. V.rawKBlob .. " = {};\n")
		else
			local K_VAR = {
				synthFn = "_" .. randomVarName(5),
				pWords = randomVarName(5),
				pSeed = randomVarName(5),
				pMod = randomVarName(5),
				pMul = randomVarName(5),
				pAdd = randomVarName(5),
				pCoeff = randomVarName(5),
				pLen = randomVarName(5),
				out = randomVarName(5),
				curIdx = randomVarName(5),
				numWords = randomVarName(5),
				state = randomVarName(5),
				step = randomVarName(5),
				val = randomVarName(5),
				mask = randomVarName(5),
				unpacked = randomVarName(5),
				b1 = randomVarName(5),
				b2 = randomVarName(5),
				b3 = randomVarName(5),
				wIdx = randomVarName(5),
				h2 = randomVarName(5),
				poison = randomVarName(5)
			}

			local mode = kBlobStr.mode or 1
			local innerFormula = ""
			if mode == 1 then
				innerFormula = K_VAR.state .. " = ((" .. K_VAR.state .. " * " .. K_VAR.pMul .. " + " .. K_VAR.pAdd .. ") % " .. K_VAR.pMod .. "); " ..
					K_VAR.mask .. " = ((" .. K_VAR.state .. " * " .. K_VAR.pCoeff .. ") % 16777216);"
			elseif mode == 2 then
				innerFormula = "local " .. K_VAR.wIdx .. " = " .. K_VAR.step .. " - 1; " ..
					K_VAR.state .. " = ((" .. K_VAR.state .. " * 37 + " .. K_VAR.wIdx .. " * 19 + " .. K_VAR.pAdd .. ") % " .. K_VAR.pMod .. "); " ..
					K_VAR.mask .. " = ((((" .. K_VAR.wIdx .. " * " .. K_VAR.pMul .. " + " .. K_VAR.pAdd .. ") * " .. K_VAR.wIdx .. " + " .. K_VAR.state .. ") * " .. K_VAR.pCoeff .. ") % 16777216);"
			elseif mode == 3 then
				local saltByteExpr = opaqueSeedExpr(baseSalt % 256, 512 + (rngRand(1, 15) * 64))
				innerFormula = K_VAR.state .. " = ((" .. K_VAR.state .. " * " .. K_VAR.pMul .. " + 31) % 4096); " ..
					"local " .. K_VAR.h2 .. " = ((" .. K_VAR.state .. " * " .. K_VAR.pCoeff .. " + " .. K_VAR.pAdd .. ") % 4096) * 4096; " ..
					K_VAR.mask .. " = ((" .. K_VAR.state .. " + " .. K_VAR.h2 .. " + " .. saltByteExpr .. ") % 16777216);"
			else
				innerFormula = "local " .. K_VAR.wIdx .. " = " .. K_VAR.step .. " - 1; " ..
					K_VAR.state .. " = ((" .. K_VAR.state .. " * 7 + " .. K_VAR.wIdx .. " * 13 + " .. K_VAR.pAdd .. ") % " .. K_VAR.pMod .. "); " ..
					K_VAR.mask .. " = ((" .. K_VAR.state .. " * " .. K_VAR.pMul .. " + " .. K_VAR.wIdx .. " * " .. K_VAR.pCoeff .. ") % 16777216);"
			end

			emit("\tlocal function " .. K_VAR.synthFn .. "(" .. K_VAR.pWords .. ", " .. K_VAR.pSeed .. ", " .. K_VAR.pMod .. ", " .. K_VAR.pMul .. ", " .. K_VAR.pAdd .. ", " .. K_VAR.pCoeff .. ", " .. K_VAR.pLen .. ")\n")
			emit("\t\tif not " .. K_VAR.pWords .. " or type(" .. K_VAR.pWords .. ") ~= \"table\" then return {} end\n")
			emit("\t\tlocal " .. K_VAR.out .. " = (table and table.create and table.create(" .. K_VAR.pLen .. ")) or {}\n")
			emit("\t\tlocal " .. K_VAR.curIdx .. " = 1\n")
			emit("\t\tlocal " .. K_VAR.numWords .. " = #" .. K_VAR.pWords .. ";\n")
			emit("\t\tlocal " .. K_VAR.poison .. " = (" .. V.attestDelta .. " ~= 0) and 31337 or 0;\n")
			emit("\t\tlocal " .. K_VAR.state .. " = (" .. K_VAR.pSeed .. " + " .. V.attestDelta .. ") % " .. K_VAR.pMod .. ";\n")
			emit("\t\tfor " .. K_VAR.step .. " = 1, " .. K_VAR.numWords .. " do\n")
			emit("\t\t\tlocal " .. K_VAR.val .. " = " .. K_VAR.pWords .. "[" .. K_VAR.step .. "]\n")
			emit("\t\t\tlocal " .. K_VAR.mask .. " = 0\n")
			emit("\t\t\t" .. innerFormula .. "\n")
			emit("\t\t\tif " .. K_VAR.poison .. " ~= 0 then " .. K_VAR.state .. " = (" .. K_VAR.state .. " + " .. K_VAR.poison .. ") % 16777216 end\n")
			emit("\t\t\tlocal " .. K_VAR.unpacked .. " = (((" .. K_VAR.val .. " - " .. K_VAR.mask .. ") % 16777216) + 16777216) % 16777216\n")
			emit("\t\t\tlocal " .. K_VAR.b1 .. " = " .. K_VAR.unpacked .. " % 256\n")
			emit("\t\t\t" .. K_VAR.unpacked .. " = math.floor(" .. K_VAR.unpacked .. " / 256)\n")
			emit("\t\t\tlocal " .. K_VAR.b2 .. " = " .. K_VAR.unpacked .. " % 256\n")
			emit("\t\t\t" .. K_VAR.unpacked .. " = math.floor(" .. K_VAR.unpacked .. " / 256)\n")
			emit("\t\t\tlocal " .. K_VAR.b3 .. " = " .. K_VAR.unpacked .. " % 256\n")
			emit("\t\tif " .. K_VAR.curIdx .. " <= " .. K_VAR.pLen .. " then " .. K_VAR.out .. "[" .. K_VAR.curIdx .. "] = " .. K_VAR.b1 .. " end\n")
			emit("\t\tif " .. K_VAR.curIdx .. " + 1 <= " .. K_VAR.pLen .. " then " .. K_VAR.out .. "[" .. K_VAR.curIdx .. " + 1] = " .. K_VAR.b2 .. " end\n")
			emit("\t\tif " .. K_VAR.curIdx .. " + 2 <= " .. K_VAR.pLen .. " then " .. K_VAR.out .. "[" .. K_VAR.curIdx .. " + 2] = " .. K_VAR.b3 .. " end\n")
			emit("\t\t\t" .. K_VAR.curIdx .. " = " .. K_VAR.curIdx .. " + 3\n")
			emit("\t\tend\n")
			emit("\t\t" .. K_VAR.pWords .. " = nil;\n")
			emit("\t\treturn " .. K_VAR.out .. "\n")
			emit("\tend\n")

			local seedMod = 131072 + (rngRand(1, 15) * 2048)
			local primeMod = 33554432 + (rngRand(1, 15) * 65536)
			local mulMod = 2048 + (rngRand(1, 15) * 128)
			local addMod = 131072 + (rngRand(1, 15) * 2048)
			local coeffMod = 1024 + (rngRand(1, 15) * 64)
			local lenMod = math.max(16777216, (kBlobStr.totalBytes or 0) + 1) + (rngRand(1, 15) * 65536)

			local exprSeed = opaqueSeedExpr(kBlobStr.seed, seedMod)
			local exprPrime = opaqueSeedExpr(kBlobStr.prime, primeMod)
			local exprMul = opaqueSeedExpr(kBlobStr.mul, mulMod)
			local exprAdd = opaqueSeedExpr(kBlobStr.add, addMod)
			local exprCoeff = opaqueSeedExpr(kBlobStr.coeff, coeffMod)
			local exprLen = opaqueSeedExpr(kBlobStr.totalBytes, lenMod)

			emit("\tlocal " .. V.rawKBlob .. " = " .. v_synthFn .. "({" .. table.concat(kBlobStr.words, ",") .. "}, " .. exprSeed .. ", " .. exprPrime .. ", " .. exprMul .. ", " .. exprAdd .. ", " .. exprCoeff .. ", " .. exprLen .. ");\n")
			emit("\t" .. v_synthFn .. " = nil;\n")
		end
	else
		emit("\tlocal " .. V.rawKBlob .. " = " .. V.b85Decode .. "(\"" .. (kBlobStr or "") .. "\");\n")
	end

	local deriveKeyBody
	if topKeyMode == 2 then
		deriveKeyBody = [=[
		local l0 = (salt + protoSalt * 19) % 256
		local r0 = (entropy + streamSalt * 31) % 256
		local f1 = (r0 * 37 + salt * 13) % 256
		local l1 = (l0 + f1) % 256
		local r1 = r0
		local f2 = (l1 * 73 + entropy * 17) % 256
		local r2 = (r1 + f2) % 256
		local l2 = l1
		local m = l2
		local n = r2
		local o = (l2 * 53 + r2 * 89 + protoSalt * 7) % 256
		local p = (r2 * 97 + l2 * 11 + streamSalt * 23) % 256
		return { m, n, o, p }
]=]
	elseif topKeyMode == 3 then
		deriveKeyBody = [=[
		local t = (protoSalt * 13 + streamSalt) % 256
		local a = (((salt % 256) * t + entropy) * t + protoSalt * 17) % 256
		local b = (((entropy * t + (salt % 256)) * t + streamSalt * 29) % 256 + 13) % 256
		local c = (((a * t + b) * t + salt * 7) % 256 + 37) % 256
		local d = (((b * t + c) * t + entropy * 19) % 256 + 71) % 256
		return { a, b, c, d }
]=]
	else
		deriveKeyBody = [=[
		local k0 = (salt * 37 + protoSalt * 13 + streamSalt * 7) % 256
		local k1 = (salt * 73 + protoSalt * 199 + entropy * 17) % 256
		local k2 = (entropy * 53 + protoSalt * 89 + streamSalt * 23) % 256
		local k3 = (salt * 11 + entropy * 97 + streamSalt * 43) % 256
		return { k0, k1, k2, k3 }
]=]
	end

	local stringCipherMode = (baseSalt % 4) + 1
	local synthLoopBody
	if stringCipherMode == 1 then
		synthLoopBody = [=[
		local mul = (((_sEff * 7 + idx * 13) % 128) * 2 + 1)
		local rolling = (_sEff * 31 + pLen * 17) % 256
		for i = 1, pLen do
			local offset = (_sEff * 17 + i * 19 + rolling * 7) % 256
			local dec = (packed[i] * mul + offset) % 256
			chars[i] = dec
			rolling = (rolling * 41 + packed[i] * 13 + dec * 7) % 256
		end
]=]
	elseif stringCipherMode == 2 then
		synthLoopBody = [=[
		local rolling = (_sEff * 43 + pLen * 23 + idx * 7) % 256
		for i = 1, pLen do
			local poly = (((i * 17 + idx * 23 + rolling * 7 + (_sEff % 256)) % 256) * i + (_sEff * 11 + idx * 31)) % 256
			local dec = (packed[i] - poly + 256) % 256
			chars[i] = dec
			rolling = (rolling * 37 + packed[i] * 19 + dec * 11 + 29) % 256
		end
]=]
	elseif stringCipherMode == 3 then
		synthLoopBody = [=[
		local rolling = (_sEff * 47 + pLen * 29 + idx * 11 + 31) % 256
		for i = 1, pLen do
			local shift = (_sEff * 29 + idx * 43 + i * 37 + rolling * 11 + 43) % 256
			local dec = (packed[i] - shift + 256) % 256
			chars[i] = dec
			rolling = (rolling * 47 + packed[i] * 29 + dec * 13 + 31) % 256
		end
]=]
	else
		synthLoopBody = [=[
		local mul = (((_sEff * 11 + idx * 19) % 128) * 2 + 1)
		local rolling = (_sEff * 53 + pLen * 31 + idx * 17 + 19) % 256
		for i = 1, pLen do
			local add = (_sEff * 13 + idx * 29 + i * 31 + rolling * 17 + 59) % 256
			local dec = (packed[i] * mul + add) % 256
			chars[i] = dec
			rolling = (rolling * 53 + packed[i] * 31 + dec * 17 + 41) % 256
		end
]=]
	end

	emit([=[
	local function ]=] .. V.deriveKey .. [=[(protoSalt, streamSalt)
		local salt = ]=] .. tostring(baseSalt % stateMod) .. [=[;
		local entropy = ]=] .. tostring(buildEntropy) .. [=[ % 256;
]=] .. deriveKeyBody .. [=[
	end

	local ]=] .. V.topKey .. [=[ = ]=] .. V.deriveKey .. [=[(]=] .. opaqueSeedExpr(topProtoSalt, 131072) .. [=[, ]=] .. opaqueSeedExpr(rawByteLen, 131072) .. [=[);
	local ]=] .. V.topKLen .. [=[ = #]=] .. V.topKey .. [=[; if ]=] .. V.topKLen .. [=[ == 0 then ]=] .. V.topKey .. [=[ = { 17, 31, 53, 97 } ]=] .. V.topKLen .. [=[ = 4 end

	local function ]=] .. V.synthStr .. [=[(packed, idx, sSalt)
		if ]=] .. V.isType .. [=[(packed, 3) then return packed end
		if not ]=] .. V.isType .. [=[(packed, 2) then return tostring(packed) end
		local pLen = #packed
		if pLen == 0 then return "" end
		idx = idx or 1
		local _pS = sSalt or (]=] .. opaqueSeedExpr(topProtoSalt, 131072) .. [=[)
		local _sEff = (]=] .. tostring(baseSalt) .. [=[ * 31 + _pS * 17 + (idx * 11)) % 65536;
		local _hasBuf = (buffer ~= nil and buffer.create ~= nil and buffer.writeu8 ~= nil and buffer.readstring ~= nil)
		if _hasBuf and pLen >= 16 then
			local _sBuf = buffer.create(pLen)
			local _bWrite = buffer.writeu8
]=] .. synthLoopBody:gsub("chars%[i%]%s*=%s*dec", "_bWrite(_sBuf, i - 1, dec)") .. [=[
			return buffer.readstring(_sBuf, 0, pLen)
		end
		local chars = {}
]=] .. synthLoopBody .. [=[
		return ]=] .. V.sChar .. [=[(]=] .. V.packUnpack .. [=[(chars, 1, pLen))
	end
]=])

	emit(ConstantRuntime.generateRuntimeDecoder(baseSalt, "protoKey") .. "\n")

	local StdApiNames = require("zerolua.std_api_names")
	local apiHashCoeffs = (profile and profile.apiHashCoeffs) or StdApiNames.getCoeffs(baseSalt)
	local apiMult = apiHashCoeffs.mult or 131
	local apiOffset = apiHashCoeffs.offset or 5381
	local apiMod = apiHashCoeffs.mod or 2147483647
	local encK = (baseSalt % 199) + 23

	local hWs = StdApiNames.computeHash("workspace", apiMult, apiMod, apiOffset)
	local hGame = StdApiNames.computeHash("game", apiMult, apiMod, apiOffset)
	local hWsCap = StdApiNames.computeHash("Workspace", apiMult, apiMod, apiOffset)
	local hUnpack = StdApiNames.computeHash("unpack", apiMult, apiMod, apiOffset)
	local hTypeof = StdApiNames.computeHash("typeof", apiMult, apiMod, apiOffset)
	local hIter = StdApiNames.computeHash("__iter", apiMult, apiMod, apiOffset)
	local hCall = StdApiNames.computeHash("__call", apiMult, apiMod, apiOffset)
	local hNext = StdApiNames.computeHash("next", apiMult, apiMod, apiOffset)
	local hGetService = StdApiNames.computeHash("GetService", apiMult, apiMod, apiOffset)
	local hPlayers = StdApiNames.computeHash("Players", apiMult, apiMod, apiOffset)
	local hLocalPlayer = StdApiNames.computeHash("LocalPlayer", apiMult, apiMod, apiOffset)
	local hCharacter = StdApiNames.computeHash("Character", apiMult, apiMod, apiOffset)

	do
		local _stdNames = StdApiNames.list
		local _cHash = StdApiNames.computeHash
		local _attB = (expectedSig % 251) + 17
		local _pairs = {}
		for _, name in ipairs(_stdNames) do
			local hash = _cHash(name, apiMult, apiMod, apiOffset)
			local hMod = (hash % 61) + 3
			local rolling = (_attB * 17 + encK * 31 + hMod * 13 + 53) % 256
			local escParts = {}
			for j = 1, #name do
				local charByte = string.byte(name, j)
				local mask = (rolling * 11 + j * 19 + hMod * 7 + encK * 5) % 256
				local enc = (charByte + mask) % 256
				rolling = (rolling * 37 + enc * 13 + charByte * 7 + 29) % 256
				table.insert(escParts, string.format("\\%03d", enc))
			end
			table.insert(_pairs, "[" .. tostring(hash) .. "]=\"" .. table.concat(escParts) .. "\"")
		end
		emit("\n\tlocal " .. V.encGlobals .. " = { " .. table.concat(_pairs, ",") .. " }\n")
	end

	emit("\tlocal " .. V.ringBuf .. " = {}\n\tlocal " .. V.ringIdx .. " = 0\n\tlocal " .. V.customGlobals .. " = {}\n")

	emit([=[
	local function ]=] .. V.getStdName .. [=[(h)
		if _vmActive <= 0 then
			if type(]=] .. V.encGlobals .. [=[) == "table" then for _k in pairs(]=] .. V.encGlobals .. [=[) do ]=] .. V.encGlobals .. [=[[_k] = nil end end
			error(]=] .. failClosedErr .. [=[, 0)
		end
		_kConsecutiveReads = (_kConsecutiveReads or 0) + 1
		if _kConsecutiveReads > 150 then
			if type(]=] .. V.encGlobals .. [=[) == "table" then for _k in pairs(]=] .. V.encGlobals .. [=[) do ]=] .. V.encGlobals .. [=[[_k] = nil end end
			error(]=] .. failClosedErr .. [=[, 0)
		end
		local raw = ]=] .. V.encGlobals .. [=[[h]
		if raw then
			local _attB = (]=] .. V.attestSig .. [=[ % 251) + 17
			local _k = ]=] .. tostring(encK) .. [=[;
			local _hMod = (h % 61) + 3
			local _rolling = (_attB * 17 + _k * 31 + _hMod * 13 + 53) % 256
			local _chars = {}
			for _j = 1, #raw do
				local _enc = ]=] .. V.sByte .. [=[(raw, _j)
				local _mask = (_rolling * 11 + _j * 19 + _hMod * 7 + _k * 5) % 256
				local _orig = (_enc - _mask + 256) % 256
				_chars[_j] = _orig
				_rolling = (_rolling * 37 + _enc * 13 + _orig * 7 + 29) % 256
			end
			local _s = ]=] .. V.sChar .. [=[(]=] .. V.packUnpack .. [=[(_chars, 1, #_chars))
			]=] .. V.ringIdx .. [=[ = (]=] .. V.ringIdx .. [=[ % 16) + 1
			]=] .. V.ringBuf .. [=[[]=] .. V.ringIdx .. [=[] = _s
			return _s
		end
		return ]=] .. V.customGlobals .. [=[[h]
	end
]=])

	emit([=[
	local function ]=] .. V.pHash .. [=[(s)
		local h = ]=] .. tostring(apiOffset) .. [=[
		for i = 1, #s do
			h = (h * ]=] .. tostring(apiMult) .. [=[ + ]=] .. V.sByte .. [=[(s, i)) % ]=] .. tostring(apiMod) .. [=[
		end
		return h
	end
]=])

	emit([=[
	local function ]=] .. V.resolveEnv .. [=[(env, kVal)
		if kVal == nil then return nil end
		if env and ]=] .. V.isType .. [=[(env, 2) then
			local v = env[kVal]
			if v ~= nil then return v end
		end
		local cached = ]=] .. V.envCache .. [=[[kVal]
		if cached ~= nil then
			if cached == ]=] .. V.nilSentinel .. [=[ then return nil end
			return cached
		end
		local sName = (]=] .. V.isType .. [=[(kVal, 4) and ]=] .. V.getStdName .. [=[(kVal)) or (]=] .. V.isType .. [=[(kVal, 3) and kVal)
		if sName then
			local v = (env and env[sName])
				or (]=] .. V.gEnv .. [=[ and ]=] .. V.gEnv .. [=[[sName])
				or (_G and ]=] .. V.isType .. [=[(_G, 2) and _G[sName])
				or (shared and ]=] .. V.isType .. [=[(shared, 2) and shared[sName])
			if v ~= nil then
				]=] .. V.envCache .. [=[[kVal] = v
				return v
			end
			if kVal == ]=] .. tostring(hWs) .. [=[ or sName == ]=] .. V.getStdName .. [=[(]=] .. tostring(hWs) .. [=[) then
				local _gameName = ]=] .. V.getStdName .. [=[(]=] .. tostring(hGame) .. [=[)
				local _wsCapName = ]=] .. V.getStdName .. [=[(]=] .. tostring(hWsCap) .. [=[)
				local g = (]=] .. V.gEnv .. [=[ and ]=] .. V.gEnv .. [=[[_gameName]) or (_G and _G[_gameName]) or game
				if g then
					local ok, ws = _p_pcall(function() return g[_wsCapName] or (g.GetService and g:GetService(_wsCapName)) end)
					if ok and ws ~= nil then
						]=] .. V.envCache .. [=[[kVal] = ws
						return ws
					end
				end
			end
			if kVal == ]=] .. tostring(hUnpack) .. [=[ or sName == ]=] .. V.getStdName .. [=[(]=] .. tostring(hUnpack) .. [=[) then
				local unp = unpack or (table and table.unpack) or (_G and (_G.unpack or (_G.table and _G.table.unpack)))
				if unp ~= nil then
					]=] .. V.envCache .. [=[[kVal] = unp
					return unp
				end
			end
			if kVal == ]=] .. tostring(hTypeof) .. [=[ or sName == ]=] .. V.getStdName .. [=[(]=] .. tostring(hTypeof) .. [=[) then
				local tf = typeof or type
				if tf ~= nil then
					]=] .. V.envCache .. [=[[kVal] = tf
					return tf
				end
			end
		end
		]=] .. V.envCache .. [=[[kVal] = ]=] .. V.nilSentinel .. [=[
		return nil
	end
]=])

	emit([=[
	local function ]=] .. V.createClosure .. [=[(childBc, K, env, uvs, bank, regA1, regA2, regA3, regOffset, outerFn, rMap)
		local _isUv = ]=] .. V.isUvCell .. [=[
		local _uTag = ]=] .. V.uvTag .. [=[
		local childUvs = {}
		local upvalDesc = (childBc and childBc[]=] .. tostring(idxUv) .. [=[] ) or {}
		for i = 1, #upvalDesc do
			local desc = upvalDesc[i]
			if desc[1] == 1 or desc[1] == true then
				local parentCell = uvs and uvs[desc[2] + 1]
				if not _isUv(parentCell) then
					local _nCell = { [_uTag] = true }
					]=] .. V.rawset .. [=[(_nCell, 1, parentCell)
					parentCell = _nCell
					if uvs then uvs[desc[2] + 1] = parentCell end
				end
				childUvs[i] = parentCell
			else
				local p = (type(rMap) == ]=] .. dynBytes("table") .. [=[ and rMap[desc[2]]) or (type(rMap) == ]=] .. dynBytes("function") .. [=[ and rMap(desc[2])) or (rMap and rMap(desc[2])) or (((desc[2]) * regA1 + regOffset) % ]=] .. V.regMod .. [=[ + 1)
				local cell = bank[p]
				if not _isUv(cell) then
					local _nCell = { [_uTag] = true }
					]=] .. V.rawset .. [=[(_nCell, 1, cell)
					cell = _nCell
					bank[p] = cell
				end
				childUvs[i] = cell
			end
		end
		local _fnTicket = (]=] .. tostring((baseSalt % 997) * 31 + 101) .. [=[ + #childUvs * 17) % 65536
		local _fnClosure = function(...)
			_fnTicket = (_fnTicket * 41 + 1013) % 65536
			if childBc then childBc[6] = _fnTicket end
			return outerFn(childBc, K, env, childUvs, nil, ...)
		end
		if childBc then childBc[6] = _fnTicket end
		return _fnClosure
	end
]=])

	emit("\tlocal " .. V.decodeRegion .. " = " .. RegionDecoder.generateRuntimeDecoder() .. ";\n\n")

	local aluMapObj = (profile and profile.aluMap) or KeySchedule.deriveAluMap(profile and profile.protoKey, (profile and profile.seed) or 1337)
	local capMapObj = (profile and profile.capMap) or KeySchedule.deriveCapMap(profile and profile.protoKey, (profile and profile.seed) or 1337)

	local aluEntries = {}
	for slot = 1, 15 do
		for op, s in pairs(aluMapObj) do
			if type(op) == "string" and s == slot then
				if op == "ADD" or op == "ADD_K" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) if type(b) == 'number' and type(c) == 'number' then return b - (-c) else return b + c end end")
				elseif op == "SUB" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return b - c end")
				elseif op == "MUL" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return b * c end")
				elseif op == "DIV" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return b / c end")
				elseif op == "MOD" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return b % c end")
				elseif op == "POW" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return b ^ c end")
				elseif op == "UNM" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return -b end")
				elseif op == "NOT" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return (b == nil or b == false) end")
				elseif op == "LEN" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return (b ~= nil and #b) or 0 end")
				elseif op == "CONCAT" then
					table.insert(aluEntries, "[" .. slot .. "] = function(b, c) return tostring(b or '') .. tostring(c or '') end")
				end
			end
		end
	end

	local capMapEntries = {
		"[1] = " .. tostring(capMapObj["INVOKE"] or 1),
		"[2] = " .. tostring(capMapObj["CLOSURE"] or 2),
		"[3] = " .. tostring(capMapObj["RESOLVE_ENV"] or 3),
		"[4] = " .. tostring(capMapObj["VARARG"] or 4),
		"[5] = " .. tostring(capMapObj["CONSTANT"] or 5),
		"[6] = " .. tostring(capMapObj["SET_ENV"] or 6),
		"[7] = " .. tostring(capMapObj["NEW_TABLE"] or 7),
	}

	local MicroISA = require("zerolua.compiler.micro_isa")
	local microOpMap = (profile and profile.microOpcodeMap) or MicroISA.getOpcodePermutation(baseSalt)

	emit("\tlocal function " .. V.readBank .. "(bnk, rMap, uTag, r)\n")
	emit("\t\tlocal p = (" .. V.isType .. "(rMap, 2) and rMap[r]) or (" .. V.isType .. "(rMap, 1) and rMap(r)) or (rMap and rMap(r)) or (r + 1)\n\t\tlocal cell = bnk[p]\n\t\tif " .. V.isType .. "(cell, 2) and " .. V.rawget .. "(cell, uTag) then return cell[1] end\n\t\treturn cell\n\tend\n")
	emit("\tlocal function " .. V.writeBank .. "(bnk, rMap, uTag, r, v)\n")
	emit("\t\tlocal p = (" .. V.isType .. "(rMap, 2) and rMap[r]) or (" .. V.isType .. "(rMap, 1) and rMap(r)) or (rMap and rMap(r)) or (r + 1)\n\t\tlocal cell = bnk[p]\n\t\tif " .. V.isType .. "(cell, 2) and " .. V.rawget .. "(cell, uTag) then " .. V.rawset .. "(cell, 1, v) else bnk[p] = v end\n\tend\n")
	emit("\tlocal function " .. V.capture .. "(...)\n\t\treturn select('#', ...), { ... }\n\tend\n")
	emit("\tlocal function " .. V.capturePcall .. "(_ok, ...)\n\t\tif not _ok then return 0, {} end\n\t\treturn select('#', ...), { ... }\n\tend\n")
	emit("\tlocal aluMap = { " .. table.concat(aluEntries, ", ") .. " }\n")
	emit("\tlocal capMap = { " .. table.concat(capMapEntries, ", ") .. " }\n\n")

	emit("\tlocal " .. V.microExec .. " = " .. MicroVM.generateRuntimeMicroVM(isProduction, V.readBank, V.writeBank, microOpMap) .. ";\n\n")

	emit("\tlocal _vmCallDepth = 0\n\tlocal " .. V.outerVM .. "\n\n")

	emit("\tlocal function " .. V.initProtoDesc .. "(bc, " .. V.rawRegions .. ")\n")
	emit("\t\tlocal meta = bc[" .. tostring(idxMeta) .. "] or {}\n")
	emit("\t\tlocal _metaSalt = meta[" .. tostring(metaSlots[1]) .. "] or 0\n")
	emit("\t\tlocal numParams = meta[" .. tostring(metaSlots[2]) .. "] or 0\n")
	emit("\t\tlocal _metaPackMode = meta[" .. tostring(metaSlots[3]) .. "] or 1\n")
	emit("\t\tlocal _metaRegPack = meta[" .. tostring(metaSlots[4]) .. "] or 257\n")
	emit("\t\tlocal _metaByteLen = meta[" .. tostring(metaSlots[5]) .. "]\n")
	emit("\t\tlocal rawByteLen = (_metaByteLen and ((_metaByteLen - " .. tostring(baseSalt) .. " * 29 + " .. V.regModLarge .. ") % " .. V.regMod .. ")) or 0\n")
	emit("\t\tlocal protoSalt = (_metaSalt - " .. tostring(baseSalt) .. " * 17 + " .. V.regModLarge .. ") % " .. V.regMod .. "\n")
	emit("\t\tlocal packMode = (_metaPackMode - " .. tostring(baseSalt) .. " * 19 + " .. V.regModLarge .. ") % " .. V.regMod .. "\n")
	emit("\t\tlocal regPack = (_metaRegPack - " .. tostring(baseSalt) .. " * 23 + " .. V.regModLarge .. ") % " .. V.regMod .. "\n")
	emit([=[
		local protoKeyMode = (packMode % 4); if protoKeyMode == 0 then protoKeyMode = 1 end
		local protoLayout = math.floor(packMode / 4) % 8
		local protoDispMode = math.floor(packMode / 32) % 8; if protoDispMode == 0 then protoDispMode = 1 end
		local regA1 = ((regPack % 31) * 2 + 1)
		local regA2 = (((regPack * 7 + protoSalt * 13 + 13) % 16) * 2)
		local regA3 = (((regPack * 11 + protoSalt * 17 + 29) % 8) * 4)
		local regOffset = (regPack * 17 + protoSalt * 19 + (protoSalt % 7) * 41 + 73) % ]=] .. V.regMod .. [=[
]=])
	emit("\t\tlocal _rMap = " .. RegisterMapper.generateRuntimeMapper("regA1", "regOffset", nil, "regA2", V.regMod) .. "\n")
	emit([=[
		local protoDCoeff = (protoSalt * 31 + 17) % 256; if protoDCoeff % 2 == 0 then protoDCoeff = protoDCoeff + 1 end
		local protoDOffset = (protoSalt * 43 + 71) % 256
]=])
	emit("\t\tlocal _vSt = ((protoSalt * 31 + packMode * 17 + regPack * 13 + 101) % " .. tostring(stateMod) .. ")\n")
	emit("\t\tlocal _opDec = " .. OperandCodec.generateRuntimeDecoder(nil, "protoSalt", "_vSt") .. "\n")
	emit("\t\tlocal protoKey = " .. V.deriveKey .. "(protoSalt, rawByteLen)\n")
	emit("\t\tlocal _pkLen = #protoKey; if _pkLen == 0 then protoKey = { 17, 31, 53, 97 }; _pkLen = 4 end\n")
	emit("\t\tlocal protoResolverDomain = (protoSalt * 31 + " .. tostring(profile.resolverDomain % 65536) .. ") % 65536\n")
	emit("\t\tlocal _resCont = function(_cReg, _outc, _stVal)\n")
	emit("\t\t\tlocal _kSabRes = " .. dynBytesRaw("__SABOTAGE_RESOLVER") .. "\n")
	emit("\t\t\tif _G and _G[_kSabRes] then local _sab = _G[_kSabRes](_cReg, _outc, _stVal); if type(_sab) ~= 'table' and (type(_sab) ~= 'number' or _sab < 0) then error(" .. failClosedErr .. ", 0) end; return _sab end\n")
	emit("\t\t\tif _outc == 5 then return 5, 0 end\n")
	emit("\t\t\tlocal _tId = 0\n")
	emit("\t\t\tif _outc == 6 then\n")
	emit("\t\t\t\t_tId = _cReg[5] or 0\n")
	emit("\t\t\t\tif not _tId or _tId <= 0 then return 5, 0 end\n")
	emit("\t\t\telseif _outc == 3 or _outc == 4 then\n")
	emit("\t\t\t\t_tId = _cReg[4] or 0\n")
	emit("\t\t\tend\n")
	emit("\t\t\tif not _tId or _tId <= 0 then\n")
	emit("\t\t\t\terror(" .. failClosedErr .. ", 0)\n")
	emit("\t\t\tend\n")
	emit("\t\t\tlocal _stComm = _cReg[6] or 0\n")
	emit("\t\t\tlocal _cTok = (_outc * 8192 + _tId) % 65536\n")
	emit("\t\t\tlocal _resTok = " .. OuterVM.generateTransitionSnippet("_cReg[1]", "_cTok", "_stVal", "protoResolverDomain", "_stComm") .. "\n")
	emit("\t\t\tlocal _decTok = " .. OuterVM.generateDecodeSnippet("_resTok", "_cReg[1]", "_stVal", "protoResolverDomain", "_stComm") .. "\n")
	emit([=[
			local _decOutcome = math.floor(_decTok / 8192)
			local _decTargetId = _decTok % 8192
			if _decOutcome ~= _outc or _decTargetId ~= _tId then
]=])
	emit("\t\t\t\terror(" .. failClosedErr .. ", 0)\n")
	emit([=[
			end
			return _decOutcome, _decTargetId
		end
		local _ps19 = (protoSalt * 19 + 71) % 256
		local _ps37 = (protoSalt * 37 + 137) % 256
		local _ps43 = (protoSalt * 43) % 256
		local function _kByte(pos)
			local kVal = protoKey[((pos - 1) % _pkLen) + 1] or 17
			local k2 = protoKey[((pos * 3 - 1) % _pkLen) + 1] or 31
			local s0 = (kVal * 37 + _ps19 + pos * 23) % 256
			local s1 = (k2 * 53 + _ps37 + pos * 31) % 256
			local f1 = (s0 * 73 + s1 * 89 + kVal * 31 + _ps43) % 256
			local f2 = (s1 * 47 + s0 * 59 + k2 * 17 + pos * 29) % 256
			return (f1 * 53 + f2 * 67 + pos * 41) % 256
		end
		local _kWin = {}
		local _kWinTag = {}
		local _getKB = function(pos)
			local slot = (pos % 32) + 1
			if _kWinTag[slot] ~= pos then
				local b = _kByte(pos)
				_kWinTag[slot] = pos
				_kWin[slot] = b
				return b
			end
			return _kWin[slot]
		end
		local _rMapIdx = {}
]=])
	emit("\t\tfor _ri = 1, #" .. V.rawRegions .. " do\n")
	emit("\t\t\tlocal _rp = " .. V.rawRegions .. "[_ri]\n")
	emit("\t\t\tif _rp then\n")
	emit("\t\t\t\tlocal _comm = _rp[11] or 0\n")
	emit("\t\t\t\tlocal _maskId = (_comm * 11 + " .. tostring(baseSalt) .. " * 13) % 65536\n")
	emit("\t\t\t\tlocal _regId = ((_rp[1] or _ri) - _maskId + 655360) % 65536\n")
	emit("\t\t\t\t_rMapIdx[_regId] = _rp\n")
	emit("\t\t\tend\n")
	emit("\t\tend\n")
	emit("\t\tlocal _rMapByDomain = {}\n")
	emit("\t\tfor _dom = 1, 4 do\n")
	emit("\t\t\tlocal _t = {}\n")
	emit("\t\t\tfor _r = 0, 63 do\n")
	emit("\t\t\t\t_t[_r] = _rMap(_r, _dom)\n")
	emit("\t\t\tend\n")
	emit("\t\t\t_rMapByDomain[_dom] = setmetatable(_t, { [" .. dynBytesRaw("__call") .. "] = function(t, r) return _rMap(r, _dom) end })\n")
	emit("\t\tend\n")
	emit([=[
		local desc = {
			protoSalt, numParams, _rMap, _vSt, _opDec, protoKey, _resCont, _getKB, _rMapIdx, meta, _rMapByDomain
		}
		bc[5] = desc
		return desc
	end
]=])

	emit("\tlocal " .. V.getRegionCache .. ", " .. V.purgeRegionCache .. "\n")
	emit("\tdo\n")
	emit("\t\tlocal " .. V.cacheStore .. " = setmetatable({}, { [" .. dynBytesRaw("__mode") .. "] = \"k\" })\n")
	emit("\t\tlocal _sSalt = " .. tostring(v_sessSalt) .. "\n")
	emit("\t\t" .. V.getRegionCache .. " = function(bc, tok)\n")
	emit("\t\t\tif tok ~= _sSalt or not bc then return {} end\n")
	emit("\t\t\tlocal c = " .. V.cacheStore .. "[bc]\n")
	emit("\t\t\tif not c then c = {}; " .. V.cacheStore .. "[bc] = c end\n")
	emit("\t\t\treturn c\n")
	emit("\t\tend\n")
	emit("\t\t" .. V.purgeRegionCache .. " = function()\n")
	emit("\t\t\tfor k in pairs(" .. V.cacheStore .. ") do " .. V.cacheStore .. "[k] = nil end\n")
	emit("\t\t\t_sSalt = (_sSalt * 1337 + 5381) % 65536\n")
	emit("\t\tend\n")
	emit("\tend\n")
	emit("\tlocal function " .. V.rawOuterVM .. "(bc, K, env, uvs, vargs, ...)\n")
	if not isProduction then
		emit("\t\tlocal rawCode = bc[" .. tostring(idxCode) .. "] or \"\"\n")
		emit("\t\tif " .. V.isType .. "(rawCode, 3) then\n\t\t\trawCode = " .. V.b85Decode .. "(rawCode)\n\t\t\tbc[" .. tostring(idxCode) .. "] = rawCode\n\t\tend\n")
	end
	emit("\t\tlocal " .. V.rawRegions .. " = bc[4]\n")
	emit("\t\tif " .. V.isType .. "(" .. V.rawRegions .. ", 1) then " .. V.rawRegions .. " = " .. V.rawRegions .. "(); bc[4] = " .. V.rawRegions .. " end\n")
	emit("\t\tif not " .. V.rawRegions .. " or not " .. V.isType .. "(" .. V.rawRegions .. ", 2) or #" .. V.rawRegions .. " == 0 then\n\t\t\t" .. V.purgeRegionCache .. "()\n\t\t\terror(" .. failClosedErr .. ", 0)\n\t\tend\n")

	emit([=[
		local desc = bc[5] or ]=] .. V.initProtoDesc .. [=[(bc, ]=] .. V.rawRegions .. [=[)
		local protoSalt = desc[1]
		local numParams = desc[2]
		local ]=] .. V.regMap .. [=[ = desc[3]
		local ]=] .. V.vmState .. [=[ = desc[4]
		local ]=] .. V.opDecode .. [=[ = desc[5]
		local protoKey = desc[6]
		local ]=] .. V.resolveCont .. [=[ = desc[7]
		local ]=] .. V.getKByte .. [=[ = desc[8]
		local _rMapIdx = desc[9]
		local meta = desc[10]
		local _rMapByDomain = desc[11]
		local _pkLen = (protoKey and #protoKey) or 4; if _pkLen == 0 then _pkLen = 4 end
		local _bsEff = ]=] .. tostring(baseSalt % 65536) .. [=[;
		local ]=] .. V.kProf .. [=[ = ]=] .. dynBytesRaw("__ZERO_PROF") .. [=[
]=])

	if not isProduction then
		emit("\t\tlocal " .. V.activeCode .. " = {}\n")
	end

	emit([=[
		_vmActive = _vmActive + 1
		_kConsecutiveReads = 0
		local _regLoadsConsecutive = 0
		local _actRegs = ]=] .. V.getRegionCache .. [=[(bc, ]=] .. tostring(v_sessSalt) .. [=[)
		local ]=] .. V.loadedRegion .. [=[ = nil
		local function ]=] .. V.loadRegion .. [=[(regionId, chainToken)
			_regLoadsConsecutive = _regLoadsConsecutive + 1
			if _vmActive <= 0 and regionId ~= 1 then
				if type(_rMapIdx) == "table" then
					for _k in pairs(_rMapIdx) do _rMapIdx[_k] = nil end
				end
				]=] .. V.purgeRegionCache .. [=[()
				error(]=] .. failClosedErr .. [=[, 0)
			end
			if _regLoadsConsecutive > 3 then
				if type(_rMapIdx) == "table" then
					for _k in pairs(_rMapIdx) do _rMapIdx[_k] = nil end
				end
				]=] .. V.purgeRegionCache .. [=[()
				error(]=] .. failClosedErr .. [=[, 0)
			end
			local rPack = _rMapIdx[regionId]
			if not rPack or not ]=] .. V.isType .. [=[(rPack, 2) or not rPack[2] then
				]=] .. V.purgeRegionCache .. [=[()
				error(]=] .. failClosedErr .. [=[, 0)
			end
			local _cached = _actRegs[regionId]
			if _cached then ]=] .. V.loadedRegion .. [=[ = _cached; return _cached end
	]=])

		if not isProduction then
			emit([=[
			if ]=] .. V.loadedRegion .. [=[ then
				for _p = ]=] .. V.loadedRegion .. [=[[2], ]=] .. V.loadedRegion .. [=[[3] - 1 do
					]=] .. V.activeCode .. [=[[_p] = nil
				end
			end

			local encBytes = ]=] .. V.b85Decode .. [=[(rPack[2])
			local _comm = rPack[11] or 0
			local _maskDip = (_comm * 37 + ]=] .. tostring(baseSalt) .. [=[ * 19) % 65536
			local startDip = ((rPack[5] or 0) - _maskDip + 655360) % 65536
			local _maskEnd = (_comm * 43 + ]=] .. tostring(baseSalt) .. [=[ * 23) % 65536
			local endDip = ((rPack[6] or 0) - _maskEnd + 655360) % 65536
			local rolling = (]=] .. tostring(baseSalt) .. [=[ * 23 + regionId * 41) % 256
			local encLen = (encBytes and #encBytes) or 0
			for bPos = 1, encLen do
				local enc = encBytes[bPos]
				local b = (enc - rolling * 37 - ]=] .. tostring(baseSalt) .. [=[ * 13 - bPos * 19) % 256
				rolling = (rolling * 53 + enc * 17 + b * 7 + bPos * 11) % 256
				]=] .. V.activeCode .. [=[[startDip + bPos - 1] = b
			end
	]=])
		end

		emit([=[
			local _comm = rPack[11] or 0
			local _maskDip = (_comm * 37 + ]=] .. tostring(baseSalt) .. [=[ * 19) % 65536
			local startDip = ((rPack[5] or 0) - _maskDip + 655360) % 65536
			local _maskEnd = (_comm * 43 + ]=] .. tostring(baseSalt) .. [=[ * 23) % 65536
			local endDip = ((rPack[6] or 0) - _maskEnd + 655360) % 65536
			local _pk0 = protoKey[1] or 17
			local _pk1 = protoKey[2] or 31
			local _pk2 = protoKey[3] or 53
			local _pk3 = protoKey[4] or 97
			if regionId == 1 then
				chainToken = chainToken or ((regionId * 1337 + ]=] .. tostring(baseSalt) .. [=[ * 31 + _pk0 * 53 + _pk1 * 17 + 101) % 65536)
			elseif not chainToken then
				if type(_rMapIdx) == "table" then
					for _k in pairs(_rMapIdx) do _rMapIdx[_k] = nil end
				end
				]=] .. V.purgeRegionCache .. [=[()
				error(]=] .. failClosedErr .. [=[, 0)
			end
			local _ctxMask = (]=] .. tostring(baseSalt) .. [=[ * 37 + regionId * 59 + _pk0 * 73 + _pk1 * 29 + _pk2 * 101 + _pk3 * 13 + (chainToken % 1000) * 41 + 104729) % 9000000 + 1000000
			local _rawCtx = rPack[8] or 1101300
			local _regCtx = (_rawCtx - _ctxMask + 10000000) % 10000000
			local _regDom = math.floor(_regCtx / 1000000) % 10
			if _regDom < 1 or _regDom > 4 then
				_regDom = ((_regDom - 1) % 4) + 1
			end
			local _codMode = math.floor(_regCtx / 100000) % 10
			if _codMode < 1 or _codMode > 4 then
				_codMode = ((_codMode - 1) % 4) + 1
			end
			local _cKey = math.floor(_regCtx / 100) % 1000
			local _rState = _regCtx % 100
			local _rMap = (_rMapByDomain and _rMapByDomain[_regDom]) or setmetatable({}, { [ ]=] .. dynBytesRaw("__call") .. [=[ ] = function(t, r) return ]=] .. V.regMap .. [=[(r, _regDom) end })
			local _opDec = function(v, role) return ]=] .. V.opDecode .. [=[(v, _codMode, _cKey, _rState, role) end

			local encNodes = ]=] .. V.b85Decode .. [=[(rPack[3])
			local _prevPack = (regionId > 1 and _rMapIdx[regionId - 1]) or nil
			local _predComm = (_prevPack and _prevPack[11]) or 1337
			local nodes, _calcComm = ]=] .. V.decodeRegion .. [=[(encNodes, ]=] .. tostring(baseSalt) .. [=[, regionId, _codMode, _cKey, _rState, _regDom, protoKey, chainToken, _predComm)
	]=])

	if profileBuild then
		emit([=[
			if _G and _G[]=] .. V.kProf .. [=[] then
				_G[]=] .. V.kProf .. [=[].regionPayloadLoads = (_G[]=] .. V.kProf .. [=[].regionPayloadLoads or 0) + 1
			end
		]=])
	end

	emit([=[
			if rPack[11] and rPack[11] ~= 0 and _calcComm ~= rPack[11] then
				]=] .. V.purgeRegionCache .. [=[()
				error(]=] .. failClosedErr .. [=[, 0)
			end

			local _aluMask = rPack[9] or 65535
			local _localAlu = {}
			for _s = 1, 15 do
				if (_aluMask % (2^_s)) >= (2^(_s - 1)) then
					_localAlu[_s] = aluMap[_s]
				end
			end

			local _stComm = rPack[11] or 0
			local _maskNext = (_stComm * 17 + ]=] .. tostring(baseSalt) .. [=[ * 31 + regionId * 13) % 65536
			local _unmaskedNext = ((rPack[10] or 0) - _maskNext + 655360) % 65536
			local _maskJump = (_stComm * 23 + ]=] .. tostring(baseSalt) .. [=[ * 41 + regionId * 19) % 65536
			local _unmaskedJump = ((rPack[7] or 0) - _maskJump + 655360) % 65536

			]=] .. V.loadedRegion .. [=[ = {
				regionId,
				startDip,
				endDip,
				_unmaskedJump,
				_unmaskedNext,
				_stComm,
				nodes,
				_rMap,
				_localAlu,
				_regDom,
				_codMode,
				_cKey,
				_rState,
				_opDec,
				_regCtx,
				_aluMask,
				rPack[13]
			}
			_actRegs[regionId] = ]=] .. V.loadedRegion .. [=[

			return ]=] .. V.loadedRegion .. [=[
		end
]=])

	emit([=[
		local ]=] .. V.Bank .. [=[ = {}
		local _frameScratch = {}
		uvs = (type(uvs) == "table" and uvs) or {}
		local ]=] .. V.inArgCount .. [=[ = select("#", ...)
		local ]=] .. V.va .. [=[ = (type(vargs) == "table" and vargs) or nil
		if not ]=] .. V.va .. [=[ then
			local _vaCount = math.max(0, ]=] .. V.inArgCount .. [=[ - numParams)
			if _vaCount == 0 then
				]=] .. V.va .. [=[ = ]=] .. V.emptyVa .. [=[
			else
				]=] .. V.va .. [=[ = { n = _vaCount }
				for _vi = 1, _vaCount do
					]=] .. V.va .. [=[[_vi] = select(numParams + _vi, ...)
				end
			end
		end
		local _initRegion = ]=] .. V.loadRegion .. [=[(1)
		local _initRMap = (_initRegion and _initRegion[8]) or function(r) return ]=] .. V.regMap .. [=[(r, 1) end
		for _i = 1, numParams do
			local _phy = _initRMap(_i - 1)
			local _val = nil
			if _i <= ]=] .. V.inArgCount .. [=[ then _val = select(_i, ...) end
			]=] .. V.Bank .. [=[[_phy] = _val
		end

		local ]=] .. V.isRet .. [=[ = false
		local ]=] .. V.retCount .. [=[ = 0
		local ]=] .. V.ret1 .. [=[, ]=] .. V.ret2 .. [=[, ]=] .. V.ret3 .. [=[
		local ]=] .. V.retTbl .. [=[ = nil
		local ]=] .. V.retCountN .. [=[ = 0
]=])

	emit([=[
		local function ]=] .. V.recvRet .. [=[(...)
			local _n = select("#", ...)
			if _n == 0 then
				]=] .. V.retCount .. [=[ = 0
			elseif _n == 1 then
				]=] .. V.ret1 .. [=[ = ...
				]=] .. V.retCount .. [=[ = 1
			elseif _n == 2 then
				local _r1, _r2 = ...
				]=] .. V.ret1 .. [=[ = _r1; ]=] .. V.ret2 .. [=[ = _r2; ]=] .. V.retCount .. [=[ = 2
			elseif _n == 3 then
				local _r1, _r2, _r3 = ...
				]=] .. V.ret1 .. [=[ = _r1; ]=] .. V.ret2 .. [=[ = _r2; ]=] .. V.ret3 .. [=[ = _r3; ]=] .. V.retCount .. [=[ = 3
			else
				]=] .. V.retTbl .. [=[ = { ... }
				]=] .. V.retCount .. [=[ = -1
				]=] .. V.retCountN .. [=[ = _n
			end
		end
]=])

	emit([=[
		local function ]=] .. V.recvPcall .. [=[(_ok, ...)
			if not _ok then
				]=] .. V.retCount .. [=[ = 0
				return
			end
			local _n = select("#", ...)
			if _n == 0 then
				]=] .. V.retCount .. [=[ = 0
			elseif _n == 1 then
				]=] .. V.ret1 .. [=[ = ...
				]=] .. V.retCount .. [=[ = 1
			elseif _n == 2 then
				local _r1, _r2 = ...
				]=] .. V.ret1 .. [=[ = _r1; ]=] .. V.ret2 .. [=[ = _r2; ]=] .. V.retCount .. [=[ = 2
			elseif _n == 3 then
				local _r1, _r2, _r3 = ...
				]=] .. V.ret1 .. [=[ = _r1; ]=] .. V.ret2 .. [=[ = _r2; ]=] .. V.ret3 .. [=[ = _r3; ]=] .. V.retCount .. [=[ = 3
			else
				]=] .. V.retTbl .. [=[ = { ... }
				]=] .. V.retCount .. [=[ = -1
				]=] .. V.retCountN .. [=[ = _n
			end
		end
]=])

	local cacheEvictionSnippet
	if cacheCapacity > 0 then
		local profEvictionSnippet = profileBuild and [=[
						if _G and _G[]=] .. V.kProf .. [=[] then
							_G[]=] .. V.kProf .. [=[].cacheEvictions = (_G[]=] .. V.kProf .. [=[].cacheEvictions or 0) + 1
						end
		]=] or ""

		local profScanRecordSnippet = profileBuild and [=[
				if _G and _G[]=] .. V.kProf .. [=[] then
					_G[]=] .. V.kProf .. [=[].cacheScans = (_G[]=] .. V.kProf .. [=[].cacheScans or 0) + _scans
					_G[]=] .. V.kProf .. [=[].cacheInsertions = (_G[]=] .. V.kProf .. [=[].cacheInsertions or 0) + 1
					if _scans > (_G[]=] .. V.kProf .. [=[].cacheMaxScans or 0) then
						_G[]=] .. V.kProf .. [=[].cacheMaxScans = _scans
					end
				end
		]=] or ""

		cacheEvictionSnippet = [=[
				local _slotFound = nil
				local _scans = 0
				for _step = 1, ]=] .. cacheCapacity .. [=[ do
					_scans = _scans + 1
					local _cand = _dynKRing[_dynKHead]
					if _cand == nil then
						_slotFound = _dynKHead
						_dynKHead = (_dynKHead % ]=] .. cacheCapacity .. [=[) + 1
						break
					elseif _dynKRef[_cand] then
						_dynKRef[_cand] = nil
						_dynKHead = (_dynKHead % ]=] .. cacheCapacity .. [=[) + 1
					else
						_dynK[_cand] = nil
						_dynKRef[_cand] = nil
]=] .. profEvictionSnippet .. [=[
						_slotFound = _dynKHead
						_dynKHead = (_dynKHead % ]=] .. cacheCapacity .. [=[) + 1
						break
					end
				end
				if not _slotFound then
					local _cand = _dynKRing[_dynKHead]
					if _cand ~= nil then
						_dynK[_cand] = nil
						_dynKRef[_cand] = nil
]=] .. profEvictionSnippet .. [=[
					end
					_slotFound = _dynKHead
					_dynKHead = (_dynKHead % ]=] .. cacheCapacity .. [=[) + 1
				end
]=] .. profScanRecordSnippet .. [=[
				_dynKRing[_slotFound] = idx
				_dynK[idx] = res
				_dynKRef[idx] = true
				meta[9] = _dynKHead
		]=]
	else
		cacheEvictionSnippet = ""
	end

	local profAccessSnippet = profileBuild and [=[
			if _G and _G[]=] .. V.kProf .. [=[] then
				_G[]=] .. V.kProf .. [=[].constantAccesses = (_G[]=] .. V.kProf .. [=[].constantAccesses or 0) + 1
			end
	]=] or ""

	local profHitSnippet = profileBuild and [=[
				if _G and _G[]=] .. V.kProf .. [=[] then
					_G[]=] .. V.kProf .. [=[].constantCacheHits = (_G[]=] .. V.kProf .. [=[].constantCacheHits or 0) + 1
				end
	]=] or ""

	local profActualDecodeSnippet = profileBuild and [=[
				if _G and _G[]=] .. V.kProf .. [=[] then
					_G[]=] .. V.kProf .. [=[].actualConstantDecodes = (_G[]=] .. V.kProf .. [=[].actualConstantDecodes or 0) + 1
				end
	]=] or ""

	emit([=[
		local _dynK = meta[7]
		local _dynKRing = meta[8]
		local _dynKHead = meta[9] or 1
		local _dynKRef = meta[10]
		if not _dynK then
			_dynK = {}
			_dynKRing = {}
			_dynKRef = {}
			meta[7] = _dynK
			meta[8] = _dynKRing
			meta[9] = _dynKHead
			meta[10] = _dynKRef
		end
		local function ]=] .. V.getK .. [=[(idx, reqNonce, reqRegId, reqNodeIdx)
			_kConsecutiveReads = _kConsecutiveReads + 1
			if _vmActive <= 0 or _kConsecutiveReads > 150 then
				if type(K) == "table" then
					for _k in pairs(K) do K[_k] = nil end
				end
				error(]=] .. failClosedErr .. [=[, 0)
			end
			if reqNonce ~= nil and reqRegId ~= nil and reqNodeIdx ~= nil then
				local _curKey = (]=] .. V.loadedRegion .. [=[ and ]=] .. V.loadedRegion .. [=[[12]) or 13
				local _expNonce = (reqRegId * 1013 + reqNodeIdx * 31 + _curKey * 17 + 5381) % 65536
				if reqNonce ~= _expNonce then
					if type(K) == "table" then
						for _k in pairs(K) do K[_k] = nil end
					end
					error(]=] .. failClosedErr .. [=[, 0)
				end
			end
			local _kPool = K
			if not _kPool then return end
	]=])
	if profileBuild then
		emit(profAccessSnippet)
	end
	if cacheCapacity > 0 then
		emit([=[
			local _hit = _dynK[idx]
			if _hit ~= nil then
				_dynKRef[idx] = true
		]=])
		if profileBuild then
			emit(profHitSnippet)
		end
		emit([=[
				return _hit
			end
		]=])
	end
	emit([=[
			local entry = _kPool[idx]
			if entry == nil then return end
			local res = entry
			if ]=] .. V.isType .. [=[(entry, 2) and #entry == 2 and entry[1] and entry[1] <= 0 then
				local _off = -entry[1]
				local _len = entry[2] or 0
				if _len == 0 then return "" end
				local _slice = {}
				for _j = 1, _len do
					_slice[_j] = ]=] .. V.rawKBlob .. [=[[_off + _j - 1] or 0
				end
				res = ]=] .. V.synthStr .. [=[(_slice, idx, ]=] .. opaqueSeedExpr(topProtoSalt, 131072) .. [=[)
			elseif ]=] .. V.isType .. [=[(entry, 2) and (#entry > 0 and ]=] .. V.isType .. [=[(entry[1], 4) and not ]=] .. V.isType .. [=[(entry[2], 2) and not ]=] .. V.isType .. [=[(entry[3], 3)) then
				res = ]=] .. V.synthStr .. [=[(entry, idx, ]=] .. opaqueSeedExpr(topProtoSalt, 131072) .. [=[)
			elseif ]=] .. V.isType .. [=[(entry, 2) and ]=] .. V.isType .. [=[(entry[1], 3) and not ]=] .. V.isType .. [=[(entry[2], 2) and not ]=] .. V.isType .. [=[(entry[3], 4) then
				local _parts = {}
				local _bsEff = (]=] .. tostring(baseSalt) .. [=[ * 31 + ]=] .. opaqueSeedExpr(topProtoSalt, 131072) .. [=[ * 17 + (idx * 11) + (]=] .. V.attestDelta .. [=[ * 31337)) % 65536;
				local _cipherEngine = (((idx * 13 + protoSalt * 17) % 4) + 1)
				for _fi, _frag in ipairs(entry) do
					local _fdec = {}
					local _fBytes = ]=] .. V.b85Decode .. [=[(_frag)
					local _prev = (idx * 37 + _fi * 41 + protoSalt * 7 + (idx * idx * 3) % 256) % 256
					for _j = 1, #_fBytes do
						local _b = _fBytes[_j]
						local _dec = _b
						if _cipherEngine == 1 then
							local _kVal = protoKey[((idx * 7 + _fi * 11 + _j * 13 + _prev) % _pkLen) + 1] or 42
							local _sVal = (_bsEff * 19 + idx * 31 + _fi * 47 + _j * 23 + _kVal * 17 + _prev * 13) % 256
							_dec = (_b - _sVal + 256) % 256
							_prev = (_prev * 31 + _b * 17 + _dec * 7) % 256
						elseif _cipherEngine == 2 then
							local _kVal = protoKey[((idx * 17 + _fi * 19 + _j * 23 + _prev) % _pkLen) + 1] or 53
							local _poly = (((_j * 17 + idx * 23 + _fi * 43 + _prev * 7 + (_bsEff % 256)) % 256) * _j + _kVal * 13 + 59) % 256
							_dec = (_b - _poly + 256) % 256
							_prev = (_prev * 41 + _b * 23 + _dec * 11 + 17) % 256
						elseif _cipherEngine == 3 then
							local _kVal = protoKey[((idx * 31 + _fi * 19 + _j * 29 + _prev) % _pkLen) + 1] or 79
							local _sVal = (_bsEff * 29 + idx * 43 + _fi * 53 + _j * 37 + _kVal * 19 + _prev * 11 + 43) % 256
							_dec = (_b - _sVal + 256) % 256
							_prev = (_prev * 47 + _b * 29 + _dec * 13 + 31) % 256
						else
							local _kVal = protoKey[((idx * 13 + _fi * 29 + _j * 17 + _prev) % _pkLen) + 1] or 97
							local _add = (_bsEff * 11 + idx * 19 + _fi * 23 + _j * 31 + _kVal * 7 + _prev * 5) % 256
							_dec = (((_b - _add + 256) % 256) * 43) % 256
							_prev = (_prev * 53 + _b * 29 + _dec * 13 + 37) % 256
						end
						_fdec[_j] = ]=])
	emit(V.sChar .. "(_dec)\n\t\t\t\t\tend\n\t\t\t\t\t_parts[_fi] = " .. V.tConcat .. "(_fdec)\n\t\t\t\tend\n\t\t\t\tres = " .. V.tConcat .. "(_parts)\n")
	emit("\t\t\telseif " .. V.isType .. "(entry, 3) then\n")
	emit("\t\t\t\tlocal _fBytes = " .. V.b85Decode .. "(entry)\n")
	emit("\t\t\t\tres = " .. V.synthStr .. "(_fBytes, idx, " .. opaqueSeedExpr(topProtoSalt, 131072) .. ")\n")
	emit("\t\t\tend\n")
	emit("\t\t\tif " .. V.isType .. "(res, 4) and " .. V.encGlobals .. "[res] ~= nil then\n")
	emit("\t\t\t\tres = " .. V.getStdName .. "(res)\n")
	emit("\t\t\tend\n")
	emit("\t\t\tif res ~= nil then\n")
	if profileBuild then
		emit(profActualDecodeSnippet)
		emit(cacheEvictionSnippet)
	end
	emit([=[
			end
			return res
		end
	]=])


	emit("\t\tlocal function " .. V.hostBridge .. "(cap, a1, a2, a3, a4, a5, a6, a7, a8)\n")
	emit("\t\t\tif _G and _G[" .. V.kProf .. "] then local _zp = _G[" .. V.kProf .. "]; local _kHBC = " .. dynBytes("hostBridgeCalls") .. "; local _kCaps = " .. dynBytes("caps") .. "; _zp[_kHBC] = (_zp[_kHBC] or 0) + 1; _zp[_kCaps] = _zp[_kCaps] or {}; _zp[_kCaps][cap] = (_zp[_kCaps][cap] or 0) + 1 end\n")
	emit("\t\t\tif cap == capMap[1] then\n")
	emit("\t\t\t\tlocal dst, numArgs, numRets, bnk, rMap, uTag, va, pb = a1, a2, a3, a4, a5, a6, a7, a8\n")
	emit("\t\t\t\tif not (pb == 3 or pb == 4 or pb == 6) and numArgs and numArgs >= 128 then numArgs = numArgs - 256 end\n")
	emit("\t\t\t\tlocal _fn = " .. V.readBank .. "(bnk, rMap, uTag, dst)\n")
	emit("\t\t\t\tif _fn == nil and pb ~= 6 then _fn = function() return nil end end\n")
	emit("\t\t\t\tif pb == 6 then\n")
	emit("\t\t\t\t\tlocal _st = " .. V.readBank .. "(bnk, rMap, uTag, numArgs)\n")
	emit("\t\t\t\t\tif " .. V.isType .. "(_fn, 2) or " .. V.isType .. "(_fn, 5) then\n")
	emit("\t\t\t\t\t\tlocal _mt = getmetatable and getmetatable(_fn)\n")
	emit("\t\t\t\t\t\tlocal _iterFn = " .. V.isType .. "(_mt, 2) and _mt[" .. V.getStdName .. "(" .. tostring(hIter) .. ")]\n")
	emit("\t\t\t\t\t\tif " .. V.isType .. "(_iterFn, 1) then\n")
	emit("\t\t\t\t\t\t\tlocal _ok, _f, _s, _v = pcall(_iterFn, _fn)\n")
	emit("\t\t\t\t\t\t\tif _ok and _f ~= nil then\n")
	emit("\t\t\t\t\t\t\t\t" .. V.writeBank .. "(bnk, rMap, uTag, dst, _f); " .. V.writeBank .. "(bnk, rMap, uTag, numArgs, _s); " .. V.writeBank .. "(bnk, rMap, uTag, numRets, _v)\n")
	emit("\t\t\t\t\t\t\t\treturn\n")
	emit("\t\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\t\tif " .. V.isType .. "(_fn, 2) then\n")
	emit("\t\t\t\t\t\t\tif _st == nil then\n")
	emit("\t\t\t\t\t\t\t\tlocal _nxt = next or (_G and _G.next) or " .. V.resolveEnv .. "(env, " .. tostring(hNext) .. ")\n")
	emit("\t\t\t\t\t\t\t\t" .. V.writeBank .. "(bnk, rMap, uTag, dst, _nxt); " .. V.writeBank .. "(bnk, rMap, uTag, numArgs, _fn); " .. V.writeBank .. "(bnk, rMap, uTag, numRets, nil)\n")
	emit("\t\t\t\t\t\t\telse\n")
	emit("\t\t\t\t\t\t\t\tlocal _callFn = " .. V.isType .. "(_mt, 2) and _mt[" .. V.getStdName .. "(" .. tostring(hCall) .. ")]\n")
	emit("\t\t\t\t\t\t\t\tif not " .. V.isType .. "(_callFn, 1) then\n")
	emit("\t\t\t\t\t\t\t\t\t" .. V.writeBank .. "(bnk, rMap, uTag, dst, function() return nil end); " .. V.writeBank .. "(bnk, rMap, uTag, numArgs, nil); " .. V.writeBank .. "(bnk, rMap, uTag, numRets, nil)\n")
	emit("\t\t\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\telseif " .. V.isType .. "(_fn, 1) and _st == nil then\n")
	emit("\t\t\t\t\t\tlocal _nxt = next or (_G and _G.next)\n")
	emit("\t\t\t\t\t\tif _fn == _nxt then\n")
	emit("\t\t\t\t\t\t\t" .. V.writeBank .. "(bnk, rMap, uTag, dst, function() return nil end); " .. V.writeBank .. "(bnk, rMap, uTag, numArgs, nil); " .. V.writeBank .. "(bnk, rMap, uTag, numRets, nil)\n")
	emit("\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\tend\n")
	emit("\t\t\t\t\treturn\n")
	emit("\t\t\t\tend\n")
	emit("\t\t\t\tif pb == 5 then\n")
	emit("\t\t\t\t\tlocal _tbl = " .. V.readBank .. "(bnk, rMap, uTag, dst)\n")
	emit("\t\t\t\t\tlocal _subFn = " .. V.readBank .. "(bnk, rMap, uTag, numArgs)\n")
	emit("\t\t\t\t\tif _subFn == nil then _subFn = function() return nil end end\n")
	emit("\t\t\t\t\tlocal _b = numRets % 32\n")
	emit("\t\t\t\t\tlocal _startIdx = math.floor(numRets / 32)\n")
	emit("\t\t\t\t\tlocal _sArgs = {}; local _nArgs = 0\n")
	emit("\t\t\t\t\tif _b == 0 then\n")
	emit("\t\t\t\t\telseif _b == 31 or _b >= 16 then\n")
	emit("\t\t\t\t\t\tlocal _num = (_b == 31 and 0) or (_b - 16)\n")
	emit("\t\t\t\t\t\tfor _ai = 1, _num do _sArgs[_ai] = " .. V.readBank .. "(bnk, rMap, uTag, numArgs + _ai) end\n")
	emit("\t\t\t\t\t\tlocal _vaCount = (va and (va.n or #va)) or 0\n")
	emit("\t\t\t\t\t\tfor _vi = 1, _vaCount do _sArgs[_num + _vi] = va[_vi] end\n")
	emit("\t\t\t\t\t\t_nArgs = _num + _vaCount\n")
	emit("\t\t\t\t\telse\n")
	emit("\t\t\t\t\t\tfor _ai = 1, _b do _sArgs[_ai] = " .. V.readBank .. "(bnk, rMap, uTag, numArgs + _ai) end\n")
	emit("\t\t\t\t\t\t_nArgs = _b\n")
	emit("\t\t\t\t\tend\n")
	emit("\t\t\t\t\tlocal _rn, _ret = " .. V.capture .. "(_subFn(" .. V.packUnpack .. "(_sArgs, 1, _nArgs)))\n")
	emit("\t\t\t\t\tif _tbl ~= nil and _ret ~= nil then for _ri = 1, _rn do _tbl[_startIdx + _ri - 1] = _ret[_ri] end end\n")
	emit("\t\t\t\t\treturn\n")
	emit("\t\t\t\tend\n")
	emit("\t\t\t\tif pb == 0 and numArgs >= 0 and numArgs <= 3 then\n")
	emit("\t\t\t\t\tlocal _r1, _r2, _r3\n")
	emit("\t\t\t\t\tif numArgs == 0 then\n")
	emit("\t\t\t\t\t\tif numRets == 0 then _fn();\n")
	emit("\t\t\t\t\t\telseif numRets == 1 then " .. V.writeBank .. "(bnk, rMap, uTag, dst, _fn());\n")
	emit("\t\t\t\t\t\telseif numRets == 2 then _r1, _r2 = _fn(); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2);\n")
	emit("\t\t\t\t\t\telseif numRets == 3 then _r1, _r2, _r3 = _fn(); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 2, _r3);\n")
	emit("\t\t\t\t\t\telse local _rn, _ret = " .. V.capture .. "(_fn()); if numRets > 3 then for _i = 1, numRets do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end else for _i = 1, _rn do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end end end\n")
	emit("\t\t\t\t\t\treturn\n")
	emit("\t\t\t\t\telseif numArgs == 1 then\n")
	emit("\t\t\t\t\t\tlocal _a1 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 1)\n")
	emit("\t\t\t\t\t\tif numRets == 0 then _fn(_a1);\n")
	emit("\t\t\t\t\t\telseif numRets == 1 then " .. V.writeBank .. "(bnk, rMap, uTag, dst, _fn(_a1));\n")
	emit("\t\t\t\t\t\telseif numRets == 2 then _r1, _r2 = _fn(_a1); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2);\n")
	emit("\t\t\t\t\t\telseif numRets == 3 then _r1, _r2, _r3 = _fn(_a1); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 2, _r3);\n")
	emit("\t\t\t\t\t\telse local _rn, _ret = " .. V.capture .. "(_fn(_a1)); if numRets > 3 then for _i = 1, numRets do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end else for _i = 1, _rn do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end end end\n")
	emit("\t\t\t\t\t\treturn\n")
	emit("\t\t\t\t\telseif numArgs == 2 then\n")
	emit("\t\t\t\t\t\tlocal _a1 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 1)\n")
	emit("\t\t\t\t\t\tlocal _a2 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 2)\n")
	emit("\t\t\t\t\t\tif numRets == 0 then _fn(_a1, _a2);\n")
	emit("\t\t\t\t\t\telseif numRets == 1 then " .. V.writeBank .. "(bnk, rMap, uTag, dst, _fn(_a1, _a2));\n")
	emit("\t\t\t\t\t\telseif numRets == 2 then _r1, _r2 = _fn(_a1, _a2); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2);\n")
	emit("\t\t\t\t\t\telseif numRets == 3 then _r1, _r2, _r3 = _fn(_a1, _a2); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 2, _r3);\n")
	emit("\t\t\t\t\t\telse local _rn, _ret = " .. V.capture .. "(_fn(_a1, _a2)); if numRets > 3 then for _i = 1, numRets do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end else for _i = 1, _rn do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end end end\n")
	emit("\t\t\t\t\t\treturn\n")
	emit("\t\t\t\t\telseif numArgs == 3 then\n")
	emit("\t\t\t\t\t\tlocal _a1 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 1)\n")
	emit("\t\t\t\t\t\tlocal _a2 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 2)\n")
	emit("\t\t\t\t\t\tlocal _a3 = " .. V.readBank .. "(bnk, rMap, uTag, dst + 3)\n")
	emit("\t\t\t\t\t\tif numRets == 0 then _fn(_a1, _a2, _a3);\n")
	emit("\t\t\t\t\t\telseif numRets == 1 then " .. V.writeBank .. "(bnk, rMap, uTag, dst, _fn(_a1, _a2, _a3));\n")
	emit("\t\t\t\t\t\telseif numRets == 2 then _r1, _r2 = _fn(_a1, _a2, _a3); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2);\n")
	emit("\t\t\t\t\t\telseif numRets == 3 then _r1, _r2, _r3 = _fn(_a1, _a2, _a3); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 2, _r3);\n")
	emit("\t\t\t\t\t\telse local _rn, _ret = " .. V.capture .. "(_fn(_a1, _a2, _a3)); if numRets > 3 then for _i = 1, numRets do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end else for _i = 1, _rn do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end end end\n")
	emit("\t\t\t\t\t\treturn\n")
	emit("\t\t\t\t\tend\n")
	emit("\t\t\t\tend\n")
	emit("\t\t\t\tlocal _args = {}; local _numArgs = 0\n")
	emit("\t\t\t\tif pb == 3 or pb == 4 then\n")
	emit("\t\t\t\t\tlocal _numFixed = math.floor(numArgs / 64)\n")
	emit("\t\t\t\t\tlocal _subMode = numArgs % 64\n")
	emit("\t\t\t\t\tlocal _subBase = (pb == 4 and (dst + _numFixed)) or (dst + _numFixed + 1)\n")
	emit("\t\t\t\t\tlocal _subFn = " .. V.readBank .. "(bnk, rMap, uTag, _subBase)\n")
	emit("\t\t\t\t\tlocal _subRet = nil; local _subN = 0\n")
	emit("\t\t\t\t\tif _subFn ~= nil then\n")
	emit("\t\t\t\t\t\tif _subMode == 31 then\n")
	emit("\t\t\t\t\t\t\tlocal _vaCount = (va and (va.n or #va)) or 0\n")
	emit("\t\t\t\t\t\t\t_subN, _subRet = " .. V.capture .. "(_subFn(" .. V.packUnpack .. "(va, 1, _vaCount)))\n")
	emit("\t\t\t\t\t\telseif _subMode >= 32 then\n")
	emit("\t\t\t\t\t\t\tlocal _sFixed = _subMode - 32\n")
	emit("\t\t\t\t\t\t\tlocal _sArgs = {}\n")
	emit("\t\t\t\t\t\t\tfor _i = 1, _sFixed do _sArgs[_i] = " .. V.readBank .. "(bnk, rMap, uTag, _subBase + _i) end\n")
	emit("\t\t\t\t\t\t\tlocal _vaCount = (va and (va.n or #va)) or 0\n")
	emit("\t\t\t\t\t\t\tfor _vi = 1, _vaCount do _sArgs[_sFixed + _vi] = va[_vi] end\n")
	emit("\t\t\t\t\t\t\t_subN, _subRet = " .. V.capture .. "(_subFn(" .. V.packUnpack .. "(_sArgs, 1, _sFixed + _vaCount)))\n")
	emit("\t\t\t\t\t\telse\n")
	emit("\t\t\t\t\t\t\tlocal _sArgs = {}\n")
	emit("\t\t\t\t\t\t\tfor _i = 1, _subMode do _sArgs[_i] = " .. V.readBank .. "(bnk, rMap, uTag, _subBase + _i) end\n")
	emit("\t\t\t\t\t\t\t_subN, _subRet = " .. V.capture .. "(_subFn(" .. V.packUnpack .. "(_sArgs, 1, _subMode)))\n")
	emit("\t\t\t\t\t\tend\n")
	emit("\t\t\t\t\tend\n")
	emit("\t\t\t\t\tif pb == 4 then\n")
	emit("\t\t\t\t\t\tlocal _res = {}; for _i = 1, _numFixed do _res[_i] = " .. V.readBank .. "(bnk, rMap, uTag, dst + _i - 1) end\n")
	emit("\t\t\t\t\t\tlocal _sN = (_subRet and (_subRet.n or #_subRet)) or 0\n")
	emit("\t\t\t\t\t\tfor _si = 1, _sN do _res[_numFixed + _si] = _subRet[_si] end\n")
	emit("\t\t\t\t\t\treturn { true, false, dst, numArgs, numRets, _res, _numFixed + _sN }\n")
	emit("\t\t\t\t\tend\n")
	emit("\t\t\t\t\tfor _i = 1, _numFixed do _args[_i] = " .. V.readBank .. "(bnk, rMap, uTag, dst + _i) end\n")
	emit("\t\t\t\t\tfor _si = 1, _subN do _args[_numFixed + _si] = _subRet[_si] end\n")
	emit("\t\t\t\t\t_numArgs = _numFixed + _subN\n")
	emit("\t\t\t\telseif numArgs == -1 then local _vaCount = (va and (va.n or #va)) or 0; for _vi = 1, _vaCount do _args[_vi] = va[_vi] end; _numArgs = _vaCount\n")
	emit("\t\t\t\telseif numArgs <= -100 then local _num = (-numArgs) - 100; for _i = 1, _num do _args[_i] = " .. V.readBank .. "(bnk, rMap, uTag, dst + _i) end; local _vaCount = (va and (va.n or #va)) or 0; for _vi = 1, _vaCount do _args[_num + _vi] = va[_vi] end; _numArgs = _num + _vaCount\n")
	emit("\t\t\t\telse for _i = 1, numArgs do _args[_i] = " .. V.readBank .. "(bnk, rMap, uTag, dst + _i) end; _numArgs = numArgs end\n")
	emit("\t\t\t\tif pb == 1 then local _rn, _ret = " .. V.capture .. "(_fn(" .. V.packUnpack .. "(_args, 1, _numArgs))); return { true, false, dst, numArgs, numRets, _ret, _rn } end\n")
	emit("\t\t\t\tif numRets == 0 then _fn(" .. V.packUnpack .. "(_args, 1, _numArgs))\n")
	emit("\t\t\t\telseif numRets == 1 then " .. V.writeBank .. "(bnk, rMap, uTag, dst, _fn(" .. V.packUnpack .. "(_args, 1, _numArgs)))\n")
	emit("\t\t\t\telseif numRets == 2 then local _r1, _r2 = _fn(" .. V.packUnpack .. "(_args, 1, _numArgs)); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2)\n")
	emit("\t\t\t\telseif numRets == 3 then local _r1, _r2, _r3 = _fn(" .. V.packUnpack .. "(_args, 1, _numArgs)); " .. V.writeBank .. "(bnk, rMap, uTag, dst, _r1); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 1, _r2); " .. V.writeBank .. "(bnk, rMap, uTag, dst + 2, _r3)\n")
	emit("\t\t\t\telse local _rn, _ret = " .. V.capture .. "(_fn(" .. V.packUnpack .. "(_args, 1, _numArgs))); if numRets > 3 then for _i = 1, numRets do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end else for _i = 1, _rn do " .. V.writeBank .. "(bnk, rMap, uTag, dst + _i - 1, _ret[_i]) end end end\n")
	emit("\t\t\telseif cap == capMap[2] then\n")
	emit("\t\t\t\tlocal dst, protoIdx, _dummy, bnk, rMap, uTag = a1, a2, a3, a4, a5, a6\n")
	emit("\t\t\t\tlocal _childBc = " .. V.getK .. "(protoIdx + 1)\n")
	emit("\t\t\t\tlocal childFn = " .. V.createClosure .. "(_childBc, K, env, uvs, bnk, 1, 0, 0, 0, " .. V.outerVM .. ", rMap)\n")
	emit("\t\t\t\t" .. V.writeBank .. "(bnk, rMap, uTag, dst, childFn)\n")
	emit("\t\t\telseif cap == capMap[3] then return " .. V.resolveEnv .. "(a1, a2)\n")
	emit("\t\t\telseif cap == capMap[4] then\n")
	emit("\t\t\t\tlocal dst, numWanted, s2, bnk, rMap, uTag, va = a1, a2, a3, a4, a5, a6, a7\n")
	emit("\t\t\t\tif numWanted and numWanted >= 128 then numWanted = numWanted - 256 end\n")
	emit("\t\t\t\tlocal vaCount = (va and (va.n or #va)) or 0\n")
	emit("\t\t\t\tif numWanted == -1 then local cell = " .. V.readBank .. "(bnk, rMap, uTag, dst); if cell ~= nil then for _vi = 1, vaCount do cell[s2 + _vi - 1] = va[_vi] end end\n")
	emit("\t\t\t\telseif numWanted > 0 then for _vi = 1, numWanted do local val = va and va[_vi]; " .. V.writeBank .. "(bnk, rMap, uTag, dst + _vi - 1, val) end end\n")
	emit("\t\t\telseif cap == capMap[5] then\n")
	emit("\t\t\t\tlocal _entry = " .. V.getK .. "(a2, a5, a3, a4)\n")
	emit("\t\t\t\tlocal _regId = a3 or (" .. V.loadedRegion .. " and " .. V.loadedRegion .. "[1]) or 0\n")
	emit("\t\t\t\tlocal _uTok = a4 or a2\n")
	emit("\t\t\t\tif type(_entry) == 'table' and (_entry[1] or _entry[2]) then\n")
	emit("\t\t\t\t\treturn _synthesizeConstant(_entry[1] or _entry[2], _uTok, protoKey, " .. tostring(baseSalt) .. ", _regId, protoSalt)\n")
	emit("\t\t\t\tend\n")
	emit("\t\t\t\treturn _entry\n")
	emit("\t\t\telseif cap == capMap[6] then a1[a2] = a3\n")
	emit("\t\t\telseif cap == capMap[7] then\n")
	emit("\t\t\t\tlocal dst, bnk, rMap, uTag = a1, a4, a5, a6; " .. V.writeBank .. "(bnk, rMap, uTag, dst, {})\n")
	emit("\t\t\tend\n")
	emit("\t\tend\n\n")

	if not isProduction then
		emit("\t\tlocal " .. V.ip .. " = 1\n\t\tlocal " .. V.dip .. " = 1\n\t\tlocal " .. V.codeLen .. " = rawByteLen or #rawCode\n\t\tlocal opA, opB, opC = nil, nil, nil\n\t\tlocal " .. V.rawA .. ", " .. V.rawB .. ", " .. V.rawC .. " = 0, 0, 0\n\t\tlocal " .. V.w .. " = 0\n\n")

		emit([=[
		local function ]=] .. V.evalAddSub .. [=[(b, c, isSub)
			if b ~= nil and c ~= nil then
				if type(b) == "number" and type(c) == "number" then
					return isSub and (b - c) or (b + c)
				elseif ]=] .. V.isType .. [=[(b, 4) and ]=] .. V.isType .. [=[(c, 4) then
					return isSub and (b - c) or (b + c)
				else
					local _ok, _res = pcall(isSub and ]=] .. V.rawSub .. [=[ or ]=] .. V.rawAdd .. [=[, b, c)
					if _ok then return _res end
				end
			end
			return nil
		end
]=])

		emit([=[
		local function ]=] .. V.evalMulDivMod .. [=[(b, c, mode)
			if b ~= nil and c ~= nil then
				if type(b) == "number" and type(c) == "number" then
					if mode == 1 then return b * c
					elseif mode == 2 then return b / c
					else return b % c end
				elseif ]=] .. V.isType .. [=[(b, 4) and ]=] .. V.isType .. [=[(c, 4) then
					if mode == 1 then return b * c
					elseif mode == 2 then return b / c
					else return b % c end
				else
					local _fn = (mode == 1 and ]=] .. V.rawMul .. [=[) or (mode == 2 and ]=] .. V.rawDiv .. [=[) or ]=] .. V.rawMod .. [=[
					local _ok, _res = pcall(_fn, b, c)
					if _ok then return _res end
				end
			end
			return nil
		end
]=])

		emit([=[
		local function ]=] .. V.evalPowUnm .. [=[(b, c, isPow)
			if b ~= nil then
				if isPow then
					if c ~= nil then
						if type(b) == "number" and type(c) == "number" then return b ^ c end
						if ]=] .. V.isType .. [=[(b, 4) and ]=] .. V.isType .. [=[(c, 4) then return b ^ c end
						local _ok, _res = pcall(]=] .. V.rawPow .. [=[, b, c)
						if _ok then return _res end
					end
				else
					if type(b) == "number" then return -b end
					if ]=] .. V.isType .. [=[(b, 4) then return -b end
					local _ok, _res = pcall(]=] .. V.rawUnm .. [=[, b)
					if _ok then return _res end
				end
			end
			return nil
		end
]=])

		emit([=[
		local function ]=] .. V.evalCompare .. [=[(b, c, mode, invert)
			local cond = false
			if mode == 1 then
				cond = (b == c)
			elseif mode == 2 then
				if b ~= nil and c ~= nil then
					if type(b) == "number" and type(c) == "number" then cond = (b < c)
					elseif ]=] .. V.isType .. [=[(b, 4) and ]=] .. V.isType .. [=[(c, 4) then cond = (b < c)
					else local _ok, _res = pcall(]=] .. V.rawLt .. [=[, b, c); if _ok then cond = not not _res end end
				end
			else
				if b ~= nil and c ~= nil then
					if type(b) == "number" and type(c) == "number" then cond = (b <= c)
					elseif ]=] .. V.isType .. [=[(b, 4) and ]=] .. V.isType .. [=[(c, 4) then cond = (b <= c)
					else local _ok, _res = pcall(]=] .. V.rawLe .. [=[, b, c); if _ok then cond = not not _res end end
				end
			end
			return cond ~= invert
		end
]=])

		emit([=[
		local function ]=] .. V.decOps .. [=[()
			if opA ~= nil then return end
			]=] .. V.rawA .. [=[ = 0
			]=] .. V.rawB .. [=[ = 0
			]=] .. V.rawC .. [=[ = 0
	]=])

		emit([=[
			local ]=] .. V.b2 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 2] or 0
			local ]=] .. V.b3 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 3] or 0
			local ]=] .. V.r2 .. [=[ = (]=] .. V.b2 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 2) + 256) % 256
			local ]=] .. V.r3 .. [=[ = (]=] .. V.b3 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 3) + 256) % 256
			]=] .. V.rawA .. [=[ = (((]=] .. V.r3 .. [=[ * 256 + ]=] .. V.r2 .. [=[) - 32768) - (((]=] .. V.dip .. [=[ * 55 + protoSalt * 53 + 97) % 1024) - 512))
	]=])

		emit([=[
			if ]=] .. V.w .. [=[ >= 3 then
				local ]=] .. V.b4 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 4] or 0
				local ]=] .. V.b5 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 5] or 0
				local ]=] .. V.r4 .. [=[ = (]=] .. V.b4 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 4) + 256) % 256
				local ]=] .. V.r5 .. [=[ = (]=] .. V.b5 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 5) + 256) % 256
				]=] .. V.rawB .. [=[ = (((]=] .. V.r5 .. [=[ * 256 + ]=] .. V.r4 .. [=[) - 32768) - (((]=] .. V.dip .. [=[ * 73 + protoSalt * 53 + 194) % 1024) - 512))
			end
	]=])

		emit([=[
			if ]=] .. V.w .. [=[ == 4 then
				local ]=] .. V.b6 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 6] or 0
				local ]=] .. V.b7 .. [=[ = ]=] .. V.activeCode .. [=[[]=] .. V.dip .. [=[ + 7] or 0
				local ]=] .. V.r6 .. [=[ = (]=] .. V.b6 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 6) + 256) % 256
				local ]=] .. V.r7 .. [=[ = (]=] .. V.b7 .. [=[ - ]=] .. V.getKByte .. [=[(]=] .. V.dip .. [=[ + 7) + 256) % 256
				]=] .. V.rawC .. [=[ = (((]=] .. V.r7 .. [=[ * 256 + ]=] .. V.r6 .. [=[) - 32768) - (((]=] .. V.dip .. [=[ * 91 + protoSalt * 53 + 291) % 1024) - 512))
			end
	]=])

		emit([=[
			if ]=] .. V.w .. [=[ == 4 then
				if protoLayout == 1 then
					opC = ]=] .. V.rawA .. [=[; opA = ]=] .. V.rawB .. [=[; opB = ]=] .. V.rawC .. [=[
				elseif protoLayout == 2 then
					opB = ]=] .. V.rawA .. [=[; opC = ]=] .. V.rawB .. [=[; opA = ]=] .. V.rawC .. [=[
				elseif protoLayout == 3 then
					opA = ]=] .. V.rawA .. [=[; opC = ]=] .. V.rawB .. [=[; opB = ]=] .. V.rawC .. [=[
				elseif protoLayout == 4 then
					opB = ]=] .. V.rawA .. [=[; opA = ]=] .. V.rawB .. [=[; opC = ]=] .. V.rawC .. [=[
				elseif protoLayout == 5 then
					opC = ]=] .. V.rawA .. [=[; opB = ]=] .. V.rawB .. [=[; opA = ]=] .. V.rawC .. [=[
				else
					opA = ]=] .. V.rawA .. [=[; opB = ]=] .. V.rawB .. [=[; opC = ]=] .. V.rawC .. [=[
				end
			elseif ]=] .. V.w .. [=[ == 3 then
				if protoLayout == 1 or protoLayout == 2 or protoLayout == 4 then
					opB = ]=] .. V.rawA .. [=[; opA = ]=] .. V.rawB .. [=[; opC = 0
				else
					opA = ]=] .. V.rawA .. [=[; opB = ]=] .. V.rawB .. [=[; opC = 0
				end
			else
				opA = ]=] .. V.rawA .. [=[; opB = 0; opC = 0
			end
			opA = (opA and ]=] .. V.opDecode .. [=[(opA)) or 0
			opB = (opB and ]=] .. V.opDecode .. [=[(opB)) or 0
			opC = (opC and ]=] .. V.opDecode .. [=[(opC)) or 0
		end
]=])
	else
		emit("\t\tlocal " .. V.ip .. " = 1\n\t\tlocal " .. V.dip .. " = 1\n\n")
	end

	local branches = {}
	local function addBranch(opVal, snippet, name)
		if opVal then
			local tok = getTok(opVal)
			local code = "\t\t\t\t" .. V.decOps .. "(); " .. snippet:gsub("^%s+", "")
			if leakageAudit then
				local hookD = "if _G and _G.__LEAKAGE_OBSERVE then _G.__LEAKAGE_OBSERVE(\"D\", { handler = \"" .. tostring(name) .. "\", opA = opA, opB = opB, opC = opC, dip = " .. V.dip .. " }) end; "
				code = "\t\t\t\t" .. V.decOps .. "(); " .. hookD .. snippet:gsub("^%s+", "")
			end
			table.insert(branches, { tok = tok, code = code, name = name })
		end
	end

	local ctx = {
		gR = gR, sR = sR, V = V,
		v_isType = V.isType, v_getStdName = V.getStdName, v_resolveEnv = V.resolveEnv,
		v_createClosure = V.createClosure, v_outerVM = V.outerVM, v_Bank = V.Bank,
		v_currentRegion = V.currentRegion, v_regMap = V.regMap, v_va = V.va,
		v_ip = V.ip, v_codeLen = V.codeLen, v_evalCompare = V.evalCompare,
		v_evalAddSub = V.evalAddSub, v_evalMulDivMod = V.evalMulDivMod, v_evalPowUnm = V.evalPowUnm,
		v_getK = V.getK, v_retCount = V.retCount, v_ret1 = V.ret1,
		v_ret2 = V.ret2, v_ret3 = V.ret3, v_retTbl = V.retTbl,
		v_retCountN = V.retCountN, v_isRet = V.isRet, v_packUnpack = V.packUnpack,
		v_rawset = V.rawset, v_predBlockHash = V.predBlockHash, v_vmState = V.vmState,
		v_dip = V.dip, stateMod = stateMod, leakageAudit = leakageAudit, stateCoupling = stateCoupling,
		hIter = hIter, hCall = hCall, hNext = hNext,
		hGetService = hGetService, hPlayers = hPlayers, hLocalPlayer = hLocalPlayer, hCharacter = hCharacter,
	}
	local dynamicDescriptors = buildDynamicDescriptors(ctx)

	-- Build-time ISA Invariant Assertion: EMITTABLE_OPCODES âŠ† RUNTIME_HANDLERS
	local descriptorSet = {}
	for _, desc in ipairs(dynamicDescriptors) do
		descriptorSet[desc.name] = true
	end
	for opName, _ in pairs(opcodes) do
		if not descriptorSet[opName] then
			error("ZeroLua ISA Invariant Violation: Opcode '" .. tostring(opName) .. "' is present in active VM profile but has no runtime descriptor in VMRuntime!", 0)
		end
	end

	-- Dynamic iteration over descriptors to register dispatch branches
	for _, desc in ipairs(dynamicDescriptors) do
		local opVal = opcodes[desc.name]
		if opVal then
			addBranch(opVal, desc.code, desc.name)
		end
	end

	-- Phase 5: Decoupled contextual dispatch - dead dispatchBlock and full-ISA jump table eliminated

	if profileBuild then
		local tokMapEntries = {}
		for _, b in ipairs(branches) do
			table.insert(tokMapEntries, "[" .. tostring(b.tok) .. '] = "' .. tostring(b.name) .. '"')
		end
		emit([=[
		if _G and _G[]=] .. V.kProf .. [=[] then
			_G[]=] .. V.kProf .. [=[].tokMap = { ]=] .. table.concat(tokMapEntries, ", ") .. [=[ }
			_G[]=] .. V.kProf .. [=[].opCounts = _G[]=] .. V.kProf .. [=[].opCounts or {}
		end
		]=])
	end

	emit("\t\tlocal " .. V.currentRegionId .. ", " .. V.currentRegion .. " = 1, " .. V.loadRegion .. "(1)\n")
	emit("\t\tlocal " .. V.regionPc .. " = " .. V.currentRegion .. "[2]\n")
	emit("\t\t" .. V.ip .. " = " .. V.regionPc .. "\n\n")
	emit("\t\twhile " .. V.currentRegionId .. " and not " .. V.isRet .. " do\n")
	emit("\t\t\t_kConsecutiveReads = 0\n")
	emit("\t\t\t_regLoadsConsecutive = 0\n")

	if profileBuild then
		emit([=[
			if _G and _G[]=] .. V.kProf .. [=[] then
				local _zp = _G[]=] .. V.kProf .. [=[]
				local _kDisp = ]=] .. dynBytesRaw("dispatches") .. [=[
				local _kOpC = ]=] .. dynBytesRaw("opCounts") .. [=[
				local _rOps = ]=] .. V.currentRegion .. [=[ and type(]=] .. V.currentRegion .. [=[[17]) == "table" and ]=] .. V.currentRegion .. [=[[17]
				local _nOps = (_rOps and #_rOps) or (]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[4]) or 1
				_zp[_kDisp] = (_zp[_kDisp] or 0) + _nOps
				_zp.regionExecutions = (_zp.regionExecutions or 0) + 1
				if _zp[_kOpC] and _rOps then
					for _oi = 1, #_rOps do
						local _opTok = _rOps[_oi]
						local _opName = nil
						if type(_opTok) == "string" then
							_opName = _opTok
						elseif _zp.tokMap and type(_opTok) == "number" then
							_opName = _zp.tokMap[_opTok]
						end
						if _opName then
							_zp[_kOpC][_opName] = (_zp[_kOpC][_opName] or 0) + 1
						end
					end
				end
			end
		]=])
	end

	if adversaryTrace then
		emit([=[
			local _kAdv = ]=] .. dynBytesRaw("__ADVERSARY_TRACE") .. [=[
			if _G and _G[_kAdv] then
				local _rTok = (]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[1]) or 1
				local _rDip = (]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[2]) or 0
				local _rNodes = ]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[7]
				if _rNodes and #_rNodes > 0 then
					for _ni = 1, #_rNodes do
						local _n = _rNodes[_ni]
						local _tok = _n[1] or _rTok
						local _opA = _n[2] or 0
						local _opB = _n[3] or 0
						local _opC = _n[4] or 0
						]=] .. V.vmState .. [=[ = (]=] .. V.vmState .. [=[ * 131 + _tok * 17 + _ni * 31 + _rDip * 7 + 101) % ]=] .. tostring(stateMod) .. [=[
						_G[_kAdv](_tok, _opA, _opB, _opC, _rDip + (_ni - 1), ]=] .. V.vmState .. [=[, _vmCallDepth)
					end
				else
					]=] .. V.vmState .. [=[ = (]=] .. V.vmState .. [=[ * 131 + _rTok * 17 + _rDip * 7 + 101) % ]=] .. tostring(stateMod) .. [=[
					_G[_kAdv](_rTok, 0, 0, 0, _rDip, ]=] .. V.vmState .. [=[, _vmCallDepth)
				end
			end
		]=])
	end

	if leakageAudit then
		emit([=[
			local _kLeak = ]=] .. dynBytesRaw("__LEAKAGE_OBSERVE") .. [=[
			if _G and _G[_kLeak] then
				local _obs = _G[_kLeak]
				local _rTok = (]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[1]) or 1
				local _rDip = (]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[2]) or 0
				local _rNodes = ]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[7]
				local _numEv = (_rNodes and #_rNodes) or 1
				for _ni = 1, _numEv do
					local _n = _rNodes and _rNodes[_ni]
					local _tok = (_n and _n[2]) or _rTok
					local _opA = (_n and _n[2]) or 0
					local _opB = (_n and _n[3]) or 0
					local _opC = (_n and _n[4]) or 0
					local _dipVal = _rDip + (_ni - 1)
					local _rawA = (]=] .. tostring(topLayout) .. [=[ == 0 and _opA) or ((_opA * 7 + 11) % 256)
					local _rawB = (]=] .. tostring(topLayout) .. [=[ == 0 and _opB) or ((_opB * 13 + 17) % 256)
					local _rawC = (]=] .. tostring(topLayout) .. [=[ == 0 and _opC) or ((_opC * 19 + 23) % 256)
					local _rawOp = (_tok * 31 + 7) % 256
					_obs("A", { dip = _dipVal, vmState = ]=] .. V.vmState .. [=[ })
					_obs("B", { rawOp = _rawOp, rawA = _rawA, rawB = _rawB, rawC = _rawC, dip = _dipVal })
					_obs("C", { tok = _tok, opA = _opA, opB = _opB, opC = _opC, dip = _dipVal })
					_obs("D", { handler = "OP_" .. tostring(_tok), opA = _opA, opB = _opB, opC = _opC, dip = _dipVal })
					_obs("E", { result = 0, reg = _opA, dip = _dipVal })
					_obs("F", { nextIp = _dipVal + 1, dip = _dipVal })
				end
			end
		]=])
	end


	emit([=[
			if ]=] .. V.currentRegion .. [=[ and ]=] .. V.currentRegion .. [=[[7] and #]=] .. V.currentRegion .. [=[[7] > 0 then
				local _microRet = ]=] .. V.microExec .. [=[(]=] .. V.currentRegion .. [=[[7], ]=] .. V.Bank .. [=[, (]=] .. V.currentRegion .. [=[[8] or ]=] .. V.regMap .. [=[), ]=] .. V.uvTag .. [=[, K, env, uvs, ]=] .. V.va .. [=[, ]=] .. V.hostBridge .. [=[, aluMap, capMap, ]=] .. V.synthStr .. [=[, ]=] .. V.currentRegion .. [=[, _frameScratch)
				if _microRet then
					if _microRet[1] then
						]=] .. V.isRet .. [=[ = true
						local _opA = _microRet[3] or 0
						local _opB = _microRet[4] or 0
						local _opC = _microRet[5] or 0
						if _opB and _opB >= 128 then _opB = _opB - 256 end
						if _microRet[6] then
							]=] .. V.retTbl .. [=[ = _microRet[6]
							]=] .. V.retCount .. [=[ = -1
							]=] .. V.retCountN .. [=[ = _microRet[7] or #_microRet[6]
						elseif _opB == -2 then
							]=] .. V.retTbl .. [=[ = ]=] .. V.va .. [=[
							]=] .. V.retCount .. [=[ = -1
							]=] .. V.retCountN .. [=[ = (]=] .. V.va .. [=[ and (]=] .. V.va .. [=[.n or #]=] .. V.va .. [=[)) or 0
	]=])

	emit([=[
						elseif _opB <= -100 then
							local _num = ((-_opB) - 100)
							local _res = {}
]=])
	emit("\t\t\t\t\t\t\tlocal _cRMap = " .. V.currentRegion .. "[8] or " .. V.regMap .. "\n")
	emit("\t\t\t\t\t\t\tfor _i = 1, _num do _res[_i] = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA + _i - 1) end\n")
	emit("\t\t\t\t\t\t\tlocal _vaCount = (" .. V.va .. " and (" .. V.va .. ".n or #" .. V.va .. ")) or 0\n")
	emit("\t\t\t\t\t\t\tfor _vi = 1, _vaCount do _res[_num + _vi] = " .. V.va .. "[_vi] end\n")
	emit("\t\t\t\t\t\t\t" .. V.retTbl .. " = _res\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = -1\n")
	emit("\t\t\t\t\t\t\t" .. V.retCountN .. " = _num + _vaCount\n")
	emit("\t\t\t\t\t\telseif _opB == -1 or _opB < _opA then\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = 0\n")
	emit("\t\t\t\t\t\telseif _opB == _opA then\n")
	emit("\t\t\t\t\t\t\tlocal _cRMap = " .. V.currentRegion .. "[8] or " .. V.regMap .. "\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = 1\n")
	emit("\t\t\t\t\t\t\t" .. V.ret1 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA)\n")
	emit("\t\t\t\t\t\telseif _opB == _opA + 1 then\n")
	emit("\t\t\t\t\t\t\tlocal _cRMap = " .. V.currentRegion .. "[8] or " .. V.regMap .. "\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = 2\n")
	emit("\t\t\t\t\t\t\t" .. V.ret1 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA)\n")
	emit("\t\t\t\t\t\t\t" .. V.ret2 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA + 1)\n")
	emit("\t\t\t\t\t\telseif _opB == _opA + 2 then\n")
	emit("\t\t\t\t\t\t\tlocal _cRMap = " .. V.currentRegion .. "[8] or " .. V.regMap .. "\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = 3\n")
	emit("\t\t\t\t\t\t\t" .. V.ret1 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA)\n")
	emit("\t\t\t\t\t\t\t" .. V.ret2 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA + 1)\n")
	emit("\t\t\t\t\t\t\t" .. V.ret3 .. " = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA + 2)\n")
	emit("\t\t\t\t\t\telse\n")
	emit("\t\t\t\t\t\t\tlocal _num = (_opB - _opA) + 1\n\t\t\t\t\t\t\tlocal _res = {}\n")
	emit("\t\t\t\t\t\t\tlocal _cRMap = " .. V.currentRegion .. "[8] or " .. V.regMap .. "\n")
	emit("\t\t\t\t\t\t\tfor _i = 1, _num do _res[_i] = " .. V.readBank .. "(" .. V.Bank .. ", _cRMap, " .. V.uvTag .. ", _opA + _i - 1) end\n")
	emit("\t\t\t\t\t\t\t" .. V.retTbl .. " = _res\n")
	emit("\t\t\t\t\t\t\t" .. V.retCount .. " = -1\n")
	emit("\t\t\t\t\t\t\t" .. V.retCountN .. " = _num\n")
	emit("\t\t\t\t\t\tend\n")

	emit([=[
					elseif _microRet[2] then
						local _jmpId = ]=] .. V.currentRegion .. [=[[4] or 0
						if _jmpId and _jmpId > 0 then
							if _jmpId <= ]=] .. V.currentRegion .. [=[[1] then
								]=] .. V.regionPc .. [=[ = ]=] .. V.currentRegion .. [=[[2] - 2
							else
								]=] .. V.regionPc .. [=[ = ]=] .. V.currentRegion .. [=[[3] + 2
							end
						else
							]=] .. V.regionPc .. [=[ = ]=] .. V.currentRegion .. [=[[3]
						end
					else
						]=] .. V.regionPc .. [=[ = ]=] .. V.currentRegion .. [=[[3]
					end
				else
					]=] .. V.regionPc .. [=[ = ]=] .. V.currentRegion .. [=[[3]
				end
			else
	]=])
	emit("\t\t\t\tlocal _kSabLeg = " .. dynBytesRaw("__SABOTAGE_LEGACY_SEMANTICS") .. "\n\t\t\t\tif _G and _G[_kSabLeg] then error(" .. failClosedErr .. ", 0) end\n")
	emit([=[
				error(]=] .. failClosedErr .. [=[, 0)
			end
	]=])

			-- Authoritative OuterVM Continuation Resolution (Â§3, Â§4, Â§5, Â§10)
	emit("\t\t\tlocal _outcome = 1\n")
	emit("\t\t\tif " .. V.isRet .. " then\n")
	emit("\t\t\t\t_outcome = 5\n")
	emit("\t\t\telseif " .. V.regionPc .. " == " .. V.currentRegion .. "[3] then\n")
	emit("\t\t\t\t_outcome = 6\n")
	emit("\t\t\telseif " .. V.regionPc .. " < " .. V.currentRegion .. "[2] then\n")
	emit("\t\t\t\t_outcome = 4\n")
	emit("\t\t\telseif " .. V.regionPc .. " > " .. V.currentRegion .. "[3] then\n")
	emit("\t\t\t\t_outcome = 3\n")
	emit("\t\t\telse\n")
	emit("\t\t\t\t_outcome = 0\n")
	emit("\t\t\tend\n\n")

	emit("\t\t\tif _outcome == 0 then\n")
	emit("\t\t\t\terror(" .. failClosedErr .. ", 0)\n")
	emit("\t\t\tend\n\n")

	emit("\t\t\tlocal _decOutcome, _decTargetId = " .. V.resolveCont .. "(" .. V.currentRegion .. ", _outcome, " .. V.vmState .. ")\n\n")

	emit([=[
		if _G and _G[]=] .. V.kProf .. [=[] then
			local _zp = _G[]=] .. V.kProf .. [=[]
			local _kRT = ]=] .. dynBytesRaw("regionTransitions") .. [=[
			local _kST = ]=] .. dynBytesRaw("stateTransitions") .. [=[
			local _kCR = ]=] .. dynBytesRaw("continuationResolutions") .. [=[
			local _kBC = ]=] .. dynBytesRaw("branchContinuations") .. [=[
			local _kLC = ]=] .. dynBytesRaw("loopContinuations") .. [=[
			local _kRC = ]=] .. dynBytesRaw("returnContinuationResolutions") .. [=[
			local _kLIT = ]=] .. dynBytesRaw("legacyIpTransitions") .. [=[
			_zp[_kRT] = (_zp[_kRT] or 0) + 1
			_zp[_kST] = (_zp[_kST] or 0) + 1
			_zp[_kCR] = (_zp[_kCR] or 0) + 1
			if _decOutcome == 3 then
				_zp[_kBC] = (_zp[_kBC] or 0) + 1
			elseif _decOutcome == 4 then
				_zp[_kLC] = (_zp[_kLC] or 0) + 1
			elseif _decOutcome == 5 then
				_zp[_kRC] = (_zp[_kRC] or 0) + 1
				_zp.returnContinuations = (_zp.returnContinuations or 0) + 1
			end
			_zp[_kLIT] = _zp[_kLIT] or 0
		end
	]=])

	emit("\t\t\tif _decOutcome == 5 then\n")
	emit("\t\t\t\t" .. V.isRet .. " = true\n")
	emit("\t\t\t\tbreak\n")
	emit("\t\t\tend\n\n")

	emit("\t\t\tif _decTargetId and _decTargetId > 0 then\n")
	emit("\t\t\t\t" .. V.currentRegionId .. " = _decTargetId\n")
	emit("\t\t\t\tlocal _transToken = (_decTargetId * 1337 + " .. tostring(baseSalt) .. " * 31 + (protoKey[1] or 17) * 53 + (protoKey[2] or 31) * 17 + 101) % 65536\n")
	emit("\t\t\t\t" .. V.currentRegion .. " = " .. V.loadRegion .. "(" .. V.currentRegionId .. ", _transToken)\n")
	emit("\t\t\t\t" .. V.regionPc .. " = " .. V.currentRegion .. "[2]\n")
	emit("\t\t\t\t" .. V.ip .. " = " .. V.regionPc .. "\n")
	emit("\t\t\telse\n")
	emit("\t\t\t\tbreak\n")
	emit("\t\t\tend\n")
	emit("\t\tend\n\n")
	emit("\t\t_vmActive = _vmActive - 1\n")

	emit("\t\tif " .. V.isRet .. " then\n")
	emit("\t\t\tif " .. V.retCount .. " == 0 then return end\n")
	emit("\t\t\tif " .. V.retCount .. " == 1 then return " .. V.ret1 .. " end\n")
	emit("\t\t\tif " .. V.retCount .. " == 2 then return " .. V.ret1 .. ", " .. V.ret2 .. " end\n")
	emit("\t\t\tif " .. V.retCount .. " == 3 then return " .. V.ret1 .. ", " .. V.ret2 .. ", " .. V.ret3 .. " end\n")
	emit("\t\t\treturn " .. V.packUnpack .. "(" .. V.retTbl .. ", 1, " .. V.retCountN .. ")\n")
	emit("\t\tend\n")
	emit("\t\treturn\n")
	emit("\tend\n")

	if profileBuild then
		emit([=[
	local function legacyExecutor()
		if _G and _G[]=] .. V.kProf .. [=[] then
			_G[]=] .. V.kProf .. [=[].legacyExecutions = (_G[]=] .. V.kProf .. [=[].legacyExecutions or 0) + 1
			_G[]=] .. V.kProf .. [=[].legacyStreamReads = (_G[]=] .. V.kProf .. [=[].legacyStreamReads or 0) + 1
		end
	end
]=])
	end

	if adversaryTrace then
		emit("\t" .. V.outerVM .. " = function(bc, K, env, uvs, vargs, ...)\n")
		emit("\t\t_vmCallDepth = _vmCallDepth + 1\n")
		emit("\t\tlocal ok, r1, r2, r3, r4 = _p_pcall(" .. V.rawOuterVM .. ", bc, K, env, uvs, vargs, ...)\n")
		emit("\t\t_vmCallDepth = _vmCallDepth - 1\n")
		emit("\t\tif not ok then error(r1, 0) end\n")
		emit("\t\treturn r1, r2, r3, r4\n")
		emit("\tend\n")
	else
		emit("\t" .. V.outerVM .. " = " .. V.rawOuterVM .. "\n")
	end

	local topMetaArr = {}
	topMetaArr[metaSlots[1]] = tostring((topProtoSalt + baseSalt * 17) % 65536)
	topMetaArr[metaSlots[2]] = "0"
	topMetaArr[metaSlots[3]] = tostring(((topDispatchMode * 32 + topLayout * 4 + topKeyMode) + baseSalt * 19) % 65536)
	topMetaArr[metaSlots[4]] = tostring(((topRegMul * 256 + topRegOffset) + baseSalt * 23) % 65536)
	topMetaArr[metaSlots[5]] = tostring((rawByteLen + baseSalt * 29) % 65536)
	local topMetaPart = "{ " .. table.concat(topMetaArr, ", ") .. " }"
	local topCodePart = (isProduction and '""') or ('"' .. (codeStr or "") .. '"')
	local topRegionsPart = (type(encodedRegions) == "string" and encodedRegions) or "{}"
	local topBcTable
	if bcLayout == 1 then
		topBcTable = "{ [1] = " .. topMetaPart .. ", [2] = {}, [3] = " .. topCodePart .. ", [4] = " .. topRegionsPart .. " }"
	elseif bcLayout == 2 then
		topBcTable = "{ [1] = {}, [2] = " .. topCodePart .. ", [3] = " .. topMetaPart .. ", [4] = " .. topRegionsPart .. " }"
	else
		topBcTable = "{ [1] = " .. topMetaPart .. ", [2] = " .. topCodePart .. ", [3] = {}, [4] = " .. topRegionsPart .. " }"
	end

	emit([=[
	local ]=] .. V.topK .. [=[ = ]=] .. kStr .. [=[;
	local ]=] .. V.topBc .. [=[ = ]=] .. topBcTable .. [=[;
	local ]=] .. V.topEnv .. [=[ = (]=] .. V.isType .. [=[(]=] .. V.gEnv .. [=[, 2) and setmetatable({}, { [ ]=] .. dynBytesRaw("__index") .. [=[ ] = ]=] .. V.gEnv .. [=[ })) or {}
	]=])

	-- Decoy Honeypot Trap (misleading regex and AST dumpers with poison)

	emit("\tlocal " .. V.decoy .. " = function(...)\n\t\tlocal " .. V.decoyTrap .. " = { ... }\n\t\tif #" .. V.decoyTrap .. " > 100 then error(\"\", 0) end\n\tend;\n")

	local entryLaunchStyle = (profile and profile.entryLaunchStyle) or ((baseSalt % 5) + 1)
	if entryLaunchStyle == 1 then

		emit("\tlocal " .. V.proxy .. " = setmetatable({ [1] = " .. V.outerVM .. " }, { __call = function(t, ...)\n\t\treturn t[1](...)\n\tend });\n")
		emit("\treturn " .. V.proxy .. "(" .. V.topBc .. ", " .. V.topK .. ", " .. V.topEnv .. ", false, false, ...)\nend)(...)\n")
	elseif entryLaunchStyle == 2 then

		emit("\tlocal " .. V.wrap .. " = (coroutine and coroutine.wrap) or function(f) return f end;\n")
		emit("\treturn " .. V.wrap .. "(function(...)\n\t\treturn " .. V.outerVM .. "(...)\n\tend)(" .. V.topBc .. ", " .. V.topK .. ", " .. V.topEnv .. ", false, false, ...)\nend)(...)\n")
	elseif entryLaunchStyle == 3 then

		emit("\tlocal function " .. V.curry .. "(f)\n\t\treturn function(...)\n\t\t\treturn f(...)\n\t\tend\n\tend;\n")
		emit("\treturn " .. V.curry .. "(" .. V.outerVM .. ")(" .. V.topBc .. ", " .. V.topK .. ", " .. V.topEnv .. ", false, false, ...)\nend)(...)\n")
	elseif entryLaunchStyle == 4 then

		local topSaltVal = tostring((topProtoSalt + baseSalt * 17) % 65536)
		emit("\tlocal " .. V.dispatchTbl .. " = { [" .. topSaltVal .. "] = " .. V.outerVM .. " };\n")
		emit("\treturn " .. V.dispatchTbl .. "[" .. topSaltVal .. "](" .. V.topBc .. ", " .. V.topK .. ", " .. V.topEnv .. ", false, false, ...)\nend)(...)\n")
	else

		emit("\tlocal " .. V.idxProxy .. " = setmetatable({}, { __index = function(_, _)\n\t\treturn " .. V.outerVM .. "\n\tend });\n")
		emit("\treturn " .. V.idxProxy .. "[1](" .. V.topBc .. ", " .. V.topK .. ", " .. V.topEnv .. ", false, false, ...)\nend)(...)\n")
	end

	return table.concat(parts)
end

return VMRuntime
