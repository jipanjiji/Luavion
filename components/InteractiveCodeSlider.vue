<template>
  <div class="code-slider-card surface">
    <!-- Header with sample selectors and mode indicator -->
    <div class="slider-topbar">
      <div class="sample-tabs">
        <span class="sample-label">SAMPLE SCRIPT:</span>
        <button 
          v-for="(sample, key) in samples" 
          :key="key"
          class="sample-tab-btn"
          :class="{ 'active': activeSample === key }"
          @click="activeSample = key"
        >
          {{ sample.name }}
        </button>
      </div>

      <div class="slider-telemetry">
        <div class="telemetry-badge">
          <span class="dot-indicator"></span>
          <span>SPLIT {{ sliderPos }}%</span>
        </div>
        <button class="btn btn-ghost btn-sm reset-btn" @click="sliderPos = 50" title="Reset split to 50%">
          Center
        </button>
      </div>
    </div>

    <!-- Interactive Comparison Stage -->
    <div 
      class="slider-stage" 
      ref="stageRef"
      @mousedown="startDrag"
      @touchstart="startDrag"
    >
      <!-- Base Layer: Obfuscated Luavion Bytecode (Revealed on Right) -->
      <div class="slider-pane pane-right">
        <div class="pane-tag tag-obfuscated">
          <span class="status-dot dot-cyan"></span>
          <span>LUAVION V9.15 VIRTUAL MACHINE</span>
          <span class="badge badge-cyan">PROTECTED</span>
        </div>
        <div class="code-container">
          <div class="line-gutter">
            <span v-for="n in rightLineCount" :key="n" class="gutter-num">{{ n }}</span>
          </div>
          <pre class="code-content"><code><span class="syntax-comment">--[[ [ LUAVION V9.15 ] — High-Assurance Luau Register VM ]]</span>
<span class="syntax-keyword">return</span>((<span class="syntax-keyword">function</span>(...)
  <span class="syntax-keyword">local</span> _vAttest = Vector3.new(3, 4, 0).Magnitude <span class="syntax-comment">-- Geometric Attestation</span>
  <span class="syntax-keyword">local</span> _seed = math.floor(_vAttest * 1000) % 16777141
  <span class="syntax-keyword">local</span> _lookup = {[140]=getmetatable, [55]=(buffer <span class="syntax-keyword">and</span> buffer.create <span class="syntax-keyword">or</span> table.create)}
  <span class="syntax-keyword">local</span> <span class="syntax-func">_GaloisDispatch</span> = (<span class="syntax-keyword">function</span>(Ji, gi, ui, ai, Ti, yi, hi, bi, wi, mi)
    <span class="syntax-keyword">for</span> dA = 1, #Ji, 1 <span class="syntax-keyword">do</span>
      <span class="syntax-keyword">local</span> nA = Ji[dA]; <span class="syntax-keyword">local</span> IA = nA[1]; <span class="syntax-keyword">local</span> pA = nA[2];
      <span class="syntax-keyword">if</span> IA == 13 <span class="syntax-keyword">then</span>
        si[pA] = wi(Ni, Ti, ((oA + GA * 256)) + 1)
      <span class="syntax-keyword">elseif</span> IA == 12 <span class="syntax-keyword">and</span> DA == ii <span class="syntax-keyword">then</span>
        di(gi, ui, ai, pA, wi(ii, yi, BA))
      <span class="syntax-keyword">elseif</span> IA == 2 <span class="syntax-keyword">then</span>
        si[pA] = si[oA][si[GA]]
      <span class="syntax-keyword">elseif</span> IA == 4 <span class="syntax-keyword">then</span>
        wi(Li, pA, oA, GA, gi, ui, ai, bi, eA)
      <span class="syntax-keyword">end</span>
    <span class="syntax-keyword">end</span>
  <span class="syntax-keyword">end</span>)
  <span class="syntax-keyword">return</span> (ri(ei))(Xi, ci, ji, <span class="syntax-keyword">false</span>, ...);
<span class="syntax-keyword">end</span>))(...);</code></pre>
        </div>
      </div>

      <!-- Top Clipped Layer: Raw Vulnerable Source (Revealed on Left) -->
      <div 
        class="slider-pane pane-left" 
        :style="{ clipPath: `inset(0 ${100 - sliderPos}% 0 0)` }"
      >
        <div class="pane-tag tag-raw">
          <span class="status-dot dot-amber"></span>
          <span>RAW LUAU SOURCE</span>
          <span class="badge badge-amber">VULNERABLE AST</span>
        </div>
        <div class="code-container">
          <div class="line-gutter">
            <span v-for="n in leftLineCount" :key="n" class="gutter-num">{{ n }}</span>
          </div>
          <pre class="code-content"><code v-html="currentSample.highlightedHtml"></code></pre>
        </div>
      </div>

      <!-- Draggable Split Divider Line & Thumb -->
      <div 
        class="slider-divider" 
        :style="{ left: `${sliderPos}%` }"
        :class="{ 'dragging': isDragging }"
      >
        <div class="divider-line"></div>
        <div class="slider-handle" title="Drag to compare before & after">
          <div class="handle-inner">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            <div class="handle-grip-dots">
              <span></span>
              <span></span>
            </div>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
          </div>
          <div class="handle-badge">
            <span>DRAG</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Bottom Controls & Hints -->
    <div class="slider-bottombar">
      <div class="slider-hint">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="16" x2="12" y2="12"></line>
          <line x1="12" y1="8" x2="12.01" y2="8"></line>
        </svg>
        <span>Drag the slider handle to contrast original AST vs. decentralized VM bytecode.</span>
      </div>

      <div class="slider-actions">
        <NuxtLink to="/app" class="btn btn-accent btn-sm">
          <span>Test in Studio</span>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="5" y1="12" x2="19" y2="12"></line>
            <polyline points="12 5 19 12 12 19"></polyline>
          </svg>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const stageRef = ref(null)
const sliderPos = ref(48) // Percentage (0-100)
const isDragging = ref(false)
const activeSample = ref('auth')

const samples = {
  auth: {
    name: 'Auth & License Key',
    rawCode: `local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function verifyLicense(authKey)
    local secretHash = "9d8e7c6b5a4f3e2d1c0b9a8"
    if authKey == secretHash then
        print("[Luavion] Authorized access for user: " .. LocalPlayer.Name)
        return true
    else
        LocalPlayer:Kick("Invalid License Key")
        return false
    end
end

verifyLicense("9d8e7c6b5a4f3e2d1c0b9a8")`,
    highlightedHtml: `<span class="syntax-keyword">local</span> HttpService = game:<span class="syntax-func">GetService</span>(<span class="syntax-str">"HttpService"</span>)
<span class="syntax-keyword">local</span> Players = game:<span class="syntax-func">GetService</span>(<span class="syntax-str">"Players"</span>)
<span class="syntax-keyword">local</span> LocalPlayer = Players.LocalPlayer

<span class="syntax-keyword">local function</span> <span class="syntax-func">verifyLicense</span>(authKey)
    <span class="syntax-keyword">local</span> secretHash = <span class="syntax-str">"9d8e7c6b5a4f3e2d1c0b9a8"</span>
    <span class="syntax-keyword">if</span> authKey == secretHash <span class="syntax-keyword">then</span>
        print(<span class="syntax-str">"[Luavion] Authorized access for user: "</span> .. LocalPlayer.Name)
        <span class="syntax-keyword">return true</span>
    <span class="syntax-keyword">else</span>
        LocalPlayer:<span class="syntax-func">Kick</span>(<span class="syntax-str">"Invalid License Key"</span>)
        <span class="syntax-keyword">return false</span>
    <span class="syntax-keyword">end</span>
<span class="syntax-keyword">end</span>

<span class="syntax-func">verifyLicense</span>(<span class="syntax-str">"9d8e7c6b5a4f3e2d1c0b9a8"</span>)`
  },
  combat: {
    name: 'Combat Autofarm Loop',
    rawCode: `local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Enemies = Workspace:WaitForChild("Enemies")

local function getClosestTarget(range)
    local closest, maxDist = nil, range or 50
    for _, mob in ipairs(Enemies:GetChildren()) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root then
            local dist = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist < maxDist then
                closest, maxDist = mob, dist
            end
        end
    end
    return closest
end`,
    highlightedHtml: `<span class="syntax-keyword">local</span> Workspace = game:<span class="syntax-func">GetService</span>(<span class="syntax-str">"Workspace"</span>)
<span class="syntax-keyword">local</span> RunService = game:<span class="syntax-func">GetService</span>(<span class="syntax-str">"RunService"</span>)
<span class="syntax-keyword">local</span> Enemies = Workspace:<span class="syntax-func">WaitForChild</span>(<span class="syntax-str">"Enemies"</span>)

<span class="syntax-keyword">local function</span> <span class="syntax-func">getClosestTarget</span>(range)
    <span class="syntax-keyword">local</span> closest, maxDist = <span class="syntax-keyword">nil</span>, range <span class="syntax-keyword">or</span> <span class="syntax-number">50</span>
    <span class="syntax-keyword">for</span> _, mob <span class="syntax-keyword">in</span> <span class="syntax-func">ipairs</span>(Enemies:<span class="syntax-func">GetChildren</span>()) <span class="syntax-keyword">do</span>
        <span class="syntax-keyword">local</span> root = mob:<span class="syntax-func">FindFirstChild</span>(<span class="syntax-str">"HumanoidRootPart"</span>)
        <span class="syntax-keyword">if</span> root <span class="syntax-keyword">then</span>
            <span class="syntax-keyword">local</span> dist = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            <span class="syntax-keyword">if</span> dist &lt; maxDist <span class="syntax-keyword">then</span>
                closest, maxDist = mob, dist
            <span class="syntax-keyword">end</span>
        <span class="syntax-keyword">end</span>
    <span class="syntax-keyword">end</span>
    <span class="syntax-keyword">return</span> closest
<span class="syntax-keyword">end</span>`
  },
  rayfield: {
    name: 'Rayfield / Fluent GUI Hook',
    rawCode: `local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Luavion Secure Hub v9.15",
    LoadingTitle = "Decrypting Galois Keystream...",
    ConfigurationSaving = { Enabled = true, FolderName = "LuavionCfg" }
})
local Tab = Window:CreateTab("Automation", 4483362458)
Tab:CreateToggle({
    Name = "Infinite Jump & Noclip",
    CurrentValue = false,
    Callback = function(Value)
        print("Toggled Noclip: ", Value)
    end
})`,
    highlightedHtml: `<span class="syntax-keyword">local</span> Rayfield = <span class="syntax-func">loadstring</span>(game:<span class="syntax-func">HttpGet</span>(<span class="syntax-str">'https://sirius.menu/rayfield'</span>))()
<span class="syntax-keyword">local</span> Window = Rayfield:<span class="syntax-func">CreateWindow</span>({
    Name = <span class="syntax-str">"Luavion Secure Hub v9.15"</span>,
    LoadingTitle = <span class="syntax-str">"Decrypting Galois Keystream..."</span>,
    ConfigurationSaving = { Enabled = <span class="syntax-keyword">true</span>, FolderName = <span class="syntax-str">"LuavionCfg"</span> }
})
<span class="syntax-keyword">local</span> Tab = Window:<span class="syntax-func">CreateTab</span>(<span class="syntax-str">"Automation"</span>, <span class="syntax-number">4483362458</span>)
Tab:<span class="syntax-func">CreateToggle</span>({
    Name = <span class="syntax-str">"Infinite Jump &amp; Noclip"</span>,
    CurrentValue = <span class="syntax-keyword">false</span>,
    Callback = <span class="syntax-keyword">function</span>(Value)
        print(<span class="syntax-str">"Toggled Noclip: "</span>, Value)
    <span class="syntax-keyword">end</span>
})`
  }
}

const currentSample = computed(() => samples[activeSample.value])
const leftLineCount = computed(() => currentSample.value.rawCode.split('\n').length)
const rightLineCount = computed(() => 21)

const updatePosFromEvent = (e) => {
  if (!stageRef.value) return
  const rect = stageRef.value.getBoundingClientRect()
  const clientX = e.touches ? e.touches[0].clientX : e.clientX
  const relativeX = clientX - rect.left
  let percentage = (relativeX / rect.width) * 100
  percentage = Math.max(8, Math.min(92, percentage))
  sliderPos.value = Math.round(percentage * 10) / 10
}

const startDrag = (e) => {
  isDragging.value = true
  updatePosFromEvent(e)
  window.addEventListener('mousemove', onDrag)
  window.addEventListener('touchmove', onDrag, { passive: false })
  window.addEventListener('mouseup', stopDrag)
  window.addEventListener('touchend', stopDrag)
}

const onDrag = (e) => {
  if (!isDragging.value) return
  if (e.cancelable) e.preventDefault()
  updatePosFromEvent(e)
}

const stopDrag = () => {
  isDragging.value = false
  window.removeEventListener('mousemove', onDrag)
  window.removeEventListener('touchmove', onDrag)
  window.removeEventListener('mouseup', stopDrag)
  window.removeEventListener('touchend', stopDrag)
}

onUnmounted(() => {
  stopDrag()
})
</script>

<style scoped>
.code-slider-card {
  overflow: hidden;
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-subtle);
  background: var(--bg-surface);
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.6), var(--surface-highlight);
}

/* Topbar */
.slider-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 18px;
  background: var(--bg-surface-raised);
  border-bottom: 1px solid var(--border-subtle);
  flex-wrap: wrap;
  gap: 12px;
}

.sample-tabs {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.sample-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.sample-tab-btn {
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  background: transparent;
  color: var(--text-secondary);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all var(--duration-fast);
}

.sample-tab-btn:hover {
  color: #ffffff;
  background: rgba(255, 255, 255, 0.05);
}

.sample-tab-btn.active {
  background: var(--bg-elevated);
  color: var(--accent-cyan);
  border-color: var(--accent-cyan-border);
  box-shadow: 0 0 12px rgba(0, 240, 255, 0.12);
}

.slider-telemetry {
  display: flex;
  align-items: center;
  gap: 8px;
}

.telemetry-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: var(--radius-xs);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  letter-spacing: 0.04em;
}

.dot-indicator {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--accent-cyan);
  box-shadow: 0 0 6px var(--accent-cyan);
}

.reset-btn {
  font-size: 10px;
  padding: 3px 7px;
  height: auto;
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

.pane-right {
  z-index: 1;
  background: radial-gradient(circle at 80% 20%, rgba(0, 240, 255, 0.03), transparent 60%), var(--bg-base);
}

.pane-left {
  z-index: 2;
  background: radial-gradient(circle at 20% 20%, rgba(245, 158, 11, 0.03), transparent 60%), var(--bg-base);
}

.pane-tag {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 18px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  border-bottom: 1px solid var(--border-faint);
  background: rgba(14, 20, 34, 0.5);
  backdrop-filter: blur(8px);
}

.tag-raw {
  color: var(--status-amber);
}

.tag-obfuscated {
  color: var(--accent-cyan);
}

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
  background: rgba(0, 0, 0, 0.2);
  border-right: 1px solid var(--border-faint);
  user-select: none;
}

.gutter-num {
  font-size: 11px;
  height: 20.4px;
}

.code-content {
  flex: 1;
  padding: 16px 20px;
  overflow: hidden;
  white-space: pre;
  tab-size: 2;
}

.code-content code {
  font-family: var(--font-mono);
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
  background: linear-gradient(180deg, var(--accent-cyan), #ffffff 50%, var(--accent-cyan));
  box-shadow: 0 0 12px var(--accent-cyan);
}

.slider-handle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--bg-surface-raised);
  border: 1px solid var(--accent-cyan);
  box-shadow: 0 0 20px rgba(0, 240, 255, 0.35), var(--surface-highlight);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: ew-resize;
  pointer-events: auto;
  transition: transform var(--duration-fast), box-shadow var(--duration-fast);
}

.slider-divider.dragging .slider-handle,
.slider-handle:hover {
  transform: translate(-50%, -50%) scale(1.1);
  box-shadow: 0 0 28px rgba(0, 240, 255, 0.55);
}

.handle-inner {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-cyan);
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
  bottom: -22px;
  font-size: 8px;
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--accent-cyan);
  background: var(--bg-void);
  padding: 1px 5px;
  border-radius: 3px;
  border: 1px solid var(--accent-cyan-border);
}

/* Bottombar */
.slider-bottombar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 18px;
  background: var(--bg-surface-raised);
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
  .slider-stage {
    height: 380px;
  }
  .line-gutter {
    width: 34px;
    padding: 12px 4px;
  }
  .code-content {
    padding: 12px 14px;
    font-size: 11px;
  }
  .slider-hint span {
    display: none;
  }
}
</style>
