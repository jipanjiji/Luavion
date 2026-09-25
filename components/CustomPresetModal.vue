<template>
  <UiModal
    :show="show"
    title="Saved obfuscation presets"
    :subtitle="`Save and reuse fine-tuned compiler configurations. Limit for ${userPlan.toUpperCase()}: ${presetsLimitLabel}.`"
    max-width="560px"
    @close="show = false"
  >
    <div class="create-preset-box" v-if="canCreateMore">
      <span class="t-label" style="margin-bottom: 10px; display: block;">Save current configuration</span>
      <div class="form-row">
        <input
          type="text"
          v-model="newPresetName"
          placeholder="e.g. Combat Production VM"
          class="input"
          style="flex: 1;"
        />
        <button
          class="btn btn-primary btn-sm"
          @click="handleSavePreset"
          :disabled="!newPresetName.trim() || saving"
        >
          {{ saving ? 'Saving…' : 'Save preset' }}
        </button>
      </div>
      <input
        type="text"
        v-model="newPresetDesc"
        placeholder="Optional description (e.g. Optimized for render loops)"
        class="input"
        style="font-size: 12px; min-height: 36px;"
      />
    </div>
    <div v-else-if="savedPresets.length >= allowedLimit && allowedLimit > 0" class="limit-banner">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
        <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" />
      </svg>
      <span>You reached the maximum of {{ allowedLimit }} saved presets on {{ userPlan.toUpperCase() }}. Upgrade to Ultra for unlimited presets.</span>
    </div>

    <span class="t-label" style="display: block; margin-bottom: 10px;">Your saved presets ({{ savedPresets.length }})</span>
    <div v-if="loading" class="presets-loading-box"><span class="spinner"></span> Loading saved presets…</div>
    <div v-else-if="savedPresets.length === 0" class="presets-empty-box">
      No custom presets saved yet. Save your current compiler settings to reuse them anytime.
    </div>
    <div v-else class="presets-items-list">
      <div v-for="p in savedPresets" :key="p.id" class="preset-card">
        <div class="preset-card-head">
          <div class="preset-card-title-group">
            <span class="card-name">{{ p.name }}</span>
            <span class="badge">{{ p.base_preset }}</span>
          </div>
          <button class="icon-btn icon-btn-danger" @click="handleDelete(p.id)" aria-label="Delete preset">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
            </svg>
          </button>
        </div>
        <p class="card-desc" v-if="p.description">{{ p.description }}</p>
        <div class="preset-card-meta mono">
          <span>Target: {{ p.lua_version }}</span>
          <span>Banner: {{ p.include_banner ? 'Yes' : 'No' }}</span>
        </div>
        <button class="btn btn-secondary btn-sm btn-apply" @click="applyPreset(p)">Apply settings</button>
      </div>
    </div>
  </UiModal>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'
import UiModal from '~/components/ui/Modal.vue'

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
.create-preset-box {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: var(--bg-base);
  padding: 16px;
  margin-bottom: 18px;
}

.form-row { display: flex; gap: 10px; margin-bottom: 10px; }

.limit-banner {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  background: var(--status-amber-dim);
  border: 1px solid var(--status-amber-border);
  padding: 12px 14px;
  border-radius: var(--radius-md);
  font-size: 12px;
  color: var(--status-amber);
  margin-bottom: 18px;
  line-height: 1.5;
}

.presets-loading-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  font-size: 12px;
  color: var(--text-muted);
  padding: 28px;
}

.presets-empty-box {
  font-size: 12px;
  color: var(--text-muted);
  padding: 24px;
  text-align: center;
  border: 1px dashed var(--border-regular);
  border-radius: var(--radius-md);
  line-height: 1.6;
}

.presets-items-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-height: 280px;
  overflow-y: auto;
  padding-right: 4px;
}

.preset-card {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 14px 16px;
  background: var(--bg-base);
  transition: border-color var(--duration-fast) var(--ease-out);
}

.preset-card:hover { border-color: var(--border-regular); }

.preset-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.preset-card-title-group { display: flex; align-items: center; gap: 8px; }

.card-name { font-size: 13px; font-weight: 600; color: var(--text-primary); }

.card-desc { font-size: 12px; color: var(--text-secondary); margin: 4px 0 8px; }

.preset-card-meta {
  display: flex;
  gap: 16px;
  font-size: 10px;
  color: var(--text-faint);
  margin-bottom: 12px;
}

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: transparent;
  border: none;
  color: var(--text-muted);
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.icon-btn-danger:hover { color: var(--status-crimson); background: var(--status-crimson-dim); }

.btn-apply { width: 100%; }

@media (max-width: 560px) {
  .form-row { flex-direction: column; }
}
</style>
