-- This Script is Part of the Zero Lua Obfuscator v4.6
--
-- constant_fragmenter.lua
--
-- Ephemeral Decentralized Constant Fragmenter for Zero Lua v4.6.
-- Decomposes constants into multi-engine ephemeral byte fragment streams.
-- Supports 4 distinct non-linear cipher engines:
-- Engine 1: Cascading Non-Linear Feistel CBC
-- Engine 2: Multi-Degree Horner Polynomial Transform
-- Engine 3: Chained Modular Multi-Prime Diffusion
-- Engine 4: Modular Coprime Multiplicative Affine Permutation

local KeySchedule = require("zerolua.compiler.key_schedule")
local StreamEncoder = require("zerolua.compiler.stream_encoder")

local ConstantFragmenter = {}

function ConstantFragmenter.new(profile, keyMaterial)
	local self = setmetatable({}, { __index = ConstantFragmenter })
	self.profile = profile or {}
	self.keyMaterial = keyMaterial or KeySchedule.generateKeyMaterial((profile and profile.seed) or 1337)
	self.protoSalt = (profile and profile.protoSalt) or 1337
	return self
end

function ConstantFragmenter:fragmentConstant(val, kIdx, protoKey)
	protoKey = protoKey or { 17, 31, 53, 97 }
	local baseSalt = (self.keyMaterial and self.keyMaterial.baseSalt) or 1337
	local mode = (((kIdx * 13 + self.protoSalt * 17) % 4) + 1)

	if type(val) == "string" then
		local bytes = {}
		local _fi = 1
		local prev = (kIdx * 37 + _fi * 41 + self.protoSalt * 7 + (kIdx * kIdx * 3) % 256) % 256
		for j = 1, #val do
			local b = string.byte(val, j)
			local enc = b
			if mode == 1 then
				-- Mode 1: Feistel CBC
				local kVal = protoKey[((kIdx * 7 + _fi * 11 + j * 13 + prev) % #protoKey) + 1] or 42
				local sVal = (baseSalt * 19 + kIdx * 31 + _fi * 47 + j * 23 + kVal * 17 + prev * 13) % 256
				enc = (b + sVal) % 256
				prev = (prev * 31 + enc * 17 + b * 7) % 256
			elseif mode == 2 then
				-- Mode 2: Horner Polynomial
				local kVal = protoKey[((kIdx * 17 + _fi * 19 + j * 23 + prev) % #protoKey) + 1] or 53
				local poly = (((j * 17 + kIdx * 23 + _fi * 43 + prev * 7 + (baseSalt % 256)) % 256) * j + kVal * 13 + 59) % 256
				enc = (b + poly) % 256
				prev = (prev * 41 + enc * 23 + b * 11 + 17) % 256
			elseif mode == 3 then
				-- Mode 3: Multi-Prime Diffusion
				local kVal = protoKey[((kIdx * 31 + _fi * 19 + j * 29 + prev) % #protoKey) + 1] or 79
				local sVal = (baseSalt * 29 + kIdx * 43 + _fi * 53 + j * 37 + kVal * 19 + prev * 11 + 43) % 256
				enc = (b + sVal) % 256
				prev = (prev * 47 + enc * 29 + b * 13 + 31) % 256
			else
				-- Mode 4: Modular Coprime Multiplicative Affine (131 mod 256, inverse 43)
				local kVal = protoKey[((kIdx * 13 + _fi * 29 + j * 17 + prev) % #protoKey) + 1] or 97
				local add = (baseSalt * 11 + kIdx * 19 + _fi * 23 + j * 31 + kVal * 7 + prev * 5) % 256
				enc = (b * 131 + add) % 256
				prev = (prev * 53 + enc * 29 + b * 13 + 37) % 256
			end
			table.insert(bytes, enc)
		end

		local permutedAlphabet = (self.keyMaterial and self.keyMaterial.alphabet) or StreamEncoder.getPermutedAlphabet((self.profile and self.profile.seed) or baseSalt)
		local encoded = StreamEncoder.encodeBase85(bytes, permutedAlphabet)
		return encoded, mode
	elseif type(val) == "number" or type(val) == "boolean" then
		return tostring(val), 0
	else
		return "nil", 0
	end
end

return ConstantFragmenter

