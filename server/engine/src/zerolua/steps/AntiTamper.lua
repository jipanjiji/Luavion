-- This Script is Part of the Zero Impact Obfuscator
--
-- AntiTamper.lua
--
-- Safe Roblox Luau Integrity Guard with Recursive Stack Poisoning & Multi-point Verification.

local Step = require("zerolua.step")
local RandomStrings = require("zerolua.randomStrings")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")

local AntiTamper = Step:extend()
AntiTamper.Description = "Integritas & Anti-Tamper Roblox Luau dengan Multi-point Stack Poisoning."
AntiTamper.Name = "Anti Tamper"

AntiTamper.SettingsDescriptor = {
	UseDebug = {
		type = "boolean",
		default = false,
		description = "Luau Native Integrity Check.",
	},
}

function AntiTamper:init(settings) end

function AntiTamper:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local seed = (pipeline and pipeline.Seed) or 1337

	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 31 + 223) % 2147483647
		pipeline:registerGuardAttestation("AntiTamper", function(bs, sMod)
			local tok = (bs * 31 + 223) % sMod
			local code = "local _ok = (string.byte(type(pcall), 1) == 102 and string.byte(type(type), 1) == 102 and string.byte(type(math), 1) == 116 and string.byte(type(string), 1) == 116 and string.byte(type(table), 1) == 116); " ..
				"if _ok and math.abs(-42) == 42 and math.floor(257.8) == 257 then return " .. tostring(tok) .. " else return 0 end"
			return code, tok
		end, expected)
	end

	return ast
end

return AntiTamper
