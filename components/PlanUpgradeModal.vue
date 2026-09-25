<template>
  <UiModal
    :show="activeUpgradeModal.show"
    :title="`Unlock ${targetPlanConfig.name}`"
    :subtitle="activeUpgradeModal.reason || 'This feature requires a higher tier plan. Upgrade to scale your Lua protection.'"
    max-width="500px"
    @close="close"
  >
    <div class="plan-showcase">
      <div class="plan-top-row">
        <div>
          <div class="plan-name-group">
            <span class="plan-tier-name">{{ targetPlanConfig.name }}</span>
            <span class="badge badge-cyan" v-if="targetPlanConfig.badge">{{ targetPlanConfig.badge }}</span>
          </div>
          <div class="plan-pricing">
            <span class="price-val mono">{{ formatPrice(targetPlanConfig.priceUsd, targetPlanConfig.priceIdr) }}</span>
            <span class="price-cycle">/month</span>
          </div>
        </div>
        <div class="currency-pill-toggle" role="group" aria-label="Currency">
          <button class="curr-btn mono" :class="{ active: currency === 'USD' }" @click="currency = 'USD'">USD</button>
          <button class="curr-btn mono" :class="{ active: currency === 'IDR' }" @click="currency = 'IDR'">IDR</button>
        </div>
      </div>

      <div class="plan-features-list">
        <div v-for="(f, i) in targetPlanConfig.features" :key="i" class="feature-row">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="check-icon" aria-hidden="true">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
          <span>{{ f }}</span>
        </div>
      </div>
    </div>

    <template #footer>
      <button class="btn btn-ghost" @click="close">Cancel</button>
      <NuxtLink :to="`/billing?upgrade=${targetPlanConfig.id}`" class="btn btn-primary" @click="close">
        Upgrade to {{ targetPlanConfig.name }}
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
          <line x1="5" y1="12" x2="19" y2="12"></line>
          <polyline points="12 5 19 12 12 19"></polyline>
        </svg>
      </NuxtLink>
    </template>
  </UiModal>
</template>

<script setup>
import { computed } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'
import UiModal from '~/components/ui/Modal.vue'

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
.plan-showcase {
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 18px;
}

.plan-top-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
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
  font-size: 16px;
  font-weight: 600;
  letter-spacing: -0.01em;
  color: var(--text-primary);
}

.plan-pricing { display: flex; align-items: baseline; gap: 5px; }

.price-val { font-size: 22px; font-weight: 600; color: var(--text-primary); }

.price-cycle { font-size: 12px; color: var(--text-muted); }

.currency-pill-toggle {
  display: flex;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 2px;
}

.curr-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 11px;
  font-weight: 500;
  padding: 5px 10px;
  border-radius: 4px;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.curr-btn.active {
  background: var(--bg-elevated);
  color: var(--text-primary);
}

.plan-features-list { display: flex; flex-direction: column; gap: 9px; }

.feature-row {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--text-secondary);
}

.check-icon { color: var(--status-emerald); flex-shrink: 0; }
</style>
