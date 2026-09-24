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
              :class="{ 'active': selectedPreset === p.id }"
              @click="selectedPreset = p.id"
              :title="p.desc"
            >
              <span class="pill-name">{{ p.name }}</span>
              <span v-if="p.badge" class="pill-sub" :class="p.id === 'BALANCED' ? 'sub-cyan' : 'sub-muted'">
                {{ p.badge }}
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
            <button 
              class="toggle-btn"
              :class="{ 'active': includeBanner }"
              @click="includeBanner = !includeBanner"
              :title="includeBanner ? 'Header comment banner included' : 'No header comments'"
            >
              {{ includeBanner ? 'Included' : 'Off' }}
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
              <span class="telemetry-tag">{{ inputLineCount }} lines • {{ inputByteCount }} bytes</span>
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
              :disabled="!sourceCode.trim() || isObfuscating"
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
                <span>{{ copied ? 'Copied!' : 'Copy Code' }}</span>
              </button>

              <button class="btn btn-ghost btn-sm" @click="downloadOutput" title="Download protected .lua file">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="7 10 12 15 17 10"></polyline>
                  <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                <span>Download .lua</span>
              </button>
            </div>
          </div>

          <!-- Code Output Area -->
          <div class="editor-body">
            <!-- Notice: We do NOT clear outputCode while compiling! The past output stays visible! -->
            <textarea
              v-model="outputCode"
              class="code-textarea output-textarea"
              placeholder="-- The protected virtualized script will appear here once obfuscated."
              spellcheck="false"
              readonly
            ></textarea>

            <!-- Compiling Progress Banner / Overlay (shown ON TOP of previous output while compiling) -->
            <transition name="fade">
              <div v-if="isObfuscating" class="compiling-overlay">
                <div class="compiling-status-card surface-raised">
                  <div class="compiling-spinner-box">
                    <span class="spinner"></span>
                  </div>
                  <div class="compiling-info">
                    <span class="compiling-title">Synthesizing Register VM</span>
                    <span class="compiling-sub">
                      Preserving past output • Compiling new seed ({{ elapsedTime }}s)...
                    </span>
                  </div>
                </div>
              </div>
            </transition>

            <!-- Empty State (Only shown if NO output code exists and NOT compiling) -->
            <div v-if="!outputCode && !isObfuscating" class="empty-state">
              <div class="empty-icon-box">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                  <line x1="3" y1="9" x2="21" y2="9"></line>
                  <line x1="9" y1="21" x2="9" y2="9"></line>
                </svg>
              </div>
              <span class="empty-heading">Ready to Virtualize</span>
              <p class="empty-sub">
                Select your security preset above and click "Obfuscate Script" to compile into a decentralized register VM.
              </p>
            </div>
          </div>

          <!-- Telemetry Metrics Bar Footer -->
          <div class="pane-footer output-footer">
            <div v-if="executionStats" class="metrics-row">
              <div class="metric-pill">
                <span class="pill-lbl">LATENCY</span>
                <span class="pill-val val-cyan">{{ executionStats.durationMs }}ms</span>
              </div>
              <div class="metric-pill">
                <span class="pill-lbl">EXPANSION</span>
                <span class="pill-val">{{ executionStats.expansionRatio }}x</span>
              </div>
              <div class="metric-pill">
                <span class="pill-lbl">PROFILE</span>
                <span class="pill-val">{{ executionStats.preset }}</span>
              </div>
              <div class="metric-pill">
                <span class="pill-lbl">SEED</span>
                <span class="pill-val val-cyan">{{ executionStats.seed }}</span>
              </div>
            </div>
            <div v-else class="metrics-row text-muted">
              <span>Ready for compiler job</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Pipeline Compiler Trace Drawer -->
      <div v-if="pipelineLogs.length" class="surface pipeline-drawer">
        <div class="drawer-header" @click="showLogs = !showLogs">
          <div class="drawer-title-group">
            <span class="badge badge-cyan">Pipeline Telemetry</span>
            <span class="drawer-summary">{{ pipelineLogs.length }} compiler passes recorded</span>
          </div>
          <button class="btn btn-ghost btn-sm">
            <span>{{ showLogs ? 'Collapse Trace' : 'Expand Trace' }}</span>
          </button>
        </div>

        <div v-show="showLogs" class="drawer-content">
          <div v-for="(log, i) in pipelineLogs" :key="i" class="log-row">
            <span class="log-index">{{ String(i + 1).padStart(2, '0') }}</span>
            <span class="log-pass">PASS</span>
            <span class="log-text">{{ log.message }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast Notification -->
    <div class="toast-container" v-if="toastMessage">
      <div class="toast">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" color="#10b981">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>{{ toastMessage }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

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
const toastMessage = ref('')
const seedJustRefreshed = ref(false)

const presets = [
  { 
    id: 'BALANCED', 
    name: 'Balanced', 
    badge: 'Recommended', 
    security: 'High',
    vmProfile: 'STRONG',
    desc: 'Strong Register VM with Roblox geometric math attestation & MBA expressions.' 
  },
  { 
    id: 'EXTREME', 
    name: 'Extreme', 
    badge: 'Max Defense', 
    security: 'Military-Grade',
    vmProfile: 'EXTREME',
    desc: 'Dynamic Galois opcode dispatching, dead code injection & strict float verification.' 
  },
  { 
    id: 'HARD', 
    name: 'Hard', 
    badge: 'Anti-Tamper', 
    security: 'Very High',
    vmProfile: 'HARD',
    desc: 'API reflection hashing, anti-proxy probes, and hardened register VM.' 
  },
  { 
    id: 'PERFORMANCE', 
    name: 'Performance', 
    badge: 'High FPS', 
    security: 'Standard',
    vmProfile: 'PERFORMANCE',
    desc: 'Low overhead for high-frequency physics/render loops.' 
  },
  { 
    id: 'COMPATIBLE', 
    name: 'Compatible', 
    badge: 'Universal', 
    security: 'Safe',
    vmProfile: 'SAFE',
    desc: 'Broadest compatibility across legacy Lua 5.1 and all executors.' 
  },
  { 
    id: 'MINIFY', 
    name: 'Minify', 
    badge: 'Raw AST', 
    security: 'None',
    vmProfile: 'NONE',
    desc: 'Compression and variable mangling only, without virtualization.' 
  }
]

const activePresetObj = computed(() => presets.find(p => p.id === selectedPreset.value))

const inputLineCount = computed(() => sourceCode.value ? sourceCode.value.split('\n').length : 0)
const inputByteCount = computed(() => new TextEncoder().encode(sourceCode.value).length)

const outputLineCount = computed(() => outputCode.value ? outputCode.value.split('\n').length : 0)
const outputByteCount = computed(() => new TextEncoder().encode(outputCode.value).length)

// Randomize seed function
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

/* ==========================================================================
   runObfuscation:
   1. DO NOT CLEAR PAST OUTPUT while compiling! Past output stays visible.
   2. Replace outputCode ONLY after new compilation finishes.
   3. Auto-refresh seed on every completion so consecutive runs are distinct!
   ========================================================================== */
const runObfuscation = async () => {
  if (!sourceCode.value.trim() || isObfuscating.value) return

  isObfuscating.value = true
  errorMessage.value = ''
  syntaxError.value = null
  // Notice: We intentionally do NOT do `outputCode.value = ''` here!
  // The past output stays intact while compiling.
  elapsedTime.value = 0

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
      // Compilation finished: replace output with newly compiled bytecode
      outputCode.value = res.output
      executionStats.value = res.stats
      pipelineLogs.value = res.logs || []
      errorMessage.value = ''
      syntaxError.value = null
      showToast('Obfuscation complete!')

      // MANDATED: Auto refresh seed on completion so next output is different!
      randomizeSeed()
    } else {
      errorMessage.value = res.error || 'Failed to obfuscate script.'
      syntaxError.value = res.syntaxError || null
      // Past output remains untouched so user does not lose their previous code!
    }
  } catch (err) {
    errorMessage.value = err?.data?.error || err?.data?.statusMessage || err?.message || 'Server error during obfuscation.'
    syntaxError.value = err?.data?.syntaxError || null
  } finally {
    clearInterval(timerId)
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

const showToast = (msg) => {
  toastMessage.value = msg
  setTimeout(() => { toastMessage.value = '' }, 2500)
}

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
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  flex-wrap: wrap;
  background: var(--bg-surface-raised);
}

.toolbar-section {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.toolbar-presets {
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
  flex: 1;
  min-width: 320px;
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
  font-size: 10px;
  color: var(--accent-cyan);
  font-weight: 600;
}

.preset-pills-row {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.preset-pill-btn {
  font-family: var(--font-mono);
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  transition: all var(--duration-fast);
}

.preset-pill-btn:hover {
  border-color: var(--border-hover);
  color: #ffffff;
}

.preset-pill-btn.active {
  background: var(--bg-elevated);
  border-color: var(--accent-cyan-border);
  color: var(--accent-cyan);
  box-shadow: 0 0 14px rgba(0, 240, 255, 0.15);
}

.pill-sub {
  font-size: 9px;
  font-weight: 600;
  padding: 1px 5px;
  border-radius: 3px;
  text-transform: uppercase;
}

.sub-cyan {
  background: var(--accent-cyan-dim);
  color: var(--accent-cyan);
}

.sub-muted {
  background: rgba(255, 255, 255, 0.06);
  color: var(--text-muted);
}

.toolbar-divider {
  width: 1px;
  height: 48px;
  background: var(--border-subtle);
}

.toolbar-options {
  display: flex;
  align-items: center;
  gap: 20px;
}

.config-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

/* Segmented Control */
.segmented-control {
  display: flex;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 2px;
}

.seg-btn {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast);
}

.seg-btn.active {
  background: var(--bg-elevated);
  color: #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
}

/* Shield Status */
.shield-indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface);
  border: 1px solid var(--status-emerald-border);
  font-size: 10px;
  font-weight: 600;
  color: var(--status-emerald);
}

/* Toggle Button */
.toggle-btn {
  font-family: var(--font-mono);
  font-size: 11px;
  padding: 5px 12px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  cursor: pointer;
  transition: all var(--duration-fast);
}

.toggle-btn.active {
  background: var(--bg-elevated);
  border-color: var(--accent-cyan-border);
  color: var(--accent-cyan);
}

/* Seed Input Group with Auto-Refresh visual */
.seed-label-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.seed-refreshed-badge {
  font-size: 9px;
  font-weight: 700;
  color: var(--accent-cyan);
  animation: flashIn 300ms var(--ease-spring);
}

@keyframes flashIn {
  from { opacity: 0; transform: scale(0.9); }
  to { opacity: 1; transform: scale(1); }
}

.seed-control {
  display: flex;
  align-items: center;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 2px 4px;
  transition: border-color var(--duration-fast), box-shadow var(--duration-fast);
}

.seed-control.refreshed-glow {
  border-color: var(--accent-cyan);
  box-shadow: 0 0 14px rgba(0, 240, 255, 0.35);
}

.seed-input {
  font-family: var(--font-mono);
  font-size: 11px;
  color: #ffffff;
  background: transparent;
  border: none;
  outline: none;
  width: 90px;
  padding: 3px 6px;
}

.seed-refresh-btn {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 3px;
}

.seed-refresh-btn:hover {
  color: var(--accent-cyan);
  background: rgba(255, 255, 255, 0.05);
}

/* Editor Workspace Grid */
.editor-workspace {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.editor-card {
  display: flex;
  flex-direction: column;
  height: 600px;
  overflow: hidden;
  border-radius: var(--radius-md);
  position: relative;
  transition: border-color var(--duration-fast);
}

.editor-card.drag-over {
  border-color: var(--accent-cyan);
  box-shadow: 0 0 24px rgba(0, 240, 255, 0.25);
}

.editor-card.compiling-active {
  border-color: rgba(0, 240, 255, 0.3);
}

/* Pane Header */
.pane-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: var(--bg-surface-raised);
  border-bottom: 1px solid var(--border-subtle);
  gap: 12px;
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
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
  color: #ffffff;
}

.telemetry-tag {
  font-size: 10px;
  color: var(--text-muted);
}

.pane-controls {
  display: flex;
  align-items: center;
  gap: 6px;
}

.file-label {
  cursor: pointer;
}

/* Editor Body & Textareas */
.editor-body {
  flex: 1;
  position: relative;
  display: flex;
  overflow: hidden;
  background: var(--bg-base);
}

.code-textarea {
  flex: 1;
  width: 100%;
  height: 100%;
  padding: 16px;
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.65;
  color: var(--text-primary);
  background: transparent;
  border: none;
  outline: none;
  resize: none;
  white-space: pre;
  tab-size: 2;
  overflow: auto;
}

.output-textarea {
  color: #93c5fd;
}

/* Drag & Drop Overlay */
.drag-drop-overlay {
  position: absolute;
  inset: 0;
  background: rgba(5, 8, 14, 0.85);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 20;
}

.drag-drop-card {
  padding: 24px 32px;
  border-radius: var(--radius-md);
  border: 1px dashed var(--accent-cyan);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.drop-text {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
}

/* Compiling Status Overlay (Keeps past output visible underneath) */
.compiling-overlay {
  position: absolute;
  top: 14px;
  right: 14px;
  z-index: 10;
  pointer-events: none;
}

.compiling-status-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  border-radius: var(--radius-sm);
  background: rgba(14, 20, 34, 0.95);
  border: 1px solid var(--accent-cyan-border);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.6), 0 0 16px rgba(0, 240, 255, 0.2);
  backdrop-filter: blur(12px);
  animation: slideIn 200ms var(--ease-spring);
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

.compiling-spinner-box {
  color: var(--accent-cyan);
}

.compiling-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.compiling-title {
  font-size: 11px;
  font-weight: 700;
  color: #ffffff;
}

.compiling-sub {
  font-size: 10px;
  color: var(--text-secondary);
}

/* Empty State */
.empty-state {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 32px;
  text-align: center;
  pointer-events: none;
}

.empty-icon-box {
  width: 52px;
  height: 52px;
  border-radius: var(--radius-md);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-faint);
}

.empty-heading {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
}

.empty-sub {
  font-size: 12px;
  color: var(--text-muted);
  max-width: 340px;
  line-height: 1.5;
}

/* Pane Footer */
.pane-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: var(--bg-surface-raised);
  border-top: 1px solid var(--border-subtle);
}

.btn-obfuscate {
  width: 100%;
  padding: 10px;
  font-size: 13px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.output-footer {
  font-size: 11px;
}

.metrics-row {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.metric-pill {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pill-lbl {
  font-size: 9px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.06em;
}

.pill-val {
  font-size: 11px;
  font-weight: 600;
  color: #ffffff;
}

.val-cyan {
  color: var(--accent-cyan);
}

/* Pipeline Drawer */
.pipeline-drawer {
  overflow: hidden;
  border-radius: var(--radius-md);
}

.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 18px;
  background: var(--bg-surface-raised);
  cursor: pointer;
  transition: background var(--duration-fast);
}

.drawer-header:hover {
  background: var(--bg-elevated);
}

.drawer-title-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.drawer-summary {
  font-size: 11px;
  color: var(--text-secondary);
}

.drawer-content {
  padding: 14px 18px;
  background: var(--bg-base);
  border-top: 1px solid var(--border-subtle);
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 240px;
  overflow-y: auto;
}

.log-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 11px;
  font-family: var(--font-mono);
}

.log-index {
  color: var(--text-faint);
}

.log-pass {
  font-size: 9px;
  font-weight: 700;
  padding: 1px 5px;
  border-radius: 3px;
  background: var(--accent-cyan-dim);
  color: var(--accent-cyan);
}

.log-text {
  color: var(--text-secondary);
}

/* Transitions */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 200ms var(--ease-spring);
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@media (max-width: 960px) {
  .editor-workspace {
    grid-template-columns: 1fr;
  }
  .editor-card {
    height: 480px;
  }
  .toolbar-divider {
    display: none;
  }
}
</style>
