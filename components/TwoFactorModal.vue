<template>
  <UiModal
    :show="show"
    :title="title || 'Confirm destructive action'"
    :subtitle="message || 'This action cannot be undone. Type the confirmation phrase below to proceed.'"
    max-width="440px"
    @close="handleCancel"
  >
    <div class="danger-tag mono">
      <span class="status-dot dot-crimson"></span>
      High-security action
    </div>

    <div class="confirm-box">
      <span class="confirm-instruction">
        Type <code class="phrase-target mono">{{ requiredPhrase }}</code> to confirm
      </span>
      <input
        type="text"
        v-model="inputPhrase"
        :placeholder="requiredPhrase"
        class="input mono confirm-input"
        autocomplete="off"
        spellcheck="false"
        @keydown.enter="handleConfirm"
      />
    </div>

    <template #footer>
      <button class="btn btn-ghost" @click="handleCancel">Cancel</button>
      <button
        class="btn btn-danger btn-danger-solid"
        :disabled="inputPhrase !== requiredPhrase"
        @click="handleConfirm"
      >
        Confirm & Execute
      </button>
    </template>
  </UiModal>
</template>

<script setup>
import { ref, computed } from 'vue'
import UiModal from '~/components/ui/Modal.vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: '' },
  message: { type: String, default: '' },
  requiredPhrase: { type: String, default: 'CONFIRM' }
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

const inputPhrase = ref('')

const show = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const handleCancel = () => {
  inputPhrase.value = ''
  show.value = false
  emit('cancel')
}

const handleConfirm = () => {
  if (inputPhrase.value === props.requiredPhrase) {
    emit('confirm')
    inputPhrase.value = ''
    show.value = false
  }
}
</script>

<style scoped>
.danger-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--status-crimson);
  margin-bottom: 14px;
}

.confirm-box {
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 16px;
}

.confirm-instruction {
  display: block;
  font-size: 12px;
  color: var(--text-secondary);
  margin-bottom: 12px;
}

.phrase-target {
  color: var(--status-crimson);
  background: var(--status-crimson-dim);
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 600;
}

.confirm-input:focus {
  border-color: var(--status-crimson-border);
  box-shadow: 0 0 0 3px var(--status-crimson-dim);
}

.btn-danger-solid {
  background: var(--status-crimson);
  border-color: var(--status-crimson);
  color: #fff;
  font-weight: 600;
}

.btn-danger-solid:hover:not(:disabled) {
  background: #ef4444;
  transform: translateY(-1px);
}
</style>
