<template>
  <transition name="toast">
    <div v-if="toast.show" class="app-toast-container" role="status" aria-live="polite">
      <div class="app-toast" :class="`toast-${toast.type}`">
        <div class="toast-icon">
          <svg v-if="toast.type === 'success'" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
          <svg v-else-if="toast.type === 'error'" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="15" y1="9" x2="9" y2="15"></line>
            <line x1="9" y1="9" x2="15" y2="15"></line>
          </svg>
          <svg v-else width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="16" x2="12" y2="12"></line>
            <line x1="12" y1="8" x2="12.01" y2="8"></line>
          </svg>
        </div>
        <span class="toast-message">{{ toast.message }}</span>
        <button class="toast-close" @click="toast.show = false" aria-label="Dismiss notification">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { useUser } from '~/composables/useUser'
const { toast } = useUser()
</script>

<style scoped>
.app-toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 9999;
  pointer-events: none;
}

.app-toast {
  pointer-events: auto;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: var(--radius-md);
  font-size: 13px;
  font-weight: 500;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  box-shadow: var(--surface-highlight), var(--shadow-lg);
  color: var(--text-primary);
  max-width: 420px;
}

.toast-success { border-left: 2px solid var(--status-emerald); }
.toast-success .toast-icon { color: var(--status-emerald); }

.toast-error { border-left: 2px solid var(--status-crimson); }
.toast-error .toast-icon { color: var(--status-crimson); }

.toast-info { border-left: 2px solid rgba(255, 255, 255, 0.4); }
.toast-info .toast-icon { color: var(--text-secondary); }

.toast-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.toast-message { flex: 1; line-height: 1.5; }

.toast-close {
  background: transparent;
  border: none;
  color: var(--text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 6px;
  border-radius: var(--radius-xs);
  transition: color var(--duration-fast), background var(--duration-fast);
}

.toast-close:hover { color: var(--text-primary); background: rgba(255, 255, 255, 0.06); }

.toast-enter-active { transition: all 280ms var(--ease-spring); }
.toast-leave-active { transition: all 180ms var(--ease-out); }
.toast-enter-from, .toast-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.96);
}

@media (max-width: 640px) {
  .app-toast-container { left: 16px; right: 16px; bottom: 16px; }
  .app-toast { max-width: none; width: 100%; }
}
</style>
