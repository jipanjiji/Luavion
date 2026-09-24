-- This Script is Part of the Zero Lua Obfuscator v2.2
--
-- stream_encoder.lua
--
-- Streaming Bytecode & Chunk Encoder for Zero Lua V2.2.
-- Uses standard 3-digit decimal byte escaping (\ddd) for 100% cross-version compatibility
-- across Lua 5.1, Lua 5.2, Lua 5.3, Lua 5.4, Luau, and LuaJIT.

local RandomDomains = require("zerolua.random_domains")

local StreamEncoder = {}

local function deriveStreamByte(keyBytes, protoSalt, pos)
	local kLen = #keyBytes
	if kLen == 0 then keyBytes = { 17, 31, 53, 97 } kLen = 4 end
	local kVal = keyBytes[((pos - 1) % kLen) + 1] or 17
	local k2 = keyBytes[((pos * 3 - 1) % kLen) + 1] or 31
	local s0 = (kVal * 37 + protoSalt * 19 + pos * 23 + 71) % 256
	local s1 = (k2 * 53 + protoSalt * 37 + pos * 31 + 137) % 256
	local f1 = (s0 * 73 + s1 * 89 + kVal * 31 + protoSalt * 43) % 256
	local f2 = (s1 * 47 + s0 * 59 + k2 * 17 + pos * 29) % 256
	return (f1 * 53 + f2 * 67 + pos * 41) % 256
end

local function genKeystream(keyBytes, length, protoSalt)
	protoSalt = protoSalt or 17
	local ks = {}
	for i = 1, length do
		ks[i] = deriveStreamByte(keyBytes, protoSalt, i)
	end
	return ks
end

StreamEncoder.deriveStreamByte = deriveStreamByte
StreamEncoder.genKeystream = genKeystream

local DEFAULT_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&()*+-;<=>?@^_[]{|}"
StreamEncoder.BASE85_ALPHABET = DEFAULT_ALPHABET

local BYTE_ESCAPES = {}
for i = 0, 255 do
	BYTE_ESCAPES[i] = string.format("\\%03d", i)
end
StreamEncoder.BYTE_ESCAPES = BYTE_ESCAPES

function StreamEncoder.getPermutedAlphabet(seed, stateMod)
	stateMod = stateMod or 16777213
	local chars = {}
	for i = 33, 125 do
		if i ~= 34 and i ~= 39 and i ~= 44 and i ~= 46 and i ~= 47 and i ~= 58 and i ~= 92 and i ~= 96 then
			chars[#chars + 1] = string.char(i)
		end
	end
	local baseSalt = seed or 1337
	local prngMul = (baseSalt * 17 + 31337) % 65536
	if prngMul % 2 == 0 then prngMul = prngMul + 1 end
	local prngAdd = (baseSalt * 31 + 1013) % 65536
	local k1 = ((baseSalt * 7 + 13) % 256) + 1
	local k2 = ((baseSalt * 11 + 31) % 256) + 1
	local s = (baseSalt * k1 + 37 * k2) % stateMod
	for i = #chars, 2, -1 do
		s = (s * prngMul + prngAdd) % stateMod
		local j = (s % i) + 1
		chars[i], chars[j] = chars[j], chars[i]
	end
	return table.concat(chars)
end

function StreamEncoder.encodeBase85(rawBytes, alphabet)
	alphabet = alphabet or DEFAULT_ALPHABET
	local radix = #alphabet
	local floor = math.floor
	local len = #rawBytes
	local alphaChars = {}
	for i = 1, radix do
		alphaChars[i] = string.sub(alphabet, i, i)
	end
	local out = {}
	local outCount = 0
	local idx = 1
	while idx <= len do
		local rem = len - idx + 1
		local count = rem >= 4 and 4 or rem
		local b1 = rawBytes[idx] or 0
		local b2 = rawBytes[idx + 1] or 0
		local b3 = rawBytes[idx + 2] or 0
		local b4 = rawBytes[idx + 3] or 0
		idx = idx + count

		local acc = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
		local chars = {}
		for i = 5, 1, -1 do
			local code = (acc % radix) + 1
			chars[i] = alphaChars[code]
			acc = floor(acc / radix)
		end

		outCount = outCount + 1
		out[outCount] = table.concat(chars, "", 1, count + 1)
	end
	return table.concat(out)
end

function StreamEncoder.getEncryptedStreamBytes(codeArr, keyBytes, protoSalt)
	local rawBytes = {}
	for i = 1, #codeArr do
		local val = codeArr[i] or 0
		local u16 = (val + 32768) % 65536
		local b1 = u16 % 256
		local b2 = math.floor(u16 / 256) % 256
		table.insert(rawBytes, b1)
		table.insert(rawBytes, b2)
	end

	local ks = genKeystream(keyBytes, #rawBytes, protoSalt)
	local encBytes = {}
	for idx = 1, #rawBytes do
		local enc = (rawBytes[idx] + ks[idx]) % 256
		table.insert(encBytes, enc)
	end
	return encBytes
end

function StreamEncoder.encodeStream(codeArr, keyBytes, alphabet, protoSalt)
	alphabet = alphabet or DEFAULT_ALPHABET
	local encBytes = StreamEncoder.getEncryptedStreamBytes(codeArr, keyBytes, protoSalt)
	return StreamEncoder.encodeBase85(encBytes, alphabet or DEFAULT_ALPHABET)
end

function StreamEncoder.buildFragmentPool(stringList, keyBytes, baseSalt)
	baseSalt = baseSalt or 1337
	local fragMap = {}
	local fragments = {}
	local function addFrag(f)
		if not fragMap[f] then
			table.insert(fragments, f)
			fragMap[f] = #fragments
		end
		return fragMap[f]
	end

	local strChains = {}
	for sIdx, str in ipairs(stringList) do
		local chain = {}
		local len = #str
		if len == 0 then
			local fId = addFrag("")
			table.insert(chain, fId)
		else
			local pos = 1
			while pos <= len do
				local chunkLen = 2
				if (pos + 2 <= len) and ((pos % 2) == 0) then
					chunkLen = 3
				elseif pos == len then
					chunkLen = 1
				end
				local sub = str:sub(pos, pos + chunkLen - 1)
				local fId = addFrag(sub)
				table.insert(chain, fId)
				pos = pos + chunkLen
			end
		end
		strChains[sIdx] = chain
	end

	-- Encrypt each fragment in the pool with keystream
	local encFrags = {}
	local kLen = #keyBytes
	if kLen == 0 then keyBytes = { 17, 31, 53, 97 } kLen = 4 end
	for idx, frag in ipairs(fragments) do
		local parts = {}
		for j = 1, #frag do
			local b = string.byte(frag, j)
			local sVal = (baseSalt * 13 + idx * 17 + j * 19 + keyBytes[((idx - 1) % kLen) + 1]) % 256
			local enc = (b + sVal) % 256
			parts[j] = BYTE_ESCAPES[enc]
		end
		table.insert(encFrags, '"' .. table.concat(parts) .. '"')
	end

	return fragments, encFrags, strChains
end

function StreamEncoder.encodeSplitString(str, keyBytes, salt, seedIdx)
	salt = salt or 1337
	seedIdx = seedIdx or 1
	local kLen = #keyBytes
	if kLen == 0 then keyBytes = { 1, 2, 3, 4 } kLen = 4 end
	local partsA = {}
	local partsB = {}
	for j = 1, #str do
		local x = string.byte(str, j)
		local s1 = (salt * 7 + j * 13 + seedIdx * 17) % 256
		local s2 = (keyBytes[((j - 1) % kLen) + 1] + j * 11 + seedIdx * 19) % 256
		local a = (3 * x + s1) % 256
		local b = (5 * x + s2) % 256
		partsA[j] = BYTE_ESCAPES[a]
		partsB[j] = BYTE_ESCAPES[b]
	end
	return table.concat(partsA), table.concat(partsB)
end

function StreamEncoder.encodeStringDirect(str, keyBytes, baseSalt, idx)
	baseSalt = baseSalt or 1337
	idx = idx or 1
	local kLen = #keyBytes
	if kLen == 0 then keyBytes = { 17, 31, 53, 97 } kLen = 4 end
	local parts = {}
	for j = 1, #str do
		local b = string.byte(str, j)
		local sVal = (baseSalt * 13 + idx * 17 + j * 19 + keyBytes[((idx + j - 1) % kLen) + 1]) % 256
		local enc = (b + sVal) % 256
		parts[j] = BYTE_ESCAPES[enc]
	end
	return table.concat(parts)
end

function StreamEncoder.encodeByteStreamDirect(byteArr)
	local parts = {}
	for _, b in ipairs(byteArr or {}) do
		parts[#parts + 1] = BYTE_ESCAPES[b % 256] or string.format("\\%03d", b % 256)
	end
	return table.concat(parts)
end

return StreamEncoder
