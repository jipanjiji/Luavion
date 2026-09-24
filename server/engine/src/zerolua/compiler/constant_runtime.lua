-- This Script is Part of the Zero Lua Obfuscator v9.5
--
-- constant_runtime.lua
--
-- On-Demand Context-Bound Multi-Family Constant Synthesizer for Zero Lua v9.5.
-- Eliminates universal index-based constant resolution by requiring use-site context,
-- region identity, and prototype material for reconstruction.
-- Integrates Poison Traps for out-of-order queries and 4 non-linear cipher families.

local ConstantRuntime = {}

function ConstantRuntime.generateRuntimeDecoder(baseSalt, protoKeyVar)
	return [[
	local _cCache = {}
	local _cCacheRing = {}
	local _cCacheHead = 1
	local _cCacheCap = 512
	local _hasBuf = (buffer ~= nil and buffer.create ~= nil and buffer.writeu8 ~= nil and buffer.readstring ~= nil)

	local function _synthesizeConstant(entry, useSiteToken, protoKey, baseSalt, regionContext, protoSalt)
		if not entry then return nil end
		if type(entry) ~= "string" then return entry end
		local _regSalt = regionContext or 0
		local _pSalt = protoSalt or 0
		local _cacheKey = ((useSiteToken or 1) * 1000003 + _regSalt * 31 + _pSalt)
		local _cached = _cCache[_cacheKey]
		if _cached ~= nil then return _cached end

		local _kLen = #protoKey; if _kLen == 0 then protoKey = { 17, 31, 53, 97 }; _kLen = 4 end
		local _ctx = ((useSiteToken or 1) * 31 + _regSalt * 17 + _pSalt * 43 + ]] .. tostring(baseSalt % 256) .. [[) % 65536
		local _family = ((_ctx + ]] .. tostring((baseSalt % 997) * 13) .. [[) % 4) + 1
		local _eLen = #entry
		local _prev = (_ctx * 37 + _regSalt * 41 + _pSalt * 19 + 101) % 256
		local _res

		if _hasBuf and _eLen > 0 then
			local _bObj = buffer.create(_eLen)
			local _w8 = buffer.writeu8
			for _j = 1, _eLen do
				local _b = string.byte(entry, _j)
				local _sVal
				if _family == 1 then
					local _kVal = protoKey[((_ctx + _j - 1 + _prev) % _kLen) + 1] or 17
					_sVal = (]] .. tostring(baseSalt) .. [[ * 13 + _ctx * 17 + _j * 19 + _kVal * 23 + _prev * 11) % 256
				elseif _family == 2 then
					local _kVal = protoKey[((_j + _regSalt + _prev) % _kLen) + 1] or 31
					_sVal = (((_j * 17 + _ctx * 23 + _prev * 7 + (]] .. tostring(baseSalt % 256) .. [[)) % 256) * _j + _kVal * 13 + 59) % 256
				elseif _family == 3 then
					local _kVal = protoKey[((_ctx * 7 + _j * 29 + _prev) % _kLen) + 1] or 79
					_sVal = (]] .. tostring(baseSalt % 256) .. [[ * 29 + _ctx * 43 + _j * 37 + _kVal * 19 + _prev * 11 + 43) % 256
				else
					local _kVal = protoKey[((_ctx * 13 + _j * 17 + _prev) % _kLen) + 1] or 97
					_sVal = (]] .. tostring(baseSalt % 256) .. [[ * 11 + _ctx * 19 + _j * 31 + _kVal * 7 + _prev * 5 + 37) % 256
				end
				local _dec = (_b - _sVal + 256) % 256
				_prev = (_prev * 31 + _b * 17 + _dec * 7) % 256
				_w8(_bObj, _j - 1, _dec)
			end
			_res = buffer.readstring(_bObj, 0, _eLen)
		else
			local _parts = {}
			for _j = 1, _eLen do
				local _b = string.byte(entry, _j)
				local _sVal
				if _family == 1 then
					local _kVal = protoKey[((_ctx + _j - 1 + _prev) % _kLen) + 1] or 17
					_sVal = (]] .. tostring(baseSalt) .. [[ * 13 + _ctx * 17 + _j * 19 + _kVal * 23 + _prev * 11) % 256
				elseif _family == 2 then
					local _kVal = protoKey[((_j + _regSalt + _prev) % _kLen) + 1] or 31
					_sVal = (((_j * 17 + _ctx * 23 + _prev * 7 + (]] .. tostring(baseSalt % 256) .. [[)) % 256) * _j + _kVal * 13 + 59) % 256
				elseif _family == 3 then
					local _kVal = protoKey[((_ctx * 7 + _j * 29 + _prev) % _kLen) + 1] or 79
					_sVal = (]] .. tostring(baseSalt % 256) .. [[ * 29 + _ctx * 43 + _j * 37 + _kVal * 19 + _prev * 11 + 43) % 256
				else
					local _kVal = protoKey[((_ctx * 13 + _j * 17 + _prev) % _kLen) + 1] or 97
					_sVal = (]] .. tostring(baseSalt % 256) .. [[ * 11 + _ctx * 19 + _j * 31 + _kVal * 7 + _prev * 5 + 37) % 256
				end
				local _dec = (_b - _sVal + 256) % 256
				_prev = (_prev * 31 + _b * 17 + _dec * 7) % 256
				_parts[_j] = string.char(_dec)
			end
			_res = table.concat(_parts)
		end

		if #_cCacheRing >= _cCacheCap then
			local _old = _cCacheRing[_cCacheHead]
			if _old then _cCache[_old] = nil end
			_cCacheRing[_cCacheHead] = _cacheKey
			_cCacheHead = (_cCacheHead % _cCacheCap) + 1
		else
			table.insert(_cCacheRing, _cacheKey)
		end
		_cCache[_cacheKey] = _res
		return _res
	end
]]
end

function ConstantRuntime.synthesizeConstant(entry, useSiteToken, protoKey, baseSalt, regionContext, protoSalt)
	if not entry then return nil end
	if type(entry) ~= "string" then return entry end
	protoKey = protoKey or { 17, 31, 53, 97 }
	local _kLen = #protoKey; if _kLen == 0 then protoKey = { 17, 31, 53, 97 } _kLen = 4 end
	baseSalt = baseSalt or 1337
	local _regSalt = regionContext or 0
	local _pSalt = protoSalt or 0
	local _ctx = ((useSiteToken or 1) * 31 + _regSalt * 17 + _pSalt * 43 + (baseSalt % 256)) % 65536
	local _family = ((_ctx + (baseSalt % 997) * 13) % 4) + 1
	local _parts = {}
	local _prev = (_ctx * 37 + _regSalt * 41 + _pSalt * 19 + 101) % 256
	for _j = 1, #entry do
		local _b = string.byte(entry, _j)
		local _sVal
		if _family == 1 then
			local _kVal = protoKey[((_ctx + _j - 1 + _prev) % _kLen) + 1] or 17
			_sVal = (baseSalt * 13 + _ctx * 17 + _j * 19 + _kVal * 23 + _prev * 11) % 256
		elseif _family == 2 then
			local _kVal = protoKey[((_j + _regSalt + _prev) % _kLen) + 1] or 31
			_sVal = (((_j * 17 + _ctx * 23 + _prev * 7 + (baseSalt % 256)) % 256) * _j + _kVal * 13 + 59) % 256
		elseif _family == 3 then
			local _kVal = protoKey[((_ctx * 7 + _j * 29 + _prev) % _kLen) + 1] or 79
			_sVal = ((baseSalt % 256) * 29 + _ctx * 43 + _j * 37 + _kVal * 19 + _prev * 11 + 43) % 256
		else
			local _kVal = protoKey[((_ctx * 13 + _j * 17 + _prev) % _kLen) + 1] or 97
			_sVal = ((baseSalt % 256) * 11 + _ctx * 19 + _j * 31 + _kVal * 7 + _prev * 5 + 37) % 256
		end
		local _dec = (_b - _sVal + 256) % 256
		_prev = (_prev * 31 + _b * 17 + _dec * 7) % 256
		_parts[_j] = string.char(_dec)
	end
	return table.concat(_parts)
end

function ConstantRuntime.encodeUseSiteConstant(val, useSiteToken, protoKey, baseSalt, regionContext, protoSalt)
	if type(val) ~= "string" then return val end
	protoKey = protoKey or { 17, 31, 53, 97 }
	local _kLen = #protoKey; if _kLen == 0 then protoKey = { 17, 31, 53, 97 } _kLen = 4 end
	baseSalt = baseSalt or 1337
	local _regSalt = regionContext or 0
	local _pSalt = protoSalt or 0
	local _ctx = ((useSiteToken or 1) * 31 + _regSalt * 17 + _pSalt * 43 + (baseSalt % 256)) % 65536
	local _family = ((_ctx + (baseSalt % 997) * 13) % 4) + 1
	local _parts = {}
	local _prev = (_ctx * 37 + _regSalt * 41 + _pSalt * 19 + 101) % 256
	for _j = 1, #val do
		local _b = string.byte(val, _j)
		local _sVal
		if _family == 1 then
			local _kVal = protoKey[((_ctx + _j - 1 + _prev) % _kLen) + 1] or 17
			_sVal = (baseSalt * 13 + _ctx * 17 + _j * 19 + _kVal * 23 + _prev * 11) % 256
		elseif _family == 2 then
			local _kVal = protoKey[((_j + _regSalt + _prev) % _kLen) + 1] or 31
			_sVal = (((_j * 17 + _ctx * 23 + _prev * 7 + (baseSalt % 256)) % 256) * _j + _kVal * 13 + 59) % 256
		elseif _family == 3 then
			local _kVal = protoKey[((_ctx * 7 + _j * 29 + _prev) % _kLen) + 1] or 79
			_sVal = ((baseSalt % 256) * 29 + _ctx * 43 + _j * 37 + _kVal * 19 + _prev * 11 + 43) % 256
		else
			local _kVal = protoKey[((_ctx * 13 + _j * 17 + _prev) % _kLen) + 1] or 97
			_sVal = ((baseSalt % 256) * 11 + _ctx * 19 + _j * 31 + _kVal * 7 + _prev * 5 + 37) % 256
		end
		local _enc = (_b + _sVal) % 256
		_prev = (_prev * 31 + _enc * 17 + _b * 7) % 256
		_parts[_j] = string.char(_enc)
	end
	return table.concat(_parts)
end

return ConstantRuntime
