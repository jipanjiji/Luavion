-- This Script is Part of the Zero Lua Obfuscator v1.4
--
-- block_encoder.lua
--
-- Implements Basic Block partitioning, hierarchical key schedules,
-- and per-block lazy encryption/decryption encoding.

local BlockEncoder = {}

-- Stream cipher generator (polymorphic state mixing per block)
function BlockEncoder.streamCipher(keyBytes, count, salt)
	salt = salt or 0
	local S = {}
	for i = 0, 255 do
		S[i] = i
	end
	local j = 0
	local kLen = #keyBytes
	for i = 0, 255 do
		local kByte = keyBytes[(i % kLen) + 1] or 0
		j = (j + S[i] + kByte + salt * 7) % 256
		S[i], S[j] = S[j], S[i]
	end

	local keystream = {}
	local i = 0
	j = 0
	for idx = 1, count do
		i = (i + 1) % 256
		j = (j + S[i]) % 256
		S[i], S[j] = S[j], S[i]
		keystream[idx] = S[(S[i] + S[j]) % 256]
	end
	return keystream
end

-- Hierarchical key derivation:
-- Prototype Key -> Block Key -> Ephemeral Instruction Key
function BlockEncoder.deriveBlockKey(protoKeyBytes, blockIdx, blockSalt)
	local blockKey = {}
	local pLen = #protoKeyBytes
	blockSalt = blockSalt or (blockIdx * 29)
	for i = 1, pLen do
		local pb = protoKeyBytes[i] or 0
		local derived = (pb * 3 + blockIdx * 37 + blockSalt * 13 + i * 19) % 256
		table.insert(blockKey, derived)
	end
	return blockKey
end

-- Encodes a flat array of integer words into an encrypted byte string for a specific block
function BlockEncoder.encodeBlock(words, blockKeyBytes, blockSalt)
	local rawBytes = {}
	for i = 1, #words do
		local val = words[i] or 0
		local u16 = (val + 32768) % 65536
		local b1 = u16 % 256
		local b2 = math.floor(u16 / 256) % 256
		table.insert(rawBytes, b1)
		table.insert(rawBytes, b2)
	end

	local ks = BlockEncoder.streamCipher(blockKeyBytes, #rawBytes, blockSalt)
	local parts = {}
	for idx = 1, #rawBytes do
		local enc = (rawBytes[idx] + ks[idx]) % 256
		local m = (idx + (blockKeyBytes[2] or 0) + (blockSalt or 0)) % 3
		if m == 0 then
			table.insert(parts, string.format("\\x%02X", enc))
		elseif m == 1 then
			table.insert(parts, string.format("\\%03d", enc))
		else
			table.insert(parts, string.format("\\x%02x", enc))
		end
	end
	return '"' .. table.concat(parts) .. '"'
end

-- Partition a linear instruction stream into basic blocks (e.g. max 12-16 instructions per block or branch targets)
function BlockEncoder.partitionIntoBlocks(code, opcodes, opcodeWidths, operandLayout)
	-- In v1.4, block partitioning breaks the bytecode into discrete blocks
	-- If code is small (<= 20 words), single block is preserved for efficiency.
	-- For larger code, consecutive blocks of ~16 instructions are formed.
	local blocks = {}
	local blockSize = 48 -- words per block (e.g. 12 instructions of width 4)
	local totalWords = #code

	if totalWords <= blockSize then
		table.insert(blocks, {
			id = 1,
			startWord = 1,
			endWord = totalWords,
			words = code
		})
	else
		local currStart = 1
		local blkId = 1
		while currStart <= totalWords do
			local currEnd = math.min(currStart + blockSize - 1, totalWords)
			local blkWords = {}
			for w = currStart, currEnd do
				table.insert(blkWords, code[w])
			end
			table.insert(blocks, {
				id = blkId,
				startWord = currStart,
				endWord = currEnd,
				words = blkWords
			})
			blkId = blkId + 1
			currStart = currEnd + 1
		end
	end

	return blocks
end

return BlockEncoder
