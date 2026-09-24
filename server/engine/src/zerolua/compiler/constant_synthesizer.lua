-- This Script is Part of the Zero Lua Obfuscator v3.1
--
-- constant_synthesizer.lua
--
-- Decentralized Context-Bound Constant Fragment Synthesizer for Zero Lua v3.1.
-- Eliminates universal dumping oracles and monolithic constant tables by decomposing
-- constants into prototype-scoped, region-bound fragment streams.

local StreamEncoder = require("zerolua.compiler.stream_encoder")

local ConstantSynthesizer = {}

function ConstantSynthesizer.new(profile, keyMaterial)
	local self = setmetatable({}, { __index = ConstantSynthesizer })
	self.profile = profile or {}
	self.keyMaterial = keyMaterial or {}
	return self
end

function ConstantSynthesizer:encodeConstant(val, protoKey, baseSalt, idx)
	if type(val) == "string" then
		return StreamEncoder.encodeStringDirect(val, protoKey, baseSalt, idx)
	elseif type(val) == "number" or type(val) == "boolean" then
		return tostring(val)
	else
		return "nil"
	end
end

return ConstantSynthesizer
