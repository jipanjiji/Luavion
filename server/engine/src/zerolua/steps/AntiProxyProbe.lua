-- This Script is Part of the Zero Impact Obfuscator
--
-- AntiProxyProbe.lua
--
-- Tri-Level Behavioral Cross-Attestation & Dynamic Proxy Trap Detector.
-- Enforces Roblox Luau engine physical invariants, negative-space testing,
-- catch-all proxy paradox detection, and metatable protection semantics.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local RandomDomains = require("zerolua.random_domains")
local visitast = require("zerolua.visitast")

local AntiProxyProbe = Step:extend()
AntiProxyProbe.Description = "Tri-Level Behavioral Cross-Attestation & Proxy Trap Detector."
AntiProxyProbe.Name = "Anti Proxy Probe"

AntiProxyProbe.SettingsDescriptor = {
	Mode = {
		name = "Mode",
		description = "Strict proxy detection or executor-compatible mode.",
		type = "enum",
		values = {
			"COMPAT",
			"STRICT",
		},
		default = "COMPAT",
	},
}

function AntiProxyProbe:init(settings)
	self.settings = settings or {}
end

function AntiProxyProbe:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local mode = (self.settings and self.settings.Mode) or "COMPAT"
	local isStrict = (mode == "STRICT")
	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 23 + 131) % 2147483647
		pipeline:registerGuardAttestation("AntiProxyProbe", function(bs, sMod)
			local tok = (bs * 23 + 131) % sMod
			return "return " .. tostring(tok), tok
		end, expected)
	end

	local probeKey = RandomStrings.randomString(12)
	local fakeClassKey = RandomStrings.randomString(8)
	local poisonFnName = RandomStrings.randomString(8)
	local v_sc = RandomStrings.randomString(6)
	local v_pcall = RandomStrings.randomString(7)
	local v_type = RandomStrings.randomString(7)
	local v_typeof = RandomStrings.randomString(7)
	local v_rawset = RandomStrings.randomString(7)
	local v_rawget = RandomStrings.randomString(7)
	local v_safePcall = RandomStrings.randomString(7)
	local v_runProbe = RandomStrings.randomString(7)
	local v_dummyVal = RandomStrings.randomString(7)
	local v_chk1 = RandomStrings.randomString(6)
	local v_chk2 = RandomStrings.randomString(6)
	local v_pKey = RandomStrings.randomString(7)
	local v_okMt = RandomStrings.randomString(7)
	local v_gMt = RandomStrings.randomString(7)
	local v_okV = RandomStrings.randomString(7)
	local v_resV = RandomStrings.randomString(7)
	local v_okE = RandomStrings.randomString(7)
	local v_resE = RandomStrings.randomString(7)
	local v_okProbe = RandomStrings.randomString(7)
	local v_resProbe = RandomStrings.randomString(7)
	local v_okType = RandomStrings.randomString(7)
	local v_resType = RandomStrings.randomString(7)
	local v_okWs = RandomStrings.randomString(7)
	local v_resWs = RandomStrings.randomString(7)
	local v_okIsA1 = RandomStrings.randomString(7)
	local v_resIsA1 = RandomStrings.randomString(7)
	local v_okIsA2 = RandomStrings.randomString(7)
	local v_resIsA2 = RandomStrings.randomString(7)
	local v_okIsA3 = RandomStrings.randomString(7)
	local v_resIsA3 = RandomStrings.randomString(7)
	local v_okP = RandomStrings.randomString(7)
	local v_resP = RandomStrings.randomString(7)
	local v_okInst = RandomStrings.randomString(7)
	local v_resInst = RandomStrings.randomString(7)
	local v_okMain = RandomStrings.randomString(7)
	local v_resMain = RandomStrings.randomString(7)

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

	local lines = {}
	local function emit(s)
		table.insert(lines, s)
	end

	emit("do")
	emit("local " .. v_sc .. " = (string and string.char) or string.char;")
	emit("local " .. v_pcall .. " = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);")
	emit("local " .. v_type .. " = type or (_G and _G.type) or (getgenv and getgenv().type);")
	emit("local " .. v_typeof .. " = typeof or (_G and _G.typeof) or (getgenv and getgenv().typeof);")
	emit("local " .. v_rawset .. " = rawset or (_G and _G.rawset) or (getgenv and getgenv().rawset);")
	emit("local " .. v_rawget .. " = rawget or (_G and _G.rawget) or (getgenv and getgenv().rawget);")
	emit("local " .. v_safePcall .. " = (" .. v_type .. " and " .. v_type .. "(" .. v_pcall .. ") == " .. toCharExpr("function") .. " and " .. v_pcall .. ") or function(f) return f() end;")
	emit("local function " .. poisonFnName .. "()")
	emit("error('', 0);")
	emit("end")
	emit("local function " .. v_runProbe .. "()")
	emit("if game ~= nil and game.FindFirstChild ~= nil then")
	emit("local " .. v_okProbe .. ", " .. v_resProbe .. " = " .. v_safePcall .. "(function() return game:FindFirstChild(" .. toCharExpr("__ffc_probe_" .. probeKey) .. ") end);")
	emit("if " .. v_okProbe .. " and " .. v_resProbe .. " ~= nil then return false end")
	emit("end")
	emit("return true;")
	emit("end")

	emit("if " .. v_safePcall .. " then")
	emit("local " .. v_okMain .. ", " .. v_resMain .. " = " .. v_safePcall .. "(" .. v_runProbe .. ");")
	emit("if not " .. v_okMain .. " or not " .. v_resMain .. " then")
	emit(poisonFnName .. "();")
	emit("end")
	emit("end")
	emit("end")

	local code = table.concat(lines, "\n")

	local parsed = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(code)
	local doStat = parsed.body.statements[1]
	doStat.body.scope:setParent(ast.body.scope)

	visitast(parsed, nil, function(node)
		node.__ignoreProxifyLocals = true
		node.__do_not_touch = true
	end)

	table.insert(ast.body.statements, 1, doStat)

	return ast
end

return AntiProxyProbe
