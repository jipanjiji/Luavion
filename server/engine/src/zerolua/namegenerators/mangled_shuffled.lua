-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- namegenerators/mangled_shuffled.lua
--
-- This Script provides a function for generation of mangled names with shuffled character order


local util = require("zerolua.util");
local chararray = util.chararray;

local BASE_VAR_DIGITS = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_");
local BASE_VAR_START_DIGITS = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");

local VarDigits = {};
local VarStartDigits = {};

local function generateName(id, _)
	local name = ''
	local d = id % #VarStartDigits
	id = (id - d) / #VarStartDigits
	name = name..VarStartDigits[d+1]
	while id > 0 do
		local e = id % #VarDigits
		id = (id - e) / #VarDigits
		name = name..VarDigits[e+1]
	end
	if #name < 2 then name = "_" .. name .. VarDigits[(d * 7 + 11) % #VarDigits + 1] end
	if name == "_rw" then name = "_rx" end
	if name == "_GM" then name = "_GX" end
	if name == "_k0" or name == "_k1" or name == "_k2" or name == "_a" or name == "_ps" then name = name .. "x" end
	return name
end

local function prepare(_)
	VarDigits = {}
	for i = 1, #BASE_VAR_DIGITS do VarDigits[i] = BASE_VAR_DIGITS[i] end
	VarStartDigits = {}
	for i = 1, #BASE_VAR_START_DIGITS do VarStartDigits[i] = BASE_VAR_START_DIGITS[i] end
	util.shuffle(VarDigits);
	util.shuffle(VarStartDigits);
end

return {
	generateName = generateName,
	prepare = prepare
};