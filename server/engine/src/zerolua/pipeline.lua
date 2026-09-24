-- This Script is Part of the ZeroLua Obfuscator by levno-710
--
-- pipeline.lua
--
-- This Script provides a configurable obfuscation pipeline that can obfuscate code using different modules
-- These modules can simply be added to the pipeline.

local Enums = require("zerolua.enums");
local util = require("zerolua.util");
local Parser = require("zerolua.parser");
local Unparser = require("zerolua.unparser");
local logger = require("logger");

local NameGenerators = require("zerolua.namegenerators");
local RandomDomains = require("zerolua.random_domains");

local Steps = require("zerolua.steps");
local LuaVersion = Enums.LuaVersion;

-- On Windows, os.clock can be used. On other systems, os.time must be used for benchmarking.
local isWindows = package and package.config and type(package.config) == "string" and package.config:sub(1,1) == "\\";
local function gettime()
	if isWindows then
		return os.clock();
	else
		return os.time();
	end
end

local Pipeline = {
	NameGenerators = NameGenerators;
	Steps = Steps;
	DefaultSettings = {
		LuaVersion = LuaVersion.LuaU; -- The Lua Version to use for the Tokenizer, Parser and Unparser
		PrettyPrint = false; -- Note that Pretty Print is currently not producing Pretty results
		Seed = 0; -- The Seed. 0 or below uses the current time as a seed
		VarNamePrefix = ""; -- The Prefix that every variable will start with
	}
}


function Pipeline:new(settings)
	local luaVersion = settings.luaVersion or settings.LuaVersion or Pipeline.DefaultSettings.LuaVersion;
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion
			.. "\" is not recognized by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end

	local prettyPrint = settings.PrettyPrint or Pipeline.DefaultSettings.PrettyPrint;
	local prefix = settings.VarNamePrefix or Pipeline.DefaultSettings.VarNamePrefix;
	local seed = settings.Seed or 0;

	local pipeline = {
		LuaVersion = luaVersion;
		PrettyPrint = prettyPrint;
		VarNamePrefix = prefix;
		Seed = seed;
		parser = Parser:new({
			LuaVersion = luaVersion;
		});
		unparser = Unparser:new({
			LuaVersion = luaVersion;
			PrettyPrint = prettyPrint;
			Highlight = settings.Highlight;
		});
		namegenerator = Pipeline.NameGenerators.MangledShuffled;
		conventions = conventions;
		steps = {};
		guardAttestation = { providers = {} };
	}

	setmetatable(pipeline, self);
	self.__index = self;

	return pipeline;
end

function Pipeline:registerGuardAttestation(guardName, checkCodeGenerator, expectedTokenVal)
	self.guardAttestation = self.guardAttestation or { providers = {} }
	table.insert(self.guardAttestation.providers, {
		name = guardName,
		generator = checkCodeGenerator,
		expected = expectedTokenVal,
	})
end

function Pipeline:fromConfig(config)
	config = config or {};
	local pipeline = Pipeline:new({
		LuaVersion = config.LuaVersion or LuaVersion.Lua51;
		PrettyPrint = config.PrettyPrint or false;
		VarNamePrefix = config.VarNamePrefix or "";
		Seed = config.Seed or 0;
	});

	pipeline:setNameGenerator(config.NameGenerator or "MangledShuffled")

	-- Add all Steps defined in Config
	local steps = config.Steps or {};
	for i, step in ipairs(steps) do
		if type(step.Name) ~= "string" then
			logger:error("Step.Name must be a String");
		end
		local constructor = pipeline.Steps[step.Name];
		if not constructor then
			logger:error(string.format("The Step \"%s\" was not found!", step.Name));
		end
		pipeline:addStep(constructor:new(step.Settings or {}));
	end

	return pipeline;
end

function Pipeline:addStep(step)
	table.insert(self.steps, step);
end

function Pipeline:resetSteps(_)
	self.steps = {};
end

function Pipeline:getSteps()
	return self.steps;
end

function Pipeline:setOption(name, value)
	if Pipeline.DefaultSettings[name] ~= nil then
		self[name] = value;
		if name == "LuaVersion" then
			self:setLuaVersion(value);
		elseif name == "PrettyPrint" and self.unparser then
			self.unparser.PrettyPrint = value;
		end
	else
		logger:error(string.format("\"%s\" is not a valid setting", tostring(name)));
	end
end

function Pipeline:setLuaVersion(luaVersion)
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion
			.. "\" is not recognized by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end

	self.parser = Parser:new({
		luaVersion = luaVersion;
	});
	self.unparser = Unparser:new({
		LuaVersion = luaVersion;
	});
	self.conventions = conventions;
end

function Pipeline:getLuaVersion()
	return self.luaVersion;
end

function Pipeline:setNameGenerator(nameGenerator)
	if(type(nameGenerator) == "string") then
		nameGenerator = Pipeline.NameGenerators[nameGenerator];
	end

	if(type(nameGenerator) == "function" or type(nameGenerator) == "table") then
		self.namegenerator = nameGenerator;
		return;
	else
		logger:error("The Argument to Pipeline:setNameGenerator must be a valid NameGenerator function or function name e.g: \"mangled\"")
	end
end

function Pipeline:apply(code, filename)
	local startTime = gettime();
	filename = filename or "Anonymous Script";
	logger:info(string.format("Applying Security Pipeline to %s ...", filename));

	-- Seed the Random Generator
	if(self.Seed > 0) then
		math.randomseed(self.Seed);
		RandomDomains.init(self.Seed)
	else
		--> use secure random number generator
		local success, seed = pcall(function()
			local seedStr =  io.popen("openssl rand -hex 12"):read("*a"):gsub("\n", "")..""
			local seedNum = 0;

			--> NOTE: tonumber caps at 1.844674407371e+19. So we use this instead.
			for i = 1, #seedStr do
				local char = seedStr:sub(i, i):lower()
				local digit = char:match("%d") and (char:byte() - 48) or (char:byte() - 87)
				seedNum = seedNum * 16 + digit
			end

			--> Random Number Generator in Lua 5.1 is limited to 9.007199254741e+15.
			if _VERSION == "Lua 5.1" and not jit then
				seedNum = seedNum % 9.007199254741e+15
			end

			return seedNum
		end)

		if success and seed and seed > 0 then
			math.randomseed(seed)
			RandomDomains.init(seed)
		else
			local h = 2166136261
			local t1 = os.time() or 1337
			local t2 = math.floor(((os.clock and os.clock()) or 0) * 1000000)
			local ptr1 = tostring({})
			local ptr2 = tostring({})
			local combined = tostring(t1) .. ":" .. tostring(t2) .. ":" .. ptr1 .. ":" .. ptr2
			for i = 1, #combined do
				h = ((h * 16777619) + string.byte(combined, i) * 31 + (i * 17)) % 2147483647
			end
			if h <= 0 then h = 1 end
			math.randomseed(h)
			RandomDomains.init(h)
		end
	end

	logger:info("Parsing Abstract Syntax Tree ...");
	local parserStartTime = gettime();

	local sourceLen = string.len(code);
	local ast = self.parser:parse(code);

	local parserTimeDiff = gettime() - parserStartTime;
	logger:info(string.format("Parsing Complete in %.2f seconds", parserTimeDiff));

	-- Dynamically shuffle contiguous security guard steps to break static AST patterns per build
	local buildRng = RandomDomains.get("BUILD")
	local isGuard = {
		["Anti Hook"] = true,
		["Closure Integrity"] = true,
		["Anti Tamper"] = true,
		["Anti Proxy Probe"] = true,
		["Anti Timing"] = true,
		["Anti Offline Simulation"] = true,
	}
	local guardIndices = {}
	for i, step in ipairs(self.steps) do
		local sName = (step.class and step.class.Name) or step.Name or ""
		if isGuard[sName] then
			table.insert(guardIndices, i)
		end
	end
	if #guardIndices > 1 and buildRng and buildRng.shuffle then
		local guardSteps = {}
		for _, idx in ipairs(guardIndices) do
			table.insert(guardSteps, self.steps[idx])
		end
		buildRng:shuffle(guardSteps)
		for k, idx in ipairs(guardIndices) do
			self.steps[idx] = guardSteps[k]
		end
	end

	-- User Defined Steps
	for i, step in ipairs(self.steps) do
		local stepStartTime = gettime();
		logger:info(string.format("Applying Security Layer %d ...", i));
		local newAst = step:apply(ast, self);
		if type(newAst) == "table" then
			ast = newAst;
		end
		logger:info(string.format("Security Layer %d Verified in %.2f seconds", i, gettime() - stepStartTime));
	end

	-- Phase Boundary GC before Variable Renaming & Unparsing
	collectgarbage("step", 500);

	-- Rename Variables Step
	self:renameVariables(ast);

	code = self:unparse(ast);

	local timeDiff = gettime() - startTime;
	logger:info(string.format("Security Pipeline Complete in %.2f seconds", timeDiff));

	logger:info(string.format("Protected Payload size is %.2f%% of Source", (string.len(code) / sourceLen)*100))

	return code;
end

function Pipeline:unparse(ast)
	local startTime = gettime();
	logger:info("Synthesizing Virtual Machine Bytecode ...");

	local unparsed = self.unparser:unparse(ast);

	local timeDiff = gettime() - startTime;
	logger:info(string.format("Bytecode Synthesis Done in %.2f seconds", timeDiff));

	return unparsed;
end

function Pipeline:renameVariables(ast)
	local startTime = gettime();
	logger:info("Scrambling Symbol Registers ...");


	local generatorFunction = self.namegenerator or Pipeline.NameGenerators.mangled;
	if(type(generatorFunction) == "table") then
		if (type(generatorFunction.prepare) == "function") then
			generatorFunction.prepare(ast);
		end
		generatorFunction = generatorFunction.generateName;
	end

	if not self.unparser:isValidIdentifier(self.VarNamePrefix) and #self.VarNamePrefix ~= 0 then
		logger:error(string.format("The Prefix \"%s\" is not a valid Identifier in %s", self.VarNamePrefix, self.LuaVersion));
	end

	local globalScope = ast.globalScope;
	globalScope:renameVariables({
		Keywords = self.conventions.Keywords;
		generateName = generatorFunction;
		prefix = self.VarNamePrefix;
	});

	local timeDiff = gettime() - startTime;
	logger:info(string.format("Symbol Scrambling Complete in %.2f seconds", timeDiff));
end

return Pipeline;
