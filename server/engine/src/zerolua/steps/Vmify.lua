-- This Script is Part of the Zero Lua Obfuscator v1.4
--
-- Vmify.lua
--
-- Compiles Lua AST into polymorphic register-based bytecode executed by an isolated runtime VM interpreter.

local Step = require("zerolua.step")
local BytecodeCompiler = require("zerolua.compiler.bytecode_compiler")

local Vmify = Step:extend()
Vmify.Description = "Compiles Lua AST into polymorphic register-based pure bytecode opcodes executed by an isolated runtime VM interpreter."
Vmify.Name = "Vmify"

Vmify.SettingsDescriptor = {}

function Vmify:init(settings)
	self.settings = settings or {}
end

function Vmify:apply(ast, pipeline)
	local profileLevel = (self.settings and (self.settings.Profile or self.settings.Level)) or "STRONG"
	local compiler = BytecodeCompiler:new(nil, profileLevel, self.settings, pipeline)
	return compiler:compile(ast)
end

return Vmify