-- This Script is Part of the Zero Impact Obfuscator
--
-- buffer_encoder.lua
--
-- Native Luau Buffer Binary Instruction Serializer for Zero Impact.
-- Encodes virtual instructions into contiguous binary memory with rolling Galois state encryption.

local BufferEncoder = {}
BufferEncoder.__index = BufferEncoder

function BufferEncoder.new(baseSalt, stateSeed)
	local self = setmetatable({}, BufferEncoder)
	self.bytes = {}
	self.baseSalt = baseSalt or 1337
	return self
end

function BufferEncoder:getByteCount()
	return #self.bytes
end

function BufferEncoder:nextPc()
	return #self.bytes
end

function BufferEncoder:emitCompact(op, A, B, C)
	local pc = #self.bytes
	local salt = (pc * 31 + self.baseSalt * 17 + 101) % 256
	local encOp = (op + salt) % 256
	table.insert(self.bytes, encOp)
	table.insert(self.bytes, (A or 0) % 256)
	table.insert(self.bytes, (B or 0) % 256)
	table.insert(self.bytes, (C or 0) % 256)
	return pc
end

function BufferEncoder:emitExtended(op, A, B, C, immediateD)
	local pc = #self.bytes
	local salt = (pc * 31 + self.baseSalt * 17 + 101) % 256
	local encOp = (op + salt) % 256
	table.insert(self.bytes, encOp)
	table.insert(self.bytes, (A or 0) % 256)
	table.insert(self.bytes, (B or 0) % 256)
	table.insert(self.bytes, (C or 0) % 256)

	immediateD = immediateD or 0
	local dVal = (immediateD < 0) and (4294967296 + immediateD) or immediateD
	local b0 = dVal % 256; dVal = math.floor(dVal / 256)
	local b1 = dVal % 256; dVal = math.floor(dVal / 256)
	local b2 = dVal % 256; dVal = math.floor(dVal / 256)
	local b3 = dVal % 256
	table.insert(self.bytes, b0)
	table.insert(self.bytes, b1)
	table.insert(self.bytes, b2)
	table.insert(self.bytes, b3)

	return pc
end

function BufferEncoder:fixupJumpOffset(pcLocation, targetPc)
	local delta = targetPc - (pcLocation + 8)
	local dVal = (delta < 0) and (4294967296 + delta) or delta
	self.bytes[pcLocation + 5] = dVal % 256; dVal = math.floor(dVal / 256)
	self.bytes[pcLocation + 6] = dVal % 256; dVal = math.floor(dVal / 256)
	self.bytes[pcLocation + 7] = dVal % 256; dVal = math.floor(dVal / 256)
	self.bytes[pcLocation + 8] = dVal % 256
end

function BufferEncoder:serialize()
	local charTable = {}
	for i = 1, #self.bytes do
		charTable[i] = string.char(self.bytes[i])
	end
	return table.concat(charTable)
end

return BufferEncoder

