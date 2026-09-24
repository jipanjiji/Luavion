-- Standard Roblox and Luau API, service, and member property dictionary
-- Used across ApiHashing, BytecodeCompiler, and VMRuntime to eliminate plaintext APIs.

local StdApiNames = {}

StdApiNames.list = {
	"workspace", "game", "script", "task", "Vector3", "Vector2", "Vector3int16", "Vector2int16",
	"CFrame", "Color3", "UDim", "UDim2", "Enum", "Instance", "TweenInfo", "RaycastParams",
	"Ray", "BrickColor", "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence",
	"ColorSequenceKeypoint", "Rect", "PhysicalProperties", "Font", "OverlapParams", "PathWaypoint",
	"Random", "Region3", "Region3int16", "Faces", "Axes", "DateTime", "CatalogSearchParams",
	"FloatCurveKey", "RotationCurveKey", "Secret", "Content", "buffer", "math", "string",
	"table", "coroutine", "os", "debug", "bit32", "utf8", "print", "warn", "error",
	"pairs", "ipairs", "next", "pcall", "xpcall", "select", "tonumber", "tostring",
	"type", "typeof", "rawget", "rawset", "rawequal", "rawlen", "setmetatable", "getmetatable",
	"unpack", "require", "tick", "time", "elapsedTime", "spawn", "delay", "wait",
	"shared", "_G", "getgenv", "getrenv", "getrawmetatable", "setrawmetatable", "hookmetamethod",
	"hookfunction", "getnamecallmethod", "setnamecallmethod", "checkcaller", "newcclosure",
	"clonefunction", "replaceclosure", "loadstring", "getfenv", "setfenv", "newproxy",
	-- Roblox Services & Core Globals
	"Players", "Workspace", "Lighting", "ReplicatedStorage",
	"ReplicatedFirst", "ServerScriptService", "ServerStorage",
	"StarterGui", "StarterPack", "StarterPlayer",
	"SoundService", "Chat", "LocalizationService",
	"TweenService", "RunService", "HttpService",
	"TeleportService", "UserInputService", "ContextActionService",
	"GuiService", "CoreGui", "Debris", "Stats", "PlayerGui",
	-- Roblox Core Methods
	"GetService", "FindFirstChild", "FindFirstChildOfClass",
	"FindFirstChildWhichIsA", "WaitForChild", "GetChildren",
	"GetDescendants", "IsA", "Clone", "Destroy", "DestroyGui",
	"ClearAllChildren", "FindFirstAncestor", "FindFirstAncestorOfClass",
	"FindFirstAncestorWhichIsA", "GetPropertyChangedSignal",
	"Connect", "Disconnect", "Fire", "Wait", "GetFullName",
	"FireServer", "InvokeServer", "FireClient", "InvokeClient",
	"HttpGet", "HttpPost", "GetAsync", "PostAsync",
	"RequestAsync", "JSONDecode", "JSONEncode", "GenerateGUID",
	"GetPlayers", "GetUserThumbnailAsync", "GetUserIdFromNameAsync",
	"GetNameFromUserIdAsync", "IsFriendsWith", "IsInGroup",
	"GetRankInGroup", "GetRoleInGroup", "safeGetService",
	-- Common Roblox Object Properties
	"LocalPlayer", "Character", "Humanoid", "HumanoidRootPart",
	"Parent", "Name", "Value", "Position",
	"Size", "Transparency", "Anchored", "CanCollide",
	"Health", "MaxHealth", "WalkSpeed", "JumpPower",
	"JumpHeight", "DisplayName", "UserId",
	"ThumbnailType", "ThumbnailSize", "HeadShot",
	"OnClose", "Send",
	-- Executor APIs & Tooling Globals
	"queue_on_teleport", "identifyexecutor", "filtergc", "getupvalues",
	"Constants", "WebSocket", "readfile", "writefile", "delfile", "listfiles",
	"username", "robloxId", "avatarUrl", "scriptFile", "executor", "secretKey", "ping", "init",
	-- Core Luau Metamethods
	"__iter", "__call", "__index", "__newindex", "__mode", "__tostring", "__metatable"
}

StdApiNames.set = {}
for _, name in ipairs(StdApiNames.list) do
	StdApiNames.set[name] = true
end

function StdApiNames.computeHash(str, mult, mod, offset)
	mult = mult or 131
	mod = mod or 2147483647
	offset = offset or 5381
	local h = offset
	for i = 1, #str do
		h = (h * mult + string.byte(str, i)) % mod
	end
	return h
end

function StdApiNames.getCoeffs(baseSalt)
	baseSalt = baseSalt or 1337
	return {
		mult = 128 + (baseSalt % 64) * 2 + 1,
		offset = 5000 + (baseSalt * 37) % 2000,
		mod = 2147483647,
	}
end

return StdApiNames
