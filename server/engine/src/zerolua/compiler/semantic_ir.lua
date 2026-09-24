-- This Script is Part of the Zero Lua Obfuscator v3.1
--
-- semantic_ir.lua
--
-- Semantic Intermediate Representation (IR) for Zero Lua v3.1.
-- High-level program semantics are captured in an abstract IR before being synthesized
-- into prototype-specific micro-operation execution graphs by the GraphSynthesizer.

local SemanticIR = {}

SemanticIR.IR_NOP          = 0
SemanticIR.IR_MOVE         = 1
SemanticIR.IR_LOADK        = 2
SemanticIR.IR_LOADBOOL     = 3
SemanticIR.IR_LOADNIL      = 4
SemanticIR.IR_GETGLOBAL    = 5
SemanticIR.IR_SETGLOBAL    = 6
SemanticIR.IR_GETUPVAL     = 7
SemanticIR.IR_SETUPVAL     = 8
SemanticIR.IR_GETTABLE     = 9
SemanticIR.IR_SETTABLE     = 10
SemanticIR.IR_NEWTABLE     = 11
SemanticIR.IR_ADD          = 12
SemanticIR.IR_SUB          = 13
SemanticIR.IR_MUL          = 14
SemanticIR.IR_DIV          = 15
SemanticIR.IR_MOD          = 16
SemanticIR.IR_POW          = 17
SemanticIR.IR_UNM          = 18
SemanticIR.IR_NOT          = 19
SemanticIR.IR_LEN          = 20
SemanticIR.IR_CONCAT       = 21
SemanticIR.IR_JMP          = 22
SemanticIR.IR_EQ           = 23
SemanticIR.IR_LT           = 24
SemanticIR.IR_LE           = 25
SemanticIR.IR_CALL         = 26
SemanticIR.IR_RETURN       = 27
SemanticIR.IR_FORPREP      = 28
SemanticIR.IR_FORLOOP      = 29
SemanticIR.IR_CLOSURE      = 30
SemanticIR.IR_VARARG       = 31
SemanticIR.IR_GETTABLE_K   = 32
SemanticIR.IR_SETTABLE_K   = 33
SemanticIR.IR_ADD_K        = 34

function SemanticIR.createNode(op, a, b, c, aux)
	return {
		op = op,
		a = a or 0,
		b = b or 0,
		c = c or 0,
		aux = aux
	}
end

return SemanticIR
