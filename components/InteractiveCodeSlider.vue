<template>
  <div class="code-slider-card surface">
    <!-- Topbar -->
    <div class="slider-topbar">
      <div class="sample-tabs">
        <span class="sample-label">SAMPLES:</span>
        <button
          v-for="(sample, key) in samples"
          :key="key"
          class="sample-tab-btn"
          :class="{ active: activeSample === key }"
          @click="activeSample = key"
        >
          {{ sample.name }}
        </button>
      </div>
      <div class="slider-telemetry">
        <div class="telemetry-badge">
          <span class="status-dot dot-cyan"></span>
          <span>LUAVION V9.15 VM</span>
        </div>
        <button class="btn btn-ghost btn-sm reset-btn" @click="sliderPos = 50">RESET</button>
      </div>
    </div>

    <!-- Stage Area -->
    <div
      ref="stageRef"
      class="slider-stage"
      @mousedown="onDragStart"
      @touchstart.passive="onDragStart"
    >
      <!-- Raw Source Pane (Left) -->
      <div class="slider-pane pane-left" :style="{ clipPath: `inset(0 ${100 - sliderPos}% 0 0)` }">
        <div class="pane-tag tag-raw">
          <span>// ORIGINAL RAW AST</span>
          <span>{{ leftLineCount }} LINES</span>
        </div>
        <div class="code-container">
          <div class="line-gutter">
            <span v-for="n in leftLineCount" :key="n" class="gutter-num">{{ n }}</span>
          </div>
          <pre class="code-content"><code v-html="currentSample.highlightedRaw"></code></pre>
        </div>
      </div>

      <!-- Obfuscated Pane (Right) — real engine output -->
      <div class="slider-pane pane-right">
        <div class="pane-tag tag-obfuscated">
          <span>// PROTECTED VM BYTECODE</span>
          <span>{{ rightLineCount.toLocaleString() }} LINES</span>
        </div>
        <div class="code-container code-container-wrap">
          <pre v-if="rightHighlighted" class="code-content code-content-wrap"><code v-html="rightHighlighted"></code></pre>
          <pre v-else class="code-content"><code class="syntax-comment">// compiling sample…</code></pre>
        </div>
      </div>

      <!-- Draggable Divider -->
      <div class="slider-divider" :style="{ left: `${sliderPos}%` }" :class="{ dragging: isDragging }">
        <div class="divider-line"></div>
        <div class="slider-handle">
          <div class="handle-inner">
            <div class="handle-grip-dots">
              <span></span><span></span><span></span>
            </div>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="8 7 3 12 8 17"></polyline>
              <polyline points="16 7 21 12 16 17"></polyline>
            </svg>
            <div class="handle-grip-dots">
              <span></span><span></span><span></span>
            </div>
          </div>
          <div class="handle-badge">COMPARE</div>
        </div>
      </div>
    </div>

    <!-- Bottombar -->
    <div class="slider-bottombar">
      <div class="slider-hint">
        <kbd class="kbd">←</kbd>
        <kbd class="kbd">→</kbd>
        <span>or drag to compare</span>
      </div>
      <div class="telemetry-badge">
        <span class="dot-indicator"></span>
        <span>ANTI-DUMP</span>
      </div>
      <div class="telemetry-badge">
        <span class="dot-indicator"></span>
        <span>ZERO STATIC STRINGS</span>
      </div>
      <div class="telemetry-badge">
        <span class="dot-indicator"></span>
        <span>MUTABLE VM</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import demoOutputs from '~/assets/data/demo-outputs.json'

const stageRef = ref(null)
const sliderPos = ref(50)
const isDragging = ref(false)
const activeSample = ref('auth')

const rightOutputs = ref({})
const rightHighlighted = ref('')

// ---------------------------------------------------------------------------
// Lua syntax highlighter (client-side, no deps)
// ---------------------------------------------------------------------------
const LUA_KEYWORDS = new Set([
  'local','function','end','if','then','else','elseif','while','do','for','in',
  'repeat','until','return','break','goto','and','or','not','true','false','nil'
])

function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function highlightLua(code) {
  // token-based single pass: comments, strings, numbers, keywords, calls
  const token = /(--\[\[[\s\S]*?\]\]|--[^\n]*)|("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|\[\[[\s\S]*?\]\])|(\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b|0x[0-9a-fA-F]+)|(\b[A-Za-z_]\w*\b)/g
  let out = ''
  let last = 0
  let m
  while ((m = token.exec(code)) !== null) {
    out += esc(code.slice(last, m.index))
    if (m[1]) {
      out += `<span class="syntax-comment">${esc(m[1])}</span>`
    } else if (m[2]) {
      out += `<span class="syntax-str">${esc(m[2])}</span>`
    } else if (m[3]) {
      out += `<span class="syntax-number">${esc(m[3])}</span>`
    } else if (m[4]) {
      const w = m[4]
      if (LUA_KEYWORDS.has(w)) {
        out += `<span class="syntax-keyword">${esc(w)}</span>`
      } else if (code[m.index + w.length] === '(' || code[m.index + w.length] === '"' || code[m.index + w.length] === "'") {
        out += `<span class="syntax-func">${esc(w)}</span>`
      } else {
        out += `<span class="syntax-id">${esc(w)}</span>`
      }
    }
    last = m.index + m[0].length
  }
  out += esc(code.slice(last))
  return out
}

// ---------------------------------------------------------------------------
// Samples — raw sources are real; obfuscated panes load real engine output
// generated offline with seed 1337, BALANCED preset, LuaU target.
// ---------------------------------------------------------------------------
const RAW_SOURCES = {
  auth: {
    name: 'Auth System',
    rawCode: `--@title: Auth System
local AuthService = {}
local HttpService = game:GetService("HttpService")

function AuthService:VerifyKey(user, key)
  if not key or key == "" then return false end
  local payload = HttpService:JSONEncode({
    user = user.Name,
    key = key,
    timestamp = os.time()
  })
  return #key == 32 and key:sub(1,4) == "LUA_"
end

return AuthService`
  },
  combat: {
    name: 'Combat Loop',
    rawCode: `--@title: Combat Loop
local player = game.Players.LocalPlayer

function killAura(range)
  for _, enemy in pairs(workspace.Enemies:GetChildren()) do
    if (enemy.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= range then
      enemy.Humanoid.Health = 0
    end
  end
end

while true do
  killAura(10)
  task.wait(0.5)
end`
  },
  gui: {
    name: 'Rayfield Hub',
    rawCode: `--@title: Rayfield Hub
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftware/rayfield/main/source.lua"))()

local Window = Rayfield:CreateWindow({
  Name = "Luavion Hub v9.15",
  LoadingTitle = "Loading Luavion Hub...",
  ConfigurationSaving = { Enabled = false }
})

Rayfield:Notify({ Title = "Success", Content = "Script loaded securely" })
Window:CreateTab("Main")`
  }
}

const samples = computed(() => {
  const map = {}
  for (const [key, s] of Object.entries(RAW_SOURCES)) {
    map[key] = { ...s, highlightedRaw: highlightLua(s.rawCode) }
  }
  return map
})

const currentSample = computed(() => samples.value[activeSample.value])

// Real obfuscated output for the active sample
watch(activeSample, (key) => {
  rightHighlighted.value = ''
  const raw = rightOutputs.value[key]
  if (raw) {
    rightHighlighted.value = highlightLua(raw)
  }
}, { immediate: true })

onMounted(() => {
  rightOutputs.value = demoOutputs
  rightHighlighted.value = highlightLua(demoOutputs[activeSample.value] || '')
  window.addEventListener('mousemove', onDragMove)
  window.addEventListener('mouseup', onDragEnd)
  window.addEventListener('touchmove', onDragMove, { passive: false })
  window.addEventListener('touchend', onDragEnd)
  window.addEventListener('keydown', onKeyDown)
})

onUnmounted(() => {
  window.removeEventListener('mousemove', onDragMove)
  window.removeEventListener('mouseup', onDragEnd)
  window.removeEventListener('touchmove', onDragMove)
  window.removeEventListener('touchend', onDragEnd)
  window.removeEventListener('keydown', onKeyDown)
})

const leftLineCount = computed(() => currentSample.value.rawCode.split('\n').length)
const rightLineCount = computed(() => {
  const raw = rightOutputs.value[activeSample.value] || ''
  return raw ? raw.split('\n').length : 0
})

const updatePosFromEvent = (e) => {
  if (!stageRef.value) return
  const rect = stageRef.value.getBoundingClientRect()
  const clientX = e.touches ? e.touches[0].clientX : e.clientX
  let percentage = ((clientX - rect.left) / rect.width) * 100
  percentage = Math.max(2, Math.min(98, percentage))
  sliderPos.value = percentage
}

const onDragStart = (e) => {
  isDragging.value = true
  updatePosFromEvent(e)
}

const onDragMove = (e) => {
  if (!isDragging.value) return
  if (e.cancelable) e.preventDefault()
  updatePosFromEvent(e)
}

const onDragEnd = () => {
  isDragging.value = false
}

const onKeyDown = (e) => {
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
    const delta = e.key === 'ArrowLeft' ? -2 : 2
    sliderPos.value = Math.max(2, Math.min(98, sliderPos.value + delta))
  }
}
</script>

<style scoped>
.code-slider-card {
  overflow: hidden;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-regular);
  background: #0c0c0e;
  box-shadow: var(--surface-highlight), var(--shadow-lg);
}

/* Topbar */
.slider-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: var(--bg-surface);
  border-bottom: 1px solid var(--border-subtle);
  flex-wrap: wrap;
  gap: 12px;
}

.sample-tabs {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.sample-label {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.08em;
  color: var(--text-faint);
  margin-right: 6px;
}

.sample-tab-btn {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  padding: 5px 11px;
  border-radius: var(--radius-xs);
  background: transparent;
  color: var(--text-muted);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.sample-tab-btn:hover {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.05);
}

.sample-tab-btn.active {
  background: var(--bg-elevated);
  color: var(--text-primary);
  border-color: var(--border-regular);
}

.slider-telemetry {
  display: flex;
  align-items: center;
  gap: 8px;
}

.telemetry-badge {
  display: flex;
  align-items: center;
  gap: 7px;
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  padding: 4px 9px;
  border-radius: var(--radius-xs);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  letter-spacing: 0.05em;
}

.dot-indicator {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--text-primary);
}

.reset-btn {
  font-size: 10px;
  padding: 3px 8px;
  min-height: 26px;
}

/* Stage Area */
.slider-stage {
  position: relative;
  height: 440px;
  background: var(--bg-base);
  user-select: none;
  overflow: hidden;
  cursor: ew-resize;
}

/* Panes */
.slider-pane {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: var(--bg-base);
}

.pane-right { z-index: 1; }

.pane-left {
  z-index: 2;
  background: radial-gradient(circle at 20% 20%, rgba(251, 191, 36, 0.03), transparent 60%), var(--bg-base);
}

.pane-tag {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 8px 18px;
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.08em;
  border-bottom: 1px solid var(--border-faint);
  color: var(--text-muted);
}

.tag-raw { color: var(--status-amber); }
.tag-obfuscated { color: var(--text-primary); }

.code-container {
  display: flex;
  flex: 1;
  overflow: hidden;
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.7;
}

.line-gutter {
  width: 44px;
  padding: 16px 8px;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  color: var(--text-faint);
  background: rgba(0, 0, 0, 0.25);
  border-right: 1px solid var(--border-faint);
  user-select: none;
  flex-shrink: 0;
}

.gutter-num { font-size: 11px; height: 20.4px; }

.code-content {
  flex: 1;
  padding: 16px 20px;
  overflow: hidden;
  white-space: pre;
  tab-size: 2;
}

.code-content code { font-family: var(--font-mono); }

/* Right pane: dense wrapped blob (no gutter, fills the frame) */
.code-container-wrap { background: rgba(0, 0, 0, 0.18); }

.code-content-wrap {
  white-space: pre-wrap;
  word-break: break-all;
  overflow-wrap: anywhere;
  color: var(--text-secondary);
}

/* Draggable Divider */
.slider-divider {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  z-index: 10;
  transform: translateX(-50%);
  pointer-events: none;
}

.divider-line {
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.85);
  box-shadow: 0 0 16px rgba(255, 255, 255, 0.35);
}

.slider-handle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--bg-elevated);
  border: 1px solid var(--border-hover);
  box-shadow: 0 0 24px rgba(255, 255, 255, 0.2), var(--surface-highlight);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: ew-resize;
  pointer-events: auto;
  transition: transform var(--duration-fast) var(--ease-out), box-shadow var(--duration-fast) var(--ease-out);
}

.slider-divider.dragging .slider-handle,
.slider-handle:hover {
  transform: translate(-50%, -50%) scale(1.08);
  box-shadow: 0 0 32px rgba(255, 255, 255, 0.35);
}

.handle-inner {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
}

.handle-grip-dots {
  display: flex;
  flex-direction: column;
  gap: 3px;
  margin: 0 1px;
}

.handle-grip-dots span {
  width: 2px;
  height: 2px;
  border-radius: 50%;
  background: #ffffff;
}

.handle-badge {
  position: absolute;
  bottom: -24px;
  font-family: var(--font-mono);
  font-size: 8px;
  font-weight: 600;
  letter-spacing: 0.12em;
  color: var(--text-muted);
  background: var(--bg-void);
  padding: 2px 6px;
  border-radius: 3px;
  border: 1px solid var(--border-subtle);
}

/* Bottombar */
.slider-bottombar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: var(--bg-surface);
  border-top: 1px solid var(--border-subtle);
  flex-wrap: wrap;
  gap: 10px;
}

.slider-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  color: var(--text-muted);
}

@media (max-width: 768px) {
  .slider-stage { height: 380px; }
  .line-gutter { width: 34px; padding: 12px 4px; }
  .code-content { padding: 12px 14px; font-size: 11px; }
  .slider-hint span { display: none; }
}
</style>
