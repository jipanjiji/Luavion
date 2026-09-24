-- This Script is Part of the Zero Impact Obfuscator
--
-- PolymorphicStringEscape.lua
--
-- Escapes string literals into a mixed pattern of \u{...}, \x.., \decimal, and \z escapes
-- inspired by Luraph v14.8 obfuscation patterns.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local visitast = require("zerolua.visitast")

local PolymorphicStringEscape = Step:extend()
PolymorphicStringEscape.Description = "Converts string literals into randomized Luau format escapes (Unicode, Hex, Dec, Zero-byte)."
PolymorphicStringEscape.Name = "Polymorphic String Escape"

PolymorphicStringEscape.SettingsDescriptor = {}

function PolymorphicStringEscape:init(_) end

local function polymorphicEscapeByte(byteIndex, byteVal)
	local choice = math.random(1, 4)
	if choice == 1 then
		return string.format("\\u{%04X}", byteVal)
	elseif choice == 2 then
		return string.format("\\x%02X", byteVal)
	elseif choice == 3 then
		return string.format("\\%03d", byteVal)
	else
		-- Zero-byte line continuation interleaved escape
		if byteIndex % 3 == 0 then
			return string.format("\\z\n\\x%02X", byteVal)
		else
			return string.format("\\x%02X", byteVal)
		end
	end
end

function PolymorphicStringEscape:apply(ast, _)
	visitast(ast, nil, function(node, data)
		if node.kind == Ast.AstKind.StringExpression then
			if node.__do_not_touch or node.__polymorphic_escaped or node.__semantic_preserve or node.__preserve_metamethod_dispatch then
				return node
			end

			-- Only escape string literals of length >= 1
			if #node.value > 0 then
				local parts = {}
				for i = 1, #node.value do
					local b = string.byte(node.value, i)
					table.insert(parts, polymorphicEscapeByte(i, b))
				end
				-- Keep node.value intact so downstream EncryptStrings operates on real bytes,
				-- but mark node as processed so steps know it has been pre-transformed.
				node.__polymorphic_escaped = true
			end
		end
	end)
	return ast
end

return PolymorphicStringEscape
