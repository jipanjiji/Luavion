-- This Script is Part of the Zero Lua Obfuscator v3.4
--
-- region_encoder.lua
--
-- Serializes and encodes micro-code execution graphs using a Chained Rolling-State Stream Cipher.
-- Enforces cross-instruction state dependencies so no single node can be decoded or lifted in isolation.

local MicroISA = require("zerolua.compiler.micro_isa")

local RegionEncoder = {}

function RegionEncoder.new(profile, rng, salt)
	local self = setmetatable({}, { __index = RegionEncoder })
	self.profile = profile or {}
	self.rng = rng
	self.salt = salt or (profile and (profile.baseSalt or (profile.keyMaterial and profile.keyMaterial.baseSalt) or profile.protoSalt)) or 1337
	return self
end

function RegionEncoder:encodeRegionStream(regions, protoKey)
	local encoded = {}
	local baseSalt = self.salt

	local KeySchedule = require("zerolua.compiler.key_schedule")
	protoKey = protoKey or (self.profile and self.profile.protoKey) or { 17, 31, 53, 97 }
	local capMap = (self.profile and self.profile.capMap) or KeySchedule.deriveCapMap(protoKey, (self.profile and self.profile.seed) or 1337)
	local constCap = (capMap and capMap["CONSTANT"]) or 5
	local resolveEnvCap = (capMap and capMap["RESOLVE_ENV"]) or 3
	local setEnvCap = (capMap and capMap["SET_ENV"]) or 6
	local closureCap = (capMap and capMap["CLOSURE"]) or 2

	local pkLen = #protoKey
	if pkLen == 0 then protoKey = { 17, 31, 53, 97 }; pkLen = 4 end
	local pk0 = protoKey[1] or 17
	local pk1 = protoKey[2] or 31
	local pk2 = protoKey[3] or 53
	local pk3 = protoKey[4] or 97
	local prevCommitment = 1337

	for idx, region in ipairs(regions or {}) do
		local nodes = region.microNodes or {}
		local rawStream = {}

		local protoRegDomain = (self.profile and self.profile.semanticProfile and self.profile.semanticProfile.registerDomain) or (((self.salt + baseSalt) % 4) + 1)
		local regDomain = ((protoRegDomain - 1) % 4) + 1
		local codecMode = ((idx * 3 + baseSalt * 7) % 4) + 1
		local contextKey = (baseSalt * 13 + idx * 37 + 11) % 256
		if contextKey == 0 then contextKey = 13 end
		local regionState = (baseSalt * 23 + idx * 41 + 101) % 100
		local packedContext = regDomain * 1000000 + codecMode * 100000 + contextKey * 100 + regionState
		local regId = region.id or idx
		local chainToken = (regId * 1337 + baseSalt * 31 + pk0 * 53 + pk1 * 17 + 101) % 65536
		local ctxMask = (baseSalt * 37 + regId * 59 + pk0 * 73 + pk1 * 29 + pk2 * 101 + pk3 * 13 + (chainToken % 1000) * 41 + 104729) % 9000000 + 1000000
		local maskedContext = (packedContext + ctxMask) % 10000000
		local rolling = (baseSalt * 17 + idx * 31 + contextKey * 19 + regionState * 13 + codecMode * 29 + (chainToken % 256) * 7) % 256

		region.regDomain = regDomain
		region.codecMode = codecMode
		region.contextKey = contextKey
		region.regionState = regionState
		region.packedContext = maskedContext
		region.rawPackedContext = packedContext

		local mopA = ((contextKey % 7) * 2 + 1)
		local mopB = (contextKey * 3 + idx * 5) % 16

		local activeAlu = {}
		local encodedNodes = {}
		for nodeIdx, n in ipairs(nodes) do
			local c  = (type(n) == "table" and n[1]) or 1
			local d  = (type(n) == "table" and n[2]) or 0
			local s1 = (type(n) == "table" and n[3]) or 0
			local s2 = (type(n) == "table" and n[4]) or 0
			local pa = (type(n) == "table" and n[5]) or 0
			local pb = (type(n) == "table" and n[6]) or 0

			if c == 6 and pa and pa > 0 then
				activeAlu[pa] = true
			end

			local enc_c = ((c * mopA + mopB) % 16)
			local b_c = enc_c % 256
			local b_pa = pa % 256
			local d_val = (d + 65536) % 65536
			local b_d_lo = d_val % 256
			local b_d_hi = math.floor(d_val / 256) % 256
			local s1_val = (s1 + 65536) % 65536
			local b_s1_lo = s1_val % 256
			local b_s1_hi = math.floor(s1_val / 256) % 256
			local s2_val = (s2 + 65536) % 65536
			local b_s2_lo = s2_val % 256
			local b_s2_hi = math.floor(s2_val / 256) % 256
			local pb_val = (pb + 65536) % 65536
			local b_pb_lo = pb_val % 256
			local b_pb_hi = math.floor(pb_val / 256) % 256

			local layoutMode = ((regDomain * 3 + codecMode * 5 + regionState * 7) % 8)
			local rawBytes
			if layoutMode == 1 then
				-- L1: Split-control layout
				rawBytes = { b_pa, b_c, b_s1_lo, b_s1_hi, b_d_lo, b_d_hi, b_pb_lo, b_pb_hi, b_s2_lo, b_s2_hi }
			elseif layoutMode == 2 then
				-- L2: State-interleaved layout
				rawBytes = { b_d_lo, b_d_hi, b_c, b_pa, b_s2_lo, b_s2_hi, b_s1_lo, b_s1_hi, b_pb_lo, b_pb_hi }
			elseif layoutMode == 3 then
				-- L3: Fused/extended layout
				rawBytes = { b_s1_lo, b_s1_hi, b_s2_lo, b_s2_hi, b_pb_lo, b_pb_hi, b_d_lo, b_d_hi, b_c, b_pa }
			elseif layoutMode == 4 then
				-- L4: Dual-operand rotated layout
				rawBytes = { b_pb_lo, b_pb_hi, b_pa, b_c, b_d_lo, b_d_hi, b_s1_lo, b_s1_hi, b_s2_lo, b_s2_hi }
			elseif layoutMode == 5 then
				-- L5: Source-prefixed destination layout
				rawBytes = { b_s2_lo, b_s2_hi, b_d_lo, b_d_hi, b_s1_lo, b_s1_hi, b_c, b_pa, b_pb_lo, b_pb_hi }
			elseif layoutMode == 6 then
				-- L6: Inverted parameter bundle layout
				rawBytes = { b_d_lo, b_d_hi, b_s1_lo, b_s1_hi, b_pb_lo, b_pb_hi, b_c, b_pa, b_s2_lo, b_s2_hi }
			elseif layoutMode == 7 then
				-- L7: High-entropy interlaced layout
				rawBytes = { b_pa, b_c, b_pb_lo, b_pb_hi, b_s2_lo, b_s2_hi, b_d_lo, b_d_hi, b_s1_lo, b_s1_hi }
			else
				-- L0: Compact canonical layout
				rawBytes = { b_c, b_pa, b_d_lo, b_d_hi, b_s1_lo, b_s1_hi, b_s2_lo, b_s2_hi, b_pb_lo, b_pb_hi }
			end

			table.insert(encodedNodes, { c, d, s1, s2, pa, pb })
			for bIdx, bVal in ipairs(rawBytes) do
				local pkByte = protoKey[((bIdx + idx - 1) % pkLen) + 1] or 17
				local enc = (bVal + rolling * 37 + baseSalt * 13 + contextKey * 7 + bIdx * 19 + codecMode * 11 + pkByte * 17) % 256
				table.insert(rawStream, enc)
				rolling = (rolling * 53 + enc * 17 + bVal * 7 + nodeIdx * 11 + regionState * 3 + pkByte * 13) % 256
			end
		end

		local GraphIntegrity = require("zerolua.compiler.graph_integrity")
		local regId = region.id or idx
		local predComm = prevCommitment
		local stateVal = (regId * 31 + 101) % 65536
		local commData = GraphIntegrity.computeDistributedCommitment(
			encodedNodes,
			regId,
			protoKey,
			stateVal,
			predComm
		)
		region.commitment = commData.commitment
		prevCommitment = commData.commitment

		local aluMask = 0
		for pa, _ in pairs(activeAlu) do
			aluMask = math.floor(aluMask + (2 ^ (pa - 1)))
		end

		local rPack = {
			id = regId,
			stream = rawStream,
			numNodes = #nodes,
			regA = region.regA or 0,
			regB = region.regB or 0,
			regC = region.regC or 0,
			regContext = maskedContext,
			packedContext = maskedContext,
			rawPackedContext = packedContext,
			commitment = commData.commitment,
			jumpId = region.jumpId or 0,
			aluMask = aluMask,
		}
		table.insert(encoded, rPack)
	end
	return encoded
end

return RegionEncoder
