-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- steps.lua
--
-- This Script provides a collection of obfuscation steps.

return {
	WrapInFunction = require("zerolua.steps.WrapInFunction"),
	SplitStrings = require("zerolua.steps.SplitStrings"),
	Vmify = require("zerolua.steps.Vmify"),
	ConstantArray = require("zerolua.steps.ConstantArray"),
	ProxifyLocals = require("zerolua.steps.ProxifyLocals"),
	AntiTamper = require("zerolua.steps.AntiTamper"),
	EncryptStrings = require("zerolua.steps.EncryptStrings"),
	NumbersToExpressions = require("zerolua.steps.NumbersToExpressions"),
	AddVararg = require("zerolua.steps.AddVararg"),
	WatermarkCheck = require("zerolua.steps.WatermarkCheck"),
	JunkCode = require("zerolua.steps.JunkCode"),
	MBAExpressions = require("zerolua.steps.MBAExpressions"),
	OpaquePredicates = require("zerolua.steps.OpaquePredicates"),
	TrollHoneypots = require("zerolua.steps.TrollHoneypots"),
	MacroProcessor = require("zerolua.steps.MacroProcessor"),
	HookCompatibility = require("zerolua.steps.HookCompatibility"),
	AntiHook = require("zerolua.steps.AntiHook"),
	PolymorphicStringEscape = require("zerolua.steps.PolymorphicStringEscape"),
	ControlFlowFlattening = require("zerolua.steps.ControlFlowFlattening"),
	ClosureIntegrity = require("zerolua.steps.ClosureIntegrity"),
	AntiProxyProbe = require("zerolua.steps.AntiProxyProbe"),
	AntiTiming = require("zerolua.steps.AntiTiming"),
	Anti25msTrace = require("zerolua.steps.Anti25msTrace"),
	ApiHashing = require("zerolua.steps.ApiHashing"),
	Base85Encoder = require("zerolua.steps.Base85Encoder"),
	MathStringEscape = require("zerolua.steps.MathStringEscape"),
	AntiOfflineSimulation = require("zerolua.steps.AntiOfflineSimulation"),
	["Anti Offline Simulation"] = require("zerolua.steps.AntiOfflineSimulation"),
	RobloxMathAttestation = require("zerolua.steps.RobloxMathAttestation"),
	["Roblox Math Attestation"] = require("zerolua.steps.RobloxMathAttestation"),
	SteganographicPromptShield = require("zerolua.steps.SteganographicPromptShield"),
	["Steganographic Prompt Shield"] = require("zerolua.steps.SteganographicPromptShield"),
	["Steganographic AI Prompt Shield"] = require("zerolua.steps.SteganographicPromptShield"),
}