-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- randomStrings.lua
--
-- This Script provides a library for generating random strings

local Ast = require("zerolua.ast")
local utils = require("zerolua.util")
local charset = utils.chararray("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890")

local letterset = utils.chararray("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM")

local function randomString(wordsOrLen)
	if type(wordsOrLen) == "table" then
		return wordsOrLen[math.random(1, #wordsOrLen)];
	end

	wordsOrLen = wordsOrLen or math.random(2, 15);
	local res = letterset[math.random(1, #letterset)]
	for i = 2, wordsOrLen do
		res = res .. charset[math.random(1, #charset)]
	end
	return res
end

local function randomStringNode(wordsOrLen)
	return Ast.StringExpression(randomString(wordsOrLen))
end

return {
	randomString = randomString,
	randomStringNode = randomStringNode,
}
