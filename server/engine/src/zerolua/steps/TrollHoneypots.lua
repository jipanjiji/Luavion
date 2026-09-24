-- This Script is Part of the Zero Lua Obfuscator
--
-- TrollHoneypots.lua
--
-- Injects semantically valid decoy data structures and realistic state buffers.

local Step = require("zerolua.step");
local Ast = require("zerolua.ast");
local visitast = require("zerolua.visitast");
local Scope = require("zerolua.scope");
local Parser = require("zerolua.parser");
local Enums = require("zerolua.enums");
local RandomDomains = require("zerolua.random_domains");

local TrollHoneypots = Step:extend();
TrollHoneypots.Description = "Injects structurally valid decoy buffers and internal state caches.";
TrollHoneypots.Name = "Troll Honeypots";

TrollHoneypots.SettingsDescriptor = {};

function TrollHoneypots:init(_) end

function TrollHoneypots:apply(ast, pipeline)
	local seed = (pipeline and pipeline.Seed) or 1337
	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 41 + 277) % 2147483647
		pipeline:registerGuardAttestation("TrollHoneypots", function(bs, sMod)
			local tok = (bs * 41 + 277) % sMod
			return "return " .. tostring(tok), tok
		end, expected)
	end

	if ast.body and ast.body.kind == Ast.AstKind.Block then
		local statements = ast.body.statements
		local newStatements = {}
		local scope = ast.body.scope

		-- Inject structurally valid, plausible internal state structures
		local rng = RandomDomains.get("OBFUSCATION")
		local seedVal = (rng and rng:random(1000, 9999)) or math.random(1000, 9999)
		local RandomStrings = require("zerolua.randomStrings")
		local stateVar = RandomStrings.randomString(7)
		local valVar = RandomStrings.randomString(7)
		local k0 = RandomStrings.randomString(6)
		local k1 = RandomStrings.randomString(6)
		local k2 = RandomStrings.randomString(6)

		local mult1 = (rng and rng:random(2, 9)) or math.random(2, 9)
		local mult2 = (rng and rng:random(11, 23)) or math.random(11, 23)
		local modOffset = (rng and rng:random(13, 199)) or math.random(13, 199)
		local sentinel = (rng and rng:random(-999999, -10000)) or math.random(-999999, -10000)

		local decoyCode = string.format([[
do
	local %s = {
		[%q] = %d,
		[%q] = %d,
		[%q] = %d
	}
	local %s = (%s[%q] + %s[%q]) %% %d
	if %s == %d then
		%s = nil
	end
end
]], stateVar, k0, seedVal, k1, seedVal * mult1, k2, seedVal * mult2, valVar, stateVar, k0, stateVar, k1, seedVal + modOffset, valVar, sentinel, stateVar)

		local parsedDecoy = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(decoyCode)
		local doStat = parsedDecoy.body.statements[1]
		visitast(parsedDecoy, nil, function(node)
			node.__do_not_touch = true
		end)

		doStat.body.scope:setParent(scope)
		table.insert(newStatements, doStat)

		for _, stmt in ipairs(statements) do
			table.insert(newStatements, stmt)
		end
		ast.body.statements = newStatements
	end

	return ast
end

return TrollHoneypots
