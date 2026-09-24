<template>
  <transition name="modal">
    <div v-if="show" class="modal-backdrop" @click.self="show = false">
      <div class="modal-card surface preset-modal">
        <button class="modal-close-btn" @click="show = false" aria-label="Close modal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <div class="modal-header">
          <div class="header-tag">
            <span class="status-dot dot-cyan"></span>
            <span>CUSTOM CONFIGURATIONS</span>
          </div>
          <h2 class="modal-title">Saved Obfuscation Presets</h2>
          <p class="modal-subtitle">
            Save and reuse your fine-tuned compiler configurations. Limit for {{ userPlan.toUpperCase() }}: {{ presetsLimitLabel }}.
          </p>
        </div>

        <!-- Create Preset Form -->
        <div class="create-preset-box surface-raised" v-if="canCreateMore">
          <span class="box-title">Save Current Configuration</span>
          <div class="form-row">
            <input 
              type="text" 
              v-model="newPresetName" 
              placeholder="e.g. Combat Production VM" 
              class="preset-name-input"
            />
            <button 
              class="btn btn-accent btn-sm" 
              @click="handleSavePreset"
              :disabled="!newPresetName.trim() || saving"
            >
              {{ saving ? 'Saving...' : 'Save Preset' }}
            </button>
          </div>
          <input 
            type="text" 
            v-model="newPresetDesc" 
            placeholder="Optional description (e.g. Optimized for render loops)" 
            class="preset-desc-input"
          />
        </div>
        <div v-else-if="savedPresets.length >= allowedLimit && allowedLimit > 0" class="limit-reached-banner">
          <span>You have reached the maximum of {{ allowedLimit }} saved presets on {{ userPlan.toUpperCase() }}. Upgrade to Ultra for unlimited presets.</span>
        </div>

        <!-- Presets List -->
        <div class="presets-list-wrap">
          <span class="list-label">YOUR SAVED PRESETS ({{ savedPresets.length }})</span>
          <div v-if="loading" class="presets-loading">Loading saved presets...</div>
          <div v-else-if="savedPresets.length === 0" class="presets-empty">
            No custom presets saved yet. Save your current compiler settings to access them anytime.
          </div>
          <div v-else class="presets-items-grid">
            <div 
              v-for="p in savedPresets" 
              :key="p.id" 
              class="preset-card surface-raised"
            >
              <div class="preset-card-head">
                <div class="preset-card-title-group">
                  <span class="card-name">{{ p.name }}</span>
                  <span class="badge badge-cyan">{{ p.base_preset }}</span>
                </div>
                <button class="delete-btn" @click="handleDelete(p.id)" title="Delete preset">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="3 6 5 6 21 6"></polyline>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                  </svg>
                </button>
              </div>
              <p class="card-desc" v-if="p.description">{{ p.description }}</p>
              <div class="preset-card-meta">
                <span>Target: {{ p.lua_version }}</span>
                <span>Banner: {{ p.include_banner ? 'Yes' : 'No' }}</span>
              </div>
              <button class="btn btn-secondary btn-xs btn-apply" @click="applyPreset(p)">
                Apply Settings
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  currentSettings: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:modelValue', 'apply'])

const { user, showToast } = useUser()

const show = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const userPlan = computed(() => user.value?.plan || 'free')
const allowedLimit = ref(0)
const savedPresets = ref([])
const loading = ref(false)
const saving = ref(false)

const newPresetName = ref('')
const newPresetDesc = ref('')

const presetsLimitLabel = computed(() => {
  if (userPlan.value === 'ultra') return 'Unlimited'
  if (userPlan.value === 'pro') return 'Up to 3 presets'
  return '0 (Pro & Ultra only)'
})

const canCreateMore = computed(() => {
  if (userPlan.value === 'ultra') return true
  if (userPlan.value === 'pro') return savedPresets.value.length < 3
  return false
})

const loadPresets = async () => {
  try {
    loading.value = true
    const res = await $fetch('/api/presets/custom')
    savedPresets.value = res.presets || []
    allowedLimit.value = res.allowedLimit || 0
  } catch (err) {
    console.error('Failed to load custom presets:', err)
  } finally {
    loading.value = false
  }
}

const handleSavePreset = async () => {
  if (!newPresetName.value.trim()) return
  try {
    saving.value = true
    const res = await $fetch('/api/presets/custom', {
      method: 'POST',
      body: {
        name: newPresetName.value,
        description: newPresetDesc.value,
        basePreset: props.currentSettings.preset || 'BALANCED',
        luaVersion: props.currentSettings.luaVersion || 'LuaU',
        prettyPrint: props.currentSettings.prettyPrint || false,
        includeBanner: props.currentSettings.includeBanner !== false,
        settings: {}
      }
    })
    if (res.ok) {
      showToast('Custom preset saved successfully!', 'success')
      newPresetName.value = ''
      newPresetDesc.value = ''
      await loadPresets()
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Failed to save preset', 'error')
  } finally {
    saving.value = false
  }
}

const handleDelete = async (id) => {
  try {
    const res = await $fetch(`/api/presets/custom/${id}`, { method: 'DELETE' })
    if (res.ok) {
      showToast('Preset removed', 'info')
      await loadPresets()
    }
  } catch (err) {
    showToast('Failed to delete preset', 'error')
  }
}

const applyPreset = (p) => {
  emit('apply', p)
  showToast(`Applied preset: ${p.name}`, 'success')
  show.value = false
}

onMounted(() => {
  loadPresets()
})
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

.preset-modal {
  width: 100%;
  max-width: 580px;
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
  margin-bottom: 20px;
}

.create-preset-box {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 16px;
  margin-bottom: 20px;
}

.box-title {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.05em;
  margin-bottom: 10px;
}

.form-row {
  display: flex;
  gap: 10px;
  margin-bottom: 8px;
}

.preset-name-input {
  flex: 1;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 12px;
  padding: 8px 12px;
  border-radius: var(--radius-xs);
}

.preset-desc-input {
  width: 100%;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 11px;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
}

.limit-reached-banner {
  background: rgba(245, 158, 11, 0.1);
  border: 1px solid rgba(245, 158, 11, 0.3);
  padding: 12px;
  border-radius: var(--radius-sm);
  font-size: 12px;
  color: #fbbf24;
  margin-bottom: 20px;
}

.list-label {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.05em;
  margin-bottom: 10px;
}

.presets-empty {
  font-size: 12px;
  color: var(--text-muted);
  padding: 24px;
  text-align: center;
  border: 1px dashed var(--border-subtle);
  border-radius: var(--radius-sm);
}

.presets-items-grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 240px;
  overflow-y: auto;
}

.preset-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-sm);
  padding: 12px 14px;
}

.preset-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.preset-card-title-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.card-name {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
}

.card-desc {
  font-size: 11px;
  color: var(--text-secondary);
  margin-bottom: 8px;
}

.preset-card-meta {
  display: flex;
  gap: 16px;
  font-size: 10px;
  color: var(--text-muted);
  margin-bottom: 10px;
}

.delete-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  padding: 4px;
}
.delete-btn:hover {
  color: var(--status-crimson);
}

.btn-apply {
  width: 100%;
}
</style>
