-- This Script is Part of the Zero Impact Obfuscator
--
-- RobloxMathAttestation.lua
--
-- Layer 1 Geometric & Floating-Point Environment Attestation (LimeObf-grade).
-- Cryptographically binds the VM key derivation directly to Roblox Luau's Vector3 C++ geometry,
-- floating-point bitcast invariants, and native C-closure integrity.

local Step = require("zerolua.step")
local Parser = require("zerolua.parser")
local Ast = require("zerolua.ast")
local AstKind = Ast.AstKind
local Enums = require("zerolua.enums")
local RandomStrings = require("zerolua.randomStrings")
local RandomDomains = require("zerolua.random_domains")
local visitast = require("zerolua.visitast")

local RobloxMathAttestation = Step:extend()
RobloxMathAttestation.Description = "Cryptographically binds VM key material to Roblox Luau Vector3 geometric invariants and C-closure integrity (LimeObf technique)."
RobloxMathAttestation.Name = "Roblox Math Attestation"

RobloxMathAttestation.SettingsDescriptor = {
	Mode = {
		name = "Mode",
		description = "Enforcement mode: 'STRICT' (fails if not Roblox) or 'COMPAT' (graceful fallback for non-Roblox Lua).",
		type = "enum",
		values = { "COMPAT", "STRICT" },
		default = "COMPAT",
	},
}

function RobloxMathAttestation:init(settings)
	self.settings = settings or {}
end

function RobloxMathAttestation:apply(ast, pipeline)
	if pipeline and pipeline.PrettyPrint then
		return ast
	end

	local mode = (self.settings and self.settings.Mode) or "COMPAT"
	local seed = (pipeline and pipeline.Seed) or 1337
	local isStrict = (mode == "STRICT")

	-- Register with VM decentralized state attestation framework
	if pipeline and pipeline.registerGuardAttestation then
		local expected = (seed * 41 + 193) % 2147483647
		pipeline:registerGuardAttestation("RobloxMathAttestation", function(bs, sMod)
			local tok = (bs * 41 + 193) % sMod

			-- Construct LimeObf-style geometric and floating point verification code
			-- 1. Vector3.new(3, 4, 0).Magnitude == 5
			-- 2. Vector3.new(1, 2, 3):Dot(Vector3.new(4, 5, 6)) == 32
			-- 3. string.unpack("<I4", string.pack("<f", 1.0)) == 1065353216
			-- 4. Native closure verification (iscclosure check on core functions)
			local checkCode
			if isStrict then
				checkCode = [[
					local _v3 = Vector3 or (_G and _G.Vector3)
					if not _v3 or type(_v3.new) ~= "function" then return 0 end
					local _u = _v3.new(3, 4, 0)
					if _u.Magnitude ~= 5 then return 0 end
					local _d = _v3.new(1, 2, 3):Dot(_v3.new(4, 5, 6))
					if _d ~= 32 then return 0 end
					local _sp = string and string.pack
					local _su = string and string.unpack
					if _sp and _su then
						local _f = _su("<I4", _sp("<f", 1.0))
						if _f ~= 1065353216 then return 0 end
					end
					local _isc = iscclosure or (_G and _G.iscclosure)
					if _isc and (not _isc(type) or not _isc(pcall)) then return 0 end
					return ]] .. tostring(tok)
			else
				-- COMPAT Mode: If Vector3 exists, enforces strict invariants.
				-- If running in non-Roblox Lua 5.1/Wasm, verifies equivalent math identities.
				checkCode = [[
					local _v3 = Vector3 or (_G and _G.Vector3)
					if _v3 and type(_v3.new) == "function" then
						local _u = _v3.new(3, 4, 0)
						if _u.Magnitude ~= 5 then return 0 end
						local _d = _v3.new(1, 2, 3):Dot(_v3.new(4, 5, 6))
						if _d ~= 32 then return 0 end
						local _isc = iscclosure or (_G and _G.iscclosure)
						if _isc and (not _isc(type) or not _isc(pcall)) then return 0 end
					else
						local _s = math.sqrt(3*3 + 4*4)
						if _s ~= 5 then return 0 end
						if type(pcall) ~= "function" then return 0 end
					end
					return ]] .. tostring(tok)
			end

			return checkCode, tok
		end, expected)
	end

	-- Also inject an inline invariant attestation node into the AST
	local v_sc = RandomStrings.randomString(6)
	local v_chk = RandomStrings.randomString(8)
	local v_v3 = RandomStrings.randomString(7)
	local v_res = RandomStrings.randomString(6)

	local function toCharExpr(s)
		local parts = {}
		for i = 1, #s do
			local b = string.byte(s, i)
			local off = ((seed * (i * 5 + 7) + i * 11) % 256)
			local masked = (b + off) % 256
			table.insert(parts, string.format("((%d - %d + 256) %% 256)", masked, off))
		end
		return v_sc .. "(" .. table.concat(parts, ",") .. ")"
	end

	local inlineCode
	if isStrict then
		inlineCode = string.format([[
			local %s = string.char
			local %s = Vector3 or (_G and _G.Vector3)
			if not %s or type(%s.new) ~= %s then return end
			local %s = %s.new(6, 8, 0)
			if %s.Magnitude ~= 10 then return end
		]], v_sc, v_v3, v_v3, v_v3, toCharExpr("function"), v_res, v_v3, v_res)
	else
		inlineCode = string.format([[
			local %s = string.char
			local %s = Vector3 or (_G and _G.Vector3)
			if %s and type(%s.new) == %s then
				local %s = %s.new(6, 8, 0)
				if %s.Magnitude ~= 10 then return end
			end
		]], v_sc, v_v3, v_v3, v_v3, toCharExpr("function"), v_res, v_v3, v_res)
	end

	local status, parsed = pcall(function()
		return Parser:new({ LuaVersion = pipeline and pipeline.LuaVersion or Enums.LuaVersion.LuaU }):parse(inlineCode)
	end)

	if status and parsed and parsed.body and parsed.body.statements then
		for i = #parsed.body.statements, 1, -1 do
			local stat = parsed.body.statements[i]
			stat.__do_not_touch = true
			stat.__semantic_preserve = true
			table.insert(ast.body.statements, 1, stat)
		end
	end

	return ast
end

return RobloxMathAttestation
