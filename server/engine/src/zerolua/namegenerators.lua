-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- namegenerators.lua
--
-- This Script provides a collection of name generators for ZeroLua.

return {
	Mangled = require("zerolua.namegenerators.mangled");
	MangledShuffled = require("zerolua.namegenerators.mangled_shuffled");
	Il = require("zerolua.namegenerators.Il");
	Number = require("zerolua.namegenerators.number");
	Confuse = require("zerolua.namegenerators.confuse");
}