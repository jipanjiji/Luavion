-- This Script is Part of the Zero Lua Obfuscator v4.0
--
-- register_mapper.lua
--
-- Non-Linear Multi-Domain Register Permutation System for Zero Lua v4.0.
-- Replaces single-formula mapping with 4 distinct per-domain non-linear layouts.

local RegisterMapper = {}

RegisterMapper.DOMAIN_AFFINE      = 1
RegisterMapper.DOMAIN_SEGMENTED   = 2
RegisterMapper.DOMAIN_QUADRATIC   = 3
RegisterMapper.DOMAIN_INTERLEAVED = 4

function RegisterMapper.new(profile, rng)
	local self = setmetatable({}, { __index = RegisterMapper })
	self.profile = profile or {}
	self.regMul = profile.regMul or 1
	if self.regMul % 2 == 0 then self.regMul = self.regMul + 1 end
	self.regOffset = profile.regOffset or 0
	local d = (profile.semanticProfile and profile.semanticProfile.registerDomain) or 1
	self.domain = ((d - 1) % 4) + 1
	self.regA2 = (profile.regA2 or (((self.regMul * 7 + self.regOffset * 13 + 13) % 8) + 1) * 2)
	if self.regA2 % 2 ~= 0 then self.regA2 = self.regA2 + 1 end
	return self
end

function RegisterMapper:mapLogicalToPhysical(r, regionId)
	r = (((type(r) == "number" and r) or tonumber(r)) or 0) % 65536
	local mul = self.regMul
	local offset = self.regOffset
	if regionId and regionId ~= 0 then
		offset = (offset + regionId * 17) % 65536
	end
	local domain = self.domain

	if domain == RegisterMapper.DOMAIN_SEGMENTED then
		local mul2 = (mul * 5 + 2)
		if mul2 % 2 == 0 then mul2 = mul2 + 1 end
		return (((r * mul2 + offset * 31 + 17) % 65536) + 1)
	elseif domain == RegisterMapper.DOMAIN_QUADRATIC then
		local a2 = self.regA2 or 2
		if a2 % 2 ~= 0 then a2 = a2 + 1 end
		return (((a2 * r * r + mul * r + offset) % 65536) + 1)
	elseif domain == RegisterMapper.DOMAIN_INTERLEAVED then
		local mul4 = (mul * 7 + 4)
		if mul4 % 2 == 0 then mul4 = mul4 + 1 end
		return (((r * mul4 + offset * 13 + 59) % 65536) + 1)
	else
		return (((r * mul + offset) % 65536) + 1)
	end
end

function RegisterMapper.generateRuntimeMapper(regMulVar, regOffsetVar, domain, regA2Var, modVar)
	modVar = modVar or "65536"
	local a2 = regA2Var or "2"
	if domain == RegisterMapper.DOMAIN_SEGMENTED then
		return "function(r) r = (((type(r) == \"number\" and r) or tonumber(r)) or 0) % " .. modVar .. "; local k = math.floor(r / 64); local l = r % 64; return (((l * 4 + k) * " .. regMulVar .. " + " .. regOffsetVar .. ") % " .. modVar .. ") + 1 end"
	elseif domain == RegisterMapper.DOMAIN_QUADRATIC then
		return "function(r) r = (((type(r) == \"number\" and r) or tonumber(r)) or 0) % " .. modVar .. "; return (((" .. a2 .. " * r * r + " .. regMulVar .. " * r + " .. regOffsetVar .. ") % " .. modVar .. ") + 1) end"
	elseif domain == RegisterMapper.DOMAIN_INTERLEAVED then
		return "function(r) r = (((type(r) == \"number\" and r) or tonumber(r)) or 0) % " .. modVar .. "; local l = r % 4; local k = math.floor(r / 4); return (((l * 64 + k) * " .. regMulVar .. " + " .. regOffsetVar .. ") % " .. modVar .. ") + 1 end"
	elseif domain == RegisterMapper.DOMAIN_AFFINE then
		return "function(r) r = (((type(r) == \"number\" and r) or tonumber(r)) or 0) % " .. modVar .. "; return (((r * " .. regMulVar .. " + " .. regOffsetVar .. ") % " .. modVar .. ") + 1) end"
	else
		return "(function(r, d) d = d or 1; r = (((type(r) == \"number\" and r) or tonumber(r)) or 0) % " .. modVar .. "; if d == 2 then local m2 = (" .. regMulVar .. " * 5 + 2); if m2 % 2 == 0 then m2 = m2 + 1 end; return (((r * m2 + " .. regOffsetVar .. " * 31 + 17) % " .. modVar .. ") + 1) elseif d == 3 then return (((" .. a2 .. " * r * r + " .. regMulVar .. " * r + " .. regOffsetVar .. ") % " .. modVar .. ") + 1) elseif d == 4 then local m4 = (" .. regMulVar .. " * 7 + 4); if m4 % 2 == 0 then m4 = m4 + 1 end; return (((r * m4 + " .. regOffsetVar .. " * 13 + 59) % " .. modVar .. ") + 1) else return (((r * " .. regMulVar .. " + " .. regOffsetVar .. ") % " .. modVar .. ") + 1) end end)"
	end
end

return RegisterMapper
