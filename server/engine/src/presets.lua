-- This Script is Part of the Zero Lua Obfuscator v9.15
--
-- presets.lua
--
-- Tiered Security & Compatibility Presets for Zero Lua v9.15.

local CompatiblePreset = {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "MacroProcessor", Settings = {} },
		{ Name = "HookCompatibility", Settings = {} },
		{ Name = "TrollHoneypots", Settings = {} },
		{ Name = "SteganographicPromptShield", Settings = {} },
		{ Name = "NumbersToExpressions", Settings = { Threshold = 0.3 } },
		{ Name = "Vmify", Settings = { Profile = "SAFE" } },
	},
}

local BalancedPreset = {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "MacroProcessor", Settings = {} },
		{ Name = "HookCompatibility", Settings = {} },
		{ Name = "TrollHoneypots", Settings = {} },
		{ Name = "SteganographicPromptShield", Settings = {} },
		{ Name = "PolymorphicStringEscape", Settings = { Threshold = 1.0 } },
		{ Name = "NumbersToExpressions", Settings = { Threshold = 0.5 } },
		{ Name = "MBAExpressions", Settings = { Intensity = 0.25 } },
		{ Name = "OpaquePredicates", Settings = { Intensity = 0.1 } },
		{ Name = "RobloxMathAttestation", Settings = { Mode = "COMPAT" } },
		{ Name = "Vmify", Settings = { Profile = "STRONG" } },
	},
}

local PerformancePreset = {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "MacroProcessor", Settings = {} },
		{ Name = "HookCompatibility", Settings = {} },
		{ Name = "TrollHoneypots", Settings = {} },
		{ Name = "SteganographicPromptShield", Settings = {} },
		{ Name = "Vmify", Settings = { Profile = "PERFORMANCE" } },
	},
}

local HardPreset = {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "MacroProcessor", Settings = {} },
		{ Name = "HookCompatibility", Settings = {} },
		{ Name = "TrollHoneypots", Settings = {} },
		{ Name = "SteganographicPromptShield", Settings = {} },
		{ Name = "PolymorphicStringEscape", Settings = { Threshold = 1.0 } },
		{ Name = "AntiProxyProbe", Settings = { Mode = "COMPAT" } },
		{ Name = "RobloxMathAttestation", Settings = { Mode = "COMPAT" } },
		{ Name = "ApiHashing", Settings = {} },
		{ Name = "Vmify", Settings = { Profile = "HARD" } },
	},
}

local ExtremePreset = {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "MacroProcessor", Settings = {} },
		{ Name = "HookCompatibility", Settings = {} },
		{ Name = "TrollHoneypots", Settings = {} },
		{ Name = "SteganographicPromptShield", Settings = {} },
		{ Name = "PolymorphicStringEscape", Settings = { Threshold = 1.0 } },
		{ Name = "AntiProxyProbe", Settings = { Mode = "COMPAT" } },
		{ Name = "Anti25msTrace", Settings = {} },
		{ Name = "AntiTamper", Settings = {} },
		{ Name = "AntiHook", Settings = { Mode = "COMPAT" } },
		{ Name = "RobloxMathAttestation", Settings = { Mode = "STRICT" } },
		{ Name = "ApiHashing", Settings = {} },
		{ Name = "Vmify", Settings = { Profile = "EXTREME" } },
	},
}

local Presets = {
	["COMPATIBLE"] = CompatiblePreset,
	["Compatible"] = CompatiblePreset,
	["SAFE"] = CompatiblePreset,
	["Safe"] = CompatiblePreset,
	["BALANCED"] = BalancedPreset,
	["Balanced"] = BalancedPreset,
	["PERFORMANCE"] = PerformancePreset,
	["Performance"] = PerformancePreset,
	["STRONG"] = BalancedPreset,
	["HARD"] = HardPreset,
	["Hard"] = HardPreset,
	["EXTREME"] = ExtremePreset,
	["Extreme"] = ExtremePreset,
	["Maximum"] = ExtremePreset,
	["Zero Lua"] = ExtremePreset,
	["Zero Impact"] = ExtremePreset,
	["Luavion"] = ExtremePreset,
	["LUAVION"] = ExtremePreset,
	["Minify"] = {
		LuaVersion = "LuaU",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {},
	},
}

return Presets
