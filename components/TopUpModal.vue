<template>
  <UiModal
    :show="show"
    title="Purchase quota top-up"
    subtitle="Need extra obfuscations without upgrading? Credits are $0.50 / Rp 5,000 per script and never expire."
    max-width="520px"
    @close="show = false"
  >
    <div class="currency-row">
      <span class="t-label">Billing currency</span>
      <div class="currency-pill-toggle" role="group" aria-label="Currency">
        <button class="curr-btn mono" :class="{ active: currency === 'USD' }" @click="currency = 'USD'">USD $</button>
        <button class="curr-btn mono" :class="{ active: currency === 'IDR' }" @click="currency = 'IDR'">IDR Rp</button>
      </div>
    </div>

    <div class="packs-grid" role="radiogroup" aria-label="Top-up amount">
      <button
        v-for="pack in topUpPricing.packs"
        :key="pack.count"
        class="pack-card"
        :class="{ selected: selectedPack === pack.count }"
        role="radio"
        :aria-checked="selectedPack === pack.count"
        @click="selectedPack = pack.count"
      >
        <span v-if="pack.discountLabel" class="badge badge-emerald pack-badge-wrap">{{ pack.discountLabel }}</span>
        <span class="pack-count mono">+{{ pack.count }}</span>
        <span class="pack-unit">Obfuscations</span>
        <span class="pack-price mono">{{ formatPrice(pack.priceUsd, pack.priceIdr) }}</span>
      </button>
    </div>

    <template #footer>
      <span class="gateway-note">
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
          <rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
        </svg>
        {{ currency === 'USD' ? 'Billed securely via Stripe' : 'Billed via Indonesian gateway (Midtrans)' }}
      </span>
      <button class="btn btn-ghost" @click="show = false">Cancel</button>
      <button class="btn btn-primary" @click="handleCheckout" :disabled="loading">
        <span v-if="loading" class="spinner" aria-hidden="true"></span>
        {{ loading ? 'Preparing…' : 'Proceed to checkout' }}
      </button>
    </template>
  </UiModal>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'
import UiModal from '~/components/ui/Modal.vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false }
})

const emit = defineEmits(['update:modelValue'])

const { showToast, fetchUser } = useUser()
const { topUpPricing, currency, formatPrice } = usePlans()

const show = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val)
})

const selectedPack = ref(50)
const loading = ref(false)

const handleCheckout = async () => {
  try {
    loading.value = true
    const res = await $fetch('/api/billing/checkout', {
      method: 'POST',
      body: {
        isTopUp: true,
        topUpCount: selectedPack.value,
        currency: currency.value
      }
    })

    if (res.checkoutUrl) {
      window.location.href = res.checkoutUrl
    } else if (res.simulated) {
      showToast(res.message || 'Top-up credits added successfully!', 'success')
      await fetchUser()
      show.value = false
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Failed to initiate checkout', 'error')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.currency-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
  padding: 10px 14px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
}

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

.curr-btn.active { background: var(--bg-elevated); color: var(--text-primary); }

.packs-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.pack-card {
  position: relative;
  background: var(--bg-base);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 18px 14px;
  text-align: center;
  cursor: pointer;
  font-family: inherit;
  color: inherit;
  transition: all var(--duration-fast) var(--ease-out);
}

.pack-card:hover { border-color: var(--border-hover); background: var(--bg-surface); }

.pack-card.selected {
  border-color: var(--border-focus);
  background: var(--accent-dimmer);
  box-shadow: 0 0 0 1px var(--border-focus);
}

.pack-badge-wrap { position: absolute; top: -9px; right: 10px; }

.pack-count {
  display: block;
  font-size: 24px;
  font-weight: 600;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.pack-unit {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.pack-price {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.gateway-note {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--text-muted);
  margin-right: auto;
}
</style>
