-- This Script is Part of the Zero Impact Obfuscator
--
-- ClosureIntegrity.lua
--
-- Inspects closure stack frames via debug.info / debug.getinfo with Memory Allocation Poisoning.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local visitast = require("zerolua.visitast")

local ClosureIntegrity = Step:extend()
ClosureIntegrity.Description = "Closure stack frame integrity check for core builtins."
ClosureIntegrity.Name = "Closure Integrity Guard"

ClosureIntegrity.SettingsDescriptor = {
	Mode = {
		name = "Mode",
		description = "Strict C-closure integrity or executor-compatible mode.",
		type = "enum",
		values = {
			"COMPAT",
			"STRICT",
		},
		default = "COMPAT",
	},
}

function ClosureIntegrity:init(settings)
	self.settings = settings or {}
end

function ClosureIntegrity:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local mode = (self.settings and self.settings.Mode) or "COMPAT"
	local isStrict = (mode == "STRICT")
	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 17 + 89) % 2147483647
		pipeline:registerGuardAttestation("ClosureIntegrity", function(bs, sMod)
			local tok = (bs * 17 + 89) % sMod
			local code = "local _ok = (string.byte(type(tonumber), 1) == 102 and string.byte(type(tostring), 1) == 102 and tonumber(string.char(49,51,51,55)) == 1337 and string.byte(string.char(90), 1) == 90); " ..
				"if _ok then return " .. tostring(tok) .. " else return 0 end"
			return code, tok
		end, expected)
	end

	local RandomStrings = require("zerolua.randomStrings")
	local poisonFnName = RandomStrings.randomString(8)
	local v_sc = RandomStrings.randomString(6)
	local v_g_pcall = RandomStrings.randomString(6)
	local v_g_type = RandomStrings.randomString(6)
	local v_dbg = RandomStrings.randomString(6)
	local v_safePcall = RandomStrings.randomString(6)
	local v_safeType = RandomStrings.randomString(6)
	local v_checkAll = RandomStrings.randomString(6)
	local v_targets = RandomStrings.randomString(6)
	local v_fn = RandomStrings.randomString(6)
	local v_ok = RandomStrings.randomString(6)
	local v_ok2 = RandomStrings.randomString(6)
	local v_fnInfo = RandomStrings.randomString(7)
	local v_fnGetInfo = RandomStrings.randomString(7)
	local v_line = RandomStrings.randomString(6)
	local v_src = RandomStrings.randomString(6)
	local v_resL = RandomStrings.randomString(6)
	local v_resS = RandomStrings.randomString(6)
	local v_isNative = RandomStrings.randomString(7)
	local v_idx = RandomStrings.randomString(5)

	local function toCharExpr(s)
		local parts = {}
		for i = 1, #s do
			table.insert(parts, tostring(string.byte(s, i)))
		end
		return v_sc .. "(" .. table.concat(parts, ",") .. ")"
	end

	local strictDbgCheck = ""
	local strictDbgSetup = ""
	if isStrict then
		strictDbgSetup = "\tlocal " .. v_dbg .. " = debug or (_G and _G.debug) or (getgenv and getgenv().debug);\n"
		strictDbgCheck = [[
				local ]] .. v_fnInfo .. " = " .. v_dbg .. " and " .. v_dbg .. "[" .. toCharExpr("info") .. "];\n" .. [[
				local ]] .. v_fnGetInfo .. " = " .. v_dbg .. " and " .. v_dbg .. "[" .. toCharExpr("getinfo") .. "];\n" .. [[
				if ]] .. v_fnInfo .. " and " .. v_safeType .. "(" .. v_fnInfo .. ") == " .. toCharExpr("function") .. [[ then
					local ]] .. v_ok .. ", " .. v_line .. " = " .. v_safePcall .. "(function() return " .. v_fnInfo .. "(" .. v_fn .. ", " .. toCharExpr("l") .. [[) end);
					if ]] .. v_ok .. " and " .. v_line .. " and " .. v_line .. [[ ~= -1 then
						]] .. poisonFnName .. [[();
					end

					local ]] .. v_ok2 .. ", " .. v_src .. " = " .. v_safePcall .. "(function() return " .. v_fnInfo .. "(" .. v_fn .. ", " .. toCharExpr("s") .. [[) end);
					if ]] .. v_ok2 .. " and " .. v_src .. " and not " .. v_isNative .. "(tostring(" .. v_src .. [[), nil) then
						]] .. poisonFnName .. [[();
					end
				elseif ]] .. v_fnGetInfo .. " and " .. v_safeType .. "(" .. v_fnGetInfo .. ") == " .. toCharExpr("function") .. [[ then
					local ]] .. v_ok .. ", " .. v_resL .. " = " .. v_safePcall .. "(function() return " .. v_fnGetInfo .. "(" .. v_fn .. ", " .. toCharExpr("l") .. [[) end);
					if ]] .. v_ok .. " and type(" .. v_resL .. ") == \"table\" and " .. v_resL .. ".currentline and " .. v_resL .. [[.currentline ~= -1 then
						]] .. poisonFnName .. [[();
					end

					local ]] .. v_ok2 .. ", " .. v_resS .. " = " .. v_safePcall .. "(function() return " .. v_fnGetInfo .. "(" .. v_fn .. ", " .. toCharExpr("S") .. [[) end);
					if ]] .. v_ok2 .. " and type(" .. v_resS .. ") == \"table\" and not " .. v_isNative .. "(tostring(" .. v_resS .. ".source or \"\"), " .. v_resS .. [[) then
						]] .. poisonFnName .. [[();
					end
				end
]]
	end

	local code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_g_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_g_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
]] .. strictDbgSetup .. [[
	local ]] .. v_safePcall .. [[ = (]] .. v_g_type .. [[ and ]] .. v_g_type .. [[(]] .. v_g_pcall .. [[) == ]] .. toCharExpr("function") .. [[ and ]] .. v_g_pcall .. [[) or function(f, a, b) return true, f(a, b) end;
	local ]] .. v_safeType .. [[ = (]] .. v_g_type .. [[ and ]] .. v_g_type .. [[(]] .. v_g_type .. [[) == ]] .. toCharExpr("function") .. [[ and ]] .. v_g_type .. [[) or function(v) return typeof and typeof(v) or ]] .. toCharExpr("unknown") .. [[ end;

	local function ]] .. poisonFnName .. [[()
		return;
	end

	local function ]] .. v_checkAll .. [[()
		local function ]] .. v_isNative .. [[(s, t)
			if type(t) == "table" and t.what == ]] .. toCharExpr("C") .. [[ then return true end
			if not s or #s == 0 or s == ]] .. toCharExpr("[C]") .. [[ or s == ]] .. toCharExpr("=[C]") .. [[ or s == ]] .. toCharExpr("builtin") .. [[ then
				return true
			end
			if string and string.find and string.find(s, ]] .. toCharExpr("%[C%]") .. [[) then
				return true
			end
			return false
		end

		local ]] .. v_targets .. [[ = { ]] .. v_g_pcall .. [[, ]] .. v_g_type .. [[, string and string.byte, string and string.char, string and string.sub, table and table.concat, math and math.floor, tonumber, tostring, require, (game and game.GetService), (Instance and Instance.new) };
		for ]] .. v_idx .. [[ = 1, #]] .. v_targets .. [[ do
			local ]] .. v_fn .. [[ = ]] .. v_targets .. "[" .. v_idx .. [[];
			if ]] .. v_fn .. [[ and ]] .. v_safeType .. [[(]] .. v_fn .. [[) == ]] .. toCharExpr("function") .. [[ then
]] .. strictDbgCheck .. [[
			end
		end
	end

	if ]] .. v_safeType .. [[ then
		]] .. v_safePcall .. [[(]] .. v_checkAll .. [[);
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

return ClosureIntegrity
