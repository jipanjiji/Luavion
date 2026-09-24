-- This Script is Part of the Zero Lua Obfuscator v4.0
--
-- region_decoder.lua
--
-- Runtime Chained Rolling-State Stream Unwinder for Zero Lua v4.0.
-- Sequentially decodes context-dependent micro-op byte streams.

local RegionDecoder = {}

function RegionDecoder.decodeRegionStream(stream, baseSalt, regionIdx, codecMode, contextKey, regionState, regDomain, protoKey, chainToken, predCommitment)
	codecMode = codecMode or 1
	contextKey = contextKey or 13
	regionState = regionState or 0
	regDomain = regDomain or 1
	protoKey = protoKey or { 17, 31, 53, 97 }
	local _pkLen = #protoKey; if _pkLen == 0 then protoKey = { 17, 31, 53, 97 }; _pkLen = 4 end
	chainToken = chainToken or ((regionIdx * 1337 + baseSalt * 31 + (protoKey[1] or 17) * 53 + (protoKey[2] or 31) * 17 + 101) % 65536)
	local layoutMode = ((regDomain * 3 + codecMode * 5 + regionState * 7) % 8)
	local nodes = {}
	local rolling = (baseSalt * 17 + regionIdx * 31 + contextKey * 19 + regionState * 13 + codecMode * 29 + (chainToken % 256) * 7) % 256
	local nodeIdx = 1

	local _predComm = predCommitment or 1337
	local _stateVal = (regionIdx * 31 + 101) % 65536
	local _laneA = (_predComm * 31 + regionIdx * 17 + 5381) % 65536
	local _laneB = (_stateVal * 43 + (protoKey[1] or 17) * 23 + 31337) % 65536
	local _laneC = ((protoKey[2] or 31) * 73 + (protoKey[3] or 53) * 19 + 7919) % 65536

	local i = 1
	local streamLen = (stream and #stream) or 0
	while i <= streamLen do
		local rawBytes = {}
		for bIdx = 1, 10 do
			local enc = stream[i]
			if not enc then break end
			local pkByte = protoKey[((bIdx + regionIdx - 1) % _pkLen) + 1] or 17
			local bVal = (enc - rolling * 37 - baseSalt * 13 - contextKey * 7 - bIdx * 19 - codecMode * 11 - pkByte * 17) % 256
			rawBytes[bIdx] = bVal
			rolling = (rolling * 53 + enc * 17 + bVal * 7 + nodeIdx * 11 + regionState * 3 + pkByte * 13) % 256
			i = i + 1
		end

		if #rawBytes == 10 then
			local c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi
			if layoutMode == 1 then
				pa, c, s1_lo, s1_hi, d_lo, d_hi, pb_lo, pb_hi, s2_lo, s2_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 2 then
				d_lo, d_hi, c, pa, s2_lo, s2_hi, s1_lo, s1_hi, pb_lo, pb_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 3 then
				s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi, d_lo, d_hi, c, pa =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 4 then
				pb_lo, pb_hi, pa, c, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 5 then
				s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi, c, pa, pb_lo, pb_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 6 then
				d_lo, d_hi, s1_lo, s1_hi, pb_lo, pb_hi, c, pa, s2_lo, s2_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			elseif layoutMode == 7 then
				pa, c, pb_lo, pb_hi, s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			else
				c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi =
					rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
			end

			local mopA = ((contextKey % 7) * 2 + 1)
			local mopB = (contextKey * 3 + regionIdx * 5) % 16
			local invA = (mopA == 1 and 1) or (mopA == 3 and 11) or (mopA == 5 and 13) or (mopA == 7 and 7) or (mopA == 9 and 9) or (mopA == 11 and 3) or (mopA == 13 and 5) or 15
			local c_dec = ((c - mopB + 160) * invA) % 16
			if c_dec == 0 then c_dec = 16 end
			c = c_dec

			local d = d_lo + d_hi * 256
			if d >= 32768 then d = d - 65536 end
			local s1 = s1_lo + s1_hi * 256
			if s1 >= 32768 then s1 = s1 - 65536 end
			local s2 = s2_lo + s2_hi * 256
			if s2 >= 32768 then s2 = s2 - 65536 end
			local pb = pb_lo + pb_hi * 256
			if pb >= 32768 then pb = pb - 65536 end

			table.insert(nodes, { c, d, s1, s2, pa, pb })
			nodeIdx = nodeIdx + 1
		else
			break
		end
	end

	return nodes
end

function RegionDecoder.generateRuntimeDecoder()
	return [=[(function()
		local _hasBuf = (buffer ~= nil and buffer.create ~= nil and buffer.readu8 ~= nil and buffer.writeu8 ~= nil)
		local _workBuf = _hasBuf and buffer.create(10) or nil
		local _wRead = _hasBuf and buffer.readu8 or nil
		local _wWrite = _hasBuf and buffer.writeu8 or nil

		return function(stream, baseSalt, regionIdx, codecMode, contextKey, regionState, regDomain, protoKey, chainToken, predCommitment)
		codecMode = codecMode or 1
		contextKey = contextKey or 13
		regionState = regionState or 0
		regDomain = regDomain or 1
		protoKey = protoKey or { 17, 31, 53, 97 }
		local _pkLen = #protoKey; if _pkLen == 0 then protoKey = { 17, 31, 53, 97 }; _pkLen = 4 end
		chainToken = chainToken or ((regionIdx * 1337 + baseSalt * 31 + (protoKey[1] or 17) * 53 + (protoKey[2] or 31) * 17 + 101) % 65536)
		local layoutMode = ((regDomain * 3 + codecMode * 5 + regionState * 7) % 8)
		local nodes = {}
		local rolling = (baseSalt * 17 + regionIdx * 31 + contextKey * 19 + regionState * 13 + codecMode * 29 + (chainToken % 256) * 7) % 256
		local nodeIdx = 1
		local i = 1
		local streamLen = (stream and #stream) or 0

		local _predComm = predCommitment or 1337
		local _stateVal = (regionIdx * 31 + 101) % 65536
		local _laneA = (_predComm * 31 + regionIdx * 17 + 5381) % 65536
		local _laneB = (_stateVal * 43 + (protoKey[1] or 17) * 23 + 31337) % 65536
		local _laneC = ((protoKey[2] or 31) * 73 + (protoKey[3] or 53) * 19 + 7919) % 65536

		if _hasBuf and streamLen >= 10 then
			while i <= streamLen do
				for bIdx = 1, 10 do
					local enc = stream[i]
					if not enc then break end
					local pkByte = protoKey[((bIdx + regionIdx - 1) % _pkLen) + 1] or 17
					local bVal = (enc - rolling * 37 - baseSalt * 13 - contextKey * 7 - bIdx * 19 - codecMode * 11 - pkByte * 17) % 256
					_wWrite(_workBuf, bIdx - 1, bVal)
					rolling = (rolling * 53 + enc * 17 + bVal * 7 + nodeIdx * 11 + regionState * 3 + pkByte * 13) % 256
					i = i + 1
				end
				if i - 1 >= 10 * nodeIdx then
					local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10 =
						_wRead(_workBuf, 0), _wRead(_workBuf, 1), _wRead(_workBuf, 2), _wRead(_workBuf, 3), _wRead(_workBuf, 4),
						_wRead(_workBuf, 5), _wRead(_workBuf, 6), _wRead(_workBuf, 7), _wRead(_workBuf, 8), _wRead(_workBuf, 9)
					local c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi
					if layoutMode == 1 then
						pa, c, s1_lo, s1_hi, d_lo, d_hi, pb_lo, pb_hi, s2_lo, s2_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 2 then
						d_lo, d_hi, c, pa, s2_lo, s2_hi, s1_lo, s1_hi, pb_lo, pb_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 3 then
						s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi, d_lo, d_hi, c, pa = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 4 then
						pb_lo, pb_hi, pa, c, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 5 then
						s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi, c, pa, pb_lo, pb_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 6 then
						d_lo, d_hi, s1_lo, s1_hi, pb_lo, pb_hi, c, pa, s2_lo, s2_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					elseif layoutMode == 7 then
						pa, c, pb_lo, pb_hi, s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					else
						c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi = b1, b2, b3, b4, b5, b6, b7, b8, b9, b10
					end
					local _mA = ((contextKey % 7) * 2 + 1)
					local _mB = (contextKey * 3 + regionIdx * 5) % 16
					local _invA = (_mA == 1 and 1) or (_mA == 3 and 11) or (_mA == 5 and 13) or (_mA == 7 and 7) or (_mA == 9 and 9) or (_mA == 11 and 3) or (_mA == 13 and 5) or 15
					local _c_dec = ((c - _mB + 160) * _invA) % 16
					if _c_dec == 0 then _c_dec = 16 end
					c = _c_dec

					local d = d_lo + d_hi * 256; if d >= 32768 then d = d - 65536 end
					local s1 = s1_lo + s1_hi * 256; if s1 >= 32768 then s1 = s1 - 65536 end
					local s2 = s2_lo + s2_hi * 256; if s2 >= 32768 then s2 = s2 - 65536 end
					local pb = pb_lo + pb_hi * 256; if pb >= 32768 then pb = pb - 65536 end
					nodes[nodeIdx] = { c, d, s1, s2, pa, pb }
					_laneA = (_laneA * 37 + c * 19 + d * 11 + nodeIdx * 7) % 65536
					_laneB = (_laneB * 41 + s1 * 23 + s2 * 13 + pa * 17 + pb * 7 + c * 5) % 65536
					_laneC = (_laneC * 47 + c * 29 + (protoKey[((nodeIdx % 4) + 1)] or 17) * 11) % 65536
					nodeIdx = nodeIdx + 1
				else
					break
				end
			end
			local _calcComm = (_laneA * 31 + _laneB * 17 + _laneC * 13) % 65536
			return nodes, _calcComm
		end
		while i <= streamLen do
			local rawBytes = {}
			for bIdx = 1, 10 do
				local enc = stream[i]
				if not enc then break end
				local pkByte = protoKey[((bIdx + regionIdx - 1) % _pkLen) + 1] or 17
				local bVal = (enc - rolling * 37 - baseSalt * 13 - contextKey * 7 - bIdx * 19 - codecMode * 11 - pkByte * 17) % 256
				rawBytes[bIdx] = bVal
				rolling = (rolling * 53 + enc * 17 + bVal * 7 + nodeIdx * 11 + regionState * 3 + pkByte * 13) % 256
				i = i + 1
			end
			if #rawBytes == 10 then
				local c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi
				if layoutMode == 1 then
					pa, c, s1_lo, s1_hi, d_lo, d_hi, pb_lo, pb_hi, s2_lo, s2_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 2 then
					d_lo, d_hi, c, pa, s2_lo, s2_hi, s1_lo, s1_hi, pb_lo, pb_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 3 then
					s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi, d_lo, d_hi, c, pa =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 4 then
					pb_lo, pb_hi, pa, c, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 5 then
					s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi, c, pa, pb_lo, pb_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 6 then
					d_lo, d_hi, s1_lo, s1_hi, pb_lo, pb_hi, c, pa, s2_lo, s2_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				elseif layoutMode == 7 then
					pa, c, pb_lo, pb_hi, s2_lo, s2_hi, d_lo, d_hi, s1_lo, s1_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				else
					c, pa, d_lo, d_hi, s1_lo, s1_hi, s2_lo, s2_hi, pb_lo, pb_hi =
						rawBytes[1], rawBytes[2], rawBytes[3], rawBytes[4], rawBytes[5], rawBytes[6], rawBytes[7], rawBytes[8], rawBytes[9], rawBytes[10]
				end
				local _mA = ((contextKey % 7) * 2 + 1)
				local _mB = (contextKey * 3 + regionIdx * 5) % 16
				local _invA = (_mA == 1 and 1) or (_mA == 3 and 11) or (_mA == 5 and 13) or (_mA == 7 and 7) or (_mA == 9 and 9) or (_mA == 11 and 3) or (_mA == 13 and 5) or 15
				local _c_dec = ((c - _mB + 160) * _invA) % 16
				if _c_dec == 0 then _c_dec = 16 end
				c = _c_dec

				local d = d_lo + d_hi * 256
				if d >= 32768 then d = d - 65536 end
				local s1 = s1_lo + s1_hi * 256
				if s1 >= 32768 then s1 = s1 - 65536 end
				local s2 = s2_lo + s2_hi * 256
				if s2 >= 32768 then s2 = s2 - 65536 end
				local pb = pb_lo + pb_hi * 256
				if pb >= 32768 then pb = pb - 65536 end
				nodes[nodeIdx] = { c, d, s1, s2, pa, pb }
				_laneA = (_laneA * 37 + c * 19 + d * 11 + nodeIdx * 7) % 65536
				_laneB = (_laneB * 41 + s1 * 23 + s2 * 13 + pa * 17 + pb * 7 + c * 5) % 65536
				_laneC = (_laneC * 47 + c * 29 + (protoKey[((nodeIdx % 4) + 1)] or 17) * 11) % 65536
				nodeIdx = nodeIdx + 1
			else
				break
			end
		end
		local _calcComm = (_laneA * 31 + _laneB * 17 + _laneC * 13) % 65536
		return nodes, _calcComm
	end
end)()]=]
end

return RegionDecoder
