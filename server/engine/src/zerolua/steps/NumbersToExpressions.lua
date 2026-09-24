-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- NumbersToExpressions.lua
--
-- This Script provides an Obfuscation Step, that converts Number Literals to expressions.
-- This step can now also convert numbers to different representations!
-- Supported representations: hex, binary, scientific, normal. Please note that binary is only supported in Lua 5.2 and above.

unpack = unpack or table.unpack

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local visitast = require("zerolua.visitast")
local util = require("zerolua.util")
local logger = require("logger")
local AstKind = Ast.AstKind

local NumbersToExpressions = Step:extend()
NumbersToExpressions.Description = "This Step Converts number Literals to Expressions"
NumbersToExpressions.Name = "Numbers To Expressions"

NumbersToExpressions.SettingsDescriptor = {
	Threshold = {
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},

	InternalThreshold = {
		type = "number",
		default = 0.2,
		min = 0,
		max = 0.8,
	},

	NumberRepresentationMutation = {
		type = "boolean",
		default = false,
		aliases = { "NumberRepresentationMutaton" },
	},

	AllowedNumberRepresentations = {
		type = "table",
		default = {"hex", "scientific", "normal"},
		values = {"hex", "binary", "scientific", "normal"},
	},
}

local function generateModuloExpression(n)
	local rhs = n + math.random(1, 2^24)
	local multiplier = math.random(1, 2^8)
	local lhs = n + (multiplier * rhs)
	return lhs, rhs
end

local function contains(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

function NumbersToExpressions:init(_)
	self.MaxDepth = 2
	self.ExpressionGenerators = {
		-- 1. Affine Scaling: (val - (m * k)) + (m * k) (Integer-preserving)
		function(val, depth)
			if type(val) ~= "number" or math.floor(val) ~= val or val < -2^24 or val > 2^24 then
				return false
			end
			local multipliers = { 3, 5, 7, 9, 11, 13, 17, 19, 23, 29, 31 }
			local m = multipliers[math.random(1, #multipliers)]
			local k = math.random(-2048, 2048)
			local mk = m * k
			local diff = val - mk
			if (diff + mk) ~= val then
				return false
			end
			local prod = Ast.MulExpression(
				self:CreateNumberExpression(m, depth),
				self:CreateNumberExpression(k, depth),
				true
			)
			return Ast.AddExpression(
				self:CreateNumberExpression(diff, depth),
				prod,
				true
			)
		end,

		-- 2. 3-Term Polymorphic Decomposition: (p1 + p2) + (val - p1 - p2)
		function(val, depth)
			if type(val) ~= "number" or math.floor(val) ~= val then
				return false
			end
			local p1 = math.random(-2^18, 2^18)
			local p2 = math.random(-2^18, 2^18)
			local p3 = val - (p1 + p2)
			if (p1 + p2 + p3) ~= val then
				return false
			end
			local leftGroup = Ast.AddExpression(
				self:CreateNumberExpression(p1, depth),
				self:CreateNumberExpression(p2, depth),
				true
			)
			return Ast.AddExpression(
				leftGroup,
				self:CreateNumberExpression(p3, depth),
				true
			)
		end,

		-- 3. Inverted Affine: (val + (factor * k)) - (factor * k) (Integer-preserving)
		function(val, depth)
			if type(val) ~= "number" or math.floor(val) ~= val or val == 0 or val < -2^20 or val > 2^20 then
				return false
			end
			local factors = { 2, 4, 8, 10, 16, 20, 25 }
			local factor = factors[math.random(1, #factors)]
			local k = math.random(-1024, 1024)
			local fk = factor * k
			local sum = val + fk
			if (sum - fk) ~= val then
				return false
			end
			local prod = Ast.MulExpression(
				self:CreateNumberExpression(factor, depth),
				self:CreateNumberExpression(k, depth),
				true
			)
			return Ast.SubExpression(
				self:CreateNumberExpression(sum, depth),
				prod,
				true
			)
		end,

		-- 4. Dynamic Addition
		function(val, depth)
			local val2 = math.random(-2 ^ 20, 2 ^ 20)
			local diff = val - val2
			if tonumber(tostring(diff)) + tonumber(tostring(val2)) ~= val then
				return false
			end
			return Ast.AddExpression(
				self:CreateNumberExpression(val2, depth),
				self:CreateNumberExpression(diff, depth),
				true
			)
		end,

		-- 5. Dynamic Subtraction
		function(val, depth)
			local val2 = math.random(-2 ^ 20, 2 ^ 20)
			local diff = val + val2
			if tonumber(tostring(diff)) - tonumber(tostring(val2)) ~= val then
				return false
			end
			return Ast.SubExpression(
				self:CreateNumberExpression(diff, depth),
				self:CreateNumberExpression(val2, depth),
				true
			)
		end,

		-- 6. Modulo
		function(val, depth)
			if type(val) ~= "number" or math.floor(val) ~= val or val < 0 or val > 2^20 then
				return false
			end
			local lhs, rhs = generateModuloExpression(val)
			if tonumber(tostring(lhs)) % tonumber(tostring(rhs)) ~= val then
				return false
			end
			return Ast.ModExpression(
				self:CreateNumberExpression(lhs, depth),
				self:CreateNumberExpression(rhs, depth),
				true
			)
		end,
	}
end

function NumbersToExpressions:CreateNumberExpression(val, depth)
	local limit = self.MaxDepth or 2
	if depth >= limit or (depth >= 1 and math.random() > 0.45) then
		return Ast.NumberExpression(val)
	end

	local generators = util.shuffle({ unpack(self.ExpressionGenerators) })
	for _, generator in ipairs(generators) do
		local node = generator(val, depth + 1)
		if node then
			return node
		end
	end
	return Ast.NumberExpression(val)
end

function NumbersToExpressions:apply(ast)
	if contains(self.AllowedNumberRepresentations, "binary") then
		logger:warn("Warning: Binary representation is only supported in Lua 5.2 and above!")
	end

	visitast(ast, nil, function(node, _)
		if node.__do_not_touch or node.__semantic_preserve then
			return
		end
		if node.kind == AstKind.NumberExpression then
			if math.random() <= self.Threshold then
				return self:CreateNumberExpression(node.value, 0)
			end
		end
	end)
end

return NumbersToExpressions
