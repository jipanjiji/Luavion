-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- namegenerators/mangled.lua
--
-- This Script provides a function for generation of mangled names


local util = require("zerolua.util");
local chararray = util.chararray;

local VarDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_");
local VarStartDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");

return function(id, _)
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
	if name == "_k0" or name == "_k1" or name == "_k2" then name = name .. "x" end
	return name
end