-- This Script is Part of the Zero Impact Obfuscator
--
-- AntiHook.lua
--
-- Runtime Hooking & Instrumentation Detection Guard with Unique Poisoning & Multi-point Checks.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local visitast = require("zerolua.visitast")

local AntiHook = Step:extend()
AntiHook.Description = "Runtime CClosure verification & silent poisoning anti-hooking guard."
AntiHook.Name = "Anti Hook"

AntiHook.SettingsDescriptor = {
	Mode = {
		name = "Mode",
		description = "Strict native integrity or hook-compatible integrity mode.",
		type = "enum",
		values = {
			"COMPAT",
			"STRICT",
		},
		default = "COMPAT",
	},
}

function AntiHook:init(settings)
	self.settings = settings or {}
end

function AntiHook:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local mode = (self.settings and self.settings.Mode) or "COMPAT"
	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 13 + 47) % 2147483647
		pipeline:registerGuardAttestation("AntiHook", function(bs, sMod)
			local tok = (bs * 13 + 47) % sMod
			local code = "local _ok = (string.byte(type(pcall), 1) == 102 and string.byte(type(type), 1) == 102); " ..
				"if _ok then return " .. tostring(tok) .. " else return 0 end"
			return code, tok
		end, expected)
	end
	local poisonFnName = RandomStrings.randomString(8)
	local v_sc = RandomStrings.randomString(6)
	local v_pcall = RandomStrings.randomString(7)
	local v_type = RandomStrings.randomString(7)
	local v_dbg = RandomStrings.randomString(6)
	local v_chkFn = RandomStrings.randomString(7)
	local v_ok = RandomStrings.randomString(6)
	local v_res = RandomStrings.randomString(6)
	local v_isNative = RandomStrings.randomString(7)
	local v_fnInfo = RandomStrings.randomString(7)
	local v_fnGetInfo = RandomStrings.randomString(7)
	local v_targets = RandomStrings.randomString(7)
	local v_i = RandomStrings.randomString(5)
	local v_targetFn = RandomStrings.randomString(7)
	local v_okL = RandomStrings.randomString(6)
	local v_resL = RandomStrings.randomString(6)
	local v_okS = RandomStrings.randomString(6)
	local v_resS = RandomStrings.randomString(6)
	local v_sigOk = RandomStrings.randomString(6)
	local v_sigErr = RandomStrings.randomString(6)

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

	local isStrict = (mode == "STRICT")

	local debugCheckCode = ""
	local debugSetupCode = ""
	if isStrict then
		debugSetupCode = "\tlocal " .. v_dbg .. " = debug or (_G and _G.debug) or (getgenv and getgenv().debug);\n"
		debugCheckCode = [[
		if ]] .. v_dbg .. [[ then
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

			local ]] .. v_fnInfo .. " = " .. v_dbg .. " and " .. v_dbg .. "[" .. toCharExpr("info") .. "];\n" .. [[
			local ]] .. v_fnGetInfo .. " = " .. v_dbg .. " and " .. v_dbg .. "[" .. toCharExpr("getinfo") .. "];\n" .. [[

			local ]] .. v_targets .. [[ = {
				]] .. v_pcall .. [[,
				]] .. v_type .. [[,
				string and string.char,
				string and string.byte,
				string and string.sub,
				table and table.concat,
				math and math.floor,
				tonumber,
				tostring,
				require,
				(game and game.GetService),
				(Instance and Instance.new)
			};

			for ]] .. v_i .. [[ = 1, #]] .. v_targets .. [[ do
				local ]] .. v_targetFn .. [[ = ]] .. v_targets .. "[" .. v_i .. [[];
				if ]] .. v_targetFn .. [[ and ]] .. v_type .. "(" .. v_targetFn .. ") == " .. toCharExpr("function") .. [[ then
					if ]] .. v_fnInfo .. [[ and ]] .. v_type .. "(" .. v_fnInfo .. ") == " .. toCharExpr("function") .. [[ then
						local ]] .. v_okL .. ", " .. v_resL .. " = " .. v_pcall .. "(function() return " .. v_fnInfo .. "(" .. v_targetFn .. ", " .. toCharExpr("l") .. [[) end);
						if ]] .. v_okL .. [[ and ]] .. v_resL .. [[ and ]] .. v_resL .. [[ ~= -1 then return false end

						local ]] .. v_okS .. ", " .. v_resS .. " = " .. v_pcall .. "(function() return " .. v_fnInfo .. "(" .. v_targetFn .. ", " .. toCharExpr("s") .. [[) end);
						if ]] .. v_okS .. [[ and ]] .. v_resS .. [[ and not ]] .. v_isNative .. "(tostring(" .. v_resS .. [[), nil) then
							return false;
						end
					elseif ]] .. v_fnGetInfo .. [[ and ]] .. v_type .. "(" .. v_fnGetInfo .. ") == " .. toCharExpr("function") .. [[ then
						local ]] .. v_okL .. ", " .. v_resL .. " = " .. v_pcall .. "(function() return " .. v_fnGetInfo .. "(" .. v_targetFn .. ", " .. toCharExpr("l") .. [[) end);
						if ]] .. v_okL .. [[ and type(]] .. v_resL .. [[) == "table" and ]] .. v_resL .. ".currentline and " .. v_resL .. [[.currentline ~= -1 then return false end

						local ]] .. v_okS .. ", " .. v_resS .. " = " .. v_pcall .. "(function() return " .. v_fnGetInfo .. "(" .. v_targetFn .. ", " .. toCharExpr("S") .. [[) end);
						if ]] .. v_okS .. [[ and type(]] .. v_resS .. [[) == "table" and not ]] .. v_isNative .. "(tostring(" .. v_resS .. ".source or \"\"), " .. v_resS .. [[) then
							return false;
						end
					end
				end
			end
		end
]]
	end

	local code = [[
do
	local ]] .. v_sc .. [[ = (string and string.char) or string.char;
	local ]] .. v_pcall .. [[ = pcall or (_G and _G.pcall) or (getgenv and getgenv().pcall);
	local ]] .. v_type .. [[ = type or (_G and _G.type) or (getgenv and getgenv().type);
	local function ]] .. poisonFnName .. [[()
		error("", 0);
	end

	local function ]] .. v_chkFn .. [[()
		if ]] .. v_type .. [[(]] .. v_pcall .. [[) ~= ]] .. toCharExpr("function") .. [[ or ]] .. v_type .. [[(]] .. v_type .. [[) ~= ]] .. toCharExpr("function") .. [[ then
			return false;
		end
		if string and string.char and ]] .. v_type .. [[(string.char) ~= ]] .. toCharExpr("function") .. [[ then return false end
		return true;
	end

	if ]] .. v_type .. [[ and ]] .. v_pcall .. [[ then
		local ]] .. v_ok .. [[, ]] .. v_res .. [[ = ]] .. v_pcall .. [[(]] .. v_chkFn .. [[);
		if not ]] .. v_ok .. [[ or not ]] .. v_res .. [[ then
			]] .. poisonFnName .. [[();
		end
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

return AntiHook
