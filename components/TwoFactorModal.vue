<template>
  <transition name="modal">
    <div v-if="show" class="modal-backdrop" @click.self="handleCancel">
      <div class="modal-card surface twofactor-modal">
        <button class="modal-close-btn" @click="handleCancel" aria-label="Close modal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <div class="modal-header">
          <div class="header-tag">
            <span class="status-dot dot-crimson"></span>
            <span>HIGH-SECURITY ACTION CONFIRMATION</span>
          </div>
          <h2 class="modal-title">{{ title || 'Confirm Destructive Action' }}</h2>
          <p class="modal-subtitle">
            {{ message || 'This action cannot be undone. Please type the confirmation phrase below to proceed.' }}
          </p>
        </div>

        <div class="confirm-box surface-raised">
          <span class="confirm-instruction">
            Type <code class="phrase-target">{{ requiredPhrase }}</code> to confirm:
          </span>
          <input 
            type="text" 
            v-model="inputPhrase" 
            :placeholder="requiredPhrase" 
            class="confirm-input"
            autocomplete="off"
            spellcheck="false"
          />
        </div>

        <div class="modal-footer">
          <button class="btn btn-secondary" @click="handleCancel">
            Cancel
          </button>
          <button 
            class="btn btn-danger" 
            :disabled="inputPhrase !== requiredPhrase"
            @click="handleConfirm"
          >
            Confirm & Execute
          </button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: ''
  },
  message: {
    type: String,
    default: ''
  },
  requiredPhrase: {
    type: String,
    default: 'CONFIRM'
  }
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

.twofactor-modal {
  width: 100%;
  max-width: 480px;
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

.header-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 700;
  color: var(--status-crimson);
  letter-spacing: 0.08em;
  margin-bottom: 6px;
}

.modal-title {
  font-size: 18px;
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

.confirm-box {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-sm);
  padding: 14px;
  margin-bottom: 20px;
}

.confirm-instruction {
  display: block;
  font-size: 12px;
  color: var(--text-secondary);
  margin-bottom: 10px;
}

.phrase-target {
  color: var(--status-crimson);
  background: rgba(244, 63, 94, 0.1);
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 700;
}

.confirm-input {
  width: 100%;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 13px;
  padding: 8px 12px;
  border-radius: var(--radius-xs);
}
.confirm-input:focus {
  border-color: var(--status-crimson);
  outline: none;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-danger {
  background: var(--status-crimson);
  color: #ffffff;
  border: none;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: var(--radius-xs);
  cursor: pointer;
}
.btn-danger:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
</style>
