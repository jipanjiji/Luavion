-- This Script is Part of the Zero Lua Obfuscator v2.0
--
-- isa.lua
--
-- Variable-Length Instruction (VLI) Architecture, Randomized Opcode Vocabulary,
-- and Dynamic Superinstructions for Zero Lua V2.0.

local RandomDomains = require("zerolua.random_domains")

local ISA = {}

local BASE_OPCODE_NAMES = {
	"MOVE", "LOADK", "LOADBOOL", "LOADNIL", "GETGLOBAL", "SETGLOBAL",
	"GETUPVAL", "SETUPVAL", "GETTABLE", "SETTABLE", "NEWTABLE",
	"ADD", "SUB", "MUL", "DIV", "MOD", "POW", "UNM", "NOT", "LEN", "CONCAT",
	"JMP", "EQ", "LT", "LE", "CALL", "RETURN", "FORPREP", "FORLOOP",
	"CLOSURE", "VARARG", "GETTABLE_K", "SETTABLE_K", "ADD_K",
	"ADD_ALT", "SUB_ALT", "MOVE_ALT", "GETTABLE_ALT", "CALL_ALT", "GETGLOBAL_ALT", "CALL_TABLE_APPEND", "CALL_EXPAND",
	"CALL_RET", "CALL_EXPAND_RET", "FORIN_PREP"
}

local SUPERINSTRUCTION_NAMES = {
	"LOADK_MOVE",
	"LOADK_CALL",
	"GETTABLE_CALL",
	"MOVE_RET",
	"GETGLOBAL_CALL",
	"GETTABLE_SETTABLE",
	"ADD_MOVE",
	"LOADK_SETTABLE",
	"ADD_SETTABLE",
	"MOVE_CALL",
	"GETUPVAL_CALL",
	"LOADNIL_RET",
	"CONCAT_MOVE",
	"ROBLOX_GETSERVICE",
	"ROBLOX_GET_LOCAL_CHAR",
	"TABLE_SET_CHAIN",
	"CALL_TABLE_APPEND",
}

-- Variable-Length Instruction Word Widths (1 word = 2 bytes)
-- Format 2 (Short 4 bytes / 2 words): JMP
-- Format 3 (Medium 6 bytes / 3 words): MOVE, LOADK, GETGLOBAL, SETGLOBAL, GETUPVAL, SETUPVAL, NEWTABLE, FORPREP, RETURN, UNM, NOT, LEN
-- Format 4 (Standard 8 bytes / 4 words): ADD, SUB, MUL, DIV, MOD, POW, CONCAT, EQ, LT, LE, GETTABLE, SETTABLE, CALL, FORLOOP, CLOSURE, VARARG, LOADBOOL, LOADNIL, Superinstructions
local DEFAULT_OPCODE_WIDTHS = {
	JMP = 2,
	LOADNIL_RET = 2,
	UNM = 3,
	NOT = 3,
	LEN = 3,
	MOVE = 3,
	MOVE_ALT = 3,
	LOADK = 3,
	GETGLOBAL = 3,
	GETGLOBAL_ALT = 3,
	SETGLOBAL = 3,
	GETUPVAL = 3,
	SETUPVAL = 3,
	NEWTABLE = 3,
	FORPREP = 3,
	RETURN = 3,
	MOVE_RET = 3,
	CALL_RET = 3,
	CALL_EXPAND_RET = 3,
	FORIN_PREP = 4,
	ADD = 4,
	ADD_ALT = 4,
	SUB = 4,
	SUB_ALT = 4,
	MUL = 4,
	DIV = 4,
	MOD = 4,
	POW = 4,
	CONCAT = 4,
	EQ = 4,
	LT = 4,
	LE = 4,
	GETTABLE = 4,
	GETTABLE_ALT = 4,
	SETTABLE = 4,
	CALL = 4,
	CALL_ALT = 4,
	FORLOOP = 4,
	CLOSURE = 4,
	VARARG = 4,
	LOADBOOL = 4,
	LOADNIL = 4,
	GETTABLE_K = 4,
	SETTABLE_K = 4,
	ADD_K = 4,
	LOADK_MOVE = 4,
	LOADK_CALL = 4,
	GETTABLE_CALL = 4,
	GETGLOBAL_CALL = 4,
	GETTABLE_SETTABLE = 4,
	ADD_MOVE = 4,
	LOADK_SETTABLE = 4,
	ADD_SETTABLE = 4,
	MOVE_CALL = 4,
	GETUPVAL_CALL = 4,
	CONCAT_MOVE = 4,
	ROBLOX_GETSERVICE = 4,
	ROBLOX_GET_LOCAL_CHAR = 4,
	TABLE_SET_CHAIN = 4,
	CALL_TABLE_APPEND = 4,
	CALL_EXPAND = 4,
}

function ISA.getRandomizedOpcodes(includeSuper)
	local vmRng = RandomDomains.get("VM")
	local used = {}
	local opcodes = {}
	local widths = {}

	local allNames = {}
	for _, n in ipairs(BASE_OPCODE_NAMES) do
		table.insert(allNames, n)
	end
	if includeSuper ~= false then
		for _, n in ipairs(SUPERINSTRUCTION_NAMES) do
			table.insert(allNames, n)
		end
	end

	for _, name in ipairs(allNames) do
		local id
		repeat
			id = (vmRng and vmRng:random(11, 249)) or math.random(11, 249)
		until not used[id]
		used[id] = true
		opcodes[name] = id
		widths[name] = DEFAULT_OPCODE_WIDTHS[name] or 4
	end
	return opcodes, widths
end

ISA.BASE_OPCODES = BASE_OPCODE_NAMES
ISA.SUPERINSTRUCTIONS = SUPERINSTRUCTION_NAMES
ISA.DEFAULT_OPCODE_WIDTHS = DEFAULT_OPCODE_WIDTHS

return ISA
