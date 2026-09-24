-- This Script is Part of the Zero Impact Obfuscator
--
-- AntiOfflineSimulation.lua
--
-- Layer 1 Environment Attestation: Evaluates host environment invariants to detect
-- out-of-context offline execution (e.g. standalone interpreters, headless emulators).
--
-- Design Notes & Architectural Classification:
-- 1. Attestation Layer, NOT Absolute Security Boundary:
--    Sophisticated adversaries with fully semantic emulators may replicate host APIs.
--    Security is primarily enforced through instruction/state coupling and polymorphic encoding.
-- 2. Capability-Gated Invariants:
--    Distinguishes between Target-Required Invariants (e.g. Roblox DataModel, Luau typeof)
--    and Optional Host Features, preventing compatibility regressions across targets.
-- 3. Bounded & Deterministic Failure:
--    Attestation invalidity generates a bounded deterministic failure path without
--    runaway loops, memory allocation explosions, or runtime nondeterminism.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Ast = require("zerolua.ast")
local AstKind = Ast.AstKind
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local RandomDomains = require("zerolua.random_domains")
local visitast = require("zerolua.visitast")

local AntiOfflineSimulation = Step:extend()
AntiOfflineSimulation.Description = "Environment attestation layer verifying host execution invariants with bounded deterministic failure."
AntiOfflineSimulation.Name = "Anti Offline Simulation"
AntiOfflineSimulation.SettingsDescriptor = {
	Target = {
		type = "string",
		default = "Auto",
		description = "Execution target: 'Roblox', 'Luau', 'Lua51', or 'Auto'."
	}
}

function AntiOfflineSimulation:init(settings)
	self.Settings = settings or {}
end

function AntiOfflineSimulation:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local targetMode = (self.Settings and self.Settings.Target)
		or (pipeline and (pipeline.Target or (pipeline.Preset == "Roblox" and "Roblox")))
		or "Auto"
	local isRobloxRequired = (targetMode == "Roblox")
	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 29 + 179) % 2147483647
		pipeline:registerGuardAttestation("AntiOfflineSimulation", function(bs, sMod)
			local tok = (bs * 29 + 179) % sMod
			return "if (typeof and string.byte(typeof(123), 1) == 110) or (_G and _G.type) then return " .. tostring(tok) .. " else return 0 end", tok
		end, expected)
	end

	local function randId()
		return RandomStrings.randomString(math.random(8, 12))
	end

	local v_sc = randId()
	local function toCharExpr(s)
		local parts = {}
		for i = 1, #s do
			local b = string.byte(s, i)
			local off = ((seed * (i * 7 + 3) + i * 13) % 256)
			local masked = (b + off) % 256
			table.insert(parts, string.format("((%d - %d + 256) %% 256)", masked, off))
		end
		return v_sc .. "(" .. table.concat(parts, ",") .. ")"
	end

	local v_attestName = randId()
	local v_pcall = randId()
	local v_type = randId()
	local v_typeof = randId()
	local v_clock = randId()
	local v_game = randId()
	local v_checkLuau = randId()
	local v_checkRoblox = randId()
	local v_checkClock = randId()
	local v_t0 = randId()
	local v_t1 = randId()
	local v_acc = randId()
	local v_wFn = randId()

	-- =========================================================================
	-- CHECKPOINT 1: Luau Type Invariant Attestation
	-- =========================================================================
	local luauCheckBody
	if isLuauRequired then
		luauCheckBody = [[
		-- Luau target: typeof is a REQUIRED execution invariant
		if not ]] .. v_typeof .. [[ or ]] .. v_type .. [[(]] .. v_typeof .. [[) ~= ]] .. toCharExpr("function") .. [[ then
			return false;
		end
		local _okN, _resN = ]] .. v_pcall .. [[(]] .. v_typeof .. [[, 1234);
		if not _okN or _resN ~= ]] .. toCharExpr("number") .. [[ then return false end
		local _okS, _resS = ]] .. v_pcall .. [[(]] .. v_typeof .. [[, "test");
		if not _okS or _resS ~= ]] .. toCharExpr("string") .. [[ then return false end
		local _okT, _resT = ]] .. v_pcall .. [[(]] .. v_typeof .. [[, {});
		if not _okT or _resT ~= ]] .. toCharExpr("table") .. [[ then return false end

		-- Native Primitives Invariant Probes
		if Vector3 and Vector3.new then
			local _okV, _resV = ]] .. v_pcall .. [[(function() return ]] .. v_typeof .. [[(Vector3.new(1, 2, 3)) end);
			if not _okV or _resV ~= ]] .. toCharExpr("Vector3") .. [[ then return false end
		end
		if CFrame and CFrame.new then
			local _okCF, _resCF = ]] .. v_pcall .. [[(function() return ]] .. v_typeof .. [[(CFrame.new()) end);
			if not _okCF or _resCF ~= ]] .. toCharExpr("CFrame") .. [[ then return false end
		end
		if Color3 and Color3.new then
			local _okCol, _resCol = ]] .. v_pcall .. [[(function() return ]] .. v_typeof .. [[(Color3.new(1, 1, 1)) end);
			if not _okCol or _resCol ~= ]] .. toCharExpr("Color3") .. [[ then return false end
		end
		if task and ]] .. v_type .. [[(task) == ]] .. toCharExpr("table") .. [[ then
			if task.wait and ]] .. v_type .. [[(task.wait) ~= ]] .. toCharExpr("function") .. [[ then return false end
			if task.spawn and ]] .. v_type .. [[(task.spawn) ~= ]] .. toCharExpr("function") .. [[ then return false end
		end
		return true;
		]]
	else
		luauCheckBody = [[
		-- Optional host capability: if typeof exists, must exhibit consistent primitive typing
		if ]] .. v_typeof .. [[ and ]] .. v_type .. [[(]] .. v_typeof .. [[) == ]] .. toCharExpr("function") .. [[ then
			local _okN, _resN = ]] .. v_pcall .. [[(]] .. v_typeof .. [[, 1234);
			if _okN and _resN ~= ]] .. toCharExpr("number") .. [[ then return false end
			if Vector3 and Vector3.new then
				local _okV, _resV = ]] .. v_pcall .. [[(function() return ]] .. v_typeof .. [[(Vector3.new(1, 2, 3)) end);
				if _okV and _resV ~= ]] .. toCharExpr("Vector3") .. [[ then return false end
			end
		end
		return true;
		]]
	end

	local offset1 = ((seed * 47 + 1009) % 65521) + 1
	local offset2 = ((seed * 79 + 2017) % 65521) + 1
	local offset3 = ((seed * 113 + 3049) % 65521) + 1

	local cp1Code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
	local ]] .. v_typeof .. [[ = typeof or (getgenv and getgenv().typeof) or (_G and _G.typeof);

	local function ]] .. v_checkLuau .. [[()
		if not ]] .. v_pcall .. [[ or not ]] .. v_type .. [[ then return false end
]] .. luauCheckBody .. [[
	end

	local _ok, _valid = ]] .. v_pcall .. [[(]] .. v_checkLuau .. [[);
	if not _ok or not _valid then
		-- Bounded delayed poisoning: accumulate into private attestation state
		]] .. v_attestName .. [[ = (((]] .. v_attestName .. [[ or 0) + ]] .. tostring(offset1) .. [[) % 65521) + 1;
	end
end
]]

	-- =========================================================================
	-- CHECKPOINT 2: Roblox DataModel Surface Attestation
	-- =========================================================================
	local robloxCheckBody
	if isRobloxRequired then
		robloxCheckBody = [[
		-- Roblox target: game DataModel is a REQUIRED execution invariant
		if ]] .. v_game .. [[ == nil then return false end
		local _okType, _tVal = ]] .. v_pcall .. [[(function() return (typeof and typeof(]] .. v_game .. [[)) end);
		if not _okType or (_tVal ~= ]] .. toCharExpr("Instance") .. [[ and _tVal ~= ]] .. toCharExpr("userdata") .. [[ and _tVal ~= ]] .. toCharExpr("table") .. [[) then return false end
		if ]] .. v_game .. [[.GetService ~= nil then
			local _okS = ]] .. v_pcall .. [[(function() return ]] .. v_game .. [[:GetService(]] .. toCharExpr("Workspace") .. [[) end);
			if not _okS then return false end
			local _okRS, _rs = ]] .. v_pcall .. [[(function() return ]] .. v_game .. [[:GetService(]] .. toCharExpr("RunService") .. [[) end);
			if _okRS and _rs and _rs.IsClient and ]] .. v_type .. [[(_rs.IsClient) == ]] .. toCharExpr("function") .. [[ then
				local _okCl = ]] .. v_pcall .. [[(function() return _rs:IsClient() end);
				if not _okCl then return false end
			end
		end
		return true;
		]]
	else
		robloxCheckBody = [[
		-- Optional host capability: if game exists, verify reflection consistency
		if ]] .. v_game .. [[ ~= nil then
			local _okClass, _cVal = ]] .. v_pcall .. [[(function() return ]] .. v_game .. [[.ClassName end);
			if _okClass and _cVal and _cVal ~= ]] .. toCharExpr("DataModel") .. [[ then return false end
			if ]] .. v_game .. [[.GetService ~= nil then
				local _okRS, _rs = ]] .. v_pcall .. [[(function() return ]] .. v_game .. [[:GetService(]] .. toCharExpr("RunService") .. [[) end);
				if _okRS and _rs and _rs.IsClient and ]] .. v_type .. [[(_rs.IsClient) == ]] .. toCharExpr("function") .. [[ then
					local _okCl = ]] .. v_pcall .. [[(function() return _rs:IsClient() end);
					if not _okCl then return false end
				end
			end
		end
		return true;
		]]
	end

	local cp2Code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
	local ]] .. v_game .. [[ = game or (_G and _G.game) or (getgenv and getgenv().game);

	local function ]] .. v_checkRoblox .. [[()
		if not ]] .. v_pcall .. [[ then return false end
]] .. robloxCheckBody .. [[
	end

	local _ok, _valid = ]] .. v_pcall .. [[(]] .. v_checkRoblox .. [[);
	if not _ok or not _valid then
		-- Bounded delayed poisoning: accumulate into private attestation state
		]] .. v_attestName .. [[ = (((]] .. v_attestName .. [[ or 0) + ]] .. tostring(offset2) .. [[) % 65521) + 1;
	end
end
]]

	-- =========================================================================
	-- CHECKPOINT 3: Clock Monotonicity & Execution Timing Attestation
	-- =========================================================================
	local cp3Code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
	local ]] .. v_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_clock .. [[ = (os and os.clock) or (tick and tick);

	local function ]] .. v_checkClock .. [[()
		-- Clock capability check: must exist and monotonically advance
		if not ]] .. v_clock .. [[ or ]] .. v_type .. [[(]] .. v_clock .. [[) ~= ]] .. toCharExpr("function") .. [[ then
			return false;
		end
		local ]] .. v_t0 .. [[ = ]] .. v_clock .. [[();
		local ]] .. v_acc .. [[ = 0;
		local function ]] .. v_wFn .. [[(n) return (n * 5 + 13) % 251 end
		for i = 1, 30 do
			]] .. v_acc .. [[ = ]] .. v_wFn .. [[(]] .. v_acc .. [[ + i);
		end
		local ]] .. v_t1 .. [[ = ]] .. v_clock .. [[();
		if ]] .. v_t1 .. [[ < ]] .. v_t0 .. [[ or (]] .. v_t1 .. [[ - ]] .. v_t0 .. [[) > 5.0 then
			return false;
		end
		return ]] .. v_acc .. [[ >= 0;
	end

	local _ok, _valid = false, false;
	if ]] .. v_pcall .. [[ and ]] .. v_clock .. [[ then
		_ok, _valid = ]] .. v_pcall .. [[(]] .. v_checkClock .. [[);
	end
	if not _ok or not _valid then
		-- Bounded delayed poisoning: accumulate into private attestation state
		]] .. v_attestName .. [[ = (((]] .. v_attestName .. [[ or 0) + ]] .. tostring(offset3) .. [[) % 65521) + 1;
	end
end
]]

	-- =========================================================================
	-- DELAYED SYNCHRONIZATION BARRIER: Manifests Desynchronization at Completion
	-- =========================================================================
	local syncCode = [[
do
	if ]] .. v_attestName .. [[ ~= 0 then
		-- Bounded deterministic delayed failure:
		-- Intermediate payload computations have executed, but at this finalization
		-- boundary, the poisoned attestation state triggers safe termination.
		return;
	end
end
]]

	local p = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 })

	-- 1. Insert Attestation State Accumulator at Statement 1 in the root AST scope
	local varId = ast.body.scope:addVariable(v_attestName)
	local localDecl = Ast.LocalVariableDeclaration(ast.body.scope, { varId }, { Ast.NumberExpression(0) })
	localDecl.__ignoreProxifyLocals = true
	localDecl.__do_not_touch = true
	table.insert(ast.body.statements, 1, localDecl)

	local function linkAttestVar(parsedBlock, doStat)
		doStat.body.scope:setParent(ast.body.scope)
		visitast(parsedBlock, nil, function(node, data)
			node.__ignoreProxifyLocals = true
			if node.kind == AstKind.AssignmentVariable or node.kind == AstKind.VariableExpression then
				if node.scope and node.scope:getVariableName(node.id) == v_attestName then
					if data and data.scope then
						data.scope:removeReferenceToHigherScope(node.scope, node.id)
						data.scope:addReferenceToHigherScope(ast.body.scope, varId)
					end
					node.scope = ast.body.scope
					node.id = varId
				end
			end
		end)
	end

	-- 2. Insert Checkpoint 1 (Luau type invariants)
	local parsed1 = p:parse(cp1Code)
	local doStat1 = parsed1.body.statements[1]
	linkAttestVar(parsed1, doStat1)
	table.insert(ast.body.statements, 3, doStat1)

	-- 3. Insert Checkpoint 2 (Roblox DataModel reflection) in the middle
	local numStats = #ast.body.statements
	local lastStat = ast.body.statements[numStats]
	local hasTrailingReturn = (lastStat and lastStat.kind == "ReturnStatement")

	local parsed2 = p:parse(cp2Code)
	local doStat2 = parsed2.body.statements[1]
	linkAttestVar(parsed2, doStat2)
	local maxSafeMid = hasTrailingReturn and math.max(3, numStats - 1) or numStats
	local midIdx = math.min(maxSafeMid, math.max(4, math.floor(numStats / 2)))
	table.insert(ast.body.statements, midIdx, doStat2)

	-- 4. Insert Checkpoint 3 (Clock monotonicity) before final return
	local parsed3 = p:parse(cp3Code)
	local doStat3 = parsed3.body.statements[1]
	linkAttestVar(parsed3, doStat3)
	numStats = #ast.body.statements
	lastStat = ast.body.statements[numStats]
	if lastStat and lastStat.kind == "ReturnStatement" then
		table.insert(ast.body.statements, numStats, doStat3)
	else
		table.insert(ast.body.statements, doStat3)
	end

	-- 5. Insert Delayed Synchronization Boundary right before trailing return
	local parsedSync = p:parse(syncCode)
	local doStatSync = parsedSync.body.statements[1]
	linkAttestVar(parsedSync, doStatSync)
	numStats = #ast.body.statements
	lastStat = ast.body.statements[numStats]
	if lastStat and lastStat.kind == "ReturnStatement" then
		table.insert(ast.body.statements, numStats, doStatSync)
	else
		table.insert(ast.body.statements, doStatSync)
	end

	return ast
end

return AntiOfflineSimulation
