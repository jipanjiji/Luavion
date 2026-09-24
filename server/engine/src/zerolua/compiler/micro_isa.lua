-- This Script is Part of the Zero Lua Obfuscator v3.4
--
-- micro_isa.lua
--
-- Pure Abstract State Machine Combinators for Zero Lua v3.4.
-- Completely destroys all semantic tokens, named arithmetic cases, and action strings.
-- Driven by state slot bus transfers, rolling kernel polynomials, dynamic capability matrices, and unwinding.

local MicroISA = {}

-- Abstract State Machine Combinators:
MicroISA.COMB_TRANSFER    = 1 -- Slot bus transfer between register bank and state registers
MicroISA.COMB_ALGEBRAIC   = 2 -- Generalized algebraic state kernel (dynamic polynomial & arithmetic evaluation)
MicroISA.COMB_REFERENCE   = 3 -- Dynamic table indexing and property mutation via capability masks
MicroISA.COMB_CAPABILITY  = 4 -- Host bridge capability invocation (numeric capability matrix)
MicroISA.COMB_UNWIND      = 5 -- Frame return and stack unwinding

-- Host Capability Matrix Tokens (Numeric IDs, ZERO action strings):
MicroISA.CAP_INVOKE       = 1 -- Host function call
MicroISA.CAP_CLOSURE      = 2 -- Closure / sub-prototype instantiation
MicroISA.CAP_RESOLVE_ENV  = 3 -- Scoped environment lookup
MicroISA.CAP_VARARG       = 4 -- Vararg register mapping
MicroISA.CAP_CONSTANT     = 5 -- Ephemeral constant synthesis
MicroISA.CAP_SET_ENV      = 6 -- Environment modification
MicroISA.CAP_NEW_TABLE    = 7 -- Table allocation

function MicroISA.getOpcodePermutation(baseSalt)
	baseSalt = baseSalt or 1337
	local pool = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
	local s = (baseSalt * 1337 + 5381) % 2147483647
	for i = #pool, 2, -1 do
		s = (s * 1664525 + 1013904223) % 4294967296
		local j = (math.floor(s / 65536) % i) + 1
		pool[i], pool[j] = pool[j], pool[i]
	end
	local mopMap = {}
	local invMap = {}
	for orig = 1, 14 do
		local perm = pool[orig]
		mopMap[orig] = perm
		invMap[perm] = orig
	end
	mopMap.inv = invMap
	return mopMap
end

return MicroISA
