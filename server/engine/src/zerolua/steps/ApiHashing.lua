-- This Script is Part of the Zero Lua Obfuscator v1.4
--
-- ApiHashing.lua
--
-- Replaces plaintext global API and environment references with dynamic 32-bit polynomial
-- hash lookups with per-build randomized coefficients and lazy environment caching.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")
local RandomDomains = require("zerolua.random_domains")
local StdApiNames = require("zerolua.std_api_names")
local AstKind = Ast.AstKind

local ApiHashing = Step:extend()
ApiHashing.Description = "Dynamic 32-bit Polynomial Hash Global API Resolution Guard."
ApiHashing.Name = "ApiHashing"

ApiHashing.SettingsDescriptor = {}

function ApiHashing:init(settings)
	settings = settings or {}
	self.settings = settings
end

local computePolynomialHash = StdApiNames.computeHash
local stdGlobalNames = StdApiNames.set

function ApiHashing:apply(ast, pipeline)
	local seed = (pipeline and pipeline.Seed) or 1337
	local mult = 128 + (seed % 64) * 2 + 1
	local offset = 5000 + (seed * 37) % 2000
	local mod = 2147483647

	if pipeline then
		pipeline.apiHashCoeffs = {
			mult = mult,
			offset = offset,
			mod = mod,
		}
	end

	-- Scan and resolve standard global variables, method names, and properties via dynamic polynomial hash lookups
	visitast(ast, function(node)
		if (node.kind == AstKind.VariableExpression or node.kind == AstKind.AssignmentVariable or node.kind == AstKind.FunctionDeclaration) and node.scope and node.scope.isGlobal then
			local varName = node.scope:getVariableName(node.id)
			if varName and stdGlobalNames[varName] then
				node.apiHash = computePolynomialHash(varName, mult, mod, offset)
				node.isHashedGlobal = true
			end
		end
	end)

	return ast
end

return ApiHashing
