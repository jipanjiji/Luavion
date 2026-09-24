-- This Script is Part of the Zero Lua Obfuscator v4.1
--
-- vm_profiles.lua
--
-- Manages per-prototype polymorphic VM profiles for Zero Lua v4.1
-- including randomized opcode vocabularies, multi-layout operand permutations,
-- multiple execution architectures (State-Threaded, Micro-Op Compositional,
-- Split-Vector Galois Scatter, Nested Decision Tree), scrambled register mappings,
-- outer ISA profiles, micro ISA profiles, hierarchical key derivation parameters,
-- and dynamic polymorphic ALU & Capability token mappings.

local RandomDomains = require("zerolua.random_domains")
local MicroOps = require("zerolua.compiler.micro_ops")
local SuperinstructionOptimizer = require("zerolua.compiler.superinstruction_optimizer")
local KeySchedule = require("zerolua.compiler.key_schedule")
local ISA = require("zerolua.compiler.isa")

local VMProfiles = {}

local BASE_OPCODE_NAMES = ISA.BASE_OPCODES

-- VM Execution Architectures (Poly-10 Core):
VMProfiles.ARCH_STATE_THREADED         = 1  -- Non-linear State-Evolving Morphing Dispatch
VMProfiles.ARCH_MICRO_OP_MACHINE       = 2  -- Compositional Micro-Operation Execution Machine
VMProfiles.ARCH_SPLIT_VECTOR_SCATTER   = 3  -- Dual-Token Galois Vector Scatter Dispatch
VMProfiles.ARCH_NESTED_DECISION_TREE   = 4  -- Non-Indexed Hierarchical Decision Tree Dispatch
VMProfiles.ARCH_3OP_REGISTER           = 5  -- 3-Operand Register Machine with Dynamic Permutations
VMProfiles.ARCH_STACK_EVAL             = 6  -- Stack-Based Forth/JVM Evaluation Engine
VMProfiles.ARCH_DUAL_ACCUMULATOR       = 7  -- Dual-Register Accumulator Engine (ACC/TMP)
VMProfiles.ARCH_INDIRECT_STATE_MACHINE = 8  -- Indirect State Transition Jump Engine
VMProfiles.ARCH_FUSED_SUPER_MACRO      = 9  -- Fused Superinstruction Macro Engine
VMProfiles.ARCH_EPHEMERAL_ZERO_ALLOC   = 10 -- Ephemeral Hybrid Zero-Allocation Engine
VMProfiles.ARCH_ACCELERATED_GALOIS      = 11 -- Accelerated Direct-Indexed Galois Engine
VMProfiles.ARCH_INDIRECT_JUMP_VECTOR   = 12 -- Zero Impact 9.0 Indirect Jump Vector Array
VMProfiles.ARCH_STATE_BOUND_CASCADED_FRAGMENTS = 13 -- Zero Impact 9.15 State-Bound Cascaded Fragments

-- Legacy aliases for backwards compatibility with test assertions
VMProfiles.DISPATCH_STATE   = VMProfiles.ARCH_STATE_THREADED
VMProfiles.DISPATCH_SPLIT   = VMProfiles.ARCH_SPLIT_VECTOR_SCATTER
VMProfiles.DISPATCH_SCATTER = VMProfiles.ARCH_NESTED_DECISION_TREE
VMProfiles.DISPATCH_DIRECT  = VMProfiles.ARCH_STATE_THREADED

-- Operand Layouts:
VMProfiles.LAYOUT_ABC = 0 -- [OP, A, B, C]
VMProfiles.LAYOUT_CAB = 1 -- [OP, C, A, B]
VMProfiles.LAYOUT_BCA = 2 -- [OP, B, C, A]
VMProfiles.LAYOUT_ACB = 3 -- [OP, A, C, B]
VMProfiles.LAYOUT_BAC = 4 -- [OP, B, A, C]
VMProfiles.LAYOUT_CBA = 5 -- [OP, C, B, A]

function VMProfiles.createProfile(protoId, seed, profileLevel, baseProfile, config)
	local rng = RandomDomains.get("VM")
	protoId = protoId or 0
	profileLevel = profileLevel or "EXTREME"

	local opcodes
	local widths
	local dCoeff
	local dOffset
	local stateMul
	local stateAdd
	local regMul
	local regOffset
	local keyMode

	if baseProfile then
		opcodes = baseProfile.opcodes
		widths = baseProfile.opcodeWidths
		dCoeff = rng:random(11, 89) * 2 + 1
		dOffset = rng:random(7, 199)
		stateMul = rng:random(3, 17) * 2 + 1
		stateAdd = rng:random(11, 79)
		if profileLevel == "PERFORMANCE" or profileLevel == "Performance" then
			regMul = 23
			regOffset = 0
		else
			regMul = rng:random(11, 25) * 2 + 1
			regOffset = rng:random(3, 31)
		end
		keyMode = (baseProfile and baseProfile.keyMode) or rng:random(1, 3)
	else
		-- 1. Build-Specific Randomized Opcode Vocabulary
		local used = {}
		opcodes = {}
		widths = {}
		local allNames = {}

		for _, n in ipairs(BASE_OPCODE_NAMES) do
			table.insert(allNames, n)
		end

		-- Superinstruction synthesis per profile via Corpus-Driven Cost-Model (FusionScore)
		local superList = {}
		if not (config and config.superinstructions == false) then
			superList = SuperinstructionOptimizer.getOptimizedSuperinstructions(profileLevel, nil, config and config.trainingCorpus)
		end
		for _, n in ipairs(superList) do
			table.insert(allNames, n)
		end

		for _, name in ipairs(allNames) do
			local id
			repeat
				id = rng:random(11, 249)
			until not used[id]
			used[id] = true
			opcodes[name] = id
			widths[name] = (ISA.DEFAULT_OPCODE_WIDTHS and ISA.DEFAULT_OPCODE_WIDTHS[name]) or 4
		end

		-- 2. Non-linear Token Transformation Parameters (Modulo 256 Ring)
		dCoeff = rng:random(11, 89) * 2 + 1 -- guaranteed coprime to 256
		dOffset = rng:random(7, 199)
		stateMul = rng:random(3, 17) * 2 + 1
		stateAdd = rng:random(11, 79)

		-- 3. Scrambled Register Storage Parameters
		if profileLevel == "PERFORMANCE" or profileLevel == "Performance" or profileLevel == "SAFE" or profileLevel == "Safe" then
			regMul = 23
			regOffset = 0
		else
			regMul = rng:random(11, 25) * 2 + 1
			regOffset = rng:random(3, 31)
		end

		-- 4. Key Schedule Derivation Mode
		keyMode = rng:random(1, 3)
	end

	-- 5. Shuffled Operand Layout per Prototype (0..5)
	local layout
	if profileLevel == "SAFE" or profileLevel == "Safe" then
		layout = 0 -- flat layout: no permutation / minimal scramble
	else
		layout = rng:random(1, 5) -- polymorphic scrambled operand layout
	end

	-- 6. Dynamic Execution Architecture Selection (Polymorphic across active tested architectures)
	local numBuckets = rng:random(3, 6)
	local dispatchMode
	if config and config.dispatchMode then
		dispatchMode = config.dispatchMode
	elseif profileLevel == "PERFORMANCE" or profileLevel == "Performance" or profileLevel == "SAFE" or profileLevel == "Safe" then
		dispatchMode = VMProfiles.ARCH_ACCELERATED_GALOIS
	else
		local supportedModes = { 11, 12 }
		dispatchMode = supportedModes[rng:random(1, #supportedModes)]
	end

	local protoSalt = rng:random(100, 9999)
	local keyMaterial = (baseProfile and baseProfile.keyMaterial) or KeySchedule.generateKeyMaterial(seed)
	local protoKey = KeySchedule.deriveProtoKey(keyMaterial, protoSalt, 64, keyMode)

	-- Polymorphic Per-Build / Per-Prototype Mappings (Â§3.1 & Â§3.2)
	local aluMap = (baseProfile and baseProfile.aluMap) or KeySchedule.deriveAluMap(protoKey, seed or 1337)
	local capMap = (baseProfile and baseProfile.capMap) or KeySchedule.deriveCapMap(protoKey, seed or 1337)

	-- 7. Prototype-Specific Semantic Profile (v4.1)
	local semanticProfile = {
		strategy = rng:random(1, 4),
		tokenDomain = rng:random(11, 241),
		stateDisplacement = rng:random(3, 97),
		resolverDomain = (protoSalt * 13 + protoId * 17) % 65536
	}

	-- 8. Dual-Bytecode Nested VM Profiles (v4.1)
	local outerIsaProfile = {
		streamMode = rng:random(1, 3),
		regionSalt = (protoSalt * 19 + 77) % 256,
		stepFactor = rng:random(1, 5) * 2 + 1
	}

	local microIsaProfile = {
		stateSlotCount = rng:random(4, 8),
		codecMode = rng:random(1, 3),
		entropyToken = (protoSalt * 31 + protoId * 53) % 256
	}

	local regionProfile = {
		regionShuffleKey = rng:random(1000, 99999),
		microStreamPacking = rng:random(1, 4)
	}

	local constantProfile = {
		fragmentationMode = rng:random(1, 3),
		xorMask = rng:random(1, 255)
	}

	local stateProfile = {
		initVal = (protoSalt * 37 + 101) % 256,
		evolver = rng:random(11, 89) * 2 + 1
	}

	return {
		protoId = protoId,
		seed = seed or 0,
		profileLevel = profileLevel,
		opcodes = opcodes,
		opcodeWidths = widths,
		operandLayout = layout,
		dispatchMode = dispatchMode,
		numBuckets = numBuckets,
		dCoeff = dCoeff,
		dOffset = dOffset,
		stateMul = stateMul,
		stateAdd = stateAdd,
		regMul = regMul,
		regOffset = regOffset,
		protoSalt = protoSalt,
		keyMode = keyMode,
		keyMaterial = keyMaterial,
		protoKey = protoKey,
		aluMap = aluMap,
		capMap = capMap,
		semanticProfile = semanticProfile,
		outerIsaProfile = outerIsaProfile,
		microIsaProfile = microIsaProfile,
		regionProfile = regionProfile,
		constantProfile = constantProfile,
		stateProfile = stateProfile,
		stateCoupling = (config and config.stateCoupling) or "amortized_bb",
		operandMaterialization = (config and config.operandMaterialization ~= nil) and (config.operandMaterialization == true) or ((config == nil or config.operandMaterialization == nil) and true or false),
		helperDiversification = (config and config.helperDiversification ~= nil) and (config.helperDiversification == true) or ((config == nil or config.helperDiversification == nil) and true or false),
		boundedCache = (config and config.boundedCache ~= nil) and (config.boundedCache == true) or ((config == nil or config.boundedCache == nil) and true or false),
		cacheCapacity = (config and config.cacheCapacity ~= nil) and config.cacheCapacity or 64,
		profileBuild = (config and config.profileBuild == true) or false,
		production = (config and (config.production == true or config.release == true)) or false,
		release = (config and config.release == true) or false,
		adversaryTrace = (config and config.adversaryTrace == true) or false,
		leakageAudit = (config and (config.leakageAudit == true or config.LeakageAudit == true)) or false
	}
end

return VMProfiles
