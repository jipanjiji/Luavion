-- This Script is Part of the ZeroLua Obfuscator
--
-- bytecode_compiler.lua
--
-- Pure Register Bytecode Compiler that transforms AST directly into
-- flat instruction quads [op, A, B, C] executed by an isolated opcode VM interpreter.

local Ast = require("zerolua.ast")
local AstKind = Ast.AstKind
local ISA = require("zerolua.compiler.isa")
local VMProfiles = require("zerolua.compiler.vm_profiles")
local BlockEncoder = require("zerolua.compiler.block_encoder")
local VMRuntime = require("zerolua.compiler.vm_runtime")
local Parser = require("zerolua.parser")
local Enums = require("zerolua.enums")
local visitast = require("zerolua.visitast")
local RandomDomains = require("zerolua.random_domains")
local KeySchedule = require("zerolua.compiler.key_schedule")
local StreamEncoder = require("zerolua.compiler.stream_encoder")
local SemanticIR = require("zerolua.compiler.semantic_ir")
local GraphSynthesizer = require("zerolua.compiler.graph_synthesizer")
local SemanticLowerer = require("zerolua.compiler.semantic_lowerer")
local GraphLowerer = require("zerolua.compiler.graph_lowerer")
local GraphIntegrity = require("zerolua.compiler.graph_integrity")
local RegionEncoder = require("zerolua.compiler.region_encoder")
local OuterVM = require("zerolua.compiler.outer_vm")
local MicroVM = require("zerolua.compiler.micro_vm")
local MicroISA = require("zerolua.compiler.micro_isa")
local OperandCodec = require("zerolua.compiler.operand_codec")
local RegisterMapper = require("zerolua.compiler.register_mapper")
local ConstantRuntime = require("zerolua.compiler.constant_runtime")

local BytecodeCompiler = {}

function BytecodeCompiler:new(parent, profileLevel, compilerConfig, pipeline)
	compilerConfig = compilerConfig or (parent and parent.compilerConfig) or {}
	local curPipeline = pipeline or (parent and parent.pipeline)
	local profile
	local pSeed = (curPipeline and curPipeline.Seed) or (parent and (parent.seed or (parent.profile and parent.profile.seed))) or 0
	if parent then
		local subId = #parent.K + 1
		profile = VMProfiles.createProfile(subId, pSeed, parent.profileLevel or "STRONG", parent.profile, compilerConfig)
	else
		profile = VMProfiles.createProfile(1, pSeed, profileLevel or "STRONG", nil, compilerConfig)
	end

	local keyMaterial
	if parent and parent.profile and parent.profile.keyMaterial then
		keyMaterial = parent.profile.keyMaterial
	elseif profile.keyMaterial then
		keyMaterial = profile.keyMaterial
	else
		keyMaterial = KeySchedule.generateKeyMaterial(profile.seed or 1337)
	end
	local protoSalt = profile.protoSalt or 1337
	local dCoeff = (protoSalt * 31 + 17) % 256
	if dCoeff % 2 == 0 then dCoeff = dCoeff + 1 end
	local dOffset = (protoSalt * 43 + 71) % 256
	profile.dCoeff = dCoeff
	profile.dOffset = dOffset
	profile.keyMaterial = keyMaterial

	local topProtoKey = KeySchedule.deriveProtoKey(keyMaterial, protoSalt, 64, profile.keyMode or 1)
	profile.protoKey = topProtoKey
	profile.aluMap = (parent and parent.profile and parent.profile.aluMap) or profile.aluMap or KeySchedule.deriveAluMap(topProtoKey, profile.seed or 1337)
	profile.capMap = (parent and parent.profile and parent.profile.capMap) or profile.capMap or KeySchedule.deriveCapMap(topProtoKey, profile.seed or 1337)

	local vmRng = RandomDomains.get("VM")
	local synthesizer = GraphSynthesizer.new(vmRng, profile)

	if curPipeline and curPipeline.apiHashCoeffs then
		profile.apiHashCoeffs = curPipeline.apiHashCoeffs
	elseif parent and parent.profile and parent.profile.apiHashCoeffs then
		profile.apiHashCoeffs = parent.profile.apiHashCoeffs
	end

	local compiler = {
		executionRepresentation = "REGIONS",
		profile = profile,
		profileLevel = profileLevel or (parent and parent.profileLevel) or "STRONG",
		compilerConfig = compilerConfig,
		pipeline = curPipeline,
		opcodes = profile.opcodes,
		opcodeWidths = profile.opcodeWidths,
		operandLayout = profile.operandLayout,
		synthesizer = synthesizer,
		code = {},
		instrOffsets = {},
		K = {},
		kLookup = {},
		regCount = 0,
		numLocals = 0,
		varMap = {},
		upvalues = {},
		upvalueMap = {},
		loopStack = {},
		parentCompiler = parent,
	}
	setmetatable(compiler, { __index = BytecodeCompiler })
	return compiler
end

function BytecodeCompiler:pushLoop()
	local lc = { breakJmps = {}, continueJmps = {} }
	table.insert(self.loopStack, lc)
	return lc
end

function BytecodeCompiler:popLoop()
	return table.remove(self.loopStack)
end

function BytecodeCompiler:currentLoop()
	return self.loopStack[#self.loopStack]
end

function BytecodeCompiler:getRootCompiler()
	local c = self
	while c.parentCompiler do
		c = c.parentCompiler
	end
	return c
end

local function computeApiHash(s, baseSalt)
	if type(s) ~= "string" then return 0 end
	baseSalt = baseSalt or 1337
	local h = ((baseSalt % 99991 + 10007) * 31 + 2166136261) % 2147483647
	for i = 1, #s do
		h = ((h * 16777619 + string.byte(s, i) * 31 + (baseSalt % 97 + 13)) % 2147483647)
	end
	return h
end

function BytecodeCompiler:getBaseSalt()
	local root = self:getRootCompiler()
	if root.profile and root.profile.keyMaterial and root.profile.keyMaterial.baseSalt then
		return root.profile.keyMaterial.baseSalt
	end
	if root.profile and root.profile.baseSalt then
		return root.profile.baseSalt
	end
	return 1337
end

local function modInverse256(a)
	for x = 1, 255 do
		if (a * x) % 256 == 1 then
			return x
		end
	end
	return 1
end

function BytecodeCompiler:setConstant(kIdx, val)
	local root = self:getRootCompiler()
	root.K[kIdx + 1] = val
end

function BytecodeCompiler:encodePolymorphicString(val, idx, baseSalt, protoSalt)
	local pLen = #val
	if pLen == 0 then return {} end
	protoSalt = protoSalt or (self.profile and self.profile.protoSalt) or (self:getRootCompiler().profile and self:getRootCompiler().profile.protoSalt) or 1337
	local mode = (baseSalt % 4) + 1
	local _sEff = (baseSalt * 31 + protoSalt * 17 + (idx * 11)) % 65536
	local packed = {}
	if mode == 1 then
		local mul = (((_sEff * 7 + idx * 13) % 128) * 2 + 1)
		local invMul = modInverse256(mul)
		local rolling = (_sEff * 31 + pLen * 17) % 256
		for j = 1, pLen do
			local b = string.byte(val, j)
			local offset = (_sEff * 17 + j * 19 + rolling * 7) % 256
			local diff = (b - offset + 256) % 256
			local enc = (diff * invMul) % 256
			packed[j] = enc
			rolling = (rolling * 41 + enc * 13 + b * 7) % 256
		end
	elseif mode == 2 then
		local rolling = (_sEff * 43 + pLen * 23 + idx * 7) % 256
		for j = 1, pLen do
			local b = string.byte(val, j)
			local poly = (((j * 17 + idx * 23 + rolling * 7 + (_sEff % 256)) % 256) * j + (_sEff * 11 + idx * 31)) % 256
			local enc = (b + poly) % 256
			packed[j] = enc
			rolling = (rolling * 37 + enc * 19 + b * 11 + 29) % 256
		end
	elseif mode == 3 then
		local rolling = (_sEff * 47 + pLen * 29 + idx * 11 + 31) % 256
		for j = 1, pLen do
			local b = string.byte(val, j)
			local shift = (_sEff * 29 + idx * 43 + j * 37 + rolling * 11 + 43) % 256
			local enc = (b + shift) % 256
			packed[j] = enc
			rolling = (rolling * 47 + enc * 29 + b * 13 + 31) % 256
		end
	else
		local mul = (((_sEff * 11 + idx * 19) % 128) * 2 + 1)
		local invMul = modInverse256(mul)
		local rolling = (_sEff * 53 + pLen * 31 + idx * 17 + 19) % 256
		for j = 1, pLen do
			local b = string.byte(val, j)
			local add = (_sEff * 13 + idx * 29 + j * 31 + rolling * 17 + 59) % 256
			local diff = (b - add + 256) % 256
			local enc = (diff * invMul) % 256
			packed[j] = enc
			rolling = (rolling * 53 + enc * 31 + b * 17 + 41) % 256
		end
	end
	return packed
end

function BytecodeCompiler:addConstant(val)
	if val == nil then
		val = false
	end
	if self.parentCompiler then
		local root = self:getRootCompiler()
		return root:addConstant(val)
	end

	local StdApiNames = require("zerolua.std_api_names")
	if type(val) == "string" and StdApiNames.set[val] then
		local root = self:getRootCompiler()
		local baseSalt = self:getBaseSalt()
		local apiCoeffs = (self.profile and self.profile.apiHashCoeffs) or (root.profile and root.profile.apiHashCoeffs) or StdApiNames.getCoeffs(baseSalt)
		local hash = StdApiNames.computeHash(val, apiCoeffs.mult, apiCoeffs.mod, apiCoeffs.offset)
		return self:addConstant(hash)
	end

	local key = type(val) .. ":" .. tostring(val)
	if type(val) == "string" and #val > 0 then
		self.kFreq = self.kFreq or {}
		local count = self.kFreq[val] or 0
		self.kFreq[val] = count + 1
		local variant = count % 3
		key = "string:" .. val .. "@" .. tostring(variant)
	end

	if self.kLookup[key] ~= nil then
		return self.kLookup[key]
	end

	local entry = val
	if type(val) == "string" then
		local baseSalt = self:getBaseSalt()
		local idx = #self.K + 1
		local root = self:getRootCompiler()
		local topProtoSalt = (root.profile and root.profile.protoSalt) or 1337
		local packed = self:encodePolymorphicString(val, idx, baseSalt, topProtoSalt)
		entry = { _arith = packed, _str = val }
	end

	local idx = #self.K
	table.insert(self.K, entry)
	self.kLookup[key] = idx
	return idx
end

function BytecodeCompiler:addK(val)
	return self:addConstant(val)
end

function BytecodeCompiler:getArgSlotOffset(argPos, w)
	return OperandCodec.getArgSlotOffset(self.operandLayout, argPos, w)
end

local function modInverse256(a)
	local x = a
	for i = 1, 4 do
		x = (x * (2 - a * x)) % 256
	end
	return (x + 256) % 256
end

local function getOperandWhitening(dip, slot, protoSalt)
	protoSalt = protoSalt or 1337
	slot = slot or 1
	return ((dip * (37 + slot * 18) + protoSalt * 53 + slot * 97) % 1024) - 512
end

function BytecodeCompiler:emit(opName, A, B, C)
	self.debugInstructions = self.debugInstructions or {}
	table.insert(self.debugInstructions, { op = opName, A = A, B = B, C = C, ip = #self.code + 1 })
	-- ZeroLua v4.4: Dynamic Multi-Dispatch Opcode Aliasing
	self.emitCount = (self.emitCount or 0) + 1
	local effectiveOpName = opName
	local altName = opName .. "_ALT"
	if self.opcodes[altName] and ((self.emitCount + (self.profile.protoSalt or 1337)) % 2 == 1) then
		effectiveOpName = altName
	end

	local root = self:getRootCompiler()
	local rootCoeff = root.profile.dCoeff or 131
	local rootOffset = root.profile.dOffset or 53
	local baseOp = root.opcodes[effectiveOpName] or root.opcodes[opName]
	if not baseOp then
		error("ZeroLua ISA Invariant Violation: Opcode '" .. tostring(opName) .. "' is not in active opcode vocabulary!", 0)
	end

	local targetTok = (baseOp * rootCoeff + rootOffset) % 256

	local protoSalt = self.profile.protoSalt or 1337
	local protoCoeff = (protoSalt * 31 + 17) % 256
	if protoCoeff % 2 == 0 then protoCoeff = protoCoeff + 1 end
	local protoOffset = (protoSalt * 43 + 71) % 256
	local inv = modInverse256(protoCoeff)

	local dipPos = (#self.code * 2 + 1)
	local dipMod = (dipPos * 13) % 256
	local op = (((targetTok - protoOffset - dipMod + 65536) % 256) * inv) % 256

	local w = (self.opcodeWidths and (self.opcodeWidths[effectiveOpName] or self.opcodeWidths[opName])) or 4
	local wTag = w - 2
	local opWord = op * 4 + wTag
	local startIdx = #self.code + 1
	table.insert(self.code, opWord)

	local layout = self.operandLayout or 0
	A = A or 0
	B = B or 0
	C = C or 0

	local w1 = getOperandWhitening(dipPos, 1, protoSalt)
	local w2 = getOperandWhitening(dipPos, 2, protoSalt)
	local w3 = getOperandWhitening(dipPos, 3, protoSalt)

	if w == 2 then
		table.insert(self.code, A + w1)
	elseif w == 3 then
		if layout == 1 or layout == 2 or layout == 4 then
			table.insert(self.code, B + w1)
			table.insert(self.code, A + w2)
		else
			table.insert(self.code, A + w1)
			table.insert(self.code, B + w2)
		end
	else
		if layout == 1 then
			table.insert(self.code, C + w1)
			table.insert(self.code, A + w2)
			table.insert(self.code, B + w3)
		elseif layout == 2 then
			table.insert(self.code, B + w1)
			table.insert(self.code, C + w2)
			table.insert(self.code, A + w3)
		elseif layout == 3 then
			table.insert(self.code, A + w1)
			table.insert(self.code, C + w2)
			table.insert(self.code, B + w3)
		elseif layout == 4 then
			table.insert(self.code, B + w1)
			table.insert(self.code, A + w2)
			table.insert(self.code, C + w3)
		elseif layout == 5 then
			table.insert(self.code, C + w1)
			table.insert(self.code, B + w2)
			table.insert(self.code, A + w3)
		else
			table.insert(self.code, A + w1)
			table.insert(self.code, B + w2)
			table.insert(self.code, C + w3)
		end
		for p = 5, w do
			local vmRng = RandomDomains.get("VM")
			table.insert(self.code, (vmRng and vmRng:random(0, 255)) or 0)
		end
	end

	table.insert(self.instrOffsets, startIdx)
	return #self.instrOffsets
end

function BytecodeCompiler:nextInstrIdx()
	return #self.instrOffsets + 1
end

function BytecodeCompiler:fixupJmp(instrIdx, targetInstrIdx, argPos)
	if not instrIdx or instrIdx < 1 then return end
	self.jumpTargets = self.jumpTargets or {}
	self.jumpEdges = self.jumpEdges or {}
	if targetInstrIdx then
		self.jumpTargets[targetInstrIdx] = true
		self.jumpEdges[instrIdx] = targetInstrIdx
	end
	local fromOffset = self.instrOffsets[instrIdx]
	if not fromOffset then return end
	local targetOffset = (targetInstrIdx and targetInstrIdx <= #self.instrOffsets and self.instrOffsets[targetInstrIdx]) or (#self.code + 1)
	local opWord = self.code[fromOffset]
	local w = (opWord % 4) + 2
	local byteDelta = targetOffset - fromOffset - w
	local slotOffset = self:getArgSlotOffset(argPos or 1, w)
	local slotIdx = fromOffset + slotOffset
	if slotIdx >= 1 and slotIdx <= #self.code then
		local protoSalt = self.profile.protoSalt or 1337
		local fromDip = (fromOffset - 1) * 2 + 1
		self.code[slotIdx] = byteDelta + getOperandWhitening(fromDip, slotOffset, protoSalt)
	end
end

function BytecodeCompiler:allocReg()
	local minReg = self.numLocals or 0
	if (self.regCount or 0) < minReg then
		self.regCount = minReg
	end
	local r = self.regCount
	self.regCount = self.regCount + 1
	return r
end

function BytecodeCompiler:getVarReg(scope, id)
	local key = tostring(scope) .. ":" .. tostring(id)
	if self.varMap[key] == nil then
		local r = self.numLocals or 0
		self.varMap[key] = r
		self.numLocals = r + 1
		if self.numLocals > (self.regCount or 0) then
			self.regCount = self.numLocals
		end
	end
	return self.varMap[key]
end

function BytecodeCompiler:resolveUpvalue(scope, id)
	if not self.parentCompiler or not scope or scope.isGlobal then
		return nil
	end

	local key = tostring(scope) .. ":" .. tostring(id)
	if self.upvalueMap[key] ~= nil then
		return self.upvalueMap[key]
	end

	local parentReg = self.parentCompiler.varMap[key]
	local uvDesc = nil

	if parentReg ~= nil then
		uvDesc = { 0, parentReg, isUpval = 0, index = parentReg }
	else
		local pUvIdx = self.parentCompiler:resolveUpvalue(scope, id)
		if pUvIdx ~= nil then
			uvDesc = { 1, pUvIdx, isUpval = 1, index = pUvIdx }
		end
	end

	if uvDesc == nil then
		return nil
	end

	local uvIdx = #self.upvalues
	table.insert(self.upvalues, uvDesc)
	self.upvalueMap[key] = uvIdx
	return uvIdx
end

function BytecodeCompiler:compileSubProto(block, args)
	local sub = BytecodeCompiler:new(self, self.profileLevel)
	sub.K = self.K
	sub.kLookup = self.kLookup
	local numFixed = 0
	if args then
		for _, argNode in ipairs(args) do
			if type(argNode) == "table" and argNode.kind == AstKind.VarargExpression then
				-- Vararg is not a fixed param
			else
				numFixed = numFixed + 1
				if type(argNode) == "table" and argNode.kind == AstKind.VariableExpression then
					sub:getVarReg(argNode.scope, argNode.id)
				elseif (type(argNode) == "number" or type(argNode) == "string") and block and block.scope then
					sub:getVarReg(block.scope, argNode)
				else
					sub:allocReg()
				end
			end
		end
	end
	sub.numFixedParams = numFixed
	sub.numParams = numFixed
	if block then
		sub:compileBlock(block)
	end
	sub:emit("RETURN", 0, -1, 0)
	local keyMat = (self.profile and self.profile.keyMaterial) or KeySchedule.generateKeyMaterial((self.profile and self.profile.seed) or 1337)
	sub.profile.protoSalt = sub.profile.protoSalt or ((#self.K + 1) * 37 + 101) % 65536
	sub.profile.parentProtoSalt = self.profile.protoSalt or 1337
	sub.profile.closureIndex = #self.K + 1
	sub:buildRegions(keyMat)
	return sub
end

function BytecodeCompiler:compileSubCallForExpand(rSub, subNode)
	local subMode = 0
	local subArgs = subNode.args or {}
	local numSlots = (subNode.kind == AstKind.PassSelfFunctionCallExpression) and (#subArgs + 2) or (#subArgs + 1)
	self.regCount = math.max(self.regCount, rSub + numSlots)
	if subNode.kind == AstKind.PassSelfFunctionCallExpression then
		local rSelf = rSub + 1
		self:compileExprToReg(subNode.base, rSelf)
		local nameNode = subNode.passSelfFunctionName or subNode.name
		local nameVal = (type(nameNode) == "table" and nameNode.value) or (type(nameNode) == "string" and nameNode)
		local kMethod = self:addConstant(nameVal)
		self:emit("GETTABLE_K", rSub, rSelf, kMethod)
		if #subArgs == 1 and subArgs[1].kind == AstKind.VarargExpression then
			subMode = 32 + 1
		elseif #subArgs > 1 and subArgs[#subArgs].kind == AstKind.VarargExpression then
			local sNumFixed = #subArgs - 1
			for si = 1, sNumFixed do
				self:compileExprToReg(subArgs[si], rSub + 1 + si)
			end
			subMode = 32 + (sNumFixed + 1)
		else
			for si, sArg in ipairs(subArgs) do
				self:compileExprToReg(sArg, rSub + 1 + si)
			end
			subMode = #subArgs + 1
		end
	else
		self:compileExprToReg(subNode.base, rSub)
		if #subArgs == 1 and subArgs[1].kind == AstKind.VarargExpression then
			subMode = 31
		elseif #subArgs > 1 and subArgs[#subArgs].kind == AstKind.VarargExpression then
			local sNumFixed = #subArgs - 1
			for si = 1, sNumFixed do
				self:compileExprToReg(subArgs[si], rSub + si)
			end
			subMode = 32 + sNumFixed
		else
			for si, sArg in ipairs(subArgs) do
				self:compileExprToReg(sArg, rSub + si)
			end
			subMode = #subArgs
		end
	end
	return subMode
end

function BytecodeCompiler:compileExprToReg(node, targetReg)
	if not node then
		self:emit("LOADNIL", targetReg, targetReg, 0)
		return targetReg
	end

	local k = node.kind

	if k == AstKind.NumberExpression then
		local kIdx = self:addConstant(node.value)
		self:emit("LOADK", targetReg, kIdx, 0)
	elseif k == AstKind.StringExpression then
		local kIdx = self:addConstant(node.value)
		self:emit("LOADK", targetReg, kIdx, 0)
	elseif k == AstKind.BooleanExpression then
		self:emit("LOADBOOL", targetReg, node.value and 1 or 0, 0)
	elseif k == AstKind.NilExpression then
		self:emit("LOADNIL", targetReg, targetReg, 0)
	elseif k == AstKind.VarargExpression then
		self:emit("VARARG", targetReg, 1, 0)
	elseif k == AstKind.VariableExpression or k == AstKind.AssignmentVariable then
		if node.scope and node.scope.isGlobal then
			local name = node.scope:getVariableName(node.id) or tostring(node.id)
			local constVal = (node.apiHash ~= nil and node.apiHash) or name
			local kIdx = self:addConstant(constVal)
			self:emit("GETGLOBAL", targetReg, kIdx, 0)
		else
			local varKey = tostring(node.scope) .. ":" .. tostring(node.id)
			local varReg = self.varMap[varKey]
			if varReg ~= nil then
				if targetReg ~= varReg then
					self:emit("MOVE", targetReg, varReg, 0)
				end
			else
				local uvIdx = self:resolveUpvalue(node.scope, node.id)
				if uvIdx ~= nil then
					self:emit("GETUPVAL", targetReg, uvIdx, 0)
				else
					local name = (node.scope and node.scope:getVariableName(node.id)) or tostring(node.id)
					local constVal = (node.apiHash ~= nil and node.apiHash) or name
					local kIdx = self:addConstant(constVal)
					self:emit("GETGLOBAL", targetReg, kIdx, 0)
				end
			end
		end
	elseif k == AstKind.AddExpression then
		local vmRng = RandomDomains.get("VM")
		local useAlt = (vmRng and vmRng:random(1, 100) > 60)
		if node.rhs.kind == AstKind.NumberExpression and not useAlt then
			local kIdx = self:addConstant(node.rhs.value)
			local rL = self:compileExpr(node.lhs)
			self:emit("ADD_K", targetReg, rL, kIdx)
		else
			local rL = self:compileExpr(node.lhs)
			local rR = self:compileExpr(node.rhs)
			local opName = (useAlt and self.opcodes["ADD_ALT"]) and "ADD_ALT" or "ADD"
			self:emit(opName, targetReg, rL, rR)
		end
	elseif k == AstKind.SubExpression or k == AstKind.MulExpression or k == AstKind.DivExpression or k == AstKind.ModExpression or k == AstKind.PowExpression then
		local vmRng = RandomDomains.get("VM")
		local useAlt = (vmRng and vmRng:random(1, 100) > 60)
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		local opMap = {
			[AstKind.SubExpression] = (useAlt and self.opcodes["SUB_ALT"]) and "SUB_ALT" or "SUB",
			[AstKind.MulExpression] = "MUL",
			[AstKind.DivExpression] = "DIV",
			[AstKind.ModExpression] = "MOD",
			[AstKind.PowExpression] = "POW",
		}
		self:emit(opMap[k], targetReg, rL, rR)
	elseif k == AstKind.EqualsExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("EQ", 0, rL, rR)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.NotEqualsExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("EQ", 1, rL, rR)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.LessThanExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("LT", 0, rL, rR)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.GreaterThanExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("LT", 0, rR, rL)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.LessThanOrEqualsExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("LE", 0, rL, rR)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.GreaterThanOrEqualsExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("LOADBOOL", targetReg, 0, 0)
		self:emit("LE", 0, rR, rL)
		local jmpIdx = self:emit("JMP", 0, 0, 0)
		self:emit("LOADBOOL", targetReg, 1, 0)
		self:fixupJmp(jmpIdx, self:nextInstrIdx())
	elseif k == AstKind.NotExpression then
		local rR = self:compileExpr(node.rhs)
		self:emit("NOT", targetReg, rR, 0)
	elseif k == AstKind.NegateExpression then
		local rR = self:compileExpr(node.rhs)
		self:emit("UNM", targetReg, rR, 0)
	elseif k == AstKind.LenExpression then
		local rR = self:compileExpr(node.rhs)
		self:emit("LEN", targetReg, rR, 0)
	elseif k == AstKind.OrExpression then
		self:compileExprToReg(node.lhs, targetReg)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, targetReg, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 0, rNot, rTrue)
		local jmpToEnd = self:emit("JMP", 0, 0, 0)
		self:compileExprToReg(node.rhs, targetReg)
		self:fixupJmp(jmpToEnd, self:nextInstrIdx())
	elseif k == AstKind.AndExpression then
		self:compileExprToReg(node.lhs, targetReg)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, targetReg, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 1, rNot, rTrue)
		local jmpToEnd = self:emit("JMP", 0, 0, 0)
		self:compileExprToReg(node.rhs, targetReg)
		self:fixupJmp(jmpToEnd, self:nextInstrIdx())
	elseif k == AstKind.IfElseExpression then
		local endJmps = {}
		local rCond = self:compileExpr(node.condition)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, rCond, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 1, rNot, rTrue)
		local jmpElse = self:emit("JMP", 0, 0, 0)

		self:compileExprToReg(node.true_value, targetReg)
		table.insert(endJmps, self:emit("JMP", 0, 0, 0))

		self:fixupJmp(jmpElse, self:nextInstrIdx())

		if node.elseifs and #node.elseifs > 0 then
			for _, clause in ipairs(node.elseifs) do
				local rClauseCond = self:compileExpr(clause.condition)
				local rClauseNot = self:allocReg()
				self:emit("NOT", rClauseNot, rClauseCond, 0)
				self:emit("EQ", 1, rClauseNot, rTrue)
				local jmpNext = self:emit("JMP", 0, 0, 0)

				self:compileExprToReg(clause.value, targetReg)
				table.insert(endJmps, self:emit("JMP", 0, 0, 0))

				self:fixupJmp(jmpNext, self:nextInstrIdx())
			end
		end

		self:compileExprToReg(node.false_value, targetReg)
		local finalExitPos = self:nextInstrIdx()
		for _, jmpIdx in ipairs(endJmps) do
			self:fixupJmp(jmpIdx, finalExitPos)
		end
	elseif k == AstKind.StrCatExpression then
		local rL = self:compileExpr(node.lhs)
		local rR = self:compileExpr(node.rhs)
		self:emit("CONCAT", targetReg, rL, rR)
	elseif k == AstKind.IndexExpression then
		if node.index.kind == AstKind.StringExpression or node.index.kind == AstKind.NumberExpression then
			local kIdx = self:addConstant(node.index.value)
			local rB = self:compileExpr(node.base)
			self:emit("GETTABLE_K", targetReg, rB, kIdx)
		else
			local rB = self:compileExpr(node.base)
			local rI = self:compileExpr(node.index)
			self:emit("GETTABLE", targetReg, rB, rI)
		end
	elseif k == AstKind.TableConstructorExpression then
		self:emit("NEWTABLE", targetReg, 0, 0)
		local savedReg = math.max(self.regCount, self.numLocals or 0)
		local arrayIdx = 1
		for i, entry in ipairs(node.entries or {}) do
			self.regCount = savedReg
			if type(entry) == "table" and entry.kind == AstKind.KeyedTableEntry then
				local keyNode = entry.key
				local isConstKey = false
				local kIdx = nil
				if type(keyNode) == "table" and keyNode.kind == AstKind.StringExpression then
					kIdx = self:addConstant(keyNode.value)
					isConstKey = true
				elseif type(keyNode) == "string" then
					kIdx = self:addConstant(keyNode)
					isConstKey = true
				end
				local valNode = entry.value
				if type(valNode) == "string" then valNode = Ast.StringExpression(valNode)
				elseif type(valNode) == "number" then valNode = Ast.NumberExpression(valNode)
				elseif type(valNode) == "boolean" then valNode = Ast.BooleanExpression(valNode) end
				local rV = self:compileExpr(valNode)
				if isConstKey and kIdx ~= nil and self.opcodes["TABLE_SET_CHAIN"] then
					self:emit("TABLE_SET_CHAIN", targetReg, kIdx, rV)
				elseif isConstKey and kIdx ~= nil and self.opcodes["SETTABLE_K"] then
					self:emit("SETTABLE_K", targetReg, kIdx, rV)
				else
					local rK = self:compileExpr(keyNode)
					self:emit("SETTABLE", targetReg, rK, rV)
				end
			else
				local valNode = entry
				if type(entry) == "table" and entry.kind == AstKind.TableEntry and entry.value ~= nil then
					valNode = entry.value
				end
				if i == #node.entries and type(valNode) == "table" and valNode.kind == AstKind.VarargExpression then
					self:emit("VARARG", targetReg, -1, arrayIdx)
				elseif i == #node.entries and type(valNode) == "table" and (valNode.kind == AstKind.FunctionCallExpression or valNode.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_TABLE_APPEND"] then
					if valNode.kind == AstKind.PassSelfFunctionCallExpression then
						local rSelf = self:compileExpr(valNode.base)
						local nameNode = valNode.passSelfFunctionName or valNode.name
						if type(nameNode) == "string" then nameNode = Ast.StringExpression(nameNode) end
						local rName = self:compileExpr(nameNode)
						local args = valNode.args or {}
						local rFunc = self:allocReg()
						if #args == 1 and args[1].kind == AstKind.VarargExpression then
							self.regCount = math.max(self.numLocals or 0, rFunc + 2)
							self:emit("GETTABLE", rFunc, rSelf, rName)
							self:emit("MOVE", rFunc + 1, rSelf, 0)
							local opC = arrayIdx * 32 + (16 + 1)
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
							local numFixed = #args - 1
							self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
							self:emit("GETTABLE", rFunc, rSelf, rName)
							self:emit("MOVE", rFunc + 1, rSelf, 0)
							for ai = 1, numFixed do self:compileExprToReg(args[ai], rFunc + 1 + ai) end
							local opC = arrayIdx * 32 + (16 + numFixed + 1)
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						else
							self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args)
							self:emit("GETTABLE", rFunc, rSelf, rName)
							self:emit("MOVE", rFunc + 1, rSelf, 0)
							for ai, arg in ipairs(args) do self:compileExprToReg(arg, rFunc + 1 + ai) end
							local numArgs = #args + 1
							local opC = arrayIdx * 32 + (numArgs % 16)
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						end
					else
						local args = valNode.args or {}
						local rFunc = self:allocReg()
						self:compileExprToReg(valNode.base, rFunc)
						if #args == 1 and args[1].kind == AstKind.VarargExpression then
							local opC = arrayIdx * 32 + 31
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
							local numFixed = #args - 1
							self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
							for ai = 1, numFixed do self:compileExprToReg(args[ai], rFunc + ai) end
							local opC = arrayIdx * 32 + (16 + numFixed)
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						else
							self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args)
							for ai, arg in ipairs(args) do self:compileExprToReg(arg, rFunc + ai) end
							local numArgs = #args
							local opC = arrayIdx * 32 + (numArgs % 16)
							self:emit("CALL_TABLE_APPEND", targetReg, rFunc, opC)
						end
					end
				else
					local kIdx = self:addConstant(arrayIdx)
					if type(valNode) == "string" then
						valNode = Ast.StringExpression(valNode)
					elseif type(valNode) == "number" then
						valNode = Ast.NumberExpression(valNode)
					elseif type(valNode) == "boolean" then
						valNode = Ast.BooleanExpression(valNode)
					end
					local rV = self:compileExpr(valNode)
					if self.opcodes["TABLE_SET_CHAIN"] then
						self:emit("TABLE_SET_CHAIN", targetReg, kIdx, rV)
					elseif self.opcodes["SETTABLE_K"] then
						self:emit("SETTABLE_K", targetReg, kIdx, rV)
					else
						local rK = self:allocReg()
						self:emit("LOADK", rK, kIdx, 0)
						self:emit("SETTABLE", targetReg, rK, rV)
					end
					arrayIdx = arrayIdx + 1
				end
			end
		end
		self.regCount = savedReg

	elseif k == AstKind.PassSelfFunctionCallExpression then
		local rSelf = self:compileExpr(node.base)
		local nameNode = node.passSelfFunctionName or node.name
		local args = node.args or {}
		if type(nameNode) == "string" then
			nameNode = Ast.StringExpression(nameNode)
		end
		local rName = self:compileExpr(nameNode)
		local rFunc = self:allocReg()
			local lastArg = #args > 0 and args[#args]
			if #args == 1 and args[1].kind == AstKind.VarargExpression then
				self.regCount = math.max(self.numLocals or 0, rFunc + 2)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				self:emit("CALL", rFunc, -101, 1)
			elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + 1 + i)
				end
				self:emit("CALL", rFunc, -100 - (numFixed + 1), 1)
			elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + 1 + i)
				end
				local rSub = rFunc + 1 + (numFixed + 1)
				local subMode = self:compileSubCallForExpand(rSub, lastArg)
				self:emit("CALL_EXPAND", rFunc, (numFixed + 1) * 64 + subMode, 1)
			else
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i, arg in ipairs(args) do
					self:compileExprToReg(arg, rFunc + 1 + i)
				end
				self:emit("CALL", rFunc, #args + 1, 1)
			end
			if targetReg ~= rFunc then
				self:emit("MOVE", targetReg, rFunc, 0)
			end
	elseif k == AstKind.FunctionCallExpression then
		local rFunc = self:allocReg()
		self:compileExprToReg(node.base, rFunc)
		local args = node.args or {}
		local lastArg = #args > 0 and args[#args]
		if #args == 1 and args[1].kind == AstKind.VarargExpression then
			self:emit("CALL", rFunc, -1, 1)
		elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
			local numFixed = #args - 1
			self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
			for i = 1, numFixed do
				self:compileExprToReg(args[i], rFunc + i)
			end
			self:emit("CALL", rFunc, -100 - numFixed, 1)
		elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
			local numFixed = #args - 1
			self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
			for i = 1, numFixed do
				self:compileExprToReg(args[i], rFunc + i)
			end
			local rSub = rFunc + numFixed + 1
			local subMode = self:compileSubCallForExpand(rSub, lastArg)
			self:emit("CALL_EXPAND", rFunc, numFixed * 64 + subMode, 1)
		else
			self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args)
			for i, arg in ipairs(args) do
				self:compileExprToReg(arg, rFunc + i)
			end
			self:emit("CALL", rFunc, #args, 1)
		end
		if targetReg ~= rFunc then
			self:emit("MOVE", targetReg, rFunc, 0)
		end
	elseif k == AstKind.FunctionLiteralExpression then
		local kIdx = self:addConstant({ code = {} })
		local subCompiler = self:compileSubProto(node.body, node.args)
		local uvList = {}
		for _, uvDesc in ipairs(subCompiler.upvalues) do
			table.insert(uvList, { uvDesc.isUpval, uvDesc.index })
		end
		self:setConstant(kIdx, { code = subCompiler.code, upvalues = uvList, numParams = subCompiler.numFixedParams, profile = subCompiler.profile, encodedRegions = subCompiler.encodedRegions, regions = subCompiler.regions })
		self:emit("CLOSURE", targetReg, kIdx, #uvList)
	elseif k == AstKind.VarargExpression then
		self:emit("VARARG", targetReg, 1, 0)
	else
		-- Fallback load nil
		self:emit("LOADNIL", targetReg, targetReg, 0)
	end

	return targetReg
end

function BytecodeCompiler:compileExpr(node)
	local r = self:allocReg()
	self:compileExprToReg(node, r)
	return r
end

function BytecodeCompiler:compileStatement(stat)
	if not stat then return end

	local k = stat.kind

	if k == AstKind.LocalVariableDeclaration then
		local exprs = stat.expressions or {}
		local numIds = #stat.ids
		local numExprs = #exprs

		local varRegs = {}
		for i, id in ipairs(stat.ids) do
			varRegs[i] = self:getVarReg(stat.scope, id)
		end

		if numIds == 1 and numExprs == 1 then
			self:compileExprToReg(exprs[1], varRegs[1])
			return
		end

		local rhsRegs = {}
		for i = 1, numExprs do
			local expr = exprs[i]
			if i == numExprs and numIds > numExprs and (expr.kind == AstKind.FunctionCallExpression or expr.kind == AstKind.PassSelfFunctionCallExpression) then
				local numNeeded = numIds - numExprs + 1
				local rFunc = self:allocReg()
				self.regCount = math.max(self.numLocals or 0, rFunc + math.max(numNeeded, 10))
				if expr.kind == AstKind.PassSelfFunctionCallExpression then
					local rSelf = self:compileExpr(expr.base)
					local nameNode = expr.passSelfFunctionName or expr.name
					local args = expr.args or {}
					if type(nameNode) == "string" then
						nameNode = Ast.StringExpression(nameNode)
					end
					local rName = self:compileExpr(nameNode)
					local lastArg = #args > 0 and args[#args]
					if #args == 1 and args[1].kind == AstKind.VarargExpression then
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						self:emit("CALL", rFunc, -101, numNeeded)
					elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + 1 + ai)
						end
						self:emit("CALL", rFunc, -100 - (numFixed + 1), numNeeded)
					elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + 1 + ai)
						end
						local rSub = rFunc + 1 + (numFixed + 1)
						local subMode = self:compileSubCallForExpand(rSub, lastArg)
						self:emit("CALL_EXPAND", rFunc, (numFixed + 1) * 64 + subMode, numNeeded)
					else
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai, arg in ipairs(args) do
							self:compileExprToReg(arg, rFunc + 1 + ai)
						end
						self:emit("CALL", rFunc, #args + 1, numNeeded)
					end
				else
					self:compileExprToReg(expr.base, rFunc)
					local args = expr.args or {}
					local lastArg = #args > 0 and args[#args]
					if #args == 1 and args[1].kind == AstKind.VarargExpression then
						self:emit("CALL", rFunc, -1, numNeeded)
					elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed + numNeeded)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + ai)
						end
						self:emit("CALL", rFunc, -100 - numFixed, numNeeded)
					elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed + numNeeded)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + ai)
						end
						local rSub = rFunc + numFixed + 1
						local subMode = self:compileSubCallForExpand(rSub, lastArg)
						self:emit("CALL_EXPAND", rFunc, numFixed * 64 + subMode, numNeeded)
					else
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args + numNeeded)
						for ai, arg in ipairs(args) do
							self:compileExprToReg(arg, rFunc + ai)
						end
						self:emit("CALL", rFunc, #args, numNeeded)
					end
				end
				for ri = 1, numNeeded do
					rhsRegs[i + ri - 1] = rFunc + ri - 1
				end
			elseif i == numExprs and numIds > numExprs and expr.kind == AstKind.VarargExpression then
				local numNeeded = numIds - numExprs + 1
				local rVa = self:allocReg()
				self.regCount = math.max(self.numLocals or 0, rVa + numNeeded)
				self:emit("VARARG", rVa, numNeeded, 0)
				for ri = 1, numNeeded do
					rhsRegs[i + ri - 1] = rVa + ri - 1
				end
			else
				rhsRegs[i] = self:compileExpr(expr)
			end
		end

		for i, varReg in ipairs(varRegs) do
			if rhsRegs[i] ~= nil then
				self:emit("MOVE", varReg, rhsRegs[i], 0)
			else
				self:emit("LOADNIL", varReg, varReg, 0)
			end
		end
	elseif k == AstKind.AssignmentStatement then
		local numLhs = #(stat.lhs or {})
		local exprs = stat.rhs or {}
		local numExprs = #exprs

		if numLhs == 1 and numExprs == 1 then
			local lhs = stat.lhs[1]
			local expr = exprs[1]
			if self.opcodes["LOADK_SETTABLE"] and lhs.kind == AstKind.AssignmentIndexing and (lhs.index.kind == AstKind.StringExpression or lhs.index.kind == AstKind.NumberExpression) and (expr.kind == AstKind.StringExpression or expr.kind == AstKind.NumberExpression or expr.kind == AstKind.BooleanExpression) then
				local rB = self:compileExpr(lhs.base)
				local kIdxKey = self:addConstant(lhs.index.value)
				local kIdxVal = self:addConstant(expr.value)
				self:emit("LOADK_SETTABLE", rB, kIdxKey, kIdxVal)
				return
			elseif lhs.kind == AstKind.AssignmentVariable and not (lhs.scope and lhs.scope.isGlobal) and (expr.kind == AstKind.NumberExpression or expr.kind == AstKind.StringExpression or expr.kind == AstKind.BooleanExpression or expr.kind == AstKind.NilExpression) then
				local varKey = tostring(lhs.scope) .. ":" .. tostring(lhs.id)
				local varReg = self.varMap[varKey]
				if varReg ~= nil then
					self:compileExprToReg(expr, varReg)
					return
				end
			end
		end

		local rhsRegs = {}
		for i = 1, numExprs do
			local expr = exprs[i]
			if i == numExprs and numLhs > numExprs and (expr.kind == AstKind.FunctionCallExpression or expr.kind == AstKind.PassSelfFunctionCallExpression) then
				local numNeeded = numLhs - numExprs + 1
				local rFunc = self:allocReg()
				self.regCount = math.max(self.numLocals or 0, rFunc + math.max(numNeeded, 10))
				if expr.kind == AstKind.PassSelfFunctionCallExpression then
					local rSelf = self:compileExpr(expr.base)
					local nameNode = expr.passSelfFunctionName or expr.name
					local args = expr.args or {}
					local lastArg = #args > 0 and args[#args]
					if type(nameNode) == "string" then
						nameNode = Ast.StringExpression(nameNode)
					end
					local rName = self:compileExpr(nameNode)
					if #args == 1 and args[1].kind == AstKind.VarargExpression then
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						self:emit("CALL", rFunc, -101, numNeeded)
					elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + 1 + ai)
						end
						self:emit("CALL", rFunc, -100 - (numFixed + 1), numNeeded)
					elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + 1 + ai)
						end
						local rSub = rFunc + 1 + (numFixed + 1)
						local subMode = self:compileSubCallForExpand(rSub, lastArg)
						self:emit("CALL_EXPAND", rFunc, (numFixed + 1) * 64 + subMode, numNeeded)
					else
						self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args + numNeeded)
						self:emit("GETTABLE", rFunc, rSelf, rName)
						self:emit("MOVE", rFunc + 1, rSelf, 0)
						for ai, arg in ipairs(args) do
							self:compileExprToReg(arg, rFunc + 1 + ai)
						end
						self:emit("CALL", rFunc, #args + 1, numNeeded)
					end
				else
					self:compileExprToReg(expr.base, rFunc)
					local args = expr.args or {}
					local lastArg = #args > 0 and args[#args]
					if #args == 1 and args[1].kind == AstKind.VarargExpression then
						self:emit("CALL", rFunc, -1, numNeeded)
					elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed + numNeeded)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + ai)
						end
						self:emit("CALL", rFunc, -100 - numFixed, numNeeded)
					elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
						local numFixed = #args - 1
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed + numNeeded)
						for ai = 1, numFixed do
							self:compileExprToReg(args[ai], rFunc + ai)
						end
						local rSub = rFunc + numFixed + 1
						local subMode = self:compileSubCallForExpand(rSub, lastArg)
						self:emit("CALL_EXPAND", rFunc, numFixed * 64 + subMode, numNeeded)
					else
						self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args + numNeeded)
						for ai, arg in ipairs(args) do
							self:compileExprToReg(arg, rFunc + ai)
						end
						self:emit("CALL", rFunc, #args, numNeeded)
					end
				end
				for ri = 1, numNeeded do
					rhsRegs[i + ri - 1] = rFunc + ri - 1
				end
			elseif i == numExprs and numLhs > numExprs and expr.kind == AstKind.VarargExpression then
				local numNeeded = numLhs - numExprs + 1
				local rVa = self:allocReg()
				self.regCount = math.max(self.numLocals or 0, rVa + numNeeded)
				self:emit("VARARG", rVa, numNeeded, 0)
				for ri = 1, numNeeded do
					rhsRegs[i + ri - 1] = rVa + ri - 1
				end
			else
				rhsRegs[i] = self:compileExpr(expr)
			end
		end

		for i, lhs in ipairs(stat.lhs or {}) do
			local valReg = rhsRegs[i]
			if not valReg then
				valReg = self:allocReg()
				self:emit("LOADNIL", valReg, valReg, 0)
			end

			if lhs.kind == AstKind.AssignmentVariable then
				if lhs.scope and lhs.scope.isGlobal then
					local name = lhs.scope:getVariableName(lhs.id) or tostring(lhs.id)
					local constVal = (lhs.apiHash ~= nil and lhs.apiHash) or name
					local kIdx = self:addConstant(constVal)
					self:emit("SETGLOBAL", valReg, kIdx, 0)
				else
					local varKey = tostring(lhs.scope) .. ":" .. tostring(lhs.id)
					local varReg = self.varMap[varKey]
					if varReg ~= nil then
						if varReg ~= valReg then
							self:emit("MOVE", varReg, valReg, 0)
						end
					else
						local uvIdx = self:resolveUpvalue(lhs.scope, lhs.id)
						if uvIdx ~= nil then
							self:emit("SETUPVAL", valReg, uvIdx, 0)
						else
							local vReg = self:getVarReg(lhs.scope, lhs.id)
							if vReg ~= valReg then
								self:emit("MOVE", vReg, valReg, 0)
							end
						end
					end
				end
			elseif lhs.kind == AstKind.AssignmentIndexing then
				if lhs.index.kind == AstKind.StringExpression or lhs.index.kind == AstKind.NumberExpression then
					local kIdx = self:addConstant(lhs.index.value)
					local rB = self:compileExpr(lhs.base)
					self:emit("SETTABLE_K", rB, kIdx, valReg)
				else
					local rB = self:compileExpr(lhs.base)
					local rI = self:compileExpr(lhs.index)
					self:emit("SETTABLE", rB, rI, valReg)
				end
			end
		end
	elseif k == AstKind.CompoundAddStatement or k == AstKind.CompoundSubStatement or k == AstKind.CompoundMulStatement or k == AstKind.CompoundDivStatement or k == AstKind.CompoundModStatement or k == AstKind.CompoundPowStatement or k == AstKind.CompoundConcatStatement then
		local opMap = {
			[AstKind.CompoundAddStatement] = Ast.AddExpression,
			[AstKind.CompoundSubStatement] = Ast.SubExpression,
			[AstKind.CompoundMulStatement] = Ast.MulExpression,
			[AstKind.CompoundDivStatement] = Ast.DivExpression,
			[AstKind.CompoundModStatement] = Ast.ModExpression,
			[AstKind.CompoundPowStatement] = Ast.PowExpression,
			[AstKind.CompoundConcatStatement] = Ast.StrCatExpression,
		}
		local readLhs = nil
		if stat.lhs.kind == AstKind.AssignmentVariable then
			readLhs = Ast.VariableExpression(stat.lhs.scope, stat.lhs.id)
		elseif stat.lhs.kind == AstKind.AssignmentIndexing then
			readLhs = Ast.IndexExpression(stat.lhs.base, stat.lhs.index)
		end
		if readLhs and opMap[k] then
			local binExpr = opMap[k](readLhs, stat.rhs)
			self:compileStatement(Ast.AssignmentStatement({ stat.lhs }, { binExpr }))
		end
	elseif k == AstKind.PassSelfFunctionCallStatement then
		local rSelf = self:compileExpr(stat.base)
		local nameNode = stat.passSelfFunctionName or stat.name
		local args = stat.args or {}
		if type(nameNode) == "string" then
			nameNode = Ast.StringExpression(nameNode)
		end
		local rName = self:compileExpr(nameNode)
		local rFunc = self:allocReg()
			local lastArg = #args > 0 and args[#args]
			if #args == 1 and args[1].kind == AstKind.VarargExpression then
				self.regCount = math.max(self.numLocals or 0, rFunc + 2)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				self:emit("CALL", rFunc, -101, 0)
			elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + 1 + i)
				end
				self:emit("CALL", rFunc, -100 - (numFixed + 1), 0)
			elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + 1 + i)
				end
				local rSub = rFunc + 1 + (numFixed + 1)
				local subMode = self:compileSubCallForExpand(rSub, lastArg)
				self:emit("CALL_EXPAND", rFunc, (numFixed + 1) * 64 + subMode, 0)
			else
				self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args)
				self:emit("GETTABLE", rFunc, rSelf, rName)
				self:emit("MOVE", rFunc + 1, rSelf, 0)
				for i, arg in ipairs(args) do
					self:compileExprToReg(arg, rFunc + 1 + i)
				end
				self:emit("CALL", rFunc, #args + 1, 0)
			end
	elseif k == AstKind.FunctionCallStatement then
		local args = stat.args or {}
		local lastArg = #args > 0 and args[#args]
		if #args == 0 and stat.base.kind == AstKind.IndexExpression and (stat.base.index.kind == AstKind.StringExpression or stat.base.index.kind == AstKind.NumberExpression) and self.opcodes["GETTABLE_CALL"] then
			local rBase = self:compileExpr(stat.base.base)
			local kIdx = self:addConstant(stat.base.index.value)
			local rFunc = self:allocReg()
			self:emit("GETTABLE_CALL", rFunc, rBase, kIdx)
		elseif #args == 0 and stat.base.kind == AstKind.VariableExpression and not (stat.base.scope and stat.base.scope.isGlobal) and self.opcodes["MOVE_CALL"] then
			local varKey = tostring(stat.base.scope) .. ":" .. tostring(stat.base.id)
			local varReg = self.varMap[varKey]
			if varReg ~= nil then
				local rFunc = self:allocReg()
				self:emit("MOVE_CALL", rFunc, varReg, 0)
			else
				local rFunc = self:allocReg()
				self:compileExprToReg(stat.base, rFunc)
				self:emit("CALL", rFunc, 0, 0)
			end
		elseif stat.base.kind == AstKind.VariableExpression and stat.base.scope and stat.base.scope.isGlobal and #args == 1 and args[1].kind == AstKind.StringExpression and self.opcodes["GETGLOBAL_CALL"] then
			local funcName = stat.base.scope:getVariableName(stat.base.id) or tostring(stat.base.id)
			local constVal = (stat.base.apiHash ~= nil and stat.base.apiHash) or funcName
			local kFunc = self:addConstant(constVal)
			local kArg = self:addConstant(args[1].value)
			local rFunc = self:allocReg()
			self.regCount = math.max(self.numLocals or 0, rFunc + 2)
			self:emit("LOADK", rFunc + 1, kArg, 0)
			self:emit("GETGLOBAL_CALL", rFunc, kFunc, 1)
		else
			local rFunc = self:allocReg()
			self:compileExprToReg(stat.base, rFunc)
			if #args == 1 and args[1].kind == AstKind.VarargExpression then
				self:emit("CALL", rFunc, -1, 0)
			elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + i)
				end
				self:emit("CALL", rFunc, -100 - numFixed, 0)
			elseif lastArg and type(lastArg) == "table" and (lastArg.kind == AstKind.FunctionCallExpression or lastArg.kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND"] then
				local numFixed = #args - 1
				self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
				for i = 1, numFixed do
					self:compileExprToReg(args[i], rFunc + i)
				end
				local rSub = rFunc + numFixed + 1
				local subMode = self:compileSubCallForExpand(rSub, lastArg)
				self:emit("CALL_EXPAND", rFunc, numFixed * 64 + subMode, 0)
			else
				self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args)
				for i, arg in ipairs(args) do
					self:compileExprToReg(arg, rFunc + i)
				end
				self:emit("CALL", rFunc, #args, 0)
			end
		end
	elseif k == AstKind.IfStatement then
		local rCond = self:compileExpr(stat.condition)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, rCond, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 1, rNot, rTrue)
		local jmpToElse = self:emit("JMP", 0, 0, 0)
		self:compileBlock(stat.body)

		local endJmps = {}
		table.insert(endJmps, self:emit("JMP", 0, 0, 0))

		local currentPos = self:nextInstrIdx()
		self:fixupJmp(jmpToElse, currentPos)

		for _, eif in ipairs(stat.elseifs or {}) do
			local rEifCond = self:compileExpr(eif.condition)
			local rEifNot = self:allocReg()
			self:emit("NOT", rEifNot, rEifCond, 0)
			local rEifTrue = self:allocReg()
			self:emit("LOADBOOL", rEifTrue, 1, 0)
			self:emit("EQ", 1, rEifNot, rEifTrue)
			local jmpNext = self:emit("JMP", 0, 0, 0)
			self:compileBlock(eif.body)
			table.insert(endJmps, self:emit("JMP", 0, 0, 0))
			self:fixupJmp(jmpNext, self:nextInstrIdx())
		end

		if stat.elsebody then
			self:compileBlock(stat.elsebody)
		end

		local finalPos = self:nextInstrIdx()
		for _, jmpIdx in ipairs(endJmps) do
			self:fixupJmp(jmpIdx, finalPos)
		end
	elseif k == AstKind.WhileStatement then
		local lc = self:pushLoop()
		local startPos = self:nextInstrIdx()
		local rCond = self:compileExpr(stat.condition)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, rCond, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 1, rNot, rTrue)
		local jmpEnd = self:emit("JMP", 0, 0, 0)
		self:compileBlock(stat.body)
		local jmpLoop = self:emit("JMP", 0, 0, 0)
		self:fixupJmp(jmpLoop, startPos)
		local exitPos = self:nextInstrIdx()
		self:fixupJmp(jmpEnd, exitPos)
		for _, jmpIdx in ipairs(lc.continueJmps or {}) do
			self:fixupJmp(jmpIdx, startPos)
		end
		for _, jmpIdx in ipairs(lc.breakJmps or {}) do
			self:fixupJmp(jmpIdx, exitPos)
		end
		self:popLoop()
	elseif k == AstKind.RepeatStatement then
		local lc = self:pushLoop()
		local startPos = self:nextInstrIdx()
		self:compileBlock(stat.body)
		local condPos = self:nextInstrIdx()
		for _, jmpIdx in ipairs(lc.continueJmps or {}) do
			self:fixupJmp(jmpIdx, condPos)
		end
		local rCond = self:compileExpr(stat.condition)
		local rNot = self:allocReg()
		self:emit("NOT", rNot, rCond, 0)
		local rTrue = self:allocReg()
		self:emit("LOADBOOL", rTrue, 1, 0)
		self:emit("EQ", 0, rNot, rTrue)
		local jmpExit = self:emit("JMP", 0, 0, 0)
		local jmpLoop = self:emit("JMP", 0, 0, 0)
		self:fixupJmp(jmpLoop, startPos)
		local exitPos = self:nextInstrIdx()
		self:fixupJmp(jmpExit, exitPos)
		for _, jmpIdx in ipairs(lc.breakJmps or {}) do
			self:fixupJmp(jmpIdx, exitPos)
		end
		self:popLoop()
	elseif k == AstKind.ForStatement then
		local lc = self:pushLoop()
		local rBase = self.numLocals or 0
		self.numLocals = rBase + 4
		self.regCount = self.numLocals
		self:compileExprToReg(stat.initialValue, rBase)
		self:compileExprToReg(stat.finalValue, rBase + 1)
		if stat.incrementBy then
			self:compileExprToReg(stat.incrementBy, rBase + 2)
		else
			local kIdx = self:addConstant(1)
			self:emit("LOADK", rBase + 2, kIdx, 0)
		end

		local prepIdx = self:emit("FORPREP", rBase, 0, 0)
		local loopStart = self:nextInstrIdx()
		self.varMap[tostring(stat.scope) .. ":" .. tostring(stat.id)] = rBase + 3

		self:compileBlock(stat.body)
		local loopIdx = self:emit("FORLOOP", rBase, 0, 0)
		self:fixupJmp(prepIdx, loopIdx, 2)
		self:fixupJmp(loopIdx, loopStart, 2)
		local exitPos = self:nextInstrIdx()
		for _, jmpIdx in ipairs(lc.continueJmps or {}) do
			self:fixupJmp(jmpIdx, loopIdx)
		end
		for _, jmpIdx in ipairs(lc.breakJmps or {}) do
			self:fixupJmp(jmpIdx, exitPos)
		end
		self:popLoop()
	elseif k == AstKind.ForInStatement then
		local lc = self:pushLoop()
		local rIter = self.numLocals or 0
		local rState = rIter + 1
		local rVar = rIter + 2
		self.numLocals = rIter + 3
		self.regCount = self.numLocals

		local exprs = stat.expressions or {}
		if #exprs == 1 and (exprs[1].kind == AstKind.FunctionCallExpression or exprs[1].kind == AstKind.PassSelfFunctionCallExpression) then
			local callNode = exprs[1]
			local rFunc = self:allocReg()
			if callNode.kind == AstKind.PassSelfFunctionCallExpression then
				local rSelf = self:compileExpr(callNode.base)
				local nameNode = callNode.passSelfFunctionName or callNode.name
				if type(nameNode) == "string" then
					nameNode = Ast.StringExpression(nameNode)
				end
				local rName = self:compileExpr(nameNode)
				local args = callNode.args or {}
				if #args == 1 and args[1].kind == AstKind.VarargExpression then
					self.regCount = math.max(self.numLocals or 0, rFunc + 2 + 3)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					self:emit("CALL", rFunc, -101, 3)
				elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
					local numFixed = #args - 1
					self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed + 3)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					for i = 1, numFixed do
						self:compileExprToReg(args[i], rFunc + 1 + i)
					end
					self:emit("CALL", rFunc, -100 - (numFixed + 1), 3)
				else
					self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #args + 3)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					for i, arg in ipairs(args) do
						self:compileExprToReg(arg, rFunc + 1 + i)
					end
					self:emit("CALL", rFunc, #args + 1, 3)
				end
			else
				self:compileExprToReg(callNode.base, rFunc)
				local args = callNode.args or {}
				if #args == 1 and args[1].kind == AstKind.VarargExpression then
					self:emit("CALL", rFunc, -1, 3)
				elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
					local numFixed = #args - 1
					self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed + 3)
					for i = 1, numFixed do
						self:compileExprToReg(args[i], rFunc + i)
					end
					self:emit("CALL", rFunc, -100 - numFixed, 3)
				else
					self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #args + 3)
					for i, arg in ipairs(args) do
						self:compileExprToReg(arg, rFunc + i)
					end
					self:emit("CALL", rFunc, #args, 3)
				end
			end
			self:emit("MOVE", rIter, rFunc, 0)
			self:emit("MOVE", rState, rFunc + 1, 0)
			self:emit("MOVE", rVar, rFunc + 2, 0)
		else
			if exprs[1] then self:compileExprToReg(exprs[1], rIter) else self:emit("LOADNIL", rIter, rIter, 0) end
			if exprs[2] then self:compileExprToReg(exprs[2], rState) else self:emit("LOADNIL", rState, rState, 0) end
			if exprs[3] then self:compileExprToReg(exprs[3], rVar) else self:emit("LOADNIL", rVar, rVar, 0) end
		end

		if self.opcodes["FORIN_PREP"] then
			self:emit("FORIN_PREP", rIter, rState, rVar)
		end

		local varRegs = {}
		for i, id in ipairs(stat.ids or {}) do
			varRegs[i] = self:getVarReg(stat.scope, id)
		end

		local loopStart = self:nextInstrIdx()

		local rCall = self:allocReg()
		self.regCount = math.max(self.numLocals or 0, rCall + math.max(3, #varRegs))
		self:emit("MOVE", rCall, rIter, 0)
		self:emit("MOVE", rCall + 1, rState, 0)
		self:emit("MOVE", rCall + 2, rVar, 0)
		self:emit("CALL", rCall, 2, #varRegs)

		for i = 1, #varRegs do
			self:emit("MOVE", varRegs[i], rCall + i - 1, 0)
		end

		if #varRegs > 0 then
			self:emit("MOVE", rVar, varRegs[1], 0)
		end

		local rNil = self:allocReg()
		self:emit("LOADNIL", rNil, rNil, 0)
		self:emit("EQ", 1, varRegs[1] or rNil, rNil)
		local jmpExit = self:emit("JMP", 0, 0, 0)

		self:compileBlock(stat.body)

		local jmpLoop = self:emit("JMP", 0, 0, 0)
		self:fixupJmp(jmpLoop, loopStart)
		local exitPos = self:nextInstrIdx()
		self:fixupJmp(jmpExit, exitPos)
		for _, jmpIdx in ipairs(lc.continueJmps or {}) do
			self:fixupJmp(jmpIdx, loopStart)
		end
		for _, jmpIdx in ipairs(lc.breakJmps or {}) do
			self:fixupJmp(jmpIdx, exitPos)
		end
		self:popLoop()
	elseif k == AstKind.BreakStatement then
		local lc = self:currentLoop()
		if lc then
			local jmpIdx = self:emit("JMP", 0, 0, 0)
			table.insert(lc.breakJmps, jmpIdx)
		end
	elseif k == AstKind.ContinueStatement then
		local lc = self:currentLoop()
		if lc then
			local jmpIdx = self:emit("JMP", 0, 0, 0)
			table.insert(lc.continueJmps, jmpIdx)
		end
	elseif k == AstKind.DoStatement then
		self:compileBlock(stat.body)
	elseif k == AstKind.LocalFunctionDeclaration then
		local varReg = self:getVarReg(stat.scope, stat.id)
		local kIdx = self:addConstant({ code = {} })
		local subCompiler = self:compileSubProto(stat.body, stat.args)
		local uvList = {}
		for _, uvDesc in ipairs(subCompiler.upvalues) do
			table.insert(uvList, { uvDesc.isUpval, uvDesc.index })
		end
		self:setConstant(kIdx, { code = subCompiler.code, upvalues = uvList, numParams = subCompiler.numFixedParams, profile = subCompiler.profile, encodedRegions = subCompiler.encodedRegions, regions = subCompiler.regions })
		self:emit("CLOSURE", varReg, kIdx, #uvList)
	elseif k == AstKind.FunctionDeclaration then
		local kIdx = self:addConstant({ code = {} })
		local funcArgs = stat.args or {}
		local subCompiler = self:compileSubProto(stat.body, funcArgs)
		local uvList = {}
		for _, uvDesc in ipairs(subCompiler.upvalues) do
			table.insert(uvList, { uvDesc.isUpval, uvDesc.index })
		end
		self:setConstant(kIdx, { code = subCompiler.code, upvalues = uvList, numParams = subCompiler.numFixedParams, profile = subCompiler.profile, encodedRegions = subCompiler.encodedRegions, regions = subCompiler.regions })
		local cReg = self:allocReg()
		self:emit("CLOSURE", cReg, kIdx, #uvList)

		local indices = stat.indices or {}
		if #indices > 0 then
			local rTbl = self:allocReg()
			if stat.scope and stat.scope.isGlobal then
				local name = stat.scope:getVariableName(stat.id) or tostring(stat.id)
				local constVal = (stat.apiHash ~= nil and stat.apiHash) or name
				local kName = self:addConstant(constVal)
				self:emit("GETGLOBAL", rTbl, kName, 0)
			else
				local varKey = tostring(stat.scope) .. ":" .. tostring(stat.id)
				local varReg = self.varMap[varKey]
				if varReg ~= nil then
					self:emit("MOVE", rTbl, varReg, 0)
				else
					local uvIdx = self:resolveUpvalue(stat.scope, stat.id)
					if uvIdx ~= nil then
						self:emit("GETUPVAL", rTbl, uvIdx, 0)
					else
						local name = (stat.scope and stat.scope:getVariableName(stat.id)) or tostring(stat.id)
						local constVal = (stat.apiHash ~= nil and stat.apiHash) or name
						local kName = self:addConstant(constVal)
						self:emit("GETGLOBAL", rTbl, kName, 0)
					end
				end
			end

			for i = 1, #indices - 1 do
				local idxNode = indices[i]
				if type(idxNode) == "string" then idxNode = Ast.StringExpression(idxNode) end
				local rIdx = self:compileExpr(idxNode)
				self:emit("GETTABLE", rTbl, rTbl, rIdx)
			end

			local lastIdxNode = indices[#indices]
			if type(lastIdxNode) == "string" then lastIdxNode = Ast.StringExpression(lastIdxNode) end
			local rLastIdx = self:compileExpr(lastIdxNode)
			self:emit("SETTABLE", rTbl, rLastIdx, cReg)
		else
			if stat.scope and stat.scope.isGlobal then
				local name = stat.scope:getVariableName(stat.id) or tostring(stat.id)
				local constVal = (stat.apiHash ~= nil and stat.apiHash) or name
				local kNameIdx = self:addConstant(constVal)
				self:emit("SETGLOBAL", cReg, kNameIdx, 0)
			else
				local varKey = tostring(stat.scope) .. ":" .. tostring(stat.id)
				local varReg = self.varMap[varKey]
				if varReg ~= nil then
					self:emit("MOVE", varReg, cReg, 0)
				else
					local uvIdx = self:resolveUpvalue(stat.scope, stat.id)
					if uvIdx ~= nil then
						self:emit("SETUPVAL", cReg, uvIdx, 0)
					else
						local vReg = self:getVarReg(stat.scope, stat.id)
						self:emit("MOVE", vReg, cReg, 0)
					end
				end
			end
		end
	elseif k == AstKind.ReturnStatement then
		local args = stat.args or {}
		if #args == 0 then
			if self.opcodes["LOADNIL_RET"] then
				self:emit("LOADNIL_RET", 0, 0, 0)
			else
				self:emit("RETURN", 0, -1, 0)
			end
		elseif #args == 1 and args[1].kind == AstKind.VariableExpression then
			local varKey = tostring(args[1].scope) .. ":" .. tostring(args[1].id)
			local varReg = self.varMap[varKey]
			if varReg ~= nil and self.opcodes["MOVE_RET"] then
				self:emit("MOVE_RET", 0, varReg, 0)
			else
				local rStart = self:allocReg()
				self:compileExprToReg(args[1], rStart)
				self:emit("RETURN", rStart, rStart, 0)
			end
		elseif #args == 1 and (args[1].kind == AstKind.FunctionCallExpression or args[1].kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_RET"] then
			local callNode = args[1]
			local rFunc = self:allocReg()
			if callNode.kind == AstKind.PassSelfFunctionCallExpression then
				local rSelf = self:compileExpr(callNode.base)
				local nameNode = callNode.passSelfFunctionName or callNode.name
				if type(nameNode) == "string" then nameNode = Ast.StringExpression(nameNode) end
				local rName = self:compileExpr(nameNode)
				local cArgs = callNode.args or {}
				if #cArgs == 1 and cArgs[1].kind == AstKind.VarargExpression then
					self.regCount = math.max(self.numLocals or 0, rFunc + 2)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					self:emit("CALL_RET", rFunc, -101, 0)
				elseif #cArgs > 1 and cArgs[#cArgs].kind == AstKind.VarargExpression then
					local numFixed = #cArgs - 1
					self.regCount = math.max(self.numLocals or 0, rFunc + 2 + numFixed)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					for i = 1, numFixed do
						self:compileExprToReg(cArgs[i], rFunc + 1 + i)
					end
					self:emit("CALL_RET", rFunc, -100 - (numFixed + 1), 0)
				else
					self.regCount = math.max(self.numLocals or 0, rFunc + 2 + #cArgs)
					self:emit("GETTABLE", rFunc, rSelf, rName)
					self:emit("MOVE", rFunc + 1, rSelf, 0)
					for i, arg in ipairs(cArgs) do
						self:compileExprToReg(arg, rFunc + 1 + i)
					end
					self:emit("CALL_RET", rFunc, #cArgs + 1, 0)
				end
			else
				self:compileExprToReg(callNode.base, rFunc)
				local cArgs = callNode.args or {}
				if #cArgs == 1 and cArgs[1].kind == AstKind.VarargExpression then
					self:emit("CALL_RET", rFunc, -1, 0)
				elseif #cArgs > 1 and cArgs[#cArgs].kind == AstKind.VarargExpression then
					local numFixed = #cArgs - 1
					self.regCount = math.max(self.numLocals or 0, rFunc + 1 + numFixed)
					for i = 1, numFixed do
						self:compileExprToReg(cArgs[i], rFunc + i)
					end
					self:emit("CALL_RET", rFunc, -100 - numFixed, 0)
				else
					self.regCount = math.max(self.numLocals or 0, rFunc + 1 + #cArgs)
					for i, arg in ipairs(cArgs) do
						self:compileExprToReg(arg, rFunc + i)
					end
					self:emit("CALL_RET", rFunc, #cArgs, 0)
				end
			end
		elseif #args > 1 and (args[#args].kind == AstKind.FunctionCallExpression or args[#args].kind == AstKind.PassSelfFunctionCallExpression) and self.opcodes["CALL_EXPAND_RET"] then
			local numFixed = #args - 1
			local rStart = self:allocReg()
			self.regCount = math.max(self.numLocals or 0, rStart + numFixed)
			for i = 1, numFixed do
				self:compileExprToReg(args[i], rStart + i - 1)
			end
			local rSub = rStart + numFixed
			local subMode = self:compileSubCallForExpand(rSub, args[#args])
			self:emit("CALL_EXPAND_RET", rStart, numFixed * 64 + subMode, 0)
		elseif #args == 1 and args[1].kind == AstKind.VarargExpression then
			self:emit("RETURN", 0, -2, 0)
		elseif #args > 1 and args[#args].kind == AstKind.VarargExpression then
			local rStart = self:allocReg()
			local numFixed = #args - 1
			self.regCount = math.max(self.numLocals or 0, rStart + numFixed)
			for i = 1, numFixed do
				self:compileExprToReg(args[i], rStart + i - 1)
			end
			self:emit("RETURN", rStart, -100 - numFixed, 0)
		else
			local rStart = self:allocReg()
			self.regCount = math.max(self.numLocals or 0, rStart + #args)
			for i, arg in ipairs(args) do
				self:compileExprToReg(arg, rStart + i - 1)
			end
			self:emit("RETURN", rStart, rStart + #args - 1, 0)
		end
	end
end

function BytecodeCompiler:compileBlock(block)
	if not block or not block.statements then return end
	for _, stat in ipairs(block.statements) do
		if stat.kind ~= AstKind.NopStatement then
			self.regCount = self.numLocals or 0
			self:compileStatement(stat)
			self.regCount = self.numLocals or 0
		end
	end
end

function BytecodeCompiler:buildRegions(keyMaterial)
	local vmRng = RandomDomains.get("VM")
	local lowerer = SemanticLowerer.new(self.profile, vmRng)
	local graphLowerer = GraphLowerer.new(self.profile, vmRng)
	local baseSalt = (keyMaterial and keyMaterial.baseSalt) or (self.profile and (self.profile.baseSalt or (self.profile.keyMaterial and self.profile.keyMaterial.baseSalt))) or 1337
	local protoSalt = self.profile.protoSalt or 1337
	self.profile.protoSalt = protoSalt
	local protoKey = KeySchedule.deriveProtoKey(keyMaterial, protoSalt, #self.code * 2, self.profile.keyMode or 1)
	self.profile.protoKey = protoKey
	local regEncoder = RegionEncoder.new(self.profile, vmRng, baseSalt)

	local leaderSet = { [1] = true }
	for targetIdx, _ in pairs(self.jumpTargets or {}) do
		leaderSet[targetIdx] = true
	end
	local debugInstrs = self.debugInstructions or {}
	for idx, instr in ipairs(debugInstrs) do
		local op = instr.op
		if op == "JMP" or op == "FORPREP" or op == "FORLOOP" or op == "CALL" or op == "RETURN" or op == "FORIN_PREP" then
			if idx + 1 <= #debugInstrs then
				leaderSet[idx + 1] = true
			end
		end
	end

	local regions = {}
	local currentRegion = { id = 1, microNodes = {}, regA = 0, regB = 0, regC = 0, startInstr = 1, opCodes = {}, opNames = {} }
	table.insert(regions, currentRegion)

	local prevCommitment = 1337

	for idx = 1, #debugInstrs - 1 do
		local cur = debugInstrs[idx]
		local nxt = debugInstrs[idx + 1]
		if (cur.op == "EQ" or cur.op == "LT" or cur.op == "LE" or cur.op == "TEST" or cur.op == "TESTSET") and nxt.op == "JMP" then
			if self.jumpEdges and self.jumpEdges[idx + 1] and not self.jumpEdges[idx] then
				self.jumpEdges[idx] = self.jumpEdges[idx + 1]
			end
		end
	end

	for idx, instr in ipairs(debugInstrs) do
		local prevInstr = idx > 1 and debugInstrs[idx - 1]
		local isPairedJmp = prevInstr and (prevInstr.op == "EQ" or prevInstr.op == "LT" or prevInstr.op == "LE" or prevInstr.op == "TEST" or prevInstr.op == "TESTSET") and instr.op == "JMP"
		local canSplit = not isPairedJmp
		if canSplit and ((idx > 1 and leaderSet[idx]) or #currentRegion.microNodes >= 32) then
			local predComm = prevCommitment
			local commData = GraphIntegrity.computeDistributedCommitment(
				currentRegion.microNodes,
				currentRegion.id,
				protoKey,
				(currentRegion.id * 31 + 101) % 65536,
				predComm
			)
			currentRegion.commitment = commData.commitment
			prevCommitment = commData.commitment

			currentRegion = { id = #regions + 1, microNodes = {}, regA = instr.A or 0, regB = instr.B or 0, regC = instr.C or 0, startInstr = idx, opCodes = {}, opNames = {} }
			table.insert(regions, currentRegion)
		end

		local opToLower = instr.op
		if opToLower == "JMP" and isPairedJmp then
			opToLower = "JMP_COND"
		end
		local recipe = lowerer:lowerOp(opToLower, instr.A, instr.B, instr.C, currentRegion.id)
		local lowered = graphLowerer:lowerGraph({ nodes = recipe or {} })
		for _, node in ipairs(lowered.nodes or {}) do
			table.insert(currentRegion.microNodes, node)
		end
		currentRegion.opCodes = currentRegion.opCodes or {}
		table.insert(currentRegion.opCodes, (self.opcodes and self.opcodes[opToLower]) or 0)
		currentRegion.opNames = currentRegion.opNames or {}
		table.insert(currentRegion.opNames, opToLower)
	end

	if currentRegion then
		local predComm = prevCommitment
		local commData = GraphIntegrity.computeDistributedCommitment(
			currentRegion.microNodes,
			currentRegion.id,
			protoKey,
			(currentRegion.id * 31 + 101) % 65536,
			predComm
		)
		currentRegion.commitment = commData.commitment
		prevCommitment = commData.commitment
	end

	local instrToRegion = {}
	for idx, tr in ipairs(regions) do
		local trEnd = (idx < #regions and regions[idx + 1].startInstr - 1) or #debugInstrs
		for ins = tr.startInstr, trEnd do
			instrToRegion[ins] = tr.id
		end
	end

	for i = 1, #regions do
		local r = regions[i]
		local startOffset = (self.instrOffsets and self.instrOffsets[r.startInstr]) or 1
		r.startDip = (startOffset - 1) * 2 + 1
		if i < #regions then
			local nextStartOffset = (self.instrOffsets and self.instrOffsets[regions[i + 1].startInstr]) or (#self.code + 1)
			r.endDip = (nextStartOffset - 1) * 2 + 1
			r.nextId = regions[i + 1].id
		else
			r.endDip = #self.code * 2 + 1
			r.nextId = 0
		end

		r.jumpId = 0
		local endInstr = (i < #regions and regions[i + 1].startInstr - 1) or #debugInstrs
		for insIdx = endInstr, r.startInstr, -1 do
			local targetInstr = self.jumpEdges and self.jumpEdges[insIdx]
			if targetInstr then
				local targetId = instrToRegion[targetInstr]
				if targetId and targetId ~= r.id then
					r.jumpId = targetId
					break
				end
			end
		end
	end

	self.regions = regions
	self.encodedRegions = regEncoder:encodeRegionStream(regions)
	return self.encodedRegions
end

function BytecodeCompiler:serializeRegions(encodedRegions, regions, encCodeBytes, permutedAlphabet, baseSalt)
	baseSalt = baseSalt or 1337
	permutedAlphabet = permutedAlphabet or StreamEncoder.BASE85_ALPHABET
	local regionEntries = {}

	for idx, r in ipairs(regions or {}) do
		local rPack = encodedRegions and encodedRegions[idx]
		local startDip = r.startDip or 1
		local endDip = r.endDip or ((encCodeBytes and #encCodeBytes + 1) or 1)
		local nextId = r.nextId or 0
		local numNodes = (rPack and rPack.numNodes) or #(r.microNodes or {})
		local commitment = (rPack and rPack.commitment) or (r.commitment or 0)
		local jumpId = (rPack and rPack.jumpId) or (r.jumpId or 0)
		local packedContext = (rPack and (rPack.packedContext or rPack.regContext)) or (r.packedContext or 1101300)

		local codeB85 = ""
		if self.executionRepresentation ~= "REGIONS" then
			local rolling = (baseSalt * 23 + (r.id or idx) * 41) % 256
			local regCodeStream = {}
			for p = startDip, endDip - 1 do
				local b = (encCodeBytes and encCodeBytes[p]) or 0
				local bPos = p - startDip + 1
				local enc = (b + rolling * 37 + baseSalt * 13 + bPos * 19) % 256
				rolling = (rolling * 53 + enc * 17 + b * 7 + bPos * 11) % 256
				table.insert(regCodeStream, enc)
			end
			codeB85 = StreamEncoder.encodeBase85(regCodeStream, permutedAlphabet)
		end
		local nodeB85 = StreamEncoder.encodeBase85((rPack and rPack.stream) or {}, permutedAlphabet)
		local aluMask = math.floor((rPack and rPack.aluMask) or 0)
		local commInt = math.floor(commitment)

		local regId = r.id or idx
		local encRegId = (regId + commInt * 11 + baseSalt * 13) % 65536
		local encNumNodes = (numNodes + commInt * 29 + baseSalt * 17) % 65536
		local encStartDip = (startDip + commInt * 37 + baseSalt * 19) % 65536
		local encEndDip = (endDip + commInt * 43 + baseSalt * 23) % 65536
		local encNextId = (nextId + commInt * 17 + baseSalt * 31 + regId * 13) % 65536
		local encJumpId = (jumpId + commInt * 23 + baseSalt * 41 + regId * 19) % 65536

		local opCodesStr = ""
		if self.profile and self.profile.profileBuild then
			local quoted = {}
			for _, n in ipairs(r.opNames or {}) do
				table.insert(quoted, '"' .. tostring(n) .. '"')
			end
			local payload = (#quoted > 0 and table.concat(quoted, ",")) or table.concat(r.opCodes or {}, ",")
			opCodesStr = ",nil,{" .. payload .. "}"
		end
		local entry = "{" .. tostring(encRegId) .. ',"' .. codeB85 .. '","' .. nodeB85 .. '",' .. tostring(encNumNodes) .. "," .. tostring(encStartDip) .. "," .. tostring(encEndDip) .. "," .. tostring(encJumpId) .. "," .. tostring(packedContext) .. "," .. string.format("%.0f", aluMask) .. "," .. tostring(encNextId) .. "," .. string.format("%.0f", commInt) .. opCodesStr .. "}"
		table.insert(regionEntries, entry)
	end

	return "{" .. table.concat(regionEntries, ",") .. "}"
end

function BytecodeCompiler:compile(ast)
	self.executionRepresentation = "REGIONS"
	local keyMaterial = self.profile.keyMaterial or KeySchedule.generateKeyMaterial(self.profile.seed or 1337)
	self.profile.keyMaterial = keyMaterial
	self.profile.baseSalt = keyMaterial.baseSalt

	self:compileBlock(ast.body)
	local encodedRegions = self:buildRegions(keyMaterial)

	local topProtoSalt = self.profile.protoSalt or 1337
	local topKeyMode = self.profile.keyMode or 1
	local rawLen = #self.code * 2
	local topKey = KeySchedule.deriveProtoKey(keyMaterial, topProtoSalt, rawLen, topKeyMode)

	local baseSalt = (keyMaterial and keyMaterial.baseSalt) or 1337
	self.profile.bcLayout = self.profile.bcLayout or ((baseSalt % 3) + 1)
	local bcLayout = self.profile.bcLayout
	local permutedAlphabet = (keyMaterial and keyMaterial.alphabet) or StreamEncoder.getPermutedAlphabet(baseSalt)
	local topEncBytes = (self.executionRepresentation == "REGIONS") and {} or StreamEncoder.getEncryptedStreamBytes(self.code, topKey, topProtoSalt)
	local codeStr = (self.executionRepresentation == "REGIONS") and "" or StreamEncoder.encodeBase85(topEncBytes, permutedAlphabet)
	local topSerializedRegions = self:serializeRegions(self.encodedRegions, self.regions, topEncBytes, permutedAlphabet, baseSalt)

	local function modInverse256(a)
		for x = 1, 255 do
			if (a * x) % 256 == 1 then
				return x
			end
		end
		return 1
	end

	local function getMetaSlots(salt)
		local s = salt % 24
		local perms = {
			{1,2,3,4,5}, {1,3,2,5,4}, {2,1,4,3,5}, {2,3,1,5,4},
			{3,1,2,4,5}, {3,2,1,5,4}, {4,1,2,3,5}, {4,2,3,1,5},
			{5,1,2,3,4}, {5,2,1,4,3}, {1,4,2,3,5}, {2,4,1,3,5},
			{3,4,1,2,5}, {4,3,1,2,5}, {1,5,2,3,4}, {2,5,1,3,4},
			{3,5,1,2,4}, {4,5,1,2,3}, {5,4,1,2,3}, {1,2,4,3,5},
			{2,1,5,3,4}, {3,1,5,2,4}, {4,1,5,2,3}, {5,1,4,2,3}
		}
		return perms[(s % #perms) + 1]
	end
	local metaSlots = getMetaSlots(baseSalt)

	-- 1. Emit Constant Pool with Stream-Encapsulated Polymorphic String Descriptors
	local kEntries = {}
	local kBlobBytes = {}

	for i, val in ipairs(self.K) do
		if type(val) == "string" or (type(val) == "table" and (val._arith or val._str)) then
			local rawStr = (type(val) == "string" and val) or (type(val) == "table" and val._str)
			local packed = (rawStr and self:encodePolymorphicString(rawStr, i, baseSalt, topProtoSalt)) or (type(val) == "table" and val._arith)
			local pLen = (packed and #packed) or 0
			if pLen > 0 then
				local b85 = StreamEncoder.encodeBase85(packed, permutedAlphabet)
				table.insert(kEntries, '"' .. b85 .. '"')
			else
				table.insert(kEntries, '""')
			end
		elseif type(val) == "number" or type(val) == "boolean" then
			table.insert(kEntries, tostring(val))
		elseif type(val) == "table" and val.code then
			local subProfile = val.profile or self.profile
			local salt = subProfile.protoSalt or i
			local subLen = #val.code * 2
			local subKeyMode = subProfile.keyMode or 1
			local subKey = KeySchedule.deriveProtoKey(keyMaterial, salt, subLen, subKeyMode)
			subProfile.protoKey = subKey
			local subEncBytes = (self.executionRepresentation == "REGIONS") and {} or StreamEncoder.getEncryptedStreamBytes(val.code, subKey, salt)
			local subCodeStr = (self.executionRepresentation == "REGIONS") and "" or StreamEncoder.encodeBase85(subEncBytes, permutedAlphabet)
			local subRegions = val.regions or { { id = 1, startDip = 1, endDip = subLen + 1, nextId = 0, microNodes = {} } }
			local subSerializedRegions = val.serializedRegions or self:serializeRegions(val.encodedRegions, subRegions, subEncBytes, permutedAlphabet, baseSalt)
			local uvEntries = {}
			for _, uv in ipairs(val.upvalues or {}) do
				local isUv = uv[1] or uv.isUpval or 0
				local uIdx = uv[2] or uv.index or 0
				table.insert(uvEntries, "{" .. tostring(isUv) .. "," .. tostring(uIdx) .. "}")
			end
			local packMode = (subProfile.dispatchMode or 1) * 32 + (subProfile.operandLayout or 0) * 4 + subKeyMode
			local regPack = (subProfile.regMul or 23) * 256 + (subProfile.regOffset or 0)
			local encSalt = (salt + baseSalt * 17) % 65536
			local encPackMode = (packMode + baseSalt * 19) % 65536
			local encRegPack = (regPack + baseSalt * 23) % 65536
			local encByteLen = (subLen + baseSalt * 29) % 65536
			local metaArr = {}
			metaArr[metaSlots[1]] = tostring(encSalt)
			metaArr[metaSlots[2]] = tostring(val.numParams or val.numFixedParams or 0)
			metaArr[metaSlots[3]] = tostring(encPackMode)
			metaArr[metaSlots[4]] = tostring(encRegPack)
			metaArr[metaSlots[5]] = tostring(encByteLen)
			local metaPart = "{" .. table.concat(metaArr, ",") .. "}"
			local uvPart = "{" .. table.concat(uvEntries, ",") .. "}"
			local codePart = (self.executionRepresentation == "REGIONS") and '""' or ('"' .. subCodeStr .. '"')
			local lazyRegionsPart = subSerializedRegions
			local protoTuple
			if bcLayout == 1 then
				protoTuple = "{" .. metaPart .. "," .. uvPart .. "," .. codePart .. "," .. lazyRegionsPart .. "}"
			elseif bcLayout == 2 then
				protoTuple = "{" .. uvPart .. "," .. codePart .. "," .. metaPart .. "," .. lazyRegionsPart .. "}"
			else
				protoTuple = "{" .. metaPart .. "," .. codePart .. "," .. uvPart .. "," .. lazyRegionsPart .. "}"
			end
			table.insert(kEntries, protoTuple)
		else
			table.insert(kEntries, "nil")
		end
	end

	local function buildProceduralBlob(bytes, bSalt)
		local STATE_PRIMES = { 16777213, 16777199, 16777141, 16777093, 16777087, 16777067, 16777039, 16776989 }
		local prime = STATE_PRIMES[((bSalt % #STATE_PRIMES)) + 1]
		local seed = ((bSalt * 1337 + 101) % 65536) + 17
		local mul = ((bSalt * 31 + 17) % 256) * 2 + 1
		local add = (bSalt * 43 + 71) % 65536
		local coeff = ((bSalt * 19 + 23) % 128) * 2 + 1
		local mode = (bSalt % 4) + 1
		local MOD24 = 16777216
		local words = {}
		local s = seed
		for i = 1, #bytes, 3 do
			local b1 = bytes[i] or 0
			local b2 = bytes[i + 1] or 0
			local b3 = bytes[i + 2] or 0
			local u = b1 + b2 * 256 + b3 * 65536
			local wordIdx = math.floor((i - 1) / 3)
			local k = 0
			if mode == 1 then
				s = (s * mul + add) % prime
				k = (s * coeff) % MOD24
			elseif mode == 2 then
				s = (s * 37 + wordIdx * 19 + add) % prime
				k = ((((wordIdx * mul + add) * wordIdx + s) * coeff)) % MOD24
			elseif mode == 3 then
				s = (s * mul + 31) % 4096
				local h2 = ((s * coeff + add) % 4096) * 4096
				k = (s + h2 + (bSalt % 256)) % MOD24
			else
				s = (s * 7 + wordIdx * 13 + add) % prime
				k = (s * mul + wordIdx * coeff) % MOD24
			end
			local encW = (u + k) % MOD24
			table.insert(words, tostring(encW))
		end
		return {
			mode = mode,
			words = words,
			seed = seed,
			prime = prime,
			mul = mul,
			add = add,
			coeff = coeff,
			totalBytes = #bytes,
		}
	end

	local kBlobSpec = buildProceduralBlob(kBlobBytes, baseSalt)
	local kStr = "{" .. table.concat(kEntries, ",") .. "}"

	local opWidthsById = {}
	for name, id in pairs(self.opcodes) do
		local w = (self.opcodeWidths and self.opcodeWidths[name]) or 4
		opWidthsById[id] = w
	end

	if self.profile and self.pipeline and self.pipeline.apiHashCoeffs then
		self.profile.apiHashCoeffs = self.pipeline.apiHashCoeffs
	end

	local runtimeCode = VMRuntime.generateRuntimeCode(self.profile, opWidthsById, codeStr, kStr, keyMaterial, nil, rawLen, permutedAlphabet, kBlobSpec, topSerializedRegions, self.pipeline and self.pipeline.guardAttestation)
	local parser = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 })
	local ok, ast = pcall(function() return parser:parse(runtimeCode) end)
	if not ok then
		error(tostring(ast), 0)
	end
	return ast
end

return BytecodeCompiler
