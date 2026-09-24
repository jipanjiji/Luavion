-- This Script is Part of the Zero Impact Obfuscator
--
-- MacroProcessor.lua
--
-- Evaluates developer macros (ZERO_NO_VIRTUALIZE, ZERO_ENCFUNC, ZERO_ENCSTR, ZERO_CRASH, ZERO_OBFUSCATED).

local Step = require("zerolua.step");
local Ast = require("zerolua.ast");
local visitast = require("zerolua.visitast");

local MacroProcessor = Step:extend();
MacroProcessor.Description = "Processes developer security and performance macros (ZERO_NO_VIRTUALIZE, ZERO_ENCSTR, ZERO_CRASH, ZERO_OBFUSCATED).";
MacroProcessor.Name = "Macro Processor";

MacroProcessor.SettingsDescriptor = {};

function MacroProcessor:init(_) end

function MacroProcessor:apply(ast)
	visitast(ast, nil, function(node, data)
		if node.__do_not_touch then return node end
		
		-- Replace ZERO_OBFUSCATED variable references with boolean true
		if node.kind == Ast.AstKind.VariableExpression then
			local success, varName = pcall(function() return node:getName() end)
			if success and varName == "ZERO_OBFUSCATED" then
				return Ast.BooleanExpression(true)
			end
		end
		
		-- Handle FunctionCallExpression macros
		if node.kind == Ast.AstKind.FunctionCallExpression then
			if node.base and node.base.kind == Ast.AstKind.VariableExpression then
				local success, macroName = pcall(function() return node.base:getName() end)
				if success then
					if macroName == "ZERO_NO_VIRTUALIZE" then
						local target = node.args[1]
						if target then
							target.__do_not_touch = true
							return target
						end
					elseif macroName == "ZERO_CRASH" then
						local gScope, gId = ast.globalScope:resolveGlobal("error")
						return Ast.FunctionCallExpression(
							Ast.VariableExpression(gScope, gId),
							{Ast.StringExpression("https://dsc.gg/zeroimpact")}
						)
					elseif macroName == "ZERO_ENCSTR" then
						local strArg = node.args[1]
						if strArg and strArg.kind == Ast.AstKind.StringExpression then
							strArg.__do_not_touch = false
							return strArg
						end
					end
				end
			end
		end

		return node
	end)
end

return MacroProcessor;
