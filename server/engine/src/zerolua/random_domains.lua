-- This Script is Part of the Zero Lua Obfuscator v1.5
--
-- random_domains.lua
--
-- Independent Deterministic Random Streams per Security Domain for Zero Lua V1.5
-- (AST, VM, SEMANTIC, DISPATCH, STREAM, KEYS, CONSTANTS, STRINGS, CFF, JUNK, RUNTIME, DECOY, OBFUSCATION).

local RandomDomains = {}

local function createPRNG(seed)
	local state = math.floor(tonumber(seed) or 123456789)
	if state <= 0 then state = 1 end
	state = state % 2147483647

	local prng = {}

	function prng:next()
		-- Lehmer / Park-Miller PRNG with 31-bit modulus
		state = (state * 16807) % 2147483647
		return state
	end

	function prng:random(min, max)
		local val = self:next()
		if not min then
			return val / 2147483647
		elseif not max then
			return (val % math.floor(min)) + 1
		else
			min = math.floor(min)
			max = math.floor(max)
			if min > max then min, max = max, min end
			local span = (max - min) + 1
			return min + (val % span)
		end
	end

	function prng:shuffle(tbl)
		for i = #tbl, 2, -1 do
			local j = self:random(1, i)
			tbl[i], tbl[j] = tbl[j], tbl[i]
		end
		return tbl
	end

	return prng
end

function RandomDomains.init(masterSeed)
	local root = math.floor(tonumber(masterSeed) or 1)
	if root <= 0 then root = 1 end

	local domainSalts = {
		BUILD = 10007,
		AST = 20011,
		VM = 30013,
		SEMANTIC = 40009,
		GRAPH = 50021,
		REGISTER = 60013,
		OPERAND = 70001,
		CONSTANT = 80021,
		DISPATCH = 90023,
		STREAM = 100003,
		KEYS = 110017,
		CONTROL = 120007,
		CONSTANTS = 130003,
		STRINGS = 140009,
		STRING = 140053,
		CFF = 150001,
		JUNK = 160001,
		RUNTIME = 170003,
		DECOY = 180001,
		OBFUSCATION = 190027,
		REGION = 200003,
		CAPABILITY = 210011,
		INTEGRITY = 220009,
	}

	local seenSalts = {}
	local domains = {}
	for name, salt in pairs(domainSalts) do
		if seenSalts[salt] then
			error("Duplicate salt in RandomDomains for: " .. tostring(name) .. " (collides with " .. tostring(seenSalts[salt]) .. ")", 2)
		end
		seenSalts[salt] = name
		local domainSeed = (root * 1103515245 + salt * 12345 + 6789) % 2147483647
		if domainSeed <= 0 then domainSeed = 1 end
		domains[name] = createPRNG(domainSeed)
	end

	RandomDomains.current = domains
	return domains
end

function RandomDomains.get(domainName)
	if not RandomDomains.current then
		RandomDomains.init(1337)
	end
	local prng = RandomDomains.current[domainName]
	if not prng then
		error("Unknown random domain: " .. tostring(domainName), 2)
	end
	return prng
end

return RandomDomains
