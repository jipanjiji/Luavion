-- This Script is Part of the Zero Impact Obfuscator
--
-- HookCompatibility.lua
--
-- Static semantic compatibility pass for Roblox & Luau runtime hooking APIs.
-- Identifies hook-sensitive expressions, closures, metamethod dispatch keys,
-- and alias chains, marking AST nodes for strict semantic preservation across
-- downstream transformation passes without disabling security guards.

local Step = require("zerolua.step")
local Ast = require("zerolua.ast")
local visitast = require("zerolua.visitast")

local AstKind = Ast.AstKind

local HookCompatibility = Step:extend()
HookCompatibility.Description = "Static AST semantic preservation analysis for runtime hooking APIs."
HookCompatibility.Name = "HookCompatibility"

HookCompatibility.SettingsDescriptor = {}

local HOOK_GLOBALS = {
	hookmetamethod = true,
	hookfunction = true,
	getrawmetatable = true,
	setreadonly = true,
	isreadonly = true,
	checkcaller = true,
	getnamecallmethod = true,
	setnamecallmethod = true,
	newcclosure = true,
	clonefunction = true,
	replaceclosure = true,
}

local META_KEYS = {
	__index = true,
	__newindex = true,
	__namecall = true,
	__call = true,
	__tostring = true,
	__eq = true,
	__lt = true,
	__le = true,
	__add = true,
	__sub = true,
	__mul = true,
	__div = true,
	__mod = true,
	__pow = true,
	__unm = true,
	__concat = true,
}

function HookCompatibility:init(_) end

local function markNode(node, flag)
	if not node or type(node) ~= "table" then return end
	node.__hook_sensitive = true
	node.__semantic_preserve = true
	node.__dynamic_lookup_required = true
	node.__preserve_closure_identity = true
	node.__ignoreProxifyLocals = true
	if flag then
		node[flag] = true
	end
end

local function markSubtree(rootNode, flag)
	if not rootNode or type(rootNode) ~= "table" then return end
	markNode(rootNode, flag)

	-- Recursively mark child nodes
	for k, v in pairs(rootNode) do
		if type(v) == "table" and k ~= "scope" and k ~= "parentScope" and k ~= "globalScope" then
			if v.kind then
				markSubtree(v, flag)
			elseif #v > 0 then
				for _, item in ipairs(v) do
					if type(item) == "table" and item.kind then
						markSubtree(item, flag)
					end
				end
			end
		end
	end
end

function HookCompatibility:apply(ast, pipeline)
	local manifest = {
		used = false,
		apis = {},
		metamethods = {},
		calls = {},
		mutableTargets = {},
		usesNamecall = false,
	}

	local aliasVariables = {} -- [scope] = { [id] = originalApiName }

	local function registerAlias(scope, id, apiName)
		if not scope or not id then return end
		aliasVariables[scope] = aliasVariables[scope] or {}
		aliasVariables[scope][id] = apiName
		manifest.used = true
		manifest.apis[apiName] = true
	end

	local function isHookVariable(scope, id)
		if not scope or not id then return nil end
		if scope.isGlobal then
			local name = scope:getVariableName(id)
			if name and HOOK_GLOBALS[name] then
				return name
			end
		end
		if aliasVariables[scope] and aliasVariables[scope][id] then
			return aliasVariables[scope][id]
		end
		return nil
	end

	-- Pass 1: Scan for aliases and mark hook API usages
	visitast(ast, function(node, data)
		-- Check local variable declarations for aliases: local hm = hookmetamethod
		if node.kind == AstKind.LocalVariableDeclaration then
			for i, id in ipairs(node.ids) do
				local expr = node.expressions[i]
				if expr and expr.kind == AstKind.VariableExpression then
					local apiName = isHookVariable(expr.scope, expr.id)
					if apiName then
						registerAlias(node.scope, id, apiName)
						markNode(node)
						markNode(expr)
					end
				elseif expr and (expr.kind == AstKind.FunctionCallExpression or expr.kind == AstKind.PassSelfFunctionCallExpression) then
					-- oldIndex = hookmetamethod(...)
					local base = expr.base
					if base and base.kind == AstKind.VariableExpression then
						local apiName = isHookVariable(base.scope, base.id)
						if apiName then
							manifest.used = true
							manifest.apis[apiName] = true
							markNode(node)
							markSubtree(expr)
							-- Mark the receiver variable as sensitive to preserve upvalue chaining
							registerAlias(node.scope, id, apiName .. "_result")
						end
					end
				end
			end
		end

		-- Check assignments for aliases: hm = hookmetamethod or oldIndex = hookmetamethod(...)
		if node.kind == AstKind.AssignmentStatement then
			for i, lhsItem in ipairs(node.lhs) do
				local rhsItem = node.rhs[i]
				if rhsItem and rhsItem.kind == AstKind.VariableExpression then
					local apiName = isHookVariable(rhsItem.scope, rhsItem.id)
					if apiName and lhsItem.kind == AstKind.AssignmentVariable then
						registerAlias(lhsItem.scope, lhsItem.id, apiName)
						markNode(node)
						markNode(lhsItem)
						markNode(rhsItem)
					end
				elseif rhsItem and (rhsItem.kind == AstKind.FunctionCallExpression or rhsItem.kind == AstKind.PassSelfFunctionCallExpression) then
					local base = rhsItem.base
					if base and base.kind == AstKind.VariableExpression then
						local apiName = isHookVariable(base.scope, base.id)
						if apiName then
							manifest.used = true
							manifest.apis[apiName] = true
							markNode(node)
							markSubtree(rhsItem)
							if lhsItem.kind == AstKind.AssignmentVariable then
								registerAlias(lhsItem.scope, lhsItem.id, apiName .. "_result")
								markNode(lhsItem)
							end
						end
					end
				end
			end
		end

		-- Direct VariableExpression referencing a hook global
		if node.kind == AstKind.VariableExpression then
			local apiName = isHookVariable(node.scope, node.id)
			if apiName then
				manifest.used = true
				manifest.apis[apiName] = true
				markNode(node)
			end
		end

		-- Function calls calling hook functions
		if node.kind == AstKind.FunctionCallExpression or node.kind == AstKind.PassSelfFunctionCallExpression
			or node.kind == AstKind.FunctionCallStatement or node.kind == AstKind.PassSelfFunctionCallStatement then
			local base = node.base
			local isHookCall = false
			local apiName = nil

			if base and base.kind == AstKind.VariableExpression then
				apiName = isHookVariable(base.scope, base.id)
				if apiName then
					isHookCall = true
				end
			end

			if isHookCall then
				manifest.used = true
				manifest.apis[apiName] = true
				markNode(node)
				markNode(base)

				-- Track mutable target if calling hookmetamethod
				if apiName == "hookmetamethod" and node.args and #node.args >= 1 then
					local targetArg = node.args[1]
					if targetArg and targetArg.kind == AstKind.VariableExpression and targetArg.scope and targetArg.scope.isGlobal then
						local tName = targetArg.scope:getVariableName(targetArg.id)
						if tName then
							manifest.mutableTargets[tName] = true
						end
					end
				end

				-- Mark arguments
				for _, arg in ipairs(node.args) do
					markNode(arg)
					-- If arg is string matching metamethod key, protect it
					if arg.kind == AstKind.StringExpression and META_KEYS[arg.value] then
						manifest.metamethods[arg.value] = true
						if arg.value == "__namecall" then
							manifest.usesNamecall = true
						end
						markNode(arg, "__preserve_metamethod_dispatch")
						arg.__do_not_touch = true
					end

					-- If arg is a function callback (e.g. hook callback), protect entire subtree
					if arg.kind == AstKind.FunctionLiteralExpression then
						markSubtree(arg)
						arg.__preserve_closure_identity = true
					end
				end
			end

			-- PassSelfFunctionCall semantics preservation
			if node.kind == AstKind.PassSelfFunctionCallExpression or node.kind == AstKind.PassSelfFunctionCallStatement then
				local isTargetSensitive = false
				if base and base.kind == AstKind.VariableExpression then
					if base.scope and base.scope.isGlobal then
						local gName = base.scope:getVariableName(base.id)
						if gName == "game" or gName == "workspace" or gName == "script" or manifest.mutableTargets[gName] then
							isTargetSensitive = true
						end
					end
					if isHookVariable(base.scope, base.id) then
						isTargetSensitive = true
					end
				end
				if isTargetSensitive or manifest.usesNamecall or manifest.used then
					node.__requires_namecall_semantics = true
					markNode(node)
				end
			end
		end

		-- Check table indexing on metamethod keys: mt.__index = function(...) ... end or mt.__index
		if node.kind == AstKind.AssignmentStatement then
			for i, lhsItem in ipairs(node.lhs) do
				if lhsItem.kind == AstKind.AssignmentIndexing or lhsItem.kind == AstKind.IndexExpression then
					local idx = lhsItem.index
					if idx and idx.kind == AstKind.StringExpression and META_KEYS[idx.value] then
						manifest.used = true
						manifest.metamethods[idx.value] = true
						if idx.value == "__namecall" then
							manifest.usesNamecall = true
						end
						markNode(node)
						markNode(lhsItem)
						markNode(idx, "__preserve_metamethod_dispatch")
						idx.__do_not_touch = true

						local rhsItem = node.rhs[i]
						if rhsItem and rhsItem.kind == AstKind.FunctionLiteralExpression then
							markSubtree(rhsItem)
							rhsItem.__preserve_closure_identity = true
						elseif rhsItem then
							markNode(rhsItem)
						end
					end
				end
			end
		end

		-- Check IndexExpression with metamethod key
		if node.kind == AstKind.IndexExpression or node.kind == AstKind.AssignmentIndexing then
			local idx = node.index
			if idx and idx.kind == AstKind.StringExpression and META_KEYS[idx.value] then
				manifest.metamethods[idx.value] = true
				if idx.value == "__namecall" then
					manifest.usesNamecall = true
				end
				markNode(node)
				markNode(idx, "__preserve_metamethod_dispatch")
				idx.__do_not_touch = true
			end
		end
	end)

	ast.__hook_compat = manifest

	ast.__security_contract = ast.__security_contract or {
		entryChecks = true,
		payloadStarted = false,
		allowedHookApis = {},
		allowedMetamethods = {},
		allowedMutationTargets = {},
	}
	for apiName in pairs(manifest.apis) do
		ast.__security_contract.allowedHookApis[apiName] = true
	end
	for mm in pairs(manifest.metamethods) do
		ast.__security_contract.allowedMetamethods[mm] = true
	end
	for tgt in pairs(manifest.mutableTargets) do
		ast.__security_contract.allowedMutationTargets[tgt] = true
	end

	return ast
end

return HookCompatibility
