<template>
  <transition name="modal">
    <div v-if="show" class="modal-backdrop" @click.self="handleClose">
      <div class="modal-card surface batch-modal">
        <!-- Close Button -->
        <button class="modal-close-btn" @click="handleClose" aria-label="Close modal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <div class="modal-header">
          <div class="header-tag">
            <span class="status-dot dot-cyan"></span>
            <span>BATCH OBFUSCATION STUDIO</span>
          </div>
          <h2 class="modal-title">Bulk Script Compiler</h2>
          <p class="modal-subtitle">
            Upload multiple scripts for sequential client-orchestrated compilation. Max limit for your <strong>{{ userPlan.toUpperCase() }}</strong> plan: <strong>{{ maxAllowedFiles }} files</strong>.
          </p>
        </div>

        <!-- Toolbar / Settings for Batch -->
        <div class="batch-toolbar surface-raised">
          <div class="config-item">
            <span class="config-label">PRESET</span>
            <select v-model="batchPreset" class="batch-select" :disabled="isProcessing">
              <option value="BALANCED">Balanced (Recommended)</option>
              <option value="HARD">Hard Anti-Tamper</option>
              <option value="EXTREME">Extreme Galois VM</option>
              <option value="PERFORMANCE">Performance (High FPS)</option>
              <option value="COMPATIBLE">Compatible (Universal)</option>
              <option value="MINIFY">Minify Only</option>
            </select>
          </div>

          <div class="config-item">
            <span class="config-label">RUNTIME</span>
            <div class="segmented-control">
              <button 
                class="seg-btn" 
                :class="{ active: batchRuntime === 'LuaU' }"
                @click="batchRuntime = 'LuaU'"
                :disabled="isProcessing"
              >
                Luau
              </button>
              <button 
                class="seg-btn" 
                :class="{ active: batchRuntime === 'Lua51' }"
                @click="batchRuntime = 'Lua51'"
                :disabled="isProcessing"
              >
                Lua 5.1
              </button>
            </div>
          </div>

          <div class="config-item">
            <span class="config-label">WATERMARK</span>
            <button 
              class="toggle-btn"
              :class="{ active: includeBanner }"
              @click="includeBanner = !includeBanner"
              :disabled="isProcessing"
            >
              {{ includeBanner ? 'Included' : 'Off' }}
            </button>
          </div>
        </div>

        <!-- Dropzone -->
        <div 
          v-if="filesQueue.length === 0"
          class="batch-dropzone surface-raised"
          :class="{ 'drag-over': isDragging }"
          @dragover.prevent="isDragging = true"
          @dragleave.prevent="isDragging = false"
          @drop.prevent="handleFilesDrop"
        >
          <div class="dropzone-icon">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
              <polyline points="17 8 12 3 7 8"></polyline>
              <line x1="12" y1="3" x2="12" y2="15"></line>
            </svg>
          </div>
          <h3 class="dropzone-title">Drop your Lua scripts or folder here</h3>
          <p class="dropzone-sub">
            Supports .lua, .luau, .txt files up to {{ maxAllowedFiles }} files per batch.
          </p>
          <label class="btn btn-accent btn-sm file-select-btn">
            <input type="file" multiple accept=".lua,.luau,.txt" @change="handleFilesSelect" hidden />
            <span>Select Files</span>
          </label>
        </div>

        <!-- Files Queue List -->
        <div v-else class="files-queue-wrap">
          <div class="queue-header">
            <span class="queue-meta">
              {{ filesQueue.length }} / {{ maxAllowedFiles }} files queued • 
              {{ completedCount }} completed • {{ failedCount }} failed
            </span>
            <div class="queue-actions">
              <label class="btn btn-ghost btn-xs" v-if="!isProcessing && filesQueue.length < maxAllowedFiles">
                <input type="file" multiple accept=".lua,.luau,.txt" @change="handleFilesSelect" hidden />
                <span>+ Add More</span>
              </label>
              <button class="btn btn-ghost btn-xs" @click="clearQueue" :disabled="isProcessing">
                Clear All
              </button>
            </div>
          </div>

          <!-- Overall Progress Bar -->
          <div class="overall-progress-bar-wrap" v-if="isProcessing || completedCount > 0">
            <div class="progress-bar-track">
              <div 
                class="progress-bar-fill" 
                :style="{ width: `${progressPercentage}%` }"
              ></div>
            </div>
            <div class="progress-labels">
              <span>Overall Progress</span>
              <span>{{ progressPercentage }}%</span>
            </div>
          </div>

          <!-- File Items Table -->
          <div class="queue-table-scroll">
            <div 
              v-for="(item, idx) in filesQueue" 
              :key="idx" 
              class="queue-item surface-raised"
              :class="`status-${item.status}`"
            >
              <div class="item-main">
                <div class="item-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                  </svg>
                </div>
                <div class="item-name-group">
                  <span class="item-filename">{{ item.file.name }}</span>
                  <span class="item-size">{{ formatBytes(item.file.size) }}</span>
                </div>
              </div>

              <div class="item-status-col">
                <span class="status-badge" :class="`badge-${item.status}`">
                  <span class="pulse-indicator" v-if="item.status === 'processing'">
                    <span class="dot-core"></span>
                    <span class="dot-ring"></span>
                  </span>
                  <span>{{ formatStatus(item.status) }}</span>
                </span>
                <span class="item-latency" v-if="item.durationMs">{{ item.durationMs }}ms</span>
                <span class="item-error" v-if="item.error" :title="item.error">
                  {{ item.error.substring(0, 30) }}...
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="modal-footer">
          <div class="footer-left">
            <span class="limit-indicator" v-if="filesQueue.length > maxAllowedFiles">
              ⚠️ Warning: You exceeded the {{ maxAllowedFiles }} files limit for your plan. Extra files will be skipped.
            </span>
          </div>
          <div class="footer-right">
            <button 
              v-if="isProcessing" 
              class="btn btn-secondary" 
              @click="cancelProcessing"
            >
              Stop Processing
            </button>
            <button 
              v-else-if="filesQueue.length > 0 && completedCount < filesQueue.length" 
              class="btn btn-accent btn-compile-batch" 
              @click="startBatchProcessing"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
              </svg>
              <span>Compile All Scripts ({{ filesQueue.length }})</span>
            </button>

            <!-- Download All ZIP Button -->
            <button 
              v-if="completedCount > 0" 
              class="btn btn-primary btn-zip" 
              @click="downloadZipBundle"
              :disabled="isZipping"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              <span>{{ isZipping ? 'Archiving...' : `Download ZIP (${completedCount})` }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import JSZip from 'jszip'
import { useUser } from '~/composables/useUser'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

const { user, showToast } = useUser()

const show = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const userPlan = computed(() => user.value?.plan || 'free')
const maxAllowedFiles = computed(() => {
  if (userPlan.value === 'ultra') return 100
  if (userPlan.value === 'pro') return 10
  return 1
})

interface BatchItem {
  file: File
  status: 'queued' | 'processing' | 'completed' | 'failed'
  output?: string
  durationMs?: number
  error?: string
}

const filesQueue = ref<BatchItem[]>([])
const isDragging = ref(false)
const isProcessing = ref(false)
const isZipping = ref(false)
const shouldCancel = ref(false)

const batchPreset = ref('BALANCED')
const batchRuntime = ref('LuaU')
const includeBanner = ref(true)

const completedCount = computed(() => filesQueue.value.filter(i => i.status === 'completed').length)
const failedCount = computed(() => filesQueue.value.filter(i => i.status === 'failed').length)
const progressPercentage = computed(() => {
  if (filesQueue.value.length === 0) return 0
  return Math.round(((completedCount.value + failedCount.value) / filesQueue.value.length) * 100)
})

const handleClose = () => {
  if (isProcessing.value) {
    if (!confirm('Obfuscation is in progress. Are you sure you want to close?')) return
    cancelProcessing()
  }
  show.value = false
}

const formatBytes = (bytes) => {
  if (bytes < 1024) return bytes + ' B'
  return (bytes / 1024).toFixed(1) + ' KB'
}

const formatStatus = (s) => {
  switch (s) {
    case 'queued': return 'Queued'
    case 'processing': return 'Processing...'
    case 'completed': return 'Completed'
    case 'failed': return 'Error'
    default: return s
  }
}

const addFiles = (files) => {
  const allowed = Array.from(files).filter((f) => 
    f.name.endsWith('.lua') || f.name.endsWith('.luau') || f.name.endsWith('.txt')
  )

  for (const f of allowed) {
    if (filesQueue.value.length < maxAllowedFiles.value) {
      filesQueue.value.push({
        file: f,
        status: 'queued'
      })
    }
  }

  if (files.length > maxAllowedFiles.value) {
    showToast(`Capped at ${maxAllowedFiles.value} files limit for your ${userPlan.value.toUpperCase()} plan.`, 'info')
  }
}

const handleFilesDrop = (e) => {
  isDragging.value = false
  if (e.dataTransfer?.files) {
    addFiles(e.dataTransfer.files)
  }
}

const handleFilesSelect = (e) => {
  const target = e.target
  if (target.files) {
    addFiles(target.files)
    target.value = ''
  }
}

const clearQueue = () => {
  filesQueue.value = []
}

const cancelProcessing = () => {
  shouldCancel.value = true
  isProcessing.value = false
}

const startBatchProcessing = async () => {
  if (filesQueue.value.length === 0) return
  isProcessing.value = true
  shouldCancel.value = false

  for (let i = 0; i < filesQueue.value.length; i++) {
    if (shouldCancel.value) break

    const item = filesQueue.value[i]
    if (item.status === 'completed') continue

    item.status = 'processing'

    try {
      const source = await item.file.text()
      const startTime = performance.now()

      const res = await $fetch<any>('/api/obfuscate', {
        method: 'POST',
        body: {
          source,
          filename: item.file.name,
          preset: batchPreset.value,
          luaVersion: batchRuntime.value,
          includeBanner: includeBanner.value
        }
      })

      const durationMs = Math.round((performance.now() - startTime) * 10) / 10

      if (res.ok) {
        item.status = 'completed'
        item.output = res.output
        item.durationMs = durationMs
      } else {
        item.status = 'failed'
        item.error = res.error || 'Compilation failed'
      }
    } catch (err) {
      item.status = 'failed'
      item.error = err?.data?.statusMessage || err?.message || 'Request failed'
    }
  }

  isProcessing.value = false
  if (completedCount.value > 0) {
    showToast(`Batch completed: ${completedCount.value} files compiled successfully!`, 'success')
  }
}

const downloadZipBundle = async () => {
  try {
    isZipping.value = true
    const zip = new JSZip()
    const folder = zip.folder('luavion_protected_scripts')

    for (const item of filesQueue.value) {
      if (item.status === 'completed' && item.output) {
        const outName = item.file.name.replace(/\.(lua|luau|txt)$/i, '') + '.protected.lua'
        folder.file(outName, item.output)
      }
    }

    const content = await zip.generateAsync({ type: 'blob' })
    const url = URL.createObjectURL(content)
    const a = document.createElement('a')
    a.href = url
    a.download = `Luavion_Batch_${Date.now()}.zip`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    showToast('Downloaded ZIP bundle successfully!', 'success')
  } catch (err) {
    console.error('ZIP generation failed:', err)
    showToast('Failed to create ZIP bundle', 'error')
  } finally {
    isZipping.value = false
  }
}
</script>

<style scoped>
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(5, 8, 14, 0.85);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.batch-modal {
  width: 100%;
  max-width: 680px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-lg);
  padding: 28px;
  position: relative;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
}

.modal-close-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  color: var(--text-muted);
  width: 30px;
  height: 30px;
  border-radius: var(--radius-xs);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.modal-close-btn:hover {
  color: var(--text-primary);
  border-color: var(--border-hover);
}

.header-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 700;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 6px;
}

.modal-title {
  font-size: 20px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 6px;
}

.modal-subtitle {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: 18px;
}

.batch-toolbar {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 12px 16px;
  border-radius: var(--radius-md);
  border: 1px solid var(--border-regular);
  margin-bottom: 18px;
  flex-wrap: wrap;
}

.config-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.config-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.batch-select {
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 12px;
  padding: 4px 8px;
  border-radius: var(--radius-xs);
}

.batch-dropzone {
  border: 2px dashed var(--border-regular);
  border-radius: var(--radius-md);
  padding: 48px 24px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all var(--duration-fast);
}
.batch-dropzone:hover,
.batch-dropzone.drag-over {
  border-color: var(--accent-cyan);
  background: var(--accent-cyan-dimmer);
}

.dropzone-icon {
  color: var(--accent-cyan);
  margin-bottom: 12px;
}

.dropzone-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 6px;
}

.dropzone-sub {
  font-size: 12px;
  color: var(--text-muted);
  margin-bottom: 16px;
}

.file-select-btn {
  cursor: pointer;
}

.files-queue-wrap {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  margin-bottom: 18px;
}

.queue-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.queue-meta {
  font-size: 12px;
  color: var(--text-secondary);
}

.queue-actions {
  display: flex;
  gap: 8px;
}

.overall-progress-bar-wrap {
  margin-bottom: 12px;
}

.progress-bar-track {
  height: 6px;
  background: var(--bg-surface-raised);
  border-radius: 999px;
  overflow: hidden;
  margin-bottom: 4px;
}

.progress-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #00f0ff, #10b981);
  transition: width 0.3s ease;
}

.progress-labels {
  display: flex;
  justify-content: space-between;
  font-size: 10px;
  color: var(--text-muted);
}

.queue-table-scroll {
  flex: 1;
  overflow-y: auto;
  max-height: 280px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-right: 4px;
}

.queue-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-radius: var(--radius-xs);
  border: 1px solid var(--border-subtle);
}

.item-main {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.item-icon {
  color: var(--text-muted);
  flex-shrink: 0;
}

.item-name-group {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.item-filename {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-size {
  font-size: 10px;
  color: var(--text-muted);
}

.item-status-col {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.status-badge {
  font-size: 10px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 3px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.badge-queued {
  background: rgba(255, 255, 255, 0.05);
  color: var(--text-muted);
}

.badge-processing {
  background: rgba(0, 240, 255, 0.1);
  color: var(--accent-cyan);
}

.badge-completed {
  background: rgba(16, 185, 129, 0.1);
  color: var(--status-emerald);
}

.badge-failed {
  background: rgba(244, 63, 94, 0.1);
  color: var(--status-crimson);
}

.item-latency {
  font-size: 11px;
  color: var(--text-muted);
}

.item-error {
  font-size: 10px;
  color: var(--status-crimson);
}

.modal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 14px;
  border-top: 1px solid var(--border-subtle);
}

.limit-indicator {
  font-size: 11px;
  color: var(--status-amber);
}

.footer-right {
  display: flex;
  gap: 10px;
}

.btn-zip {
  background: var(--status-emerald);
  color: var(--bg-void);
  font-weight: 600;
}
</style>
