<template>
  <div class="studio-page">
    <div class="container studio-container">
      <!-- Studio Header / Config Toolbar -->
      <div class="surface studio-toolbar">
        <div class="toolbar-section toolbar-presets">
          <div class="toolbar-label-group">
            <span class="toolbar-label">SECURITY PRESET</span>
            <span class="preset-meta-info" v-if="activePresetObj">
              {{ activePresetObj.security }} Tier • {{ activePresetObj.vmProfile }} VM
            </span>
          </div>

          <div class="preset-pills-row">
            <button 
              v-for="p in presets" 
              :key="p.id"
              class="preset-pill-btn"
              :class="{ 
                'active': selectedPreset === p.id,
                'locked': isPresetLocked(p.id)
              }"
              @click="handleSelectPreset(p)"
              :title="isPresetLocked(p.id) ? `Locked on ${userPlan.toUpperCase()} plan. Click to unlock.` : p.desc"
            >
              <span class="pill-name">
                <svg v-if="isPresetLocked(p.id)" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="lock-icon">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                  <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                </svg>
                {{ p.name }}
              </span>
              <span v-if="p.badge" class="pill-sub" :class="p.id === 'BALANCED' ? 'sub-cyan' : isPresetLocked(p.id) ? 'sub-amber' : 'sub-muted'">
                {{ isPresetLocked(p.id) ? 'Locked' : p.badge }}
              </span>
            </button>
          </div>
        </div>

        <div class="toolbar-divider"></div>

        <div class="toolbar-section toolbar-options">
          <!-- Target VM Switcher -->
          <div class="config-group">
            <span class="toolbar-label">TARGET RUNTIME</span>
            <div class="segmented-control">
              <button 
                class="seg-btn" 
                :class="{ 'active': luaVersion === 'LuaU' }"
                @click="luaVersion = 'LuaU'"
              >
                Luau
              </button>
              <button 
                class="seg-btn" 
                :class="{ 'active': luaVersion === 'Lua51' }"
                @click="luaVersion = 'Lua51'"
              >
                Lua 5.1
              </button>
            </div>
          </div>

          <!-- Stegano AI Prompt Shield Status -->
          <div class="config-group">
            <span class="toolbar-label">AI PROMPT SHIELD</span>
            <div class="shield-indicator" title="Zero-width unicode directives prevent automated LLM deobfuscation">
              <span class="status-dot dot-emerald"></span>
              <span class="shield-label">STEGANO ON</span>
            </div>
          </div>

          <!-- Watermark Banner Switch -->
          <div class="config-group">
            <span class="toolbar-label">WATERMARK</span>
            <div class="watermark-tag" title="PRD 6.1: Official watermark comment is embedded in all outputs">
              <span class="status-dot dot-cyan"></span>
              <span>INCLUDED</span>
            </div>
          </div>

          <!-- Batch Obfuscator Modal Trigger -->
          <div class="config-group">
            <span class="toolbar-label">BATCH</span>
            <button 
              class="btn-batch-trigger"
              :class="{ 'batch-locked': !hasBatchAccess }"
              @click="handleOpenBatch"
              :title="hasBatchAccess ? `Batch compile up to ${userPlan === 'ultra' ? '100' : '10'} files` : 'Batch compilation requires Pro or Ultra'"
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
                <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path>
              </svg>
              <span>Batch ({{ userPlan === 'ultra' ? '100x' : userPlan === 'pro' ? '10x' : 'Pro' }})</span>
              <svg v-if="!hasBatchAccess" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
              </svg>
            </button>
          </div>

          <!-- Custom Presets Trigger -->
          <div class="config-group">
            <span class="toolbar-label">SAVED PRESETS</span>
            <button 
              class="btn-batch-trigger"
              @click="handleOpenCustomPresets"
              title="Manage custom configurations"
            >
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
              </svg>
              <span>Presets</span>
            </button>
          </div>

          <!-- Deterministic Seed with Auto-Refresh -->
          <div class="config-group">
            <div class="seed-label-row">
              <span class="toolbar-label">SEED</span>
              <span v-if="seedJustRefreshed" class="seed-refreshed-badge">Refreshed!</span>
            </div>
            <div class="seed-control" :class="{ 'refreshed-glow': seedJustRefreshed }">
              <input 
                type="number" 
                v-model.number="seed" 
                class="seed-input" 
                placeholder="Random"
                title="Compilation entropy seed"
              />
              <button 
                class="seed-refresh-btn" 
                @click="randomizeSeedManual" 
                title="Randomize compiler seed"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Syntax Diagnostic / Error Banner -->
      <SyntaxErrorBanner 
        v-if="syntaxError || errorMessage"
        :syntax-error="syntaxError"
        :error-message="errorMessage"
        @close="clearError"
      />

      <!-- Quota / File Size Warning Banner -->
      <div v-if="isFileSizeExceeded" class="file-size-warning surface-raised">
        <span class="warn-icon">⚠️</span>
        <span class="warn-msg">
          Current script size ({{ (inputByteCount / 1024).toFixed(1) }} KB) exceeds your {{ userPlan.toUpperCase() }} plan limit of {{ userPlanConfig.maxFileSizeLabel }}.
        </span>
        <button class="btn btn-accent btn-xs" @click="promptUpgrade('pro', 'Upgrade to increase your maximum file size up to 1 MB (Pro) or 5 MB (Ultra).')">
          Upgrade Capacity
        </button>
      </div>

      <!-- Dual Pane Studio Workspace -->
      <div class="editor-workspace">
        <!-- Left Pane: Source Input -->
        <div 
          class="surface editor-card"
          :class="{ 'drag-over': isDragging }"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="handleFileDrop"
        >
          <div class="pane-header">
            <div class="pane-meta">
              <div class="pane-title-badge">
                <span class="status-dot dot-amber"></span>
                <span class="pane-name">INPUT SOURCE</span>
              </div>
              <span class="telemetry-tag" :class="{ 'tag-warn': isFileSizeExceeded }">
                {{ inputLineCount }} lines • {{ inputByteCount }} bytes 
                <span v-if="isFileSizeExceeded"> (Exceeds {{ userPlanConfig.maxFileSizeLabel }})</span>
              </span>
            </div>

            <div class="pane-controls">
              <button class="btn btn-ghost btn-sm" @click="loadSampleScript" title="Load sample script">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                  <polyline points="14 2 14 8 20 8"></polyline>
                </svg>
                <span>Sample</span>
              </button>

              <label class="btn btn-ghost btn-sm file-label" title="Upload .lua or .luau file">
                <input type="file" accept=".lua,.luau,.txt" @change="handleFileSelect" hidden />
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="17 8 12 3 7 8"></polyline>
                  <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                <span>Upload</span>
              </label>

              <button class="btn btn-ghost btn-sm" @click="clearInput" :disabled="!sourceCode" title="Clear input">
                <span>Clear</span>
              </button>
            </div>
          </div>

          <!-- Code Input Area -->
          <div class="editor-body">
            <textarea
              v-model="sourceCode"
              class="code-textarea"
              placeholder="-- Paste or write your Luau / Lua 5.1 script here...&#10;-- Or drag & drop a .lua / .luau file directly into this workspace."
              spellcheck="false"
            ></textarea>

            <!-- Drag & Drop Zone Overlay -->
            <div v-if="isDragging" class="drag-drop-overlay">
              <div class="drag-drop-card surface">
                <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" color="#00f0ff">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="17 8 12 3 7 8"></polyline>
                  <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                <span class="drop-text">Drop .lua or .luau file here to load</span>
              </div>
            </div>
          </div>

          <!-- Action Footer -->
          <div class="pane-footer">
            <button 
              class="btn btn-accent btn-obfuscate" 
              :disabled="!sourceCode.trim() || isObfuscating || isFileSizeExceeded"
              @click="runObfuscation"
            >
              <template v-if="isObfuscating">
                <span class="spinner"></span>
                <span>Compiling VM ({{ elapsedTime }}s)...</span>
              </template>
              <template v-else>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
                </svg>
                <span>Obfuscate Script</span>
              </template>
            </button>
          </div>
        </div>

        <!-- Right Pane: Protected Output -->
        <div 
          class="surface editor-card"
          :class="{ 'compiling-active': isObfuscating }"
        >
          <div class="pane-header">
            <div class="pane-meta">
              <div class="pane-title-badge">
                <span class="status-dot dot-cyan"></span>
                <span class="pane-name">VIRTUALIZED PAYLOAD</span>
              </div>
              <span v-if="outputCode" class="telemetry-tag">
                {{ outputLineCount }} lines • {{ outputByteCount }} bytes
                <span v-if="executionStats"> • {{ executionStats.durationMs }}ms</span>
              </span>
              <span v-else class="telemetry-tag text-muted">Awaiting compiler job</span>
            </div>

            <div class="pane-controls" v-if="outputCode">
              <button class="btn btn-ghost btn-sm" @click="copyOutput" title="Copy code to clipboard">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                </svg>
                <span>{{ copied ? 'Copied!' : 'Copy' }}</span>
              </button>

              <button class="btn btn-ghost btn-sm" @click="downloadOutput" title="Download protected file">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="7 10 12 15 17 10"></polyline>
                  <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                <span>Download</span>
              </button>
            </div>
          </div>

          <!-- Code Output Area -->
          <div class="editor-body">
            <!-- Active Compilation Progress Overlay -->
            <div v-if="isObfuscating" class="compiling-overlay">
              <div class="compiling-box surface">
                <div class="compiling-spinner-ring"></div>
                <span class="compiling-title">Synthesizing Galois Register VM</span>
                <span class="compiling-step-sub">{{ activeCompilationStep }}</span>
                <div class="compiling-bar-track">
                  <div class="compiling-bar-pulse"></div>
                </div>
              </div>
            </div>

            <textarea
              v-model="outputCode"
              class="code-textarea output-textarea"
              placeholder="-- The virtualized bytecode payload will appear here after obfuscation..."
              readonly
              spellcheck="false"
            ></textarea>
          </div>

          <!-- Output Telemetry Footer -->
          <div class="pane-footer output-footer">
            <div class="footer-telemetry" v-if="executionStats">
              <div class="telemetry-chip">
                <span class="chip-label">EXPANSION</span>
                <span class="chip-val">{{ executionStats.expansionRatio }}x</span>
              </div>
              <div class="telemetry-chip">
                <span class="chip-label">LATENCY</span>
                <span class="chip-val">{{ executionStats.durationMs }}ms</span>
              </div>
              <div class="telemetry-chip">
                <span class="chip-label">SEED</span>
                <span class="chip-val">{{ executionStats.seed }}</span>
              </div>
            </div>
            <div v-else class="footer-telemetry-placeholder">
              <span>Ready for compilation</span>
            </div>

            <button 
              v-if="pipelineLogs.length" 
              class="btn btn-ghost btn-xs logs-toggle"
              @click="showLogs = !showLogs"
            >
              <span>{{ showLogs ? 'Hide Logs' : `Logs (${pipelineLogs.length})` }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Pipeline Logs Drawer -->
      <div v-if="showLogs && pipelineLogs.length" class="surface logs-drawer">
        <div class="logs-header">
          <span class="logs-title">COMPILER PIPELINE EXECUTION LOGS</span>
          <button class="btn btn-ghost btn-xs" @click="showLogs = false">Close</button>
        </div>
        <div class="logs-body">
          <div 
            v-for="(log, i) in pipelineLogs" 
            :key="i"
            class="log-line"
            :class="`log-${log.level || 'info'}`"
          >
            <span class="log-level">[{{ (log.level || 'info').toUpperCase() }}]</span>
            <span class="log-msg">{{ log.message }}</span>
          </div>
        </div>
      </div>

      <!-- Batch Obfuscator Modal Component -->
      <BatchObfuscatorModal v-model="showBatchModal" />

      <!-- Custom Presets Modal Component -->
      <CustomPresetModal 
        v-model="showCustomPresetsModal"
        :current-settings="{
          preset: selectedPreset,
          luaVersion,
          includeBanner
        }"
        @apply="onApplyCustomPreset"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'

const { user, promptUpgrade, showToast } = useUser()
const { getPlan } = usePlans()

const userPlan = computed(() => user.value?.plan || 'free')
const userPlanConfig = computed(() => getPlan(userPlan.value))

const sourceCode = ref('')
const outputCode = ref('')
const selectedPreset = ref('BALANCED')
const luaVersion = ref('LuaU')
const seed = ref(Math.floor(Math.random() * 9000000) + 100000)
const includeBanner = ref(true)

const isObfuscating = ref(false)
const elapsedTime = ref(0)
let timerId = null

const errorMessage = ref('')
const syntaxError = ref(null)
const executionStats = ref(null)
const pipelineLogs = ref([])
const showLogs = ref(false)

const isDragging = ref(false)
const copied = ref(false)
const seedJustRefreshed = ref(false)

const showBatchModal = ref(false)
const showCustomPresetsModal = ref(false)
const activeCompilationStep = ref('Parsing Abstract Syntax Tree...')

const presets = [
  { 
    id: 'BALANCED', 
    name: 'Balanced', 
    badge: 'Recommended', 
    security: 'High',
    vmProfile: 'STRONG',
    minPlan: 'free',
    desc: 'Strong Register VM with Roblox geometric math attestation & MBA expressions.' 
  },
  { 
    id: 'EXTREME', 
    name: 'Extreme', 
    badge: 'Max Defense', 
    security: 'Military-Grade',
    vmProfile: 'EXTREME',
    minPlan: 'pro',
    desc: 'Dynamic Galois opcode dispatching, dead code injection & strict float verification.' 
  },
  { 
    id: 'HARD', 
    name: 'Hard', 
    badge: 'Anti-Tamper', 
    security: 'Very High',
    vmProfile: 'HARD',
    minPlan: 'plus',
    desc: 'API reflection hashing, anti-proxy probes, and hardened register VM.' 
  },
  { 
    id: 'PERFORMANCE', 
    name: 'Performance', 
    badge: 'High FPS', 
    security: 'Standard',
    vmProfile: 'PERFORMANCE',
    minPlan: 'free',
    desc: 'Low overhead for high-frequency physics/render loops.' 
  },
  { 
    id: 'COMPATIBLE', 
    name: 'Compatible', 
    badge: 'Universal', 
    security: 'Safe',
    vmProfile: 'SAFE',
    minPlan: 'free',
    desc: 'Broadest compatibility across legacy Lua 5.1 and all executors.' 
  },
  { 
    id: 'MINIFY', 
    name: 'Minify', 
    badge: 'Raw AST', 
    security: 'None',
    vmProfile: 'NONE',
    minPlan: 'free',
    desc: 'Compression and variable mangling only, without virtualization.' 
  }
]

const activePresetObj = computed(() => presets.find(p => p.id === selectedPreset.value))

const inputLineCount = computed(() => sourceCode.value ? sourceCode.value.split('\n').length : 0)
const inputByteCount = computed(() => new TextEncoder().encode(sourceCode.value).length)

const outputLineCount = computed(() => outputCode.value ? outputCode.value.split('\n').length : 0)
const outputByteCount = computed(() => new TextEncoder().encode(outputCode.value).length)

const isPresetLocked = (presetId) => {
  if (userPlan.value === 'ultra' || userPlan.value === 'pro') return false
  if (userPlan.value === 'plus') return presetId === 'EXTREME'
  // Free tier
  return presetId === 'HARD' || presetId === 'EXTREME'
}

const hasBatchAccess = computed(() => {
  return userPlan.value === 'pro' || userPlan.value === 'ultra'
})

const isFileSizeExceeded = computed(() => {
  return inputByteCount.value > userPlanConfig.value.maxFileSizeBytes
})

const handleSelectPreset = (p) => {
  if (isPresetLocked(p.id)) {
    const requiredTier = p.minPlan || 'pro'
    promptUpgrade(requiredTier, `The '${p.name}' preset requires a ${requiredTier.toUpperCase()} subscription. Upgrade to unlock ${p.desc}`)
    return
  }
  selectedPreset.value = p.id
}

const handleOpenBatch = () => {
  if (!hasBatchAccess.value) {
    promptUpgrade('pro', 'Batch obfuscation (up to 10 files on Pro, 100 on Ultra) is a Pro/Ultra exclusive feature. Upgrade to compile entire project folders at once.')
    return
  }
  showBatchModal.value = true
}

const handleOpenCustomPresets = () => {
  if (userPlan.value === 'free' || userPlan.value === 'plus') {
    promptUpgrade('pro', 'Saving and reusing custom compiler configurations is available on Pro (up to 3 presets) and Ultra (unlimited).')
    return
  }
  showCustomPresetsModal.value = true
}

const onApplyCustomPreset = (p) => {
  selectedPreset.value = p.base_preset || 'BALANCED'
  luaVersion.value = p.lua_version || 'LuaU'
  includeBanner.value = p.include_banner !== false
}

const randomizeSeed = () => {
  seed.value = Math.floor(Math.random() * 9000000) + 100000
  seedJustRefreshed.value = true
  setTimeout(() => { seedJustRefreshed.value = false }, 1800)
}

const randomizeSeedManual = () => {
  randomizeSeed()
  showToast('Seed randomized')
}

const clearError = () => {
  errorMessage.value = ''
  syntaxError.value = null
}

const clearInput = () => {
  sourceCode.value = ''
  errorMessage.value = ''
  syntaxError.value = null
}

const loadSampleScript = () => {
  sourceCode.value = `-- Luavion Sample: Combat Autofarm Controller & Auth Hub
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Config = {
    TargetGroup = "Enemies",
    AttackDistance = 14.5,
    AutoHealThreshold = 45,
    AuthKey = "LUAVION_SAMPLE_KEY_2026"
}

local function verifyLicense(key)
    if key == Config.AuthKey then
        print("[Luavion] Authentication successful for " .. LocalPlayer.Name)
        return true
    end
    return false
end

local function executeCombatLoop()
    if not verifyLicense(Config.AuthKey) then return end
    print("[Luavion] Combat loop started. Engaging target entities...")
end

executeCombatLoop()`
  showToast('Sample script loaded')
}

const handleFileSelect = (e) => {
  const file = e.target.files?.[0]
  if (file) readFile(file)
}

const handleFileDrop = (e) => {
  isDragging.value = false
  const file = e.dataTransfer?.files?.[0]
  if (file) readFile(file)
}

const readFile = (file) => {
  const reader = new FileReader()
  reader.onload = (e) => {
    sourceCode.value = e.target?.result || ''
    showToast(`Loaded ${file.name}`)
  }
  reader.readAsText(file)
}

const runObfuscation = async () => {
  if (!sourceCode.value.trim() || isObfuscating.value) return

  if (isFileSizeExceeded.value) {
    promptUpgrade('pro', `Your script size (${(inputByteCount.value / 1024).toFixed(1)} KB) exceeds the ${userPlanConfig.value.maxFileSizeLabel} limit for ${userPlan.value.toUpperCase()}. Upgrade to compile larger scripts.`)
    return
  }

  isObfuscating.value = true
  errorMessage.value = ''
  syntaxError.value = null
  elapsedTime.value = 0

  // Cycling status messages
  const steps = [
    'Parsing Luau Abstract Syntax Tree...',
    'Synthesizing Mixed Boolean-Arithmetic (MBA)...',
    'Generating Decentralized Galois Micro-Ops...',
    'Binding Roblox Vector3 Geometric Attestation...',
    'Injecting Steganographic AI Prompt Shield...'
  ]
  let stepIdx = 0
  activeCompilationStep.value = steps[0]
  const stepTimer = setInterval(() => {
    stepIdx = (stepIdx + 1) % steps.length
    activeCompilationStep.value = steps[stepIdx]
  }, 450)

  const startClock = Date.now()
  timerId = setInterval(() => {
    elapsedTime.value = ((Date.now() - startClock) / 1000).toFixed(1)
  }, 100)

  try {
    const res = await $fetch('/api/obfuscate', {
      method: 'POST',
      body: {
        source: sourceCode.value,
        preset: selectedPreset.value,
        luaVersion: luaVersion.value,
        seed: seed.value,
        includeBanner: includeBanner.value
      }
    })

    if (res.ok) {
      outputCode.value = res.output
      executionStats.value = res.stats
      pipelineLogs.value = res.logs || []
      errorMessage.value = ''
      syntaxError.value = null
      showToast('Obfuscation complete!')
      randomizeSeed()
    } else {
      errorMessage.value = res.error || 'Failed to obfuscate script.'
      syntaxError.value = res.syntaxError || null
    }
  } catch (err) {
    errorMessage.value = err?.data?.error || err?.data?.statusMessage || err?.message || 'Server error during obfuscation.'
    syntaxError.value = err?.data?.syntaxError || null
  } finally {
    clearInterval(timerId)
    clearInterval(stepTimer)
    isObfuscating.value = false
  }
}

const copyOutput = async () => {
  if (!outputCode.value) return
  await navigator.clipboard.writeText(outputCode.value)
  copied.value = true
  showToast('Copied to clipboard!')
  setTimeout(() => { copied.value = false }, 2000)
}

const downloadOutput = () => {
  if (!outputCode.value) return
  const blob = new Blob([outputCode.value], { type: 'text/plain;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `protected_${selectedPreset.value.toLowerCase()}.lua`
  a.click()
  URL.revokeObjectURL(url)
  showToast('Downloaded .lua file')
}

useHead({
  title: 'Luavion Obfuscator Studio | Next-Gen Luau Bytecode Virtualization',
  meta: [
    { name: 'description', content: 'Advanced Luau and Lua 5.1 bytecode virtualization with decentralized register VMs, geometric math attestation, and polymorphic execution flow.' }
  ]
})

onMounted(() => {
  loadSampleScript()
})
</script>

<style scoped>
.studio-page {
  padding: 24px 0 64px;
}

.studio-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Config Toolbar */
.studio-toolbar {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: var(--bg-surface);
}

.toolbar-section {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 20px;
}

.toolbar-presets {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 10px;
  width: 100%;
}

.toolbar-label-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.toolbar-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}

.preset-meta-info {
  font-size: 11px;
  color: var(--accent-cyan);
}

.preset-pills-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.preset-pill-btn {
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all var(--duration-fast);
}
.preset-pill-btn:hover {
  border-color: var(--border-hover);
}
.preset-pill-btn.active {
  background: var(--bg-elevated);
  border-color: var(--accent-cyan);
  box-shadow: 0 0 16px rgba(0, 240, 255, 0.15);
}

.preset-pill-btn.locked {
  opacity: 0.7;
}

.lock-icon {
  color: var(--status-amber);
}

.pill-sub {
  font-size: 9px;
  font-weight: 700;
  padding: 1px 4px;
  border-radius: 2px;
}
.sub-cyan { background: rgba(0, 240, 255, 0.15); color: var(--accent-cyan); }
.sub-amber { background: rgba(245, 158, 11, 0.15); color: #fbbf24; }
.sub-muted { background: rgba(255, 255, 255, 0.06); color: var(--text-muted); }

.toolbar-divider {
  height: 1px;
  background: var(--border-subtle);
  width: 100%;
}

.toolbar-options {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
}

.config-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.shield-indicator,
.watermark-tag {
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  padding: 4px 8px;
  border-radius: var(--radius-xs);
  font-size: 10px;
  font-weight: 600;
}

.btn-batch-trigger {
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: all var(--duration-fast);
}
.btn-batch-trigger:hover {
  border-color: var(--accent-cyan);
}
.btn-batch-trigger.batch-locked {
  color: var(--text-secondary);
}

/* Seed Input */
.seed-label-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.seed-refreshed-badge {
  font-size: 9px;
  color: var(--status-emerald);
  font-weight: 700;
}

.seed-control {
  display: flex;
  align-items: center;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-xs);
  overflow: hidden;
}

.seed-input {
  width: 75px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-family: inherit;
  font-size: 11px;
  padding: 4px 8px;
}
.seed-input:focus {
  outline: none;
}

.seed-refresh-btn {
  background: transparent;
  border: none;
  border-left: 1px solid var(--border-subtle);
  color: var(--text-muted);
  padding: 4px 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
}
.seed-refresh-btn:hover {
  color: var(--text-primary);
}

/* File Size Warning */
.file-size-warning {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: rgba(245, 158, 11, 0.1);
  border: 1px solid rgba(245, 158, 11, 0.3);
  border-radius: var(--radius-sm);
  font-size: 12px;
  color: #fbbf24;
}

.warn-msg {
  flex: 1;
  margin: 0 12px;
}

/* Editor Workspace */
.editor-workspace {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  min-height: 580px;
}

.editor-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  display: flex;
  flex-direction: column;
  background: var(--bg-surface);
  position: relative;
  overflow: hidden;
}

.pane-header {
  padding: 12px 16px;
  border-bottom: 1px solid var(--border-subtle);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--bg-surface-raised);
}

.pane-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pane-title-badge {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pane-name {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.06em;
  color: #ffffff;
}

.telemetry-tag {
  font-size: 10px;
  color: var(--text-muted);
}
.tag-warn {
  color: var(--status-amber);
}

.pane-controls {
  display: flex;
  align-items: center;
  gap: 6px;
}

.file-label {
  cursor: pointer;
}

.editor-body {
  flex: 1;
  position: relative;
  display: flex;
  min-height: 480px;
}

.code-textarea {
  width: 100%;
  height: 100%;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.6;
  padding: 16px;
  resize: none;
  outline: none;
  white-space: pre;
  tab-size: 2;
}

.output-textarea {
  color: #cffafe;
}

.drag-drop-overlay {
  position: absolute;
  inset: 0;
  background: rgba(5, 8, 14, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
}

.drag-drop-card {
  padding: 32px;
  border-radius: var(--radius-md);
  border: 2px dashed var(--accent-cyan);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

/* Compiling Progress Overlay */
.compiling-overlay {
  position: absolute;
  inset: 0;
  background: rgba(5, 8, 14, 0.88);
  backdrop-filter: blur(8px);
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.compiling-box {
  width: 100%;
  max-width: 380px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 24px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
}

.compiling-spinner-ring {
  width: 32px;
  height: 32px;
  border: 3px solid rgba(0, 240, 255, 0.15);
  border-top-color: var(--accent-cyan);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 14px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.compiling-title {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 6px;
}

.compiling-step-sub {
  font-size: 11px;
  color: var(--accent-cyan);
  margin-bottom: 14px;
  min-height: 16px;
}

.compiling-bar-track {
  width: 100%;
  height: 4px;
  background: var(--bg-base);
  border-radius: 999px;
  overflow: hidden;
  position: relative;
}

.compiling-bar-pulse {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 40%;
  background: linear-gradient(90deg, transparent, #00f0ff, transparent);
  animation: pulseBar 1.2s infinite ease-in-out;
}

@keyframes pulseBar {
  0% { left: -40%; }
  100% { left: 100%; }
}

.pane-footer {
  padding: 12px 16px;
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-surface-raised);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.btn-obfuscate {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-weight: 600;
}

.output-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-telemetry {
  display: flex;
  align-items: center;
  gap: 16px;
}

.telemetry-chip {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.chip-label {
  font-size: 9px;
  font-weight: 700;
  color: var(--text-muted);
}

.chip-val {
  font-size: 12px;
  font-weight: 600;
  color: var(--accent-cyan);
}

.footer-telemetry-placeholder {
  font-size: 11px;
  color: var(--text-muted);
}

/* Logs Drawer */
.logs-drawer {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 16px;
  background: #04060a;
}

.logs-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.logs-title {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.logs-body {
  max-height: 180px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.log-line {
  font-size: 11px;
  line-height: 1.5;
}
.log-info { color: #94a3b8; }
.log-warn { color: #fbbf24; }
.log-error { color: #f43f5e; }

.log-level {
  font-weight: 700;
  margin-right: 6px;
}

@media (max-width: 900px) {
  .editor-workspace {
    grid-template-columns: 1fr;
  }
}
</style>
