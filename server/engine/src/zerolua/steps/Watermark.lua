-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- Watermark.lua
--
-- This Script provides a Step that will add a watermark to the script

local Step = require("zerolua.step");
local Ast = require("zerolua.ast");
local Scope = require("zerolua.scope");

local Watermark = Step:extend();
Watermark.Description = "This Step will add a watermark to the script";
Watermark.Name = "Watermark";

Watermark.SettingsDescriptor = {
  Content = {
    name = "Content",
    description = "The Content of the Watermark",
    type = "string",
    default = "Protected by Zero Lua V9.5 - https://zerolua.pages.dev",
  },
  CustomVariable = {
    name = "Custom Variable",
    description = "The Variable that will be used for the Watermark",
    type = "string",
    default = "_WATERMARK",
  }
}

function Watermark:init(settings)
	
end

function Watermark:apply(ast)
  local body = ast.body;
  if string.len(self.Content) > 0 then
    local scope, variable = ast.globalScope:resolve(self.CustomVariable);
    local watermark = Ast.AssignmentVariable(ast.globalScope, variable);

    local functionScope = Scope:new(body.scope);
    functionScope:addReferenceToHigherScope(ast.globalScope, variable);
    
    local arg = functionScope:addVariable();
    local statement = Ast.PassSelfFunctionCallStatement(Ast.StringExpression(self.Content), "gsub", {
      Ast.StringExpression(".+"),
      Ast.FunctionLiteralExpression({
        Ast.VariableExpression(functionScope, arg)
      }, Ast.Block({
        Ast.AssignmentStatement({
          watermark
        }, {
          Ast.VariableExpression(functionScope, arg)
        })
      }, functionScope))
    });

    table.insert(ast.body.statements, 1, statement)
  end
end

return Watermark;