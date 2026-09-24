-- This Script is Part of the Zero Lua Obfuscator v3.1
--
-- semantic_profiles.lua
--
-- Manages prototype-scoped semantic execution profiles for Zero Lua v3.1.
-- Decouples semantic configuration from simple numerical randomization,
-- ensuring each prototype receives independent graph templates, micro-node vocabularies,
-- register domains, operand decoders, and constant consumption strategies.

local RandomDomains = require("zerolua.random_domains")

local SemanticProfiles = {}

function SemanticProfiles.createSemanticProfile(protoId, seed, profileLevel)
	local rng = RandomDomains.get("SEMANTIC") or RandomDomains.get("VM")
	protoId = protoId or 0
	profileLevel = profileLevel or "EXTREME"

	local graphStrategy = rng:random(1, 4)
	local registerDomain = rng:random(1, 8)
	local operandCodecMode = rng:random(1, 4)
	local constantStrategy = rng:random(1, 3)
	local dispatchTopology = rng:random(1, 4)
	local stateSlotCount = rng:random(4, 12)

	local tokenDomain = rng:random(11, 241)
	local stateDisplacement = rng:random(3, 97)
	local resolverDomain = ((seed or 1337) * 31 + protoId * 17 + rng:random(100, 9999)) % 65536

	return {
		protoId = protoId,
		profileLevel = profileLevel,
		graphStrategy = graphStrategy,
		registerDomain = registerDomain,
		operandCodecMode = operandCodecMode,
		constantStrategy = constantStrategy,
		dispatchTopology = dispatchTopology,
		stateSlotCount = stateSlotCount,
		tokenDomain = tokenDomain,
		stateDisplacement = stateDisplacement,
		resolverDomain = resolverDomain,
	}
end

return SemanticProfiles
