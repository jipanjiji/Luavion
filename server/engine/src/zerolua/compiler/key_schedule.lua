-- This Script is Part of the Zero Lua Obfuscator v4.1
--
-- key_schedule.lua
--
-- Hierarchical Ephemeral Key Derivation & Polymorphic Mapping Engine for Zero Lua v4.1.
-- Multi-tier hierarchical derivation:
-- Build Material -> Prototype Key -> Region Seed -> Stream Key -> Recipe Seed -> Register Layout Seed
-- Plus: Polymorphic Per-Build ALU and Capability Token Permutation Engines.

local RandomDomains = require("zerolua.random_domains")
local StreamEncoder = require("zerolua.compiler.stream_encoder")

local KeySchedule = {}

function KeySchedule.generateKeyMaterial(seed)
	local keysRng = RandomDomains.get("KEYS")
	local baseSalt = (keysRng and keysRng:random(10000, 999999)) or math.random(10000, 999999)
	local buildEntropy = (keysRng and keysRng:random(1, 255)) or math.random(1, 255)
	local mode = (keysRng and keysRng:random(1, 3)) or 1
	local STATE_PRIMES = { 16777213, 16777199, 16777141, 16777093, 16777087, 16777067, 16777039, 16776989 }
	local stateMod = STATE_PRIMES[((baseSalt + (seed or 0)) % #STATE_PRIMES) + 1]
	local alphabet = StreamEncoder.getPermutedAlphabet(baseSalt, stateMod)

	return {
		baseSalt = baseSalt,
		buildEntropy = buildEntropy,
		mode = mode,
		seed = seed or 1337,
		alphabet = alphabet,
		stateMod = stateMod,
	}
end

function KeySchedule.deriveProtoKey(material, protoSalt, streamSalt, mode)
	protoSalt = protoSalt or 17
	streamSalt = streamSalt or 31
	local salt = (material and material.baseSalt) or 54321
	local entropy = (material and material.buildEntropy) or 101
	mode = mode or (material and material.mode) or 1

	if mode == 2 then
		-- Mode 2: Non-Linear Feistel / Permutation Mixing
		local l0 = (salt + protoSalt * 19) % 256
		local r0 = (entropy + streamSalt * 31) % 256
		local f1 = (r0 * 37 + salt * 13) % 256
		local l1 = (l0 + f1) % 256
		local r1 = r0
		local f2 = (l1 * 73 + entropy * 17) % 256
		local r2 = (r1 + f2) % 256
		local l2 = l1
		local k1 = l2
		local k2 = r2
		local k3 = (l2 * 53 + r2 * 89 + protoSalt * 7) % 256
		local k4 = (r2 * 97 + l2 * 11 + streamSalt * 23) % 256
		return { k1, k2, k3, k4 }
	elseif mode == 3 then
		-- Mode 3: Horner Polynomial Hash Key Derivation
		local x = (protoSalt * 13 + streamSalt) % 256
		local k1 = (((salt % 256) * x + entropy) * x + protoSalt * 17) % 256
		local k2 = (((entropy * x + (salt % 256)) * x + streamSalt * 29) % 256 + 13) % 256
		local k3 = (((k1 * x + k2) * x + salt * 7) % 256 + 37) % 256
		local k4 = (((k2 * x + k3) * x + entropy * 19) % 256 + 71) % 256
		return { k1, k2, k3, k4 }
	else
		-- Mode 1: Affine Modular Linear Congruential Key Derivation
		local k1 = (salt * 37 + protoSalt * 13 + streamSalt * 7) % 256
		local k2 = (salt * 73 + protoSalt * 199 + entropy * 17) % 256
		local k3 = (entropy * 53 + protoSalt * 89 + streamSalt * 23) % 256
		local k4 = (salt * 11 + entropy * 97 + streamSalt * 43) % 256
		return { k1, k2, k3, k4 }
	end
end

-- Hierarchical Tier 2: Region Seed Derivation
function KeySchedule.deriveRegionKey(protoKey, regionSalt, mode)
	protoKey = protoKey or { 17, 31, 53, 97 }
	regionSalt = regionSalt or 7
	local k1 = (protoKey[1] * 19 + regionSalt * 31) % 256
	local k2 = (protoKey[2] * 23 + regionSalt * 43) % 256
	local k3 = (protoKey[3] * 29 + regionSalt * 53) % 256
	local k4 = (protoKey[4] * 37 + regionSalt * 61) % 256
	return { k1, k2, k3, k4 }
end

-- Hierarchical Tier 3: Recipe Seed Derivation
function KeySchedule.deriveRecipeSeed(protoKey, opIndex)
	protoKey = protoKey or { 17, 31, 53, 97 }
	opIndex = opIndex or 1
	return (protoKey[1] * 37 + protoKey[2] * 19 + opIndex * 53) % 65536
end

-- Hierarchical Tier 4: Register Layout Seed Derivation
function KeySchedule.deriveRegisterLayoutSeed(protoKey, regionId)
	protoKey = protoKey or { 17, 31, 53, 97 }
	regionId = regionId or 0
	return (protoKey[3] * 41 + protoKey[4] * 67 + regionId * 29) % 65536
end

-- Â§3.1: Dynamic Per-Prototype ALU Token Permutation Derivation
-- Permanently destroys fixed pa=1 (ADD), pa=3 (SUB), pa=4 (MUL) mapping!
function KeySchedule.deriveAluMap(protoKey, seed)
	protoKey = protoKey or { 17, 31, 53, 97 }
	seed = seed or 1337
	local entropy = (protoKey[1] * 31 + protoKey[2] * 53 + seed * 19) % 65536

	-- Standard operations list
	local ops = { "ADD", "ADD_K", "SUB", "MUL", "DIV", "MOD", "POW", "UNM", "NOT", "LEN", "CONCAT" }
	local slots = {}
	for i = 1, #ops do table.insert(slots, i) end

	-- Fisher-Yates shuffle with derived entropy
	for i = #slots, 2, -1 do
		local j = ((entropy * 17 + i * 37) % i) + 1
		slots[i], slots[j] = slots[j], slots[i]
		entropy = (entropy * 53 + 71) % 65536
	end

	local kernels = {
		ADD = function(b, c) if type(b) == "number" and type(c) == "number" then return b - (-c) else return b + c end end,
		ADD_K = function(b, c) if type(b) == "number" and type(c) == "number" then return b - (-c) else return b + c end end,
		SUB = function(b, c) return b - c end,
		MUL = function(b, c) return b * c end,
		DIV = function(b, c) return b / c end,
		MOD = function(b, c) return b % c end,
		POW = function(b, c) return b ^ c end,
		UNM = function(b, c) return -b end,
		NOT = function(b, c) return (b == nil or b == false) end,
		LEN = function(b, c) return (b ~= nil and #b) or 0 end,
		CONCAT = function(b, c) return tostring(b or "") .. tostring(c or "") end,
	}

	local map = {}
	for i, op in ipairs(ops) do
		local slot = slots[i]
		map[op] = slot
		map[slot] = kernels[op]
	end
	return map
end

-- Â§3.2: Dynamic Per-Prototype Host Capability Token Permutation Derivation
-- Permanently destroys fixed capId=1 (INVOKE), capId=2 (CLOSURE), etc.!
function KeySchedule.deriveCapMap(protoKey, seed)
	protoKey = protoKey or { 17, 31, 53, 97 }
	seed = seed or 1337
	local entropy = (protoKey[3] * 43 + protoKey[4] * 67 + seed * 23) % 65536

	local caps = { "INVOKE", "CLOSURE", "RESOLVE_ENV", "VARARG", "CONSTANT", "SET_ENV", "NEW_TABLE" }
	local slots = {}
	for i = 1, #caps do table.insert(slots, i) end

	for i = #slots, 2, -1 do
		local j = ((entropy * 29 + i * 41) % i) + 1
		slots[i], slots[j] = slots[j], slots[i]
		entropy = (entropy * 61 + 83) % 65536
	end

	local map = {}
	for i, cap in ipairs(caps) do
		map[cap] = slots[i]
		map[slots[i]] = cap
	end
	return map
end

-- Â§12.1: Domain Separation Constants
KeySchedule.DOMAINS = {
	BUILD = 1,
	VM = 2,
	KEYS = 3,
	STRING = 4,
	CONSTANT = 5,
	REGISTER = 6,
	GRAPH = 7,
	DISPATCH = 8,
	SEMANTIC = 9,
	REGION = 10,
	CAPABILITY = 11,
	INTEGRITY = 12
}

-- Â§12.1: Domain-Specific Key Material Derivation
function KeySchedule.deriveDomainKey(material, domainName, context)
	local domainId = KeySchedule.DOMAINS[domainName] or 1
	local salt = (material and material.baseSalt) or 54321
	local entropy = (material and material.buildEntropy) or 101
	context = context or 0

	local dSalt = (domainId * 10007 + salt * 17 + context * 31) % 65536
	local k1 = (dSalt * 37 + entropy * 13 + domainId * 41) % 256
	local k2 = (dSalt * 73 + entropy * 59 + domainId * 67 + 19) % 256
	local k3 = (entropy * 53 + dSalt * 23 + domainId * 89 + 71) % 256
	local k4 = (dSalt * 97 + entropy * 71 + domainId * 103 + 109) % 256
	return { k1, k2, k3, k4 }
end

-- Â§12.2: Context-Bound Semantic Binding Key Derivation
function KeySchedule.deriveSemanticBindingKey(protoKey, regionId, semanticClass)
	protoKey = protoKey or { 17, 31, 53, 97 }
	regionId = regionId or 0
	local classSalt = 1
	if type(semanticClass) == "string" then
		for i = 1, #semanticClass do
			classSalt = (classSalt * 31 + string.byte(semanticClass, i)) % 65536
		end
	elseif type(semanticClass) == "number" then
		classSalt = semanticClass % 65536
	end

	local k1 = (protoKey[1] * 37 + regionId * 19 + classSalt * 13) % 256
	local k2 = (protoKey[2] * 41 + regionId * 23 + classSalt * 29) % 256
	local k3 = (protoKey[3] * 47 + regionId * 31 + classSalt * 43) % 256
	local k4 = (protoKey[4] * 53 + regionId * 37 + classSalt * 61) % 256
	return { k1, k2, k3, k4 }
end

-- Â§12.2: Context-Bound PRF Key Construction
function KeySchedule.deriveContextKey(material, domainName, protoId, regionId, slot)
	local domainId = KeySchedule.DOMAINS[domainName] or 1
	local salt = (material and material.baseSalt) or 54321
	local entropy = (material and material.buildEntropy) or 101
	protoId = protoId or 0
	regionId = regionId or 0
	slot = slot or 0

	local x = (salt + protoId * 19 + regionId * 31 + slot * 43 + domainId * 97) % 65536
	local k1 = (((x * 37 + entropy) % 256) * 53 + domainId * 17) % 256
	local k2 = (((x * 47 + entropy * 13) % 256) * 61 + protoId * 23) % 256
	local k3 = (((x * 59 + entropy * 29) % 256) * 71 + regionId * 37) % 256
	local k4 = (((x * 79 + entropy * 43) % 256) * 89 + slot * 47) % 256
	return { k1, k2, k3, k4 }
end

return KeySchedule
