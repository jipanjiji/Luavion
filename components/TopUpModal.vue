<template>
  <transition name="modal">
    <div v-if="show" class="modal-backdrop" @click.self="show = false">
      <div class="modal-card surface topup-modal">
        <button class="modal-close-btn" @click="show = false" aria-label="Close modal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <div class="modal-header">
          <div class="header-tag">
            <span class="status-dot dot-emerald"></span>
            <span>PAY-AS-YOU-GO CREDITS</span>
          </div>
          <h2 class="modal-title">Purchase Quota Top-Up</h2>
          <p class="modal-subtitle">
            Need extra obfuscations without upgrading your tier? Add immediate credits ($0.50 / Rp 5,000 per script). Credits never expire.
          </p>
        </div>

        <!-- Currency Switcher -->
        <div class="currency-row">
          <span class="curr-label">BILLING CURRENCY:</span>
          <div class="segmented-control">
            <button 
              class="seg-btn" 
              :class="{ active: currency === 'USD' }"
              @click="currency = 'USD'"
            >
              USD ($)
            </button>
            <button 
              class="seg-btn" 
              :class="{ active: currency === 'IDR' }"
              @click="currency = 'IDR'"
            >
              IDR (Rp)
            </button>
          </div>
        </div>

        <!-- Pack Selection Cards -->
        <div class="packs-grid">
          <div 
            v-for="pack in topUpPricing.packs" 
            :key="pack.count"
            class="pack-card surface-raised"
            :class="{ selected: selectedPack === pack.count, popular: pack.popular }"
            @click="selectedPack = pack.count"
          >
            <div class="pack-badge-wrap" v-if="pack.discountLabel">
              <span class="badge badge-emerald">{{ pack.discountLabel }}</span>
            </div>
            <span class="pack-count">+{{ pack.count }}</span>
            <span class="pack-unit">Obfuscations</span>
            <div class="pack-price">
              {{ formatPrice(pack.priceUsd, pack.priceIdr) }}
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <div class="gateway-note">
            <span v-if="currency === 'USD'">🔒 Billed securely via Stripe Checkout</span>
            <span v-else>🔒 Billed securely via Indonesian Gateway (Midtrans)</span>
          </div>
          <div class="footer-btns">
            <button class="btn btn-secondary" @click="show = false">
              Cancel
            </button>
            <button 
              class="btn btn-accent btn-pay" 
              @click="handleCheckout"
              :disabled="loading"
            >
              {{ loading ? 'Preparing Checkout...' : 'Proceed to Checkout' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

const { user, showToast, fetchUser } = useUser()
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

.topup-modal {
  width: 100%;
  max-width: 540px;
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
  color: var(--status-emerald);
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
  line-height: 1.5;
  margin-bottom: 18px;
}

.currency-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
  padding: 10px 14px;
  background: var(--bg-surface-raised);
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-subtle);
}

.curr-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.packs-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 24px;
}

.pack-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 16px;
  text-align: center;
  cursor: pointer;
  position: relative;
  transition: all var(--duration-fast);
}
.pack-card:hover {
  border-color: var(--border-hover);
  background: var(--bg-elevated);
}
.pack-card.selected {
  border-color: var(--accent-cyan);
  background: var(--accent-cyan-dimmer);
  box-shadow: 0 0 16px rgba(0, 240, 255, 0.15);
}

.pack-badge-wrap {
  position: absolute;
  top: -10px;
  right: 12px;
}

.pack-count {
  display: block;
  font-size: 22px;
  font-weight: 700;
  color: #ffffff;
}

.pack-unit {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.pack-price {
  font-size: 15px;
  font-weight: 700;
  color: var(--accent-cyan);
}

.modal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 16px;
  border-top: 1px solid var(--border-subtle);
}

.gateway-note {
  font-size: 11px;
  color: var(--text-muted);
}

.footer-btns {
  display: flex;
  gap: 10px;
}

.btn-pay {
  background: var(--accent-cyan);
  color: var(--bg-void);
  font-weight: 600;
}
</style>
