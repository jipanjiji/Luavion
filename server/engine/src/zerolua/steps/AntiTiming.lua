-- This Script is Part of the Zero Impact Obfuscator
--
-- AntiTiming.lua
--
-- CPU benchmark loop measuring execution latency using os.clock with Infinite Loop Poisoning.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local visitast = require("zerolua.visitast")

local AntiTiming = Step:extend()
AntiTiming.Description = "CPU benchmark timing anti-debug guard."
AntiTiming.Name = "Anti Timing Guard"

AntiTiming.SettingsDescriptor = {}

function AntiTiming:init(_) end

function AntiTiming:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 37 + 251) % 2147483647
		pipeline:registerGuardAttestation("AntiTiming", function(bs, sMod)
			local tok = (bs * 37 + 251) % sMod
			return "return " .. tostring(tok), tok
		end, expected)
	end

	local poisonFnName = RandomStrings.randomString(8)
	local v_sc = RandomStrings.randomString(6)
	local v_pcall = RandomStrings.randomString(7)
	local v_type = RandomStrings.randomString(7)
	local v_os = RandomStrings.randomString(7)
	local v_clock = RandomStrings.randomString(7)
	local v_safePcall = RandomStrings.randomString(7)
	local v_runBench = RandomStrings.randomString(7)
	local v_t1 = RandomStrings.randomString(6)
	local v_accum = RandomStrings.randomString(6)
	local v_t2 = RandomStrings.randomString(6)
	local v_elapsed = RandomStrings.randomString(7)

	local function toCharExpr(s)
		local parts = {}
		for i = 1, #s do
			table.insert(parts, tostring(string.byte(s, i)))
		end
		return v_sc .. "(" .. table.concat(parts, ",") .. ")"
	end

	local loopLimit = 200
	local timeLimit = 3.0
	local modVal = 2147483647 - math.random(1, 500) * 2

	local code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
	local ]] .. v_os .. [[ = os or (_G and _G.os) or (getgenv and getgenv().os);
	local ]] .. v_clock .. [[ = (]] .. v_type .. [[ and ]] .. v_os .. [[ and ]] .. v_type .. [[(]] .. v_os .. [[) == ]] .. toCharExpr("table") .. [[ and ]] .. v_type .. [[(]] .. v_os .. [[.clock) == ]] .. toCharExpr("function") .. [[ and ]] .. v_os .. [[.clock) or (tick and tick) or nil;

	local ]] .. v_safePcall .. [[ = (]] .. v_type .. [[ and ]] .. v_type .. [[(]] .. v_pcall .. [[) == ]] .. toCharExpr("function") .. [[ and ]] .. v_pcall .. [[) or function(f) return f() end;

	local function ]] .. poisonFnName .. [[()
		return;
	end

	local function ]] .. v_runBench .. [[()
		local ]] .. v_t1 .. [[ = (]] .. v_clock .. [[ and ]] .. v_clock .. [[()) or 0;
		local ]] .. v_accum .. [[ = 0;
		for i = 1, ]] .. tostring(loopLimit) .. [[ do
			]] .. v_accum .. [[ = (]] .. v_accum .. [[ + i) % ]] .. tostring(modVal) .. [[;
		end
		local ]] .. v_t2 .. [[ = (]] .. v_clock .. [[ and ]] .. v_clock .. [[()) or 0;
		local ]] .. v_elapsed .. [[ = ]] .. v_t2 .. [[ - ]] .. v_t1 .. [[;
		if ]] .. v_elapsed .. [[ >= ]] .. string.format("%.2f", timeLimit) .. [[ and ]] .. v_t1 .. [[ > 0 and ]] .. v_t2 .. [[ > 0 and ]] .. v_t2 .. [[ >= ]] .. v_t1 .. [[ then
			]] .. poisonFnName .. [[();
		end
	end

	if ]] .. v_clock .. [[ then
		]] .. v_safePcall .. [[(]] .. v_runBench .. [[);
	end
end
]]

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

return AntiTiming
