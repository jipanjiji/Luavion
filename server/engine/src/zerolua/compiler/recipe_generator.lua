-- This Script is Part of the Zero Lua Obfuscator v4.3
--
-- recipe_generator.lua
--
-- Dynamic Polymorphic Recipe Selection Engine for Zero Lua v4.3.
-- Selects distinct micro-graph recipes per prototype, region, and operation index
-- using non-linear hierarchical derivation, dynamic opcode indirection (Â§2.4),
-- and applies dynamic ALU/Cap mappings across decentralized kernel families (Â§2.1).

local RecipeCatalog = require("zerolua.compiler.recipe_catalog")
local KeySchedule = require("zerolua.compiler.key_schedule")
local MicroISA = require("zerolua.compiler.micro_isa")

local RecipeGenerator = {}

-- Opcode Symbol Table Hash (Â§2.4 Indirection)
local function hashOpName(name, salt)
	local h = salt or 1337
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 65536
	end
	return h
end

function RecipeGenerator.new(profile, keyMaterial)
	local self = setmetatable({}, { __index = RecipeGenerator })
	self.profile = profile or {}
	self.keyMaterial = keyMaterial or KeySchedule.generateKeyMaterial((profile and profile.seed) or 1337)
	local baseSalt = (self.keyMaterial and self.keyMaterial.baseSalt) or (profile and profile.seed) or 1337
	self.microOpMap = (profile and profile.microOpcodeMap) or MicroISA.getOpcodePermutation(baseSalt)
	if profile and not profile.microOpcodeMap then
		profile.microOpcodeMap = self.microOpMap
	end
	self.protoSalt = (profile and profile.protoSalt) or 1337
	self.protoKey = (profile and profile.protoKey) or KeySchedule.deriveProtoKey(self.keyMaterial, self.protoSalt, 64, (profile and profile.keyMode) or 1)
	self.aluMap = (profile and profile.aluMap) or KeySchedule.deriveAluMap(self.protoKey, (profile and profile.seed) or 1337)
	self.capMap = (profile and profile.capMap) or KeySchedule.deriveCapMap(self.protoKey, (profile and profile.seed) or 1337)
	self.opCounter = 0

	-- Build Indirect Opcode Resolution Table (Â§2.4)
	self.opcodeIndirection = {}
	for k, v in pairs(RecipeCatalog.RECIPES) do
		local hashedKey = hashOpName(k, self.protoSalt)
		local bucket = self.opcodeIndirection[hashedKey]
		if not bucket then
			bucket = {}
			self.opcodeIndirection[hashedKey] = bucket
		end
		bucket[k] = v
	end

	return self
end

function RecipeGenerator:resolveOpcodeVariants(opName)
	if not opName then return nil end
	local hashedKey = hashOpName(opName, self.protoSalt)
	local bucket = self.opcodeIndirection[hashedKey]
	local variants = bucket and bucket[opName]
	if not variants then
		variants = RecipeCatalog.RECIPES[opName]
	end
	return variants
end

function RecipeGenerator:generateRecipe(opName, A, B, C, regionId)
	self.opCounter = self.opCounter + 1
	local variants = self:resolveOpcodeVariants(opName)

	if not variants or #variants == 0 then
		return {}
	end

	-- Non-linear Feistel/Horner mixing for variant & kernel family selection (Â§2.1 & Â§3.4)
	local salt = self.protoSalt
	local base = (self.keyMaterial and self.keyMaterial.baseSalt) or 1337
	local entropy = (self.keyMaterial and self.keyMaterial.buildEntropy) or 101
	local k1 = self.protoKey[1] or 17
	local k2 = self.protoKey[2] or 31

	-- Multi-round non-linear hash with optional region binding
	local regTerm = (regionId and (regionId * 41)) or 0
	local h = (base * 37 + salt * 19 + self.opCounter * 53 + entropy * 11 + regTerm) % 65536
	local f1 = (h * k1 + 13) % 256
	local f2 = (f1 * k2 + salt * 7 + self.opCounter * 23 + (regionId or 0) * 17) % 256
	local selector = (f2 % #variants) + 1

	local recipeFn = variants[selector]
	local nodes = recipeFn(A, B, C, self.aluMap, self.capMap)

	-- Opaque Dead Trap Insertion (Fase 4: Confound Static CFG & Data-Flow Reaching Definitions)
	local isHardOrExtreme = (self.profile and (self.profile.profileLevel == "HARD" or self.profile.profileLevel == "EXTREME" or self.profile.profileLevel == "Zero Lua"))
	if isHardOrExtreme and nodes and #nodes >= 2 and (f2 % 4 == 0) then
		local deadSlot = 15
		table.insert(nodes, 2, { 4, deadSlot, 0, 0, 0, 0 }) -- MOP_CREATE_TEMP
		table.insert(nodes, 3, { 5, deadSlot, 1, 0, 0, 0 }) -- MOP_MOVE_STATE
	end

	if self.microOpMap and nodes then
		for _, node in ipairs(nodes) do
			if node and node[1] then
				node[1] = self.microOpMap[node[1]] or node[1]
			end
		end
	end

	return nodes
end

return RecipeGenerator
