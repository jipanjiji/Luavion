<template>
  <div class="history-page">
    <div class="history-container">
      <div class="history-header">
        <div class="header-left">
          <div class="history-tag">
            <span class="status-dot dot-cyan"></span>
            <span>CLOUD CODE VAULT</span>
          </div>
          <h1 class="history-title">Obfuscation History</h1>
          <p class="history-subtitle">
            Search, inspect, and re-download past compiled outputs stored securely in your workspace vault.
          </p>
        </div>

        <div class="header-right">
          <div class="retention-pill surface-raised">
            <span class="retention-label">PLAN RETENTION:</span>
            <span class="retention-val">{{ retentionDays > 0 ? `${retentionDays} Days Cloud Storage` : 'Ephemeral (Not Saved)' }}</span>
          </div>
        </div>
      </div>

      <!-- Free Plan Upsell Notice if history is 0 days -->
      <div v-if="retentionDays === 0" class="history-upsell-banner surface">
        <div class="banner-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
        </div>
        <div class="banner-text">
          <h3 class="banner-title">Cloud History is Disabled on the Free Plan</h3>
          <p class="banner-desc">
            Free tier obfuscations run in ephemeral memory and are not stored. Upgrade to <strong>Plus (7 days)</strong>, <strong>Pro (30 days)</strong>, or <strong>Ultra (90 days)</strong> to preserve outputs and re-download anytime.
          </p>
        </div>
        <NuxtLink to="/pricing" class="btn btn-accent btn-sm">
          Upgrade to Enable History
        </NuxtLink>
      </div>

      <!-- Filter & Search Toolbar -->
      <div class="history-toolbar surface">
        <div class="search-input-wrap">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="search-icon">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="Search by script filename..." 
            class="search-input"
          />
        </div>

        <div class="filter-group">
          <span class="filter-label">PRESET:</span>
          <select v-model="selectedPresetFilter" class="filter-select">
            <option value="ALL">All Presets</option>
            <option value="BALANCED">Balanced</option>
            <option value="HARD">Hard</option>
            <option value="EXTREME">Extreme</option>
            <option value="PERFORMANCE">Performance</option>
            <option value="COMPATIBLE">Compatible</option>
            <option value="MINIFY">Minify</option>
          </select>
        </div>
      </div>

      <!-- History Table -->
      <div class="history-table-card surface">
        <div v-if="loading" class="state-box">
          <span class="spinner"></span>
          <span>Loading historical compiler records...</span>
        </div>

        <div v-else-if="filteredHistory.length === 0" class="state-box">
          <p class="state-title">No obfuscations found</p>
          <p class="state-sub">
            {{ searchQuery ? 'Try adjusting your search criteria.' : 'Protected scripts will appear here once compiled in Studio.' }}
          </p>
          <NuxtLink to="/app" class="btn btn-secondary btn-sm" style="margin-top: 12px;">
            Launch Studio
          </NuxtLink>
        </div>

        <div v-else class="table-scroller">
          <table class="history-table">
            <thead>
              <tr>
                <th>Script Filename</th>
                <th>Security Preset</th>
                <th>Target Runtime</th>
                <th>Original Size</th>
                <th>Protected Size</th>
                <th>Ratio</th>
                <th>Latency</th>
                <th>Date Compiled</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in filteredHistory" :key="item.id">
                <td class="cell-filename">
                  <div class="file-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                      <polyline points="14 2 14 8 20 8"></polyline>
                    </svg>
                  </div>
                  <span class="filename-text">{{ item.filename }}</span>
                </td>
                <td>
                  <span class="badge badge-subtle">{{ item.preset }}</span>
                </td>
                <td>
                  <span class="runtime-tag">{{ item.lua_version }}</span>
                </td>
                <td>{{ formatBytes(item.original_bytes) }}</td>
                <td>{{ formatBytes(item.obfuscated_bytes) }}</td>
                <td>
                  <span class="ratio-text">{{ item.expansion_ratio }}x</span>
                </td>
                <td>{{ item.duration_ms }}ms</td>
                <td class="date-text">
                  {{ new Date(item.created_at).toLocaleDateString() }}
                </td>
                <td class="actions-cell">
                  <button class="btn btn-ghost btn-xs" @click="viewCodeModal(item)" title="Inspect Code">
                    View
                  </button>
                  <button class="btn btn-secondary btn-xs" @click="downloadScript(item)" title="Download .lua">
                    Download
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- View Code Inspection Modal -->
      <transition name="modal">
        <div v-if="viewModalItem" class="modal-backdrop" @click.self="viewModalItem = null">
          <div class="modal-card surface code-viewer-modal">
            <div class="viewer-header">
              <div class="viewer-meta">
                <span class="viewer-title">{{ viewModalItem.filename }}</span>
                <span class="badge badge-cyan">{{ viewModalItem.preset }}</span>
                <span class="telemetry-tag">{{ formatBytes(viewModalItem.obfuscated_bytes) }}</span>
              </div>
              <button class="modal-close-btn" @click="viewModalItem = null">✕</button>
            </div>
            <div class="viewer-body">
              <textarea 
                class="code-textarea" 
                readonly 
                spellcheck="false" 
                :value="modalCodeContent"
              ></textarea>
            </div>
            <div class="viewer-footer">
              <button class="btn btn-secondary btn-sm" @click="copyModalCode">
                {{ modalCopied ? 'Copied!' : 'Copy to Clipboard' }}
              </button>
              <button class="btn btn-accent btn-sm" @click="downloadScript(viewModalItem)">
                Download .lua
              </button>
            </div>
          </div>
        </div>
      </transition>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'dashboard' })
import { ref, computed, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const { showToast } = useUser()

const loading = ref(true)
const history = ref([])
const retentionDays = ref(30)
const searchQuery = ref('')
const selectedPresetFilter = ref('ALL')

const viewModalItem = ref(null)
const modalCodeContent = ref('')
const modalCopied = ref(false)

useHead({
  title: 'Obfuscation History | Luavion Cloud Vault',
  meta: [
    { name: 'description', content: 'Search and re-download past Luavion compiled scripts stored in your persistent cloud code vault.' }
  ]
})

const formatBytes = (b) => {
  if (!b) return '0 B'
  if (b < 1024) return b + ' B'
  return (b / 1024).toFixed(1) + ' KB'
}

const loadHistory = async () => {
  try {
    loading.value = true
    const res = await $fetch('/api/history')
    history.value = res.history || []
    retentionDays.value = res.retentionDays !== undefined ? res.retentionDays : 30
  } catch (err) {
    console.error('Failed to load history:', err)
  } finally {
    loading.value = false
  }
}

const filteredHistory = computed(() => {
  return history.value.filter((item) => {
    const matchSearch = !searchQuery.value || item.filename.toLowerCase().includes(searchQuery.value.toLowerCase())
    const matchPreset = selectedPresetFilter.value === 'ALL' || item.preset === selectedPresetFilter.value
    return matchSearch && matchPreset
  })
})

const downloadScript = async (item) => {
  try {
    const res = await $fetch(`/api/history/${item.id}`)
    if (res?.item?.obfuscated_code) {
      const blob = new Blob([res.item.obfuscated_code], { type: 'text/plain;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = item.filename.replace(/\.lua$/i, '') + '.protected.lua'
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
      showToast('Downloaded protected file', 'success')
    } else {
      showToast('Script payload has expired based on plan retention policy.', 'info')
    }
  } catch (err) {
    showToast('Failed to download script', 'error')
  }
}

const viewCodeModal = async (item) => {
  viewModalItem.value = item
  modalCodeContent.value = 'Fetching code from cloud storage...'
  try {
    const res = await $fetch(`/api/history/${item.id}`)
    modalCodeContent.value = res?.item?.obfuscated_code || '-- Code expired'
  } catch (err) {
    modalCodeContent.value = '-- Failed to fetch code'
  }
}

const copyModalCode = async () => {
  if (!modalCodeContent.value) return
  await navigator.clipboard.writeText(modalCodeContent.value)
  modalCopied.value = true
  showToast('Copied to clipboard', 'success')
  setTimeout(() => { modalCopied.value = false }, 2000)
}

onMounted(() => {
  loadHistory()
})
</script>

<style scoped>
.history-page {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  flex-wrap: wrap;
  gap: 20px;
}

.history-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.history-title {
  font-size: 26px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.history-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

.retention-pill {
  border: 1px solid var(--border-regular);
  padding: 6px 14px;
  border-radius: var(--radius-xs);
  display: flex;
  align-items: center;
  gap: 8px;
}

.retention-label {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
}

.retention-val {
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-cyan);
}

/* Upsell Banner */
.history-upsell-banner {
  display: flex;
  align-items: center;
  gap: 20px;
  border: 1px solid rgba(245, 158, 11, 0.4);
  background: rgba(245, 158, 11, 0.08);
  border-radius: var(--radius-md);
  padding: 20px 24px;
  margin-bottom: 28px;
  flex-wrap: wrap;
}

.banner-icon {
  color: #fbbf24;
}

.banner-text {
  flex: 1;
  min-width: 240px;
}

.banner-title {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 4px;
}

.banner-desc {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.5;
}

/* Toolbar */
.history-toolbar {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 12px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.search-input-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
  min-width: 220px;
}

.search-icon {
  color: var(--text-muted);
}

.search-input {
  width: 100%;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-family: inherit;
  font-size: 12px;
}
.search-input:focus {
  outline: none;
}

.filter-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
}

.filter-select {
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 11px;
  padding: 4px 8px;
  border-radius: var(--radius-xs);
}

/* History Table */
.history-table-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.state-box {
  padding: 64px 20px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.state-title {
  font-size: 15px;
  font-weight: 600;
  color: #ffffff;
}

.state-sub {
  font-size: 12px;
  color: var(--text-muted);
}

.table-scroller {
  overflow-x: auto;
}

.history-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.history-table th,
.history-table td {
  padding: 12px 14px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
  white-space: nowrap;
}

.history-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.cell-filename {
  display: flex;
  align-items: center;
  gap: 8px;
}

.file-icon {
  color: var(--text-muted);
}

.filename-text {
  font-weight: 500;
  color: #ffffff;
}

.runtime-tag {
  font-size: 10px;
  color: var(--text-secondary);
}

.ratio-text {
  color: var(--status-emerald);
  font-weight: 600;
}

.date-text {
  color: var(--text-muted);
  font-size: 11px;
}

.actions-cell {
  display: flex;
  gap: 6px;
}

/* Code Viewer Modal */
.code-viewer-modal {
  width: 100%;
  max-width: 680px;
  height: 75vh;
  display: flex;
  flex-direction: column;
  padding: 24px;
}

.viewer-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.viewer-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.viewer-title {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

.viewer-body {
  flex: 1;
  background: #04060a;
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-xs);
  overflow: hidden;
  margin-bottom: 16px;
}

.viewer-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* Detail modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background: rgba(6, 6, 7, 0.72);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-card {
  max-height: calc(100vh - 40px);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

@media (max-width: 560px) {
  .modal-backdrop { padding: 0; align-items: flex-end; }
  .modal-backdrop .modal-card {
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
    max-height: 92vh;
    border-bottom: none;
    width: 100% !important;
  }
}
</style>
