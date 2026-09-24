<template>
  <transition name="modal">
    <div v-if="activeUpgradeModal.show" class="modal-backdrop" @click.self="close">
      <div class="modal-card surface">
        <!-- Close Button -->
        <button class="modal-close-btn" @click="close" aria-label="Close modal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <div class="modal-header">
          <div class="badge-lock">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
            </svg>
            <span>PLAN UPGRADE REQUIRED</span>
          </div>
          <h2 class="modal-title">Unlock {{ targetPlanConfig.name }} Tier Capabilities</h2>
          <p class="modal-reason" v-if="activeUpgradeModal.reason">
            {{ activeUpgradeModal.reason }}
          </p>
          <p class="modal-subtitle" v-else>
            This feature requires a higher tier plan. Upgrade today to scale your Lua protection.
          </p>
        </div>

        <div class="plan-showcase surface-raised">
          <div class="plan-top-row">
            <div>
              <div class="plan-name-group">
                <span class="plan-tier-name">{{ targetPlanConfig.name }}</span>
                <span class="badge badge-cyan" v-if="targetPlanConfig.badge">{{ targetPlanConfig.badge }}</span>
              </div>
              <div class="plan-pricing">
                <span class="price-val">{{ formatPrice(targetPlanConfig.priceUsd, targetPlanConfig.priceIdr) }}</span>
                <span class="price-cycle">/month</span>
              </div>
            </div>
            <div class="currency-pill-toggle">
              <button 
                class="curr-btn" 
                :class="{ active: currency === 'USD' }"
                @click="currency = 'USD'"
              >
                USD
              </button>
              <button 
                class="curr-btn" 
                :class="{ active: currency === 'IDR' }"
                @click="currency = 'IDR'"
              >
                IDR
              </button>
            </div>
          </div>

          <div class="plan-features-list">
            <div 
              v-for="(f, i) in targetPlanConfig.features" 
              :key="i" 
              class="feature-row"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="check-icon">
                <polyline points="20 6 9 17 4 12"></polyline>
              </svg>
              <span>{{ f }}</span>
            </div>
          </div>
        </div>

        <div class="modal-actions">
          <button class="btn btn-secondary" @click="close">
            Cancel
          </button>
          <NuxtLink 
            :to="`/billing?upgrade=${targetPlanConfig.id}`" 
            class="btn btn-accent btn-upgrade-cta" 
            @click="close"
          >
            <span>Upgrade to {{ targetPlanConfig.name }}</span>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="5" y1="12" x2="19" y2="12"></line>
              <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
          </NuxtLink>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { computed } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'

const { activeUpgradeModal } = useUser()
const { getPlan, formatPrice, currency } = usePlans()

const targetPlanConfig = computed(() => {
  return getPlan(activeUpgradeModal.value.targetTier || 'pro')
})

const close = () => {
  activeUpgradeModal.value.show = false
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

.modal-card {
  width: 100%;
  max-width: 520px;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-lg);
  padding: 32px;
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
  transition: all var(--duration-fast);
}
.modal-close-btn:hover {
  color: var(--text-primary);
  border-color: var(--border-hover);
}

.modal-header {
  margin-bottom: 24px;
}

.badge-lock {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(245, 158, 11, 0.1);
  color: #f59e0b;
  border: 1px solid rgba(245, 158, 11, 0.3);
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  font-size: 11px;
  font-weight: 700;
  margin-bottom: 14px;
}

.modal-title {
  font-size: 20px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.modal-reason {
  font-size: 13px;
  color: var(--accent-cyan);
  line-height: 1.5;
}

.modal-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

.plan-showcase {
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 20px;
  margin-bottom: 24px;
}

.plan-top-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--border-subtle);
}

.plan-name-group {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.plan-tier-name {
  font-size: 18px;
  font-weight: 700;
  color: #ffffff;
}

.plan-pricing {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.price-val {
  font-size: 24px;
  font-weight: 700;
  color: var(--accent-cyan);
}

.price-cycle {
  font-size: 12px;
  color: var(--text-muted);
}

.currency-pill-toggle {
  display: flex;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xs);
  padding: 2px;
}

.curr-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 11px;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 3px;
  cursor: pointer;
}
.curr-btn.active {
  background: var(--bg-surface-raised);
  color: var(--text-primary);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.4);
}

.plan-features-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.feature-row {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
  color: var(--text-secondary);
}

.check-icon {
  color: var(--status-emerald);
  flex-shrink: 0;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.btn-upgrade-cta {
  background: var(--accent-cyan);
  color: var(--bg-void);
  font-weight: 600;
}

.modal-enter-active,
.modal-leave-active {
  transition: all 0.25s var(--ease-spring);
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.96);
}
</style>
