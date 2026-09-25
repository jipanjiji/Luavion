<template>
  <div class="studio-page">
    <div class="studio-container">

      <!-- Command bar -->
      <header class="studio-head anim-fade-up">
        <div class="studio-title-group">
          <h1 class="studio-title">Studio</h1>
          <p class="studio-sub">Virtualize Luau &amp; Lua 5.1 scripts with the Galois register engine.</p>
        </div>
        <div class="studio-head-actions">
          <button class="btn btn-ghost btn-sm" @click="handleOpenCustomPresets">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path d="M20 7h-9" /><path d="M14 17H5" /><circle cx="17" cy="17" r="3" /><circle cx="7" cy="7" r="3" />
            </svg>
            Presets
          </button>
          <button class="btn btn-secondary btn-sm" @click="handleOpenBatch">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
            </svg>
            Batch
          </button>
        </div>
      </header>

      <!-- Preset strip -->
      <div class="preset-strip anim-fade-up" style="animation-delay: 60ms" role="radiogroup" aria-label="Obfuscation preset">
        <button
          v-for="p in presets"
          :key="p.id"
          class="preset-pill"
          :class="{ selected: selectedPreset === p.id, locked: isPresetLocked(p.id) }"
          role="radio"
          :aria-checked="selectedPreset === p.id"
          @click="handleSelectPreset(p)"
        >
          <span class="pill-name">{{ p.name }}</span>
          <span v-if="isPresetLocked(p.id)" class="pill-lock" aria-label="Locked">
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
          </span>
          <span v-else-if="p.badge" class="pill-badge mono">{{ p.badge }}</span>
        </button>
      </div>

      <p class="preset-desc mono anim-fade-up" style="animation-delay: 100ms">
        <span class="preset-desc-id">{{ selectedPreset }}</span>
        {{ activePresetObj?.desc }}
        <span class="preset-desc-sep">·</span> security {{ activePresetObj?.security }}
      </p>

      <!-- Engine controls -->
      <div class="engine-controls anim-fade-up" style="animation-delay: 140ms">
        <div class="controls-left">
          <div class="segmented-control" role="group" aria-label="Target runtime">
            <button class="seg-btn mono" :class="{ active: luaVersion === 'LuaU' }" @click="luaVersion = 'LuaU'">Luau</button>
            <button class="seg-btn mono" :class="{ active: luaVersion === 'Lua51' }" @click="luaVersion = 'Lua51'">Lua 5.1</button>
          </div>

          <div class="seed-chip mono">
            <span class="seed-label">seed</span>
            <span class="seed-val">{{ seed }}</span>
            <button class="seed-refresh" :class="{ spun: seedJustRefreshed }" @click="randomizeSeedManual" aria-label="Randomize seed">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <path d="M21 12a9 9 0 1 1-2.64-6.36" /><polyline points="21 3 21 9 15 9" />
              </svg>
            </button>
          </div>
        </div>

        <button
          class="btn btn-primary btn-lg run-btn"
          :disabled="isObfuscating || !sourceCode.trim() || isFileSizeExceeded"
          @click="runObfuscation"
        >
          <span v-if="isObfuscating" class="spinner" aria-hidden="true"></span>
          <span>{{ isObfuscating ? `Virtualizing… ${elapsedTime}s` : 'Obfuscate' }}</span>
        </button>
      </div>

      <!-- Error banner -->
      <div v-if="errorMessage || syntaxError" class="error-banner" role="alert">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" />
        </svg>
        <div class="error-body">
          <strong>{{ syntaxError ? 'Syntax error' : 'Compilation failed' }}</strong>
          <span class="mono error-msg">{{ errorMessage }}</span>
          <span v-if="syntaxError" class="mono error-loc">line {{ syntaxError.line }} · col {{ syntaxError.column }}</span>
        </div>
        <button class="error-dismiss" @click="clearError" aria-label="Dismiss error">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>

      <!-- Editor workspace -->
      <div class="studio-workspace anim-fade-up" style="animation-delay: 180ms">
        <!-- Input pane -->
        <div
          class="editor-pane terminal-frame"
          :class="{ 'drag-over': isDragging }"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="handleFileDrop"
        >
          <div class="tf-header">
            <span class="status-dot dot-cyan"></span>
            <span>source.lua</span>
            <span v-if="sourceCode" class="tf-meta mono">{{ inputLineCount }} lines · {{ (inputByteCount / 1024).toFixed(1) }} KB</span>
            <div class="tf-actions">
              <label class="tf-action-btn" title="Upload .lua file">
                <input type="file" accept=".lua,.txt" class="sr-only" @change="handleFileSelect" />
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line x1="12" y1="3" x2="12" y2="15" />
                </svg>
              </label>
              <button class="tf-action-btn" @click="loadSampleScript" title="Load sample script">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" />
                </svg>
              </button>
              <button v-if="sourceCode" class="tf-action-btn" @click="clearInput" title="Clear input">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <polyline points="3 6 5 6 21 6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                </svg>
              </button>
            </div>
          </div>

          <div class="editor-body">
            <div v-if="isDragging" class="drop-veil">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line x1="12" y1="3" x2="12" y2="15" />
              </svg>
              <span>Drop .lua file to load</span>
            </div>
            <textarea
              v-model="sourceCode"
              class="code-textarea"
              placeholder="-- Paste your Luau / Lua 5.1 script here, or drop a .lua file"
              spellcheck="false"
              aria-label="Source code input"
            ></textarea>
          </div>

          <div class="editor-foot">
            <span v-if="isFileSizeExceeded" class="foot-warn mono">
              exceeds {{ userPlanConfig.maxFileSizeLabel }} plan limit — upgrade to compile
            </span>
            <span v-else class="foot-hint mono">LuaU + Lua 5.1 · {{ userPlanConfig.maxFileSizeLabel }} max</span>
          </div>
        </div>

        <!-- Output pane -->
        <div class="editor-pane terminal-frame">
          <div class="tf-header">
            <span class="status-dot" :class="outputCode ? 'dot-emerald' : ''" :style="outputCode ? '' : 'background: var(--bg-overlay)'"></span>
            <span>protected.lua</span>
            <span v-if="outputCode" class="tf-meta mono">
              {{ outputLineCount }} lines · {{ (outputByteCount / 1024).toFixed(1) }} KB<span v-if="executionStats"> · {{ executionStats.durationMs }}ms</span>
            </span>
            <div class="tf-actions" v-if="outputCode">
              <button class="tf-action-btn" @click="copyOutput" :title="copied ? 'Copied' : 'Copy to clipboard'">
                <svg v-if="!copied" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <rect x="9" y="9" width="13" height="13" rx="2" /><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                </svg>
                <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="color: var(--status-emerald)" aria-hidden="true">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              </button>
              <button class="tf-action-btn" @click="downloadOutput" title="Download protected file">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
                </svg>
              </button>
            </div>
          </div>

          <div class="editor-body">
            <div v-if="isObfuscating" class="compiling-overlay">
              <div class="compiling-box">
                <div class="compiling-spinner-ring"></div>
                <span class="compiling-title">Synthesizing Galois Register VM</span>
                <span class="compiling-step-sub mono">{{ activeCompilationStep }}</span>
                <div class="compiling-bar-track">
                  <div class="compiling-bar-pulse"></div>
                </div>
              </div>
            </div>
            <textarea
              v-model="outputCode"
              class="code-textarea output-textarea"
              placeholder="-- Virtualized bytecode appears here after obfuscation"
              readonly
              spellcheck="false"
              aria-label="Obfuscated output"
            ></textarea>
          </div>

          <div class="editor-foot">
            <div class="foot-stats mono" v-if="executionStats">
              <span>expansion <strong>{{ executionStats.expansionRatio }}x</strong></span>
              <span>latency <strong>{{ executionStats.durationMs }}ms</strong></span>
              <span>seed <strong>{{ executionStats.seed }}</strong></span>
            </div>
            <span v-else class="foot-hint mono">ready for compilation</span>
            <button
              v-if="pipelineLogs.length"
              class="foot-logs-btn mono"
              @click="showLogs = !showLogs"
            >{{ showLogs ? 'hide logs' : `logs (${pipelineLogs.length})` }}</button>
          </div>
        </div>
      </div>

      <!-- Pipeline logs drawer -->
      <transition name="logs">
        <div v-if="showLogs && pipelineLogs.length" class="terminal-frame logs-drawer">
          <div class="tf-header">
            <span>compiler pipeline logs</span>
            <button class="tf-action-btn" style="margin-left: auto" @click="showLogs = false" aria-label="Close logs">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
          <div class="logs-body">
            <div v-for="(log, i) in pipelineLogs" :key="i" class="log-line mono" :class="`log-${log.level || 'info'}`">
              <span class="log-level">[{{ (log.level || 'info').toUpperCase() }}]</span>
              <span class="log-msg">{{ log.message }}</span>
            </div>
          </div>
        </div>
      </transition>

      <!-- Mobile sticky action bar -->
      <div class="mobile-run-bar">
        <button
          class="btn btn-primary btn-lg mobile-run-btn"
          :disabled="isObfuscating || !sourceCode.trim() || isFileSizeExceeded"
          @click="runObfuscation"
        >
          <span v-if="isObfuscating" class="spinner" aria-hidden="true"></span>
          {{ isObfuscating ? `Virtualizing… ${elapsedTime}s` : 'Obfuscate' }}
        </button>
      </div>

      <BatchObfuscatorModal v-model="showBatchModal" />
      <CustomPresetModal
        v-model="showCustomPresetsModal"
        :current-settings="{ preset: selectedPreset, luaVersion, includeBanner }"
        @apply="onApplyCustomPreset"
      />
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'dashboard' })

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
.studio-page { padding: 0 0 120px; }

.sr-only {
  position: absolute;
  width: 1px; height: 1px;
  clip-path: inset(50%);
  overflow: hidden;
}

/* ---------- Head ---------- */
.studio-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
}

.studio-title {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.03em;
}

.studio-sub { font-size: 13px; color: var(--text-muted); margin-top: 2px; }

.studio-head-actions { display: flex; gap: 8px; }

/* ---------- Preset strip ---------- */
.preset-strip {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding-bottom: 4px;
  scrollbar-width: none;
}

.preset-strip::-webkit-scrollbar { display: none; }

.preset-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 16px;
  border-radius: var(--radius-full);
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  font-family: inherit;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: all var(--duration-fast) var(--ease-out);
  min-height: 40px;
}

.preset-pill:hover { border-color: var(--border-hover); color: var(--text-primary); }

.preset-pill.selected {
  background: var(--text-primary);
  border-color: var(--text-primary);
  color: var(--text-inverse);
}

.preset-pill.locked { opacity: 0.5; }

.pill-badge, .pill-lock { font-size: 9px; }

.preset-pill.selected .pill-badge { color: var(--text-inverse); opacity: 0.7; }

.pill-badge { color: var(--text-faint); letter-spacing: 0.06em; }

.pill-lock { display: inline-flex; color: var(--text-faint); }

.preset-desc {
  font-size: 11px;
  color: var(--text-muted);
  margin: 12px 2px 18px;
  letter-spacing: 0.01em;
}

.preset-desc-id { color: var(--text-primary); font-weight: 600; margin-right: 8px; }

.preset-desc-sep { margin: 0 6px; color: var(--text-faint); }

/* ---------- Engine controls ---------- */
.engine-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 16px;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  margin-bottom: 18px;
  flex-wrap: wrap;
}

.controls-left { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }

.segmented-control {
  display: inline-flex;
  gap: 2px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 2px;
}

.seg-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 11px;
  font-weight: 500;
  padding: 6px 13px;
  border-radius: 4px;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
  min-height: 30px;
}

.seg-btn.active { background: var(--bg-elevated); color: var(--text-primary); }

.seed-chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 7px 8px 7px 13px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-full);
  font-size: 11px;
  min-height: 34px;
}

.seed-label { color: var(--text-faint); }

.seed-val { color: var(--text-primary); font-weight: 600; font-variant-numeric: tabular-nums; }

.seed-refresh {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  background: transparent;
  border: none;
  border-radius: 50%;
  color: var(--text-muted);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.seed-refresh:hover { color: var(--text-primary); background: var(--bg-overlay); }

.seed-refresh.spun svg { animation: spin 600ms var(--ease-out); }

.run-btn { min-width: 190px; }

.run-btn .kbd { border-color: rgba(0, 0, 0, 0.2); background: rgba(0, 0, 0, 0.12); color: rgba(0, 0, 0, 0.55); }

/* ---------- Error ---------- */
.error-banner {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 14px 16px;
  margin-bottom: 18px;
  background: var(--status-crimson-dim);
  border: 1px solid var(--status-crimson-border);
  border-radius: var(--radius-md);
  color: var(--status-crimson);
  animation: fadeUp 250ms var(--ease-spring);
}

.error-body { display: flex; flex-direction: column; gap: 3px; flex: 1; min-width: 0; }

.error-body strong { font-size: 12px; letter-spacing: 0.04em; text-transform: uppercase; }

.error-msg { font-size: 12px; color: var(--text-secondary); word-break: break-word; }

.error-loc { font-size: 11px; color: var(--text-faint); }

.error-dismiss {
  background: transparent;
  border: none;
  color: var(--status-crimson);
  cursor: pointer;
  padding: 6px;
  border-radius: var(--radius-xs);
  flex-shrink: 0;
}

.error-dismiss:hover { background: rgba(248, 113, 113, 0.12); }

/* ---------- Workspace ---------- */
.studio-workspace {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  align-items: stretch;
}

.editor-pane {
  display: flex;
  flex-direction: column;
  min-height: 520px;
  transition: border-color var(--duration-normal) var(--ease-out);
}

.editor-pane.drag-over { border-color: var(--border-focus); }

.tf-header { display: flex; align-items: center; gap: 10px; }

.tf-meta { color: var(--text-faint); margin-left: 4px; }

.tf-actions { display: flex; gap: 2px; margin-left: auto; }

.tf-action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: transparent;
  border: none;
  border-radius: var(--radius-xs);
  color: var(--text-muted);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.tf-action-btn:hover { color: var(--text-primary); background: var(--bg-overlay); }

.editor-body { position: relative; flex: 1; display: flex; }

.code-textarea {
  flex: 1;
  width: 100%;
  resize: none;
  border: none;
  outline: none;
  background: transparent;
  color: var(--text-primary);
  font-family: var(--font-mono);
  font-size: 12.5px;
  line-height: 1.75;
  padding: 16px 18px;
  tab-size: 2;
}

.code-textarea::placeholder { color: var(--text-faint); }

.output-textarea { color: var(--text-secondary); }

.drop-veil {
  position: absolute;
  inset: 0;
  z-index: 5;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  background: rgba(10, 10, 11, 0.85);
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 500;
  backdrop-filter: blur(4px);
}

.editor-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 16px;
  border-top: 1px solid var(--border-faint);
  min-height: 40px;
}

.foot-hint { font-size: 10px; color: var(--text-faint); letter-spacing: 0.04em; }

.foot-warn { font-size: 10px; color: var(--status-amber); }

.foot-stats { display: flex; gap: 16px; font-size: 10px; color: var(--text-faint); }

.foot-stats strong { color: var(--text-secondary); font-weight: 600; }

.foot-logs-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 10px;
  cursor: pointer;
  letter-spacing: 0.04em;
}

.foot-logs-btn:hover { color: var(--text-primary); }

/* ---------- Compiling overlay ---------- */
.compiling-overlay {
  position: absolute;
  inset: 0;
  z-index: 6;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(10, 10, 11, 0.9);
  backdrop-filter: blur(3px);
}

.compiling-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  text-align: center;
  padding: 24px;
}

.compiling-spinner-ring {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid var(--border-regular);
  border-top-color: var(--text-primary);
  animation: spin 800ms linear infinite;
}

.compiling-title { font-size: 13px; font-weight: 600; color: var(--text-primary); }

.compiling-step-sub {
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 0.05em;
  transition: opacity var(--duration-fast);
}

.compiling-bar-track {
  width: 180px;
  height: 2px;
  border-radius: 999px;
  background: var(--bg-overlay);
  overflow: hidden;
}

.compiling-bar-pulse {
  width: 40%;
  height: 100%;
  border-radius: 999px;
  background: var(--text-primary);
  animation: scan 1.2s var(--ease-out) infinite;
}

@keyframes scan {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(350%); }
}

/* ---------- Logs drawer ---------- */
.logs-drawer { margin-top: 16px; }

.logs-enter-active, .logs-leave-active { transition: opacity var(--duration-normal) var(--ease-out), transform var(--duration-normal) var(--ease-out); }
.logs-enter-from, .logs-leave-to { opacity: 0; transform: translateY(-6px); }

.logs-body {
  max-height: 220px;
  overflow-y: auto;
  padding: 12px 16px;
}

.log-line {
  display: flex;
  gap: 10px;
  font-size: 11px;
  padding: 3px 0;
  line-height: 1.6;
}

.log-level { color: var(--text-faint); flex-shrink: 0; width: 64px; }

.log-msg { color: var(--text-secondary); }

.log-warn .log-level, .log-warn .log-msg { color: var(--status-amber); }

.log-error .log-level, .log-error .log-msg { color: var(--status-crimson); }

/* ---------- Mobile ---------- */
.mobile-run-bar { display: none; }

@media (max-width: 900px) {
  .studio-page { padding: 24px 0 96px; }

  .studio-head { flex-direction: column; align-items: flex-start; gap: 12px; }

  .studio-sub { display: none; }

  .studio-head-actions { width: 100%; }
  .studio-head-actions .btn { flex: 1; }

  .engine-controls { flex-direction: column; align-items: stretch; }

  .run-btn { display: none; }

  .studio-workspace { grid-template-columns: 1fr; }

  .editor-pane { min-height: 380px; }

  .mobile-run-bar {
    display: block;
    position: fixed;
    left: 0; right: 0; bottom: 56px;
    z-index: 80;
    padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
    background: rgba(10, 10, 11, 0.85);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border-top: 1px solid var(--border-subtle);
  }

  .mobile-run-btn { width: 100%; min-height: 48px; }
}
</style>
