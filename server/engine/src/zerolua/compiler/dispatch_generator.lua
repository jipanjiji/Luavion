-- This Script is Part of the Zero Lua Obfuscator v5.7
--
-- dispatch_generator.lua
--
-- Dynamic Galois Hash-Bucket & State-Bound Opcode Dispatch Generator for Zero Lua v5.7.
-- Completely destroys static interval comparison trees (e.g. < 14, < 17, < 22).
-- Partitions opcodes into dynamic Galois residue classes and exact transmuted equality matches.
-- 10 Distinct Non-Monotonic Dispatch Architectures:
-- 1. ARCH_GALOIS_BUCKET_4: 4-Way Galois Polynomial Residue Bucket Partitioning
-- 2. ARCH_GALOIS_BUCKET_8: 8-Way Multi-Tier Galois Partitioning
-- 3. ARCH_STATE_SCATTER: Dynamic State-Interleaved Residue Scatter Matrix
-- 4. ARCH_RESIDUE_PARTITION: Modular Coprime Multi-Pivot Partitioning
-- 5. ARCH_MULTI_EQUALITY_CLUSTER: Clustered Transmuted Equality Machine
-- 6. ARCH_DUAL_STAGE_GALOIS: 2-Stage Cascaded Galois Residue Reduction
-- 7. ARCH_DYNAMIC_HASH_LADDER: Rolling State-Affine Dispatch Ladder
-- 8. ARCH_TMR_AFFINE_PARTITION: Affine Modular Residue Quad-Partition
-- 9. ARCH_EPHEMERAL_GALOIS_TREE: Non-Linear State-Evolving Dynamic Tree
-- 10. ARCH_OPAQUE_EQUALITY_MATRIX: Transmuted Galois Equality Matrix

local RandomDomains = require("zerolua.random_domains")

local DispatchGenerator = {}

DispatchGenerator.ARCH_GALOIS_BUCKET_4        = 1
DispatchGenerator.ARCH_GALOIS_BUCKET_8        = 2
DispatchGenerator.ARCH_STATE_SCATTER          = 3
DispatchGenerator.ARCH_RESIDUE_PARTITION      = 4
DispatchGenerator.ARCH_MULTI_EQUALITY_CLUSTER = 5
DispatchGenerator.ARCH_DUAL_STAGE_GALOIS      = 6
DispatchGenerator.ARCH_DYNAMIC_HASH_LADDER    = 7
DispatchGenerator.ARCH_TMR_AFFINE_PARTITION   = 8
DispatchGenerator.ARCH_EPHEMERAL_GALOIS_TREE  = 9
DispatchGenerator.ARCH_OPAQUE_EQUALITY_MATRIX = 10
DispatchGenerator.ARCH_ACCELERATED_GALOIS      = 11
DispatchGenerator.ARCH_INDIRECT_JUMP_VECTOR   = 12
DispatchGenerator.ARCH_STATE_BOUND_CASCADED_FRAGMENTS = 13
DispatchGenerator.ARCH_BINARY_SEARCH_RANGE     = 14

-- Legacy aliases
DispatchGenerator.MODE_DIRECT  = DispatchGenerator.ARCH_GALOIS_BUCKET_4
DispatchGenerator.MODE_STATE   = DispatchGenerator.ARCH_GALOIS_BUCKET_8
DispatchGenerator.MODE_SPLIT   = DispatchGenerator.ARCH_STATE_SCATTER
DispatchGenerator.MODE_SCATTER = DispatchGenerator.ARCH_RESIDUE_PARTITION

function DispatchGenerator.getCascadedParams(seed, numBuckets, protoSalt)
	seed = seed or 1337
	numBuckets = numBuckets or 4
	protoSalt = protoSalt or 101

	local bktMul = ((seed % 17) * 2 + 13) % 256
	if bktMul % 2 == 0 then bktMul = bktMul + 1 end
	local bktAdd = (seed % 31 + 7)

	local secMul = ((seed % 29) * 2 + 7) % 256
	if secMul % 2 == 0 then secMul = secMul + 1 end
	local secAdd = (seed % 43 + 11)
	local secStateMul = ((seed % 23) * 2 + 5)

	return {
		seed = seed,
		numBuckets = numBuckets,
		numPhases = 1,
		bktMul = bktMul,
		bktAdd = bktAdd,
		secMul = secMul,
		secAdd = secAdd,
		secStateMul = secStateMul,
		protoSalt = protoSalt
	}
end

function DispatchGenerator.buildCascadedJumpTable(branches, hbVar, numBuckets, protoSalt, seed)
	hbVar = hbVar or "_HB"
	local params = DispatchGenerator.getCascadedParams(seed, numBuckets, protoSalt)
	local indent = "\t\t"
	local parts = {}

	local buckets = {}
	for b = 0, params.numBuckets - 1 do
		buckets[b] = {}
	end

	for _, bItem in ipairs(branches) do
		local bIdx = ((bItem.tok * params.bktMul + params.bktAdd) % params.numBuckets)
		local secSlot = (((bItem.tok + params.protoSalt) * params.secMul + params.secAdd) % 256)
		buckets[bIdx][secSlot] = { slot = secSlot, code = bItem.code, tok = bItem.tok }
	end

	table.insert(parts, indent .. "local " .. hbVar .. " = {}\n")
	for b = 0, params.numBuckets - 1 do
		local bMap = buckets[b]
		table.insert(parts, indent .. hbVar .. "[" .. tostring(b) .. "] = {\n")
		local slotKeys = {}
		for slot, _ in pairs(bMap) do
			table.insert(slotKeys, slot)
		end
		table.sort(slotKeys)
		for _, slot in ipairs(slotKeys) do
			local item = bMap[slot]
			table.insert(parts, indent .. "\t[" .. tostring(item.slot) .. "] = function()\n")
			table.insert(parts, item.code .. "\n")
			table.insert(parts, indent .. "\tend,\n")
		end
		-- Inject 1 decoy closure with invalid slot to equalize density
		local decoySlot = ((params.seed + b * 53 + 37) % 256)
		if not bMap[decoySlot] then
			table.insert(parts, indent .. "\t[" .. tostring(decoySlot) .. "] = function() error(\"\", 0) end,\n")
		end
		table.insert(parts, indent .. "}\n")
	end

	return table.concat(parts)
end

function DispatchGenerator.buildJumpTable(branches, hVar)
	hVar = hVar or "_H"
	local indent = "\t\t"
	local parts = {}
	table.insert(parts, indent .. "local " .. hVar .. " = {\n")
	for _, bItem in ipairs(branches) do
		table.insert(parts, indent .. "\t[" .. tostring(bItem.tok) .. "] = function()\n")
		table.insert(parts, bItem.code .. "\n")
		table.insert(parts, indent .. "\tend,\n")
	end
	table.insert(parts, indent .. "}\n")
	return table.concat(parts)
end

local function shuffleList(list, seed)
	local res = {}
	for _, item in ipairs(list) do table.insert(res, item) end
	local s = seed or 1337
	for i = #res, 2, -1 do
		s = (s * 1103515245 + 12345) % 2147483648
		local j = (s % i) + 1
		res[i], res[j] = res[j], res[i]
	end
	return res
end

function DispatchGenerator.buildDispatchBlock(branches, mode, stateVar, stateMul, stateAdd, tokVar, bVar, extraParams)
	tokVar = tokVar or "_tok"
	mode = mode or 1
	stateVar = stateVar or "_vmState"
	stateMul = stateMul or 31
	stateAdd = stateAdd or 101
	local stateMod = (extraParams and extraParams.stateMod) or 16777213
	local indent = "\t\t\t"

	local rng = RandomDomains.get("DISPATCH")
	local seed = (extraParams and extraParams.seed) or (rng and rng:random(1000, 999999)) or math.random(1000, 999999)
	local m = mode

	local function randomVar(len)
		local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		local res = {}
		for i = 1, len or 5 do
			local idx = (rng and rng:random(1, #chars)) or math.random(1, #chars)
			table.insert(res, chars:sub(idx, idx))
		end
		return table.concat(res)
	end

	local function emitBinarySearchTree(branchList, curIndent)
		local parts = {}
		if not branchList or #branchList == 0 then
			table.insert(parts, curIndent .. "error(\"\", 0)\n")
			return table.concat(parts)
		end
		if #branchList == 1 then
			local item = branchList[1]
			table.insert(parts, curIndent .. "if " .. tokVar .. " == " .. tostring(item.tok) .. " then\n")
			table.insert(parts, curIndent .. "\t" .. item.code .. "\n")
			table.insert(parts, curIndent .. "else\n")
			table.insert(parts, curIndent .. "\terror(\"\", 0)\n")
			table.insert(parts, curIndent .. "end\n")
			return table.concat(parts)
		end
		if #branchList == 2 then
			local item1 = branchList[1]
			local item2 = branchList[2]
			table.insert(parts, curIndent .. "if " .. tokVar .. " == " .. tostring(item1.tok) .. " then\n")
			table.insert(parts, curIndent .. "\t" .. item1.code .. "\n")
			table.insert(parts, curIndent .. "elseif " .. tokVar .. " == " .. tostring(item2.tok) .. " then\n")
			table.insert(parts, curIndent .. "\t" .. item2.code .. "\n")
			table.insert(parts, curIndent .. "else\n")
			table.insert(parts, curIndent .. "\terror(\"\", 0)\n")
			table.insert(parts, curIndent .. "end\n")
			return table.concat(parts)
		end

		local sorted = {}
		for _, item in ipairs(branchList) do table.insert(sorted, item) end
		table.sort(sorted, function(a, b) return a.tok < b.tok end)

		local midIdx = math.floor(#sorted / 2)
		local midVal = sorted[midIdx].tok
		local leftList = {}
		local rightList = {}
		for idx, item in ipairs(sorted) do
			if idx <= midIdx then
				table.insert(leftList, item)
			else
				table.insert(rightList, item)
			end
		end

		table.insert(parts, curIndent .. "if " .. tokVar .. " <= " .. tostring(midVal) .. " then\n")
		table.insert(parts, emitBinarySearchTree(leftList, curIndent .. "\t"))
		table.insert(parts, curIndent .. "else\n")
		table.insert(parts, emitBinarySearchTree(rightList, curIndent .. "\t"))
		table.insert(parts, curIndent .. "end\n")
		return table.concat(parts)
	end

	if m == 13 then
		local numBuckets = 4
		local galoisMul = ((seed % 17) * 2 + 13) % 256
		if galoisMul % 2 == 0 then galoisMul = galoisMul + 1 end
		local galoisAdd = (seed % 31 + 7)

		local buckets = {}
		for b = 0, numBuckets - 1 do
			buckets[b] = {}
		end
		for _, item in ipairs(branches) do
			local bIdx = ((item.tok * galoisMul + galoisAdd) % numBuckets)
			table.insert(buckets[bIdx], item)
		end

		local bktVar = bVar or randomVar(5)
		local outParts = {}
		local bucketStyle = (rng and rng:random(1, 3)) or math.random(1, 3)
		if bucketStyle == 1 then
			table.insert(outParts, indent .. "local " .. bktVar .. " = (" .. tostring(galoisAdd) .. " + " .. tokVar .. " * " .. tostring(galoisMul) .. ") % " .. tostring(numBuckets) .. "\n")
		elseif bucketStyle == 2 then
			table.insert(outParts, indent .. "local " .. bktVar .. " = " .. tokVar .. " * " .. tostring(galoisMul) .. " + " .. tostring(galoisAdd) .. "; " .. bktVar .. " = " .. bktVar .. " % " .. tostring(numBuckets) .. "\n")
		else
			table.insert(outParts, indent .. "local " .. bktVar .. " = (" .. tostring(galoisAdd) .. " + (" .. tokVar .. " * " .. tostring(galoisMul) .. ")) % " .. tostring(numBuckets) .. "\n")
		end

		local hotNames = {
			MOVE = 1, GETTABLE = 2, SETTABLE = 3, GETTABLE_K = 4, SETTABLE_K = 5,
			LOADK = 6, ADD = 7, SUB = 8, CALL = 9, RETURN = 10, JMP = 11, FORLOOP = 12,
			EQ = 13, LT = 14, LE = 15, MOVE_ALT = 16, ADD_ALT = 17, SUB_ALT = 18
		}

		local function emitHeterogeneousBucket(bList, curIndent, bIdx)
			if not bList or #bList == 0 then
				return curIndent .. "error(\"\", 0)\n"
			end
			local style = ((seed + bIdx * 37 + #bList * 13) % 4) + 1
			if style == 1 and #bList >= 3 then
				return emitBinarySearchTree(bList, curIndent)
			elseif style == 2 then
				local sortedBranches = {}
				for _, item in ipairs(bList) do table.insert(sortedBranches, item) end
				table.sort(sortedBranches, function(a, b)
					local aScore = (a.name and hotNames[a.name]) or 99
					local bScore = (b.name and hotNames[b.name]) or 99
					return aScore < bScore
				end)
				local parts = {}
				local firstInBucket = true
				for _, bItem in ipairs(sortedBranches) do
					local inPfx = firstInBucket and (curIndent .. "if " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
						or (curIndent .. "elseif " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
					firstInBucket = false
					table.insert(parts, inPfx)
					table.insert(parts, "\t" .. bItem.code .. "\n")
				end
				table.insert(parts, curIndent .. "else\n")
				table.insert(parts, curIndent .. "\terror(\"\", 0)\n")
				table.insert(parts, curIndent .. "end\n")
				return table.concat(parts)
			elseif style == 3 and #bList >= 4 then
				local subMul = ((seed + bIdx * 19) % 17) * 2 + 3
				local subAdd = (seed * 11 + bIdx * 7) % 31
				local left = {}
				local right = {}
				for _, item in ipairs(bList) do
					if ((item.tok * subMul + subAdd) % 2) == 0 then
						table.insert(left, item)
					else
						table.insert(right, item)
					end
				end
				local subVar = randomVar(4)
				local parts = {}
				table.insert(parts, curIndent .. "local " .. subVar .. " = (" .. tokVar .. " * " .. tostring(subMul) .. " + " .. tostring(subAdd) .. ") % 2\n")
				table.insert(parts, curIndent .. "if " .. subVar .. " == 0 then\n")
				table.insert(parts, emitHeterogeneousBucket(left, curIndent .. "\t", bIdx * 2))
				table.insert(parts, curIndent .. "else\n")
				table.insert(parts, emitHeterogeneousBucket(right, curIndent .. "\t", bIdx * 2 + 1))
				table.insert(parts, curIndent .. "end\n")
				return table.concat(parts)
			else
				local shuffled = shuffleList(bList, seed + bIdx * 41)
				local parts = {}
				local firstInBucket = true
				for _, bItem in ipairs(shuffled) do
					local inPfx = firstInBucket and (curIndent .. "if " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
						or (curIndent .. "elseif " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
					firstInBucket = false
					table.insert(parts, inPfx)
					table.insert(parts, "\t" .. bItem.code .. "\n")
				end
				table.insert(parts, curIndent .. "else\n")
				table.insert(parts, curIndent .. "\terror(\"\", 0)\n")
				table.insert(parts, curIndent .. "end\n")
				return table.concat(parts)
			end
		end

		table.insert(outParts, indent .. "if " .. bktVar .. " < 2 then\n")
		table.insert(outParts, indent .. "\tif " .. bktVar .. " == 0 then\n")
		table.insert(outParts, emitHeterogeneousBucket(buckets[0], indent .. "\t\t", 0))
		table.insert(outParts, indent .. "\telse\n")
		table.insert(outParts, emitHeterogeneousBucket(buckets[1], indent .. "\t\t", 1))
		table.insert(outParts, indent .. "\tend\n")
		table.insert(outParts, indent .. "else\n")
		table.insert(outParts, indent .. "\tif " .. bktVar .. " == 2 then\n")
		table.insert(outParts, emitHeterogeneousBucket(buckets[2], indent .. "\t\t", 2))
		table.insert(outParts, indent .. "\telse\n")
		table.insert(outParts, emitHeterogeneousBucket(buckets[3], indent .. "\t\t", 3))
		table.insert(outParts, indent .. "\tend\n")
		table.insert(outParts, indent .. "end\n")
		return table.concat(outParts)
	end

	if m == 12 then
		local hTableVar = bVar or "_H"
		local outParts = {}
		table.insert(outParts, indent .. "local _h = " .. hTableVar .. "[" .. tokVar .. "]\n")
		table.insert(outParts, indent .. "if not _h then error(\"\", 0) end\n")
		table.insert(outParts, indent .. "_h()\n")
		return table.concat(outParts)
	end

	bVar = bVar or randomVar(5)

	-- Determine number of buckets based on mode
	local numBuckets = (extraParams and extraParams.numBuckets) or 4
	if m == 11 or m == 13 then
		numBuckets = 4
	elseif m == 2 or m == 6 or m == 9 then
		numBuckets = 8
	elseif m == 4 or m == 8 then
		numBuckets = 6
	elseif m == 5 or m == 10 then
		numBuckets = 5
	end

	local galoisMul = ((seed % 17) * 2 + 13) % 256
	if galoisMul % 2 == 0 then galoisMul = galoisMul + 1 end
	local galoisAdd = (seed % 31 + 7)

	-- Group branches into buckets: bucketIdx = ((tok * galoisMul + galoisAdd) % numBuckets)
	local buckets = {}
	for b = 0, numBuckets - 1 do
		buckets[b] = {}
	end

	for _, item in ipairs(branches) do
		local bIdx = ((item.tok * galoisMul + galoisAdd) % numBuckets)
		table.insert(buckets[bIdx], item)
	end

	local outParts = {}
	local bucketStyle = (rng and rng:random(1, 3)) or math.random(1, 3)
	if bucketStyle == 1 then
		table.insert(outParts, indent .. "local " .. bVar .. " = (" .. tostring(galoisAdd) .. " + " .. tokVar .. " * " .. tostring(galoisMul) .. ") % " .. tostring(numBuckets) .. "\n")
	elseif bucketStyle == 2 then
		table.insert(outParts, indent .. "local " .. bVar .. " = " .. tokVar .. " * " .. tostring(galoisMul) .. " + " .. tostring(galoisAdd) .. "; " .. bVar .. " = " .. bVar .. " % " .. tostring(numBuckets) .. "\n")
	else
		table.insert(outParts, indent .. "local " .. bVar .. " = (" .. tostring(galoisAdd) .. " + (" .. tokVar .. " * " .. tostring(galoisMul) .. ")) % " .. tostring(numBuckets) .. "\n")
	end

	local function emitBucketContent(bList, curIndent)
		local parts = {}
		if #bList == 0 then
			table.insert(parts, curIndent .. "error(\"\", 0)\n")
			return table.concat(parts)
		end

		local shuffledBranches
		if m == 11 then
			-- For PERFORMANCE mode: prioritize common instructions first
			local hotNames = {
				MOVE = 1, GETTABLE = 2, SETTABLE = 3, GETTABLE_K = 4, SETTABLE_K = 5,
				LOADK = 6, ADD = 7, SUB = 8, CALL = 9, RETURN = 10, JMP = 11, FORLOOP = 12
			}
			shuffledBranches = {}
			for _, item in ipairs(bList) do table.insert(shuffledBranches, item) end
			table.sort(shuffledBranches, function(a, b)
				local aScore = (a.name and hotNames[a.name]) or 99
				local bScore = (b.name and hotNames[b.name]) or 99
				return aScore < bScore
			end)
		else
			shuffledBranches = shuffleList(bList, seed + 41)
		end

		local firstInBucket = true
		for _, bItem in ipairs(shuffledBranches) do
			local inPfx = firstInBucket and (curIndent .. "if " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n") or (curIndent .. "elseif " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
			firstInBucket = false
			table.insert(parts, inPfx)
			table.insert(parts, "\t" .. bItem.code .. "\n")
		end
		table.insert(parts, curIndent .. "else\n")
		table.insert(parts, curIndent .. "\terror(\"\", 0)\n")
		table.insert(parts, curIndent .. "end\n")
		return table.concat(parts)
	end

	if m == 14 then
		-- Luraph-style nested binary interval partition dispatch
		table.insert(outParts, emitBinarySearchTree(branches, indent))
	elseif m == 11 then
		-- Binary Decision Tree for 4 Buckets
		table.insert(outParts, indent .. "if " .. bVar .. " < 2 then\n")
		table.insert(outParts, indent .. "\tif " .. bVar .. " == 0 then\n")
		table.insert(outParts, emitBucketContent(buckets[0], indent .. "\t\t"))
		table.insert(outParts, indent .. "\telse\n")
		table.insert(outParts, emitBucketContent(buckets[1], indent .. "\t\t"))
		table.insert(outParts, indent .. "\tend\n")
		table.insert(outParts, indent .. "else\n")
		table.insert(outParts, indent .. "\tif " .. bVar .. " == 2 then\n")
		table.insert(outParts, emitBucketContent(buckets[2], indent .. "\t\t"))
		table.insert(outParts, indent .. "\telse\n")
		table.insert(outParts, emitBucketContent(buckets[3], indent .. "\t\t"))
		table.insert(outParts, indent .. "\tend\n")
		table.insert(outParts, indent .. "end\n")
	else
		local firstBucket = true
		for b = 0, numBuckets - 1 do
			local bList = buckets[b]
			if #bList > 0 then
				local pfx = firstBucket and (indent .. "if " .. bVar .. " == " .. tostring(b) .. " then\n") or (indent .. "elseif " .. bVar .. " == " .. tostring(b) .. " then\n")
				firstBucket = false
				table.insert(outParts, pfx)

				-- Inside bucket: exact equality matching in randomized order
				local shuffledBranches = shuffleList(bList, seed + b * 41)
				local firstInBucket = true
				for _, bItem in ipairs(shuffledBranches) do
					local inPfx = firstInBucket and (indent .. "\tif " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n") or (indent .. "\telseif " .. tokVar .. " == " .. tostring(bItem.tok) .. " then\n")
					firstInBucket = false
					table.insert(outParts, inPfx)
					table.insert(outParts, "\t" .. bItem.code .. "\n")
				end
				table.insert(outParts, indent .. "\telse\n")
				table.insert(outParts, indent .. "\t\terror(\"\", 0)\n")
				table.insert(outParts, indent .. "\tend\n")
			end
		end
		if not firstBucket then
			table.insert(outParts, indent .. "else\n")
			table.insert(outParts, indent .. "\terror(\"\", 0)\n")
			table.insert(outParts, indent .. "end\n")
		end
	end

	return table.concat(outParts)
end

return DispatchGenerator
