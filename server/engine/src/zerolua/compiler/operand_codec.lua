-- This Script is Part of the Zero Lua Obfuscator v3.1
--
-- operand_codec.lua
--
-- Polymorphic Operand Descriptor & Resolution System for Zero Lua v3.1.
-- Replaces rigid fixed-position A/B/C operand formats with dynamic operand descriptors.

local OperandCodec = {}

OperandCodec.TYPE_REGISTER          = 1
OperandCodec.TYPE_CONSTANT_FRAGMENT = 2
OperandCodec.TYPE_TEMPORARY         = 3
OperandCodec.TYPE_UPVALUE           = 4
OperandCodec.TYPE_IMMEDIATE         = 5
OperandCodec.TYPE_STATE_REF         = 6
OperandCodec.TYPE_DERIVED_REF       = 7

OperandCodec.MODE_DIRECT            = 1
OperandCodec.MODE_SWIZZLED          = 2
OperandCodec.MODE_STATE_BOUND       = 3
OperandCodec.MODE_COMPOSITE         = 4

local hasBit32 = type(bit32) == "table" and type(bit32.bxor) == "function"

function OperandCodec.decodeOperand(rawVal, mode, contextKey, regionState, localRole)
	if type(rawVal) == "table" and rawVal.codecMode then
		-- Called as decodeOperand(regionContext, rawField, localRole)
		local ctx = rawVal
		rawVal = mode
		localRole = contextKey
		mode = ctx.codecMode
		contextKey = ctx.contextKey
		regionState = ctx.regionState
	end
	mode = mode or OperandCodec.MODE_DIRECT
	local roleSalt = (localRole or 1) * 7
	contextKey = ((contextKey or 13) + roleSalt) % 256
	regionState = ((regionState or 0) + roleSalt) % 256
	if mode == OperandCodec.MODE_SWIZZLED then
		return ((rawVal or 0) - contextKey + 256) % 256
	elseif mode == OperandCodec.MODE_STATE_BOUND then
		return ((rawVal or 0) - regionState + 256) % 256
	elseif mode == OperandCodec.MODE_COMPOSITE then
		local base = (rawVal or 0) % 16
		local delta = math.floor((rawVal or 0) / 64)
		return (delta * 16 + base) % 256
	else
		return rawVal or 0
	end
end

function OperandCodec.encodeOperand(val, mode, contextKey, regionState, localRole)
	if type(val) == "table" and val.codecMode then
		local ctx = val
		val = mode
		localRole = contextKey
		mode = ctx.codecMode
		contextKey = ctx.contextKey
		regionState = ctx.regionState
	end
	mode = mode or OperandCodec.MODE_DIRECT
	local roleSalt = (localRole or 1) * 7
	contextKey = ((contextKey or 13) + roleSalt) % 256
	regionState = ((regionState or 0) + roleSalt) % 256
	if mode == OperandCodec.MODE_SWIZZLED then
		return ((val or 0) + contextKey) % 256
	elseif mode == OperandCodec.MODE_STATE_BOUND then
		return ((val or 0) + regionState) % 256
	elseif mode == OperandCodec.MODE_COMPOSITE then
		local delta = math.floor((val or 0) / 16) % 4
		local base = (val or 0) % 16
		return delta * 64 + base
	else
		return val or 0
	end
end

function OperandCodec.encodeDescriptor(opType, val)
	return {
		kind = opType or OperandCodec.TYPE_REGISTER,
		value = val or 0
	}
end

function OperandCodec.getArgSlotOffset(layout, argPos, w)
	w = w or 4
	argPos = argPos or 1
	if w == 2 then
		return 1
	elseif w == 3 then
		layout = layout or 0
		if layout == 1 or layout == 2 or layout == 4 then
			return (argPos == 1 and 2) or 1
		else
			return argPos
		end
	end
	layout = layout or 0
	if layout == 1 then
		if argPos == 1 then return 2
		elseif argPos == 2 then return 3
		else return 1 end
	elseif layout == 2 then
		if argPos == 1 then return 3
		elseif argPos == 2 then return 1
		else return 2 end
	elseif layout == 3 then
		if argPos == 1 then return 1
		elseif argPos == 2 then return 3
		else return 2 end
	elseif layout == 4 then
		if argPos == 1 then return 2
		elseif argPos == 2 then return 1
		else return 3 end
	elseif layout == 5 then
		if argPos == 1 then return 3
		elseif argPos == 2 then return 2
		else return 1 end
	else
		return argPos
	end
end

function OperandCodec.new(profile)
	local self = setmetatable({}, { __index = OperandCodec })
	self.profile = profile or {}
	self.mode = (profile.semanticProfile and profile.semanticProfile.operandCodecMode) or 1
	return self
end

function OperandCodec.generateRuntimeDecoder(modeVar, contextKeyVar, regionStateVar)
	return "(function(rawVal, m, k, s, r) m = m or " .. (modeVar or "1") .. "; local rs = ((r or 1)) * 7; k = (((k or " .. (contextKeyVar or "13") .. ") or 0) + rs) % 256; s = (((s or " .. (regionStateVar or "0") .. ") or 0) + rs) % 256; if m == 2 then return (((rawVal or 0) - k + 256)) % 256 elseif m == 3 then return (((rawVal or 0) - s + 256)) % 256 elseif m == 4 then local base = (rawVal or 0) % 16; local delta = math.floor((rawVal or 0) / 64); return (delta * 16 + base) % 256 else return rawVal or 0 end end)"
end

return OperandCodec
