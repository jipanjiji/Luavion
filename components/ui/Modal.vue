<template>
  <teleport to="body">
    <transition name="ui-modal">
      <div
        v-if="show"
        class="ui-modal-backdrop"
        @click.self="handleClose"
        @keydown.esc="handleClose"
      >
        <div
          class="ui-modal-card"
          :style="{ maxWidth }"
          role="dialog"
          aria-modal="true"
          :aria-label="title || 'Dialog'"
          ref="cardRef"
        >
          <header v-if="title || closable" class="ui-modal-head">
            <div class="ui-modal-head-text">
              <h3 v-if="title" class="ui-modal-title">{{ title }}</h3>
              <p v-if="subtitle" class="ui-modal-subtitle">{{ subtitle }}</p>
            </div>
            <button v-if="closable" class="ui-modal-close" @click="handleClose" aria-label="Close dialog">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </header>

          <div class="ui-modal-body">
            <slot />
          </div>

          <footer v-if="$slots.footer" class="ui-modal-foot">
            <slot name="footer" />
          </footer>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { ref, watch, nextTick, onUnmounted } from 'vue'

const props = defineProps({
  show: { type: Boolean, default: false },
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  maxWidth: { type: String, default: '440px' },
  closable: { type: Boolean, default: true },
})

const emit = defineEmits(['close'])

const cardRef = ref(null)

const handleClose = () => {
  if (props.closable) emit('close')
}

watch(() => props.show, async (open) => {
  if (!import.meta.client) return
  if (open) {
    document.body.style.overflow = 'hidden'
    await nextTick()
    cardRef.value?.querySelector('input, button:not(.ui-modal-close), textarea, select')?.focus?.()
  } else {
    document.body.style.overflow = ''
  }
})

onUnmounted(() => {
  if (import.meta.client) document.body.style.overflow = ''
})
</script>

<style scoped>
.ui-modal-backdrop {
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

.ui-modal-card {
  width: 100%;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-lg);
  box-shadow: var(--surface-highlight), var(--shadow-lg);
  overflow: hidden;
  max-height: calc(100vh - 40px);
  display: flex;
  flex-direction: column;
}

.ui-modal-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 22px 16px;
  border-bottom: 1px solid var(--border-subtle);
}

.ui-modal-title {
  font-size: 15px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.ui-modal-subtitle {
  font-size: 12px;
  color: var(--text-muted);
  margin-top: 3px;
  line-height: 1.5;
}

.ui-modal-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
  flex-shrink: 0;
}

.ui-modal-close:hover {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.07);
}

.ui-modal-body {
  padding: 20px 22px;
  overflow-y: auto;
}

.ui-modal-foot {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 22px;
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-surface);
}

.ui-modal-enter-active { transition: opacity 200ms var(--ease-out); }
.ui-modal-leave-active { transition: opacity 150ms var(--ease-out); }
.ui-modal-enter-active .ui-modal-card {
  transition: opacity 250ms var(--ease-spring), transform 250ms var(--ease-spring);
}
.ui-modal-leave-active .ui-modal-card {
  transition: opacity 150ms var(--ease-out), transform 150ms var(--ease-out);
}
.ui-modal-enter-from, .ui-modal-leave-to { opacity: 0; }
.ui-modal-enter-from .ui-modal-card { opacity: 0; transform: scale(0.96) translateY(10px); }
.ui-modal-leave-to .ui-modal-card { opacity: 0; transform: scale(0.97) translateY(6px); }

@media (max-width: 560px) {
  .ui-modal-backdrop { padding: 0; align-items: flex-end; }
  .ui-modal-card {
    border-radius: var(--radius-lg) var(--radius-lg) 0 0;
    max-height: 92vh;
    border-bottom: none;
  }
}
</style>
