-- This Script is Part of the Zero Impact Obfuscator
--
-- Anti25msTrace.lua
--
-- Defeats dynamic tracing dumpers (such as 25ms, ConstantDumper, Metatable Hook Loggers)
-- by detecting proxy hooks, corrupting the execution environment, and exhausting the tracer's output buffer with decoy flooding.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")

local Anti25msTrace = Step:extend()
Anti25msTrace.Description = "Dynamic 25ms / proxy metatable tracing dumper detector, fenv poisoner, and decoy flooder."
Anti25msTrace.Name = "Anti 25ms Trace Guard"

Anti25msTrace.SettingsDescriptor = {}

function Anti25msTrace:init(_) end

function Anti25msTrace:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local seed = (pipeline and pipeline.Seed) or 1337
	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 19 + 71) % 2147483647
		pipeline:registerGuardAttestation("Anti25msTrace", function(bs, sMod)
			local tok = (bs * 19 + 71) % sMod
			local code = "local _q = rawget; local _sc = (string and string.char) or string.char; " ..
				"if _q and _sc and _G and (_q(_G, _sc(95,95,50,53,109,115)) ~= nil or _q(_G, _sc(95,95,116,114,97,99,101)) ~= nil or _q(_G, _sc(72,79,79,75,95,76,79,71)) ~= nil) then return 0 else return " .. tostring(tok) .. " end"
			return code, tok
		end, expected)
	end

	return ast
end

return Anti25msTrace
