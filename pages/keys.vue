<template>
  <div class="keys-page">
    <div class="keys-container">
      <div class="keys-header">
        <div class="header-left">
          <div class="keys-tag">
            <span class="status-dot dot-cyan"></span>
            <span>DEVELOPER CREDENTIALS</span>
          </div>
          <h1 class="keys-title">API Key Management</h1>
          <p class="keys-subtitle">
            Create and revoke programmatic REST API keys for CI/CD pipelines, build tools, and automated compilation.
          </p>
        </div>

        <div class="header-right">
          <NuxtLink to="/docs/api" class="btn btn-secondary btn-sm">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
              <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            <span>View REST Documentation</span>
          </NuxtLink>
        </div>
      </div>

      <!-- Locked State Banner (for Free, Plus, Pro) -->
      <div v-if="user?.plan !== 'ultra'" class="ultra-lock-banner surface">
        <div class="lock-graphic">
          <div class="lock-icon-circle">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
            </svg>
          </div>
        </div>
        <div class="lock-content">
          <span class="badge badge-ultra">ULTRA TIER EXCLUSIVE</span>
          <h2 class="lock-title">Programmatic REST API Access is Locked</h2>
          <p class="lock-desc">
            Public API access and secret Bearer tokens are reserved exclusively for the <strong>Ultra Plan</strong> ($30/mo or Rp 500,000/mo). Upgrade today to unlock 7,500 monthly obfuscations, 60 req/min rate limit, webhook notifications, and automated CI/CD integration.
          </p>
          <div class="lock-actions">
            <NuxtLink to="/pricing" class="btn btn-accent btn-upgrade">
              <span>Upgrade to Ultra Plan</span>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
              </svg>
            </NuxtLink>
            <NuxtLink to="/docs/api" class="btn btn-secondary">
              Browse API Endpoints
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Unlocked Ultra Key Dashboard -->
      <div v-else class="keys-dashboard-wrap">
        <div class="surface keys-toolbar">
          <div class="keys-info">
            <span class="info-title">Active API Keys ({{ keys.length }})</span>
            <span class="info-sub">Ultra rate limit: 60 req/min • 5,000 requests/day</span>
          </div>

          <button class="btn btn-accent btn-sm" @click="showCreateModal = true">
            + Generate New API Key
          </button>
        </div>

        <div class="surface keys-table-card">
          <div v-if="loading" class="state-box">
            <span class="spinner"></span>
            <span>Loading API credentials...</span>
          </div>

          <div v-else-if="keys.length === 0" class="state-box">
            <p class="state-title">No API keys created yet</p>
            <p class="state-sub">Generate a key to authenticate your CI/CD builds.</p>
            <button class="btn btn-accent btn-sm" style="margin-top: 12px;" @click="showCreateModal = true">
              Generate First Key
            </button>
          </div>

          <div v-else class="table-scroller">
            <table class="keys-table">
              <thead>
                <tr>
                  <th>Key Name</th>
                  <th>Key Token</th>
                  <th>Rate Limit</th>
                  <th>Status</th>
                  <th>Last Used</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="k in keys" :key="k.id">
                  <td class="font-bold">{{ k.name }}</td>
                  <td>
                    <code class="masked-key">{{ k.key_prefix }}</code>
                  </td>
                  <td>{{ k.rate_limit_per_minute }} req/min</td>
                  <td>
                    <span class="badge" :class="k.is_active ? 'badge-emerald' : 'badge-subtle'">
                      {{ k.is_active ? 'ACTIVE' : 'REVOKED' }}
                    </span>
                  </td>
                  <td class="text-muted">
                    {{ k.last_used_at ? new Date(k.last_used_at).toLocaleDateString() : 'Never' }}
                  </td>
                  <td class="text-muted">
                    {{ new Date(k.created_at).toLocaleDateString() }}
                  </td>
                  <td>
                    <button 
                      class="btn btn-ghost btn-xs btn-revoke" 
                      @click="promptRevokeKey(k)"
                    >
                      Revoke
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Create Key Modal -->
      <transition name="modal">
        <div v-if="showCreateModal" class="modal-backdrop" @click.self="showCreateModal = false">
          <div class="modal-card surface create-key-modal">
            <div class="modal-header">
              <h2 class="modal-title">Generate API Key</h2>
              <p class="modal-subtitle">
                Create a secret credential to authenticate REST calls.
              </p>
            </div>

            <div class="form-body">
              <label class="form-label">Key Name / Identifier:</label>
              <input 
                type="text" 
                v-model="newKeyName" 
                placeholder="e.g. GitHub Actions Release" 
                class="form-input"
              />
            </div>

            <div class="modal-footer">
              <button class="btn btn-secondary" @click="showCreateModal = false">
                Cancel
              </button>
              <button 
                class="btn btn-accent" 
                @click="executeCreateKey"
                :disabled="creatingKey || !newKeyName.trim()"
              >
                {{ creatingKey ? 'Generating...' : 'Create Key' }}
              </button>
            </div>
          </div>
        </div>
      </transition>

      <!-- View Plaintext Secret Once Modal -->
      <transition name="modal">
        <div v-if="newlyCreatedKeySecret" class="modal-backdrop">
          <div class="modal-card surface secret-display-modal">
            <div class="modal-header">
              <span class="badge badge-emerald">KEY GENERATED SUCCESSFULLY</span>
              <h2 class="modal-title">Save Your Secret API Key</h2>
              <p class="modal-subtitle">
                Please copy and store your API key in a secure vault now. <strong>You will not be able to view this key again.</strong>
              </p>
            </div>

            <div class="secret-box surface-raised">
              <code class="secret-token">{{ newlyCreatedKeySecret }}</code>
              <button class="btn btn-secondary btn-sm" @click="copySecret">
                {{ secretCopied ? 'Copied!' : 'Copy Key' }}
              </button>
            </div>

            <div class="modal-footer">
              <button class="btn btn-accent" @click="newlyCreatedKeySecret = ''">
                I Have Saved My Key
              </button>
            </div>
          </div>
        </div>
      </transition>

      <!-- Revoke Confirmation 2FA Modal -->
      <TwoFactorModal 
        v-model="showRevokeModal"
        title="Revoke API Key"
        :message="`Are you sure you want to revoke '${selectedKeyToRevoke?.name}'? Any CI/CD pipeline or build tool using this key will immediately fail.`"
        requiredPhrase="REVOKE-API-KEY"
        @confirm="executeRevokeKey"
      />
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'dashboard' })
import { ref, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const { user, showToast } = useUser()

const loading = ref(true)
const keys = ref([])
const showCreateModal = ref(false)
const creatingKey = ref(false)
const newKeyName = ref('')
const newlyCreatedKeySecret = ref('')
const secretCopied = ref(false)

const showRevokeModal = ref(false)
const selectedKeyToRevoke = ref(null)

useHead({
  title: 'API Keys | Luavion Ultra Platform',
  meta: [
    { name: 'description', content: 'Generate and revoke REST API keys for Luavion Ultra plan automated compilation pipelines.' }
  ]
})

const loadKeys = async () => {
  try {
    loading.value = true
    const res = await $fetch('/api/keys')
    keys.value = res.keys || []
  } catch (err) {
    console.error('Failed to load API keys:', err)
  } finally {
    loading.value = false
  }
}

const executeCreateKey = async () => {
  if (!newKeyName.value.trim()) return
  try {
    creatingKey.value = true
    const res = await $fetch('/api/keys/create', {
      method: 'POST',
      body: { name: newKeyName.value }
    })
    if (res.ok) {
      showCreateModal.value = false
      newKeyName.value = ''
      newlyCreatedKeySecret.value = res.secretKey
      await loadKeys()
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Failed to generate key', 'error')
  } finally {
    creatingKey.value = false
  }
}

const copySecret = async () => {
  if (!newlyCreatedKeySecret.value) return
  await navigator.clipboard.writeText(newlyCreatedKeySecret.value)
  secretCopied.value = true
  showToast('API key copied to clipboard!', 'success')
  setTimeout(() => { secretCopied.value = false }, 2000)
}

const promptRevokeKey = (key) => {
  selectedKeyToRevoke.value = key
  showRevokeModal.value = true
}

const executeRevokeKey = async () => {
  if (!selectedKeyToRevoke.value) return
  try {
    const res = await $fetch(`/api/keys/${selectedKeyToRevoke.value.id}`, { method: 'DELETE' })
    if (res.ok) {
      showToast('API key revoked successfully', 'info')
      await loadKeys()
    }
  } catch (err) {
    showToast('Failed to revoke API key', 'error')
  } finally {
    selectedKeyToRevoke.value = null
  }
}

onMounted(() => {
  loadKeys()
})
</script>

<style scoped>
.keys-page {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.keys-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  flex-wrap: wrap;
  gap: 20px;
}

.keys-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.keys-title {
  font-size: 26px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.keys-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

/* Locked Ultra Banner */
.ultra-lock-banner {
  border: 1px solid rgba(168, 85, 247, 0.4);
  background: rgba(168, 85, 247, 0.06);
  border-radius: var(--radius-md);
  padding: 40px;
  display: flex;
  gap: 32px;
  align-items: flex-start;
}

.lock-icon-circle {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: rgba(168, 85, 247, 0.15);
  border: 1px solid rgba(168, 85, 247, 0.4);
  color: #c084fc;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.lock-title {
  font-size: 22px;
  font-weight: 600;
  color: #ffffff;
  margin: 10px 0 8px;
}

.lock-desc {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
  max-width: 600px;
  margin-bottom: 24px;
}

.lock-actions {
  display: flex;
  gap: 12px;
}

.btn-upgrade {
  background: linear-gradient(135deg, #a855f7, var(--accent));
  color: var(--bg-void);
  font-weight: 600;
  border: none;
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Unlocked Keys Dashboard */
.keys-dashboard-wrap {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.keys-toolbar {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.info-title {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

.info-sub {
  font-size: 11px;
  color: var(--text-muted);
}

.keys-table-card {
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

.keys-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.keys-table th,
.keys-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
  white-space: nowrap;
}

.keys-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.masked-key {
  color: var(--accent-cyan);
  background: var(--bg-surface-raised);
  padding: 3px 8px;
  border-radius: 4px;
}

.btn-revoke {
  color: var(--status-crimson);
}

/* Modals */
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
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-lg);
  box-shadow: var(--surface-highlight), var(--shadow-lg);
  max-height: calc(100vh - 40px);
  overflow-y: auto;
}

.modal-enter-active { transition: opacity 200ms var(--ease-out); }
.modal-leave-active { transition: opacity 150ms var(--ease-out); }
.modal-enter-active .modal-card {
  transition: opacity 250ms var(--ease-spring), transform 250ms var(--ease-spring);
}
.modal-leave-active .modal-card {
  transition: opacity 150ms var(--ease-out), transform 150ms var(--ease-out);
}
.modal-enter-from, .modal-leave-to { opacity: 0; }
.modal-enter-from .modal-card { opacity: 0; transform: scale(0.96) translateY(10px); }
.modal-leave-to .modal-card { opacity: 0; transform: scale(0.97) translateY(6px); }

@media (max-width: 560px) {
  .modal-backdrop { padding: 0; align-items: flex-end; }
  .modal-backdrop .modal-card {
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
    max-height: 92vh;
    border-bottom: none;
  }
}

.create-key-modal,
.secret-display-modal {
  width: 100%;
  max-width: 500px;
  padding: 28px;
}

.form-body {
  margin: 18px 0 24px;
}

.form-label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.form-input {
  width: 100%;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 13px;
  padding: 8px 12px;
  border-radius: var(--radius-xs);
}

.secret-box {
  border: 1px solid var(--border-regular);
  padding: 14px;
  border-radius: var(--radius-xs);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin: 20px 0;
  background: #04060a;
}

.secret-token {
  font-size: 12px;
  color: var(--accent-cyan);
  word-break: break-all;
}
</style>
