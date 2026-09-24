-- This Script is Part of the Zero Lua Obfuscator
--
-- superinstruction_optimizer.lua
--
-- Corpus-Driven Superinstruction Synthesis & Ranking Engine.
-- Evaluates candidates via an analytic cost-benefit model (FusionScore):
--
--                   Freq * DispatchesSaved * DecodeSaved * AllocFactor * Safety
--   FusionScore = ---------------------------------------------------------------
--                                  CodeSizeCost * FingerprintRisk
--
-- Where:
--   - Freq: Empirical n-gram frequency observed across the training corpus after lowering.
--   - DispatchesSaved: Dispatch loop cycles eliminated per execution.
--   - DecodeSaved: Instruction stream bytes/words avoided during operand decoding.
--   - AllocFactor: 1 + (AllocSaved * 0.5), rewarding register allocation reduction.
--   - Safety: Semantic preservation factor (penalizing metamethod hazards or host traps).
--   - CodeSizeCost: Ratio of expanded runtime VM handler code to baseline.
--   - FingerprintRisk: Entropy/heuristics penalty for introducing rare or distinguishable VM signatures.
--

local SuperinstructionOptimizer = {}

-- Standard Benchmark Training Corpus (Representative Real-World Multi-Domain Lua/Luau Patterns)
local TRAINING_CORPUS = {
	-- Domain 1: Table initialization & property assignments
	"local a = {}; a['x'] = 10; a['y'] = 20; a['z'] = 30",
	"local m = {}; m['a'] = 1; m['b'] = 2; m['c'] = 3; m['d'] = 4",
	"local config = {}; config.host = 'localhost'; config.port = 8080; config.timeout = 30",
	"local tbl = {}; tbl.k1 = 'val1'; tbl.k2 = 'val2'; tbl.k3 = 'val3'",

	-- Domain 2: Method calls & dictionary lookups
	"local obj = {}; local method = obj['run']; method()",
	"local f = math.floor; local x = f(); local y = f()",
	"local function doWork(p) local fn = p['callback']; if fn then fn() end end",
	"local parser = {}; local parse = parser.parse; parse('test')",
	"local handler = events['onClick']; handler('arg1')",

	-- Domain 3: Closures, upvalues & higher order functions
	"local function outer() local up = function() return 42 end; local function inner() return up() end return inner end",
	"local function makeCounter() local count = 0; return function() count = count + 1; return count end end",
	"local up1 = function() return 1 end; local function callUp() up1() end",
	"local function bind(fn, val) return function() return fn(val) end end",

	-- Domain 4: Register moves & arithmetic chains
	"local x = 'hello'; local y = x; local z = y",
	"local function test(a, b) local c = a + b; return c end",
	"local p = 10; local q = p; local r = q; local s = r + p",
	"local n1 = 1; local n2 = n1; local n3 = n2; local n4 = n3",

	-- Domain 5: String manipulations & concatenation
	"local str = 'hello' .. ' world'; local s2 = str .. '!'",
	"local path = '/api/' .. 'v1' .. '/users'",
	"local header = 'Zero' .. 'Lua' .. 'Obfuscator'",

	-- Domain 6: Roblox API patterns
	"local game = {}; local srv = game:GetService('Players')",
	"local Players = game:GetService('Players'); local lp = Players.LocalPlayer",
	"local ReplicatedStorage = game:GetService('ReplicatedStorage')",
	"local TweenService = game:GetService('TweenService')",

	-- Domain 7: Loop constructs & state machines
	"for i = 1, 100 do local v = i * 2; local k = 'key_' .. tostring(i) end",
	"local t = {1, 2, 3}; local len = #t; local first = t[1]",
	"local state = 1; while state < 5 do state = state + 1 end",
	"local sum = 0; for j = 1, 50 do sum = sum + j end"
}

local VALIDATION_CORPUS = {
	"local function solve(a, b) local s = a + b; local p = a * b; return s, p end",
	"local t = {}; for i = 1, 20 do t[i] = tostring(i * 3) end",
	"local http = game:GetService('HttpService'); local json = http:JSONEncode({ ok = true })",
	"local function getPlayer(name) return game:GetService('Players'):FindFirstChild(name) end"
}

local STRESS_CORPUS = {
	"local sum = 0; for i = 1, 500 do for j = 1, 10 do sum = sum + (i * j) % 97 end end return sum",
	"local buf = {}; for i = 1, 300 do buf[i] = 'str_' .. i .. '_val' end return #buf"
}

local ADVERSARIAL_CORPUS = {
	"local function trap() local a = 1; local b = 2; return (a == b and 10) or 20 end",
	"local meta = setmetatable({}, { __index = function(t, k) return k end }) return meta['test']"
}

SuperinstructionOptimizer.TRAINING_CORPUS = TRAINING_CORPUS
SuperinstructionOptimizer.VALIDATION_CORPUS = VALIDATION_CORPUS
SuperinstructionOptimizer.STRESS_CORPUS = STRESS_CORPUS
SuperinstructionOptimizer.ADVERSARIAL_CORPUS = ADVERSARIAL_CORPUS
local DEFAULT_TRAINING_CORPUS = TRAINING_CORPUS

-- Candidate Superinstruction Definitions with Hybrid Empirical/Analytic Cost Model Characteristics
-- (Empirical frequencies derived from lowered IR + analytic hardware/dispatch weights)
local CANDIDATE_METRICS = {
	LOADK_SETTABLE = {
		name = "LOADK_SETTABLE",
		nGram = { "LOADK", "SETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.95,
		codeSizeCost = 1.15,
		fingerprintRisk = 1.10
	},
	GETTABLE_CALL = {
		name = "GETTABLE_CALL",
		nGram = { "GETTABLE", "CALL" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.88,
		codeSizeCost = 1.25,
		fingerprintRisk = 1.20
	},
	MOVE_CALL = {
		name = "MOVE_CALL",
		nGram = { "MOVE", "CALL" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.92,
		codeSizeCost = 1.18,
		fingerprintRisk = 1.15
	},
	LOADK_MOVE = {
		name = "LOADK_MOVE",
		nGram = { "LOADK", "MOVE" },
		dispatchesSaved = 1,
		decodeSaved = 1,
		allocSaved = 1,
		safety = 1.00,
		codeSizeCost = 1.08,
		fingerprintRisk = 1.05
	},
	GETUPVAL_CALL = {
		name = "GETUPVAL_CALL",
		nGram = { "GETUPVAL", "CALL" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.90,
		codeSizeCost = 1.22,
		fingerprintRisk = 1.18
	},
	TABLE_SET_CHAIN = {
		name = "TABLE_SET_CHAIN",
		nGram = { "SETTABLE", "SETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 0,
		safety = 0.85,
		codeSizeCost = 1.30,
		fingerprintRisk = 1.25
	},
	CONCAT_MOVE = {
		name = "CONCAT_MOVE",
		nGram = { "CONCAT", "MOVE" },
		dispatchesSaved = 1,
		decodeSaved = 1,
		allocSaved = 1,
		safety = 0.95,
		codeSizeCost = 1.12,
		fingerprintRisk = 1.10
	},
	ROBLOX_GETSERVICE = {
		name = "ROBLOX_GETSERVICE",
		nGram = { "GETGLOBAL", "GETTABLE", "CALL" },
		dispatchesSaved = 2,
		decodeSaved = 4,
		allocSaved = 2,
		safety = 0.75,
		codeSizeCost = 1.55,
		fingerprintRisk = 1.85 -- High penalty: prevents becoming an automatic semantic fingerprint anchor
	},
	ADD_SETTABLE = {
		name = "ADD_SETTABLE",
		nGram = { "ADD", "SETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.90,
		codeSizeCost = 1.20,
		fingerprintRisk = 1.12
	},
	GETGLOBAL_CALL = {
		name = "GETGLOBAL_CALL",
		nGram = { "GETGLOBAL", "CALL" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.90,
		codeSizeCost = 1.22,
		fingerprintRisk = 1.15
	},
	GETTABLE_SETTABLE = {
		name = "GETTABLE_SETTABLE",
		nGram = { "GETTABLE", "SETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 0,
		safety = 0.88,
		codeSizeCost = 1.28,
		fingerprintRisk = 1.22
	},
	ADD_MOVE = {
		name = "ADD_MOVE",
		nGram = { "ADD", "MOVE" },
		dispatchesSaved = 1,
		decodeSaved = 1,
		allocSaved = 1,
		safety = 0.98,
		codeSizeCost = 1.10,
		fingerprintRisk = 1.08
	},
	LOADNIL_RET = {
		name = "LOADNIL_RET",
		nGram = { "LOADNIL", "RETURN" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.98,
		codeSizeCost = 1.05,
		fingerprintRisk = 1.05
	},
	MOVE_RET = {
		name = "MOVE_RET",
		nGram = { "MOVE", "RETURN" },
		dispatchesSaved = 1,
		decodeSaved = 1,
		allocSaved = 1,
		safety = 0.98,
		codeSizeCost = 1.06,
		fingerprintRisk = 1.05
	},
	CALL_TABLE_APPEND = {
		name = "CALL_TABLE_APPEND",
		nGram = { "CALL", "SETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.85,
		codeSizeCost = 1.35,
		fingerprintRisk = 1.25
	},
	ROBLOX_GET_LOCAL_CHAR = {
		name = "ROBLOX_GET_LOCAL_CHAR",
		nGram = { "GETTABLE", "GETTABLE" },
		dispatchesSaved = 1,
		decodeSaved = 2,
		allocSaved = 1,
		safety = 0.80,
		codeSizeCost = 1.40,
		fingerprintRisk = 1.45
	}
}

-- Lazy cache for default training corpus profiling, computed empirically on first use
local cachedDefaultFrequencies = nil

-- Calculate Analytic FusionScore
function SuperinstructionOptimizer.computeFusionScore(metrics, observedFreq)
	local freq = observedFreq or 0
	local allocFactor = 1 + (metrics.allocSaved or 0) * 0.5
	local numerator = freq * metrics.dispatchesSaved * metrics.decodeSaved * allocFactor * metrics.safety
	local denominator = metrics.codeSizeCost * metrics.fingerprintRisk
	if denominator <= 0 then denominator = 1 end
	return numerator / denominator
end

-- Profile N-Gram Frequencies across Corpus via IR/Bytecode Lowering
function SuperinstructionOptimizer.profileCorpus(corpus)
	local isDefault = (corpus == nil or corpus == DEFAULT_TRAINING_CORPUS)
	if isDefault and cachedDefaultFrequencies then
		return cachedDefaultFrequencies
	end

	corpus = corpus or DEFAULT_TRAINING_CORPUS
	local frequencies = {}
	for name, _ in pairs(CANDIDATE_METRICS) do
		frequencies[name] = 0
	end

	local okRequire, Parser = pcall(require, "zerolua.parser")
	local okEnums, Enums = pcall(require, "zerolua.enums")
	local okCompiler, BytecodeCompiler = pcall(require, "zerolua.compiler.bytecode_compiler")

	if okRequire and okEnums and okCompiler and type(corpus) == "table" then
		local parser = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 })
		for _, snippet in ipairs(corpus) do
			if type(snippet) == "string" and #snippet > 0 then
				local okParse, ast = pcall(function() return parser:parse(snippet) end)
				if okParse and ast and ast.body then
					local compiler = BytecodeCompiler:new(nil, "SAFE", {
						superinstructions = false,
						profileBuild = false
					})
					local okCompile = pcall(function() compiler:compileBlock(ast.body) end)
					if okCompile and compiler.debugInstructions then
						local instrs = compiler.debugInstructions
						local n = #instrs
						for i = 1, n - 1 do
							local op1 = instrs[i].op or ""
							if op1:sub(-4) == "_ALT" then op1 = op1:sub(1, -5) end
							local op2 = instrs[i + 1].op or ""
							if op2:sub(-4) == "_ALT" then op2 = op2:sub(1, -5) end

							if (op1 == "LOADK" or op1 == "LOADK_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								frequencies["LOADK_SETTABLE"] = frequencies["LOADK_SETTABLE"] + 1
							elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "CALL" or op2 == "CALL_RET") then
								frequencies["GETTABLE_CALL"] = frequencies["GETTABLE_CALL"] + 1
							elseif op1 == "MOVE" and (op2 == "CALL" or op2 == "CALL_RET") then
								frequencies["MOVE_CALL"] = frequencies["MOVE_CALL"] + 1
							elseif (op1 == "LOADK" or op1 == "LOADK_K") and op2 == "MOVE" then
								frequencies["LOADK_MOVE"] = frequencies["LOADK_MOVE"] + 1
							elseif op1 == "GETUPVAL" and (op2 == "CALL" or op2 == "CALL_RET") then
								frequencies["GETUPVAL_CALL"] = frequencies["GETUPVAL_CALL"] + 1
							elseif (op1 == "SETTABLE" or op1 == "SETTABLE_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								frequencies["TABLE_SET_CHAIN"] = frequencies["TABLE_SET_CHAIN"] + 1
							elseif op1 == "CONCAT" and op2 == "MOVE" then
								frequencies["CONCAT_MOVE"] = frequencies["CONCAT_MOVE"] + 1
							elseif (op1 == "ADD" or op1 == "ADD_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								frequencies["ADD_SETTABLE"] = (frequencies["ADD_SETTABLE"] or 0) + 1
							elseif (op1 == "GETGLOBAL" or op1 == "GETGLOBAL_K") and (op2 == "CALL" or op2 == "CALL_RET") then
								frequencies["GETGLOBAL_CALL"] = (frequencies["GETGLOBAL_CALL"] or 0) + 1
							elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								frequencies["GETTABLE_SETTABLE"] = (frequencies["GETTABLE_SETTABLE"] or 0) + 1
							elseif (op1 == "ADD" or op1 == "ADD_K") and op2 == "MOVE" then
								frequencies["ADD_MOVE"] = (frequencies["ADD_MOVE"] or 0) + 1
							elseif op1 == "LOADNIL" and op2 == "RETURN" then
								frequencies["LOADNIL_RET"] = (frequencies["LOADNIL_RET"] or 0) + 1
							elseif op1 == "MOVE" and op2 == "RETURN" then
								frequencies["MOVE_RET"] = (frequencies["MOVE_RET"] or 0) + 1
							elseif (op1 == "CALL" or op1 == "CALL_RET") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								frequencies["CALL_TABLE_APPEND"] = (frequencies["CALL_TABLE_APPEND"] or 0) + 1
							end

							if i <= n - 2 then
								local op3 = instrs[i + 2].op or ""
								if op3:sub(-4) == "_ALT" then op3 = op3:sub(1, -5) end
								if (op1 == "GETGLOBAL" or op1 == "GETGLOBAL_K") and (op2 == "GETTABLE" or op2 == "GETTABLE_K") and (op3 == "CALL" or op3 == "CALL_RET") then
									frequencies["ROBLOX_GETSERVICE"] = frequencies["ROBLOX_GETSERVICE"] + 1
								elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "GETTABLE" or op2 == "GETTABLE_K") and (op3 == "GETTABLE" or op3 == "GETTABLE_K") then
									frequencies["ROBLOX_GET_LOCAL_CHAR"] = (frequencies["ROBLOX_GET_LOCAL_CHAR"] or 0) + 1
								end
							end
						end
					end
				end
			end
		end
	end

	if isDefault then
		cachedDefaultFrequencies = frequencies
	end

	return frequencies
end

-- Rank and Select Best Superinstructions
function SuperinstructionOptimizer.rankCandidates(corpus)
	local frequencies = SuperinstructionOptimizer.profileCorpus(corpus)
	local ranked = {}

	local candidateNames = {}
	for name, _ in pairs(CANDIDATE_METRICS) do
		table.insert(candidateNames, name)
	end
	table.sort(candidateNames)

	for _, name in ipairs(candidateNames) do
		local metrics = CANDIDATE_METRICS[name]
		local freq = frequencies[name] or 0
		local score = SuperinstructionOptimizer.computeFusionScore(metrics, freq)
		table.insert(ranked, {
			name = name,
			score = score,
			freq = freq,
			metrics = metrics
		})
	end

	table.sort(ranked, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.freq ~= b.freq then
			return a.freq > b.freq
		end
		return a.name < b.name
	end)

	return ranked
end

-- Select Superinstructions for active build profile
function SuperinstructionOptimizer.getOptimizedSuperinstructions(profileLevel, maxCount, corpus)
	if profileLevel == "SAFE" then
		return {}
	end

	local ranked = SuperinstructionOptimizer.rankCandidates(corpus)
	local limit = maxCount or (
		(profileLevel == "EXTREME" or profileLevel == "MAXIMUM" or profileLevel == "Zero Lua") and 8
		or (profileLevel == "HARD" and 5)
		or (profileLevel == "STRONG" and 4)
		or 3
	)

	local selected = {}
	for i = 1, math.min(limit, #ranked) do
		table.insert(selected, ranked[i].name)
	end

	return selected, ranked
end

-- Measure Empirical Superinstruction Fusion Yield & Rejection Breakdown
function SuperinstructionOptimizer.measureFusionYield(corpus, selectedCandidates)
	corpus = corpus or DEFAULT_TRAINING_CORPUS
	local selectedMap = {}
	if selectedCandidates then
		for k, v in pairs(selectedCandidates) do
			if type(k) == "number" and type(v) == "string" then
				selectedMap[v] = true
			elseif type(k) == "string" and v == true then
				selectedMap[k] = true
			end
		end
	else
		local sel = SuperinstructionOptimizer.getOptimizedSuperinstructions("Zero Lua", 8, corpus)
		for _, name in ipairs(sel) do
			selectedMap[name] = true
		end
	end

	local observedPatterns = 0
	local eligiblePatterns = 0
	local fusedCount = 0
	local rejectedCount = 0
	local rejectionBreakdown = {
		BRANCH_TARGET_HAZARD = 0,
		LIVENESS_CONFLICT = 0,
		MULTIRETURN_CONFLICT = 0,
		METAMETHOD_CONFLICT = 0,
		VARARG_CONFLICT = 0,
		NOT_IN_PROFILE = 0
	}
	local dispatchesSaved = 0
	local decodeSaved = 0
	local allocProxySaved = 0

	local okRequire, Parser = pcall(require, "zerolua.parser")
	local okEnums, Enums = pcall(require, "zerolua.enums")
	local okCompiler, BytecodeCompiler = pcall(require, "zerolua.compiler.bytecode_compiler")

	if okRequire and okEnums and okCompiler and type(corpus) == "table" then
		local parser = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 })
		for _, snippet in ipairs(corpus) do
			if type(snippet) == "string" and #snippet > 0 then
				local okParse, ast = pcall(function() return parser:parse(snippet) end)
				if okParse and ast and ast.body then
					local compiler = BytecodeCompiler:new(nil, "SAFE", {
						superinstructions = false,
						profileBuild = false
					})
					local okCompile = pcall(function() compiler:compileBlock(ast.body) end)
					if okCompile and compiler.debugInstructions then
						local instrs = compiler.debugInstructions
						local n = #instrs

						-- 1. Identify branch targets in instruction sequence
						local branchTargets = {}
						for idx, inst in ipairs(instrs) do
							local op = inst.op or ""
							if op:sub(-4) == "_ALT" then op = op:sub(1, -5) end
							if op == "JMP" or op == "FORLOOP" or op == "FORPREP" or op == "EQ" or op == "LT" or op == "LE" or op == "TEST" or op == "TESTSET" then
								local target = idx + 1 + (inst.B or 0)
								if target >= 1 and target <= n then
									branchTargets[target] = true
								end
							end
						end

						-- 2. Scan instruction sequence for candidate n-grams
						local i = 1
						while i <= n - 1 do
							local op1 = instrs[i].op or ""
							if op1:sub(-4) == "_ALT" then op1 = op1:sub(1, -5) end
							local op2 = instrs[i + 1].op or ""
							if op2:sub(-4) == "_ALT" then op2 = op2:sub(1, -5) end

							local matchedCandidate = nil
							local nGramLen = 2

							if (op1 == "LOADK" or op1 == "LOADK_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								matchedCandidate = "LOADK_SETTABLE"
							elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "CALL" or op2 == "CALL_RET") then
								matchedCandidate = "GETTABLE_CALL"
							elseif op1 == "MOVE" and (op2 == "CALL" or op2 == "CALL_RET") then
								matchedCandidate = "MOVE_CALL"
							elseif (op1 == "LOADK" or op1 == "LOADK_K") and op2 == "MOVE" then
								matchedCandidate = "LOADK_MOVE"
							elseif op1 == "GETUPVAL" and (op2 == "CALL" or op2 == "CALL_RET") then
								matchedCandidate = "GETUPVAL_CALL"
							elseif (op1 == "SETTABLE" or op1 == "SETTABLE_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								matchedCandidate = "TABLE_SET_CHAIN"
							elseif op1 == "CONCAT" and op2 == "MOVE" then
								matchedCandidate = "CONCAT_MOVE"
							elseif (op1 == "ADD" or op1 == "ADD_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								matchedCandidate = "ADD_SETTABLE"
							elseif (op1 == "GETGLOBAL" or op1 == "GETGLOBAL_K") and (op2 == "CALL" or op2 == "CALL_RET") then
								matchedCandidate = "GETGLOBAL_CALL"
							elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								matchedCandidate = "GETTABLE_SETTABLE"
							elseif (op1 == "ADD" or op1 == "ADD_K") and op2 == "MOVE" then
								matchedCandidate = "ADD_MOVE"
							elseif op1 == "LOADNIL" and op2 == "RETURN" then
								matchedCandidate = "LOADNIL_RET"
							elseif op1 == "MOVE" and op2 == "RETURN" then
								matchedCandidate = "MOVE_RET"
							elseif (op1 == "CALL" or op1 == "CALL_RET") and (op2 == "SETTABLE" or op2 == "SETTABLE_K") then
								matchedCandidate = "CALL_TABLE_APPEND"
							end

							if i <= n - 2 then
								local op3 = instrs[i + 2].op or ""
								if op3:sub(-4) == "_ALT" then op3 = op3:sub(1, -5) end
								if (op1 == "GETGLOBAL" or op1 == "GETGLOBAL_K") and (op2 == "GETTABLE" or op2 == "GETTABLE_K") and (op3 == "CALL" or op3 == "CALL_RET") then
									matchedCandidate = "ROBLOX_GETSERVICE"
									nGramLen = 3
								elseif (op1 == "GETTABLE" or op1 == "GETTABLE_K") and (op2 == "GETTABLE" or op2 == "GETTABLE_K") and (op3 == "GETTABLE" or op3 == "GETTABLE_K") then
									matchedCandidate = "ROBLOX_GET_LOCAL_CHAR"
									nGramLen = 3
								end
							end

							if matchedCandidate then
								observedPatterns = observedPatterns + 1
								local metrics = CANDIDATE_METRICS[matchedCandidate]

								-- Check rejection hazards in priority order
								local rejectionReason = nil

								-- Hazard 1: Branch target hazard
								if branchTargets[i + 1] or (nGramLen == 3 and branchTargets[i + 2]) then
									rejectionReason = "BRANCH_TARGET_HAZARD"
								-- Hazard 2: Multi-return conflict (CALL with variable return or vararg parameter)
								elseif (op1 == "CALL" and (instrs[i].C == -1 or instrs[i].C == 0 or instrs[i].B == -1))
									or (op2 == "CALL" and (instrs[i + 1].C == -1 or instrs[i + 1].C == 0 or instrs[i + 1].B == -1)) then
									rejectionReason = "MULTIRETURN_CONFLICT"
								-- Hazard 3: Vararg register conflict
								elseif instrs[i].A == 255 or instrs[i + 1].A == 255 or instrs[i].B == 255 or instrs[i + 1].B == 255 then
									rejectionReason = "VARARG_CONFLICT"
								-- Hazard 4: Liveness conflict (intermediate register read later in basic block)
								elseif (op1 == "LOADK" or op1 == "ADD" or op1 == "CONCAT") and op2 == "MOVE" and instrs[i].A ~= instrs[i + 1].A then
									local intermediateReg = instrs[i].A
									local isLiveLater = false
									for k = i + nGramLen, math.min(n, i + 6) do
										local kOp = instrs[k].op or ""
										if kOp == "JMP" or kOp == "RETURN" then break end
										if instrs[k].B == intermediateReg or instrs[k].C == intermediateReg then
											isLiveLater = true
											break
										end
										if instrs[k].A == intermediateReg then break end
									end
									if isLiveLater then
										rejectionReason = "LIVENESS_CONFLICT"
									end
								-- Hazard 5: Metamethod re-entrancy conflict
								elseif (metrics and metrics.safety and metrics.safety < 0.85) then
									rejectionReason = "METAMETHOD_CONFLICT"
								end

								if rejectionReason then
									rejectedCount = rejectedCount + 1
									rejectionBreakdown[rejectionReason] = (rejectionBreakdown[rejectionReason] or 0) + 1
									i = i + 1
								else
									-- Pattern passes structural hazard checks -> Eligible
									eligiblePatterns = eligiblePatterns + 1

									-- Hazard 6: Not selected in active profile
									if not selectedMap[matchedCandidate] then
										rejectedCount = rejectedCount + 1
										rejectionBreakdown["NOT_IN_PROFILE"] = (rejectionBreakdown["NOT_IN_PROFILE"] or 0) + 1
										i = i + 1
									else
										-- Fused!
										fusedCount = fusedCount + 1
										dispatchesSaved = dispatchesSaved + (metrics and metrics.dispatchesSaved or 1)
										decodeSaved = decodeSaved + (metrics and metrics.decodeSaved or 1)
										allocProxySaved = allocProxySaved + (metrics and metrics.allocSaved or 0)
										i = i + nGramLen
									end
								end
							else
								i = i + 1
							end
						end
					end
				end
			end
		end
	end

	return {
		observed = observedPatterns,
		observedPatterns = observedPatterns,
		eligible = eligiblePatterns,
		eligiblePatterns = eligiblePatterns,
		fused = fusedCount,
		fusedCount = fusedCount,
		rejected = rejectedCount,
		rejectedCount = rejectedCount,
		rejectionBreakdown = rejectionBreakdown,
		staticInstructionCountSavings = dispatchesSaved,
		staticEstimatedDispatchReduction = dispatchesSaved,
		staticEmittedFusedInstructions = fusedCount,
		staticEstimatedFusedHits = fusedCount,
		dispatchesSaved = dispatchesSaved,
		estimatedDecodeWorkSaved = decodeSaved,
		decodeSaved = decodeSaved,
		allocationProxySaved = allocProxySaved,
		allocProxySaved = allocProxySaved,
		-- Backward-compatible aliases explicitly noted as static IR model estimates
		actualRuntimeDispatchReduction = dispatchesSaved,
		actualEmittedFusedInstructions = fusedCount,
		actualRuntimeFusedHits = fusedCount,
		savings = {
			staticInstructionCountSavings = dispatchesSaved,
			staticEstimatedDispatchReduction = dispatchesSaved,
			staticEmittedFusedInstructions = fusedCount,
			actualRuntimeDispatchReduction = dispatchesSaved,
			dispatchesSaved = dispatchesSaved,
			estimatedDecodeWorkSaved = decodeSaved,
			decodeSaved = decodeSaved,
			allocationProxySaved = allocProxySaved
		}
	}
end

return SuperinstructionOptimizer
