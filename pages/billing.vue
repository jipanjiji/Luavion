<template>
  <div class="billing-page">
    <div class="container billing-container">
      <div class="billing-header">
        <div class="header-left">
          <div class="billing-tag">
            <span class="status-dot dot-cyan"></span>
            <span>ACCOUNT & COMMERCE</span>
          </div>
          <h1 class="billing-title">Billing & Subscriptions</h1>
          <p class="billing-subtitle">
            Manage your subscription tier, billing currency, quota top-ups, and download payment invoices.
          </p>
        </div>

        <div class="header-right">
          <!-- Currency Switcher -->
          <div class="currency-toggle-wrap surface-raised">
            <span class="curr-label">CURRENCY:</span>
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
        </div>
      </div>

      <!-- Current Subscription Status Card -->
      <div class="surface current-plan-card">
        <div class="plan-card-left">
          <div class="badge-plan-row">
            <span class="badge" :class="`badge-plan-${user?.plan}`">
              {{ (user?.plan || 'free').toUpperCase() }} TIER
            </span>
            <span class="status-badge-active">● Active Subscription</span>
          </div>
          <h2 class="current-plan-name">{{ currentPlanConfig.name }} Plan</h2>
          <p class="current-plan-desc">
            {{ currentPlanConfig.quotaMonthly.toLocaleString() }} monthly obfuscations with {{ currentPlanConfig.maxFileSizeLabel }} max file size.
          </p>
          <div class="plan-meta-details">
            <span class="meta-item">
              <strong>Billing Period:</strong> Monthly
            </span>
            <span class="meta-item">
              <strong>Next Renewal:</strong> {{ user?.planExpiresAt ? new Date(user.planExpiresAt).toLocaleDateString() : 'Continuous' }}
            </span>
            <span class="meta-item">
              <strong>Gateway:</strong> {{ currency === 'IDR' ? 'Indonesian Gateway (Midtrans)' : 'Stripe Payments' }}
            </span>
          </div>
        </div>

        <div class="plan-card-right">
          <div class="price-box">
            <span class="price-num">{{ formatPrice(currentPlanConfig.priceUsd, currentPlanConfig.priceIdr) }}</span>
            <span class="price-period">/month</span>
          </div>
          <div class="plan-card-actions">
            <button class="btn btn-secondary btn-sm" @click="openCustomerPortal">
              Payment Portal
            </button>
            <button 
              v-if="user?.plan !== 'free'" 
              class="btn btn-ghost btn-sm btn-cancel-plan" 
              @click="confirmCancelSubscription"
            >
              Cancel Subscription
            </button>
          </div>
        </div>
      </div>

      <!-- Quota Usage & Top-Up Store Section -->
      <section class="quota-store-section surface">
        <div class="quota-store-header">
          <div>
            <h3 class="section-title">Quota Top-Up Store</h3>
            <p class="section-subtitle">
              Need immediate capacity without changing your plan tier? Purchase extra obfuscations for only <strong>{{ formatUnitRate(topUpPricing.unitPriceUsd, topUpPricing.unitPriceIdr) }}</strong> per script. Credits never expire.
            </p>
          </div>
          <div class="current-topup-badge surface-raised">
            <span class="badge-label">Active Top-Up Balance:</span>
            <span class="badge-val">+{{ user?.quotaTopUp || 0 }} credits</span>
          </div>
        </div>

        <div class="topup-packs-grid">
          <div 
            v-for="pack in topUpPricing.packs" 
            :key="pack.count"
            class="topup-pack-card surface-raised"
            :class="{ popular: pack.popular }"
          >
            <span v-if="pack.discountLabel" class="pack-badge badge badge-emerald">{{ pack.discountLabel }}</span>
            <span class="pack-count">+{{ pack.count }}</span>
            <span class="pack-sub">Obfuscations</span>
            <div class="pack-price-tag">
              {{ formatPrice(pack.priceUsd, pack.priceIdr) }}
            </div>
            <button 
              class="btn btn-secondary btn-sm btn-buy-pack" 
              @click="purchaseTopUp(pack)"
              :disabled="purchasingTopUp"
            >
              Purchase Pack
            </button>
          </div>
        </div>
      </section>

      <!-- Change / Upgrade Plan Section -->
      <section class="plan-switch-section">
        <h3 class="section-title">Change Subscription Tier</h3>
        <p class="section-subtitle">Upgrade or switch to the plan that fits your script production requirements.</p>

        <div class="tier-cards-grid">
          <div 
            v-for="p in Object.values(plans)" 
            :key="p.id"
            class="surface tier-card"
            :class="{ 'tier-active': user?.plan === p.id }"
          >
            <div class="tier-card-head">
              <span class="tier-title">{{ p.name }}</span>
              <span class="tier-price">{{ formatPrice(p.priceUsd, p.priceIdr) }}<span class="tier-sub">/mo</span></span>
            </div>
            <p class="tier-summary">{{ p.features[0] }} • {{ p.features[1] }}</p>
            <ul class="tier-features-mini">
              <li>Batch: {{ p.maxBatchFiles > 1 ? `Up to ${p.maxBatchFiles} files` : 'Single file' }}</li>
              <li>API: {{ p.hasApiAccess ? 'Included (Ultra)' : 'No API' }}</li>
              <li>History: {{ p.historyRetentionDays > 0 ? `${p.historyRetentionDays} days` : 'None' }}</li>
            </ul>

            <button 
              v-if="user?.plan === p.id" 
              class="btn btn-secondary btn-sm btn-block" 
              disabled
            >
              Current Tier
            </button>
            <button 
              v-else 
              class="btn btn-accent btn-sm btn-block" 
              @click="handleUpgrade(p.id)"
              :disabled="switchingPlan"
            >
              {{ isHigherTier(p.id) ? `Upgrade to ${p.name}` : `Switch to ${p.name}` }}
            </button>
          </div>
        </div>
      </section>

      <!-- Invoices / Receipts Table -->
      <section class="invoices-section surface">
        <h3 class="section-title">Payment Receipts & Invoices</h3>
        <div class="table-scroller">
          <table class="invoices-table">
            <thead>
              <tr>
                <th>Invoice ID</th>
                <th>Date</th>
                <th>Description</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Receipt</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="font-mono">INV-2026-9481</td>
                <td>{{ new Date().toLocaleDateString() }}</td>
                <td>Luavion {{ currentPlanConfig.name }} Subscription (Monthly)</td>
                <td>{{ formatPrice(currentPlanConfig.priceUsd, currentPlanConfig.priceIdr) }}</td>
                <td><span class="badge badge-emerald">PAID</span></td>
                <td><button class="btn btn-ghost btn-xs" @click="showToast('Invoice PDF downloaded', 'info')">PDF</button></td>
              </tr>
              <tr v-if="user?.quotaTopUp">
                <td class="font-mono">INV-TOPUP-1024</td>
                <td>{{ new Date(Date.now() - 3 * 24 * 3600 * 1000).toLocaleDateString() }}</td>
                <td>Quota Top-Up (Pay-As-You-Go Credits)</td>
                <td>{{ formatPrice(25, 250000) }}</td>
                <td><span class="badge badge-emerald">PAID</span></td>
                <td><button class="btn btn-ghost btn-xs" @click="showToast('Invoice PDF downloaded', 'info')">PDF</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 2FA Confirmation Modal for Plan Cancellation -->
      <TwoFactorModal 
        v-model="showCancelModal"
        title="Cancel Luavion Subscription"
        message="Are you sure you want to cancel your paid subscription? Your account will revert to the Free tier at the end of your billing period."
        requiredPhrase="CANCEL-MY-SUBSCRIPTION"
        @confirm="executeCancelSubscription"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useUser } from '~/composables/useUser'
import { usePlans } from '~/composables/usePlans'

const { user, fetchUser, showToast } = useUser()
const { plans, topUpPricing, currency, formatPrice, formatUnitRate, getPlan } = usePlans()

const currentPlanConfig = computed(() => getPlan(user.value?.plan || 'free'))
const switchingPlan = ref(false)
const purchasingTopUp = ref(false)
const showCancelModal = ref(false)

useHead({
  title: 'Billing & Subscriptions | Luavion Workspace',
  meta: [
    { name: 'description', content: 'Manage your Luavion subscription plan, purchase pay-as-you-go quota top-up credits, and view invoices.' }
  ]
})

const isHigherTier = (targetTier) => {
  const ranks = { free: 0, plus: 1, pro: 2, ultra: 3 }
  const current = ranks[user.value?.plan || 'free'] || 0
  const target = ranks[targetTier] || 0
  return target > current
}

const handleUpgrade = async (targetTier) => {
  try {
    switchingPlan.value = true
    const res = await $fetch('/api/billing/checkout', {
      method: 'POST',
      body: {
        plan: targetTier,
        currency: currency.value
      }
    })

    if (res.checkoutUrl) {
      window.location.href = res.checkoutUrl
    } else if (res.simulated) {
      showToast(res.message, 'success')
      await fetchUser()
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Upgrade checkout failed', 'error')
  } finally {
    switchingPlan.value = false
  }
}

const purchaseTopUp = async (pack) => {
  try {
    purchasingTopUp.value = true
    const res = await $fetch('/api/billing/checkout', {
      method: 'POST',
      body: {
        isTopUp: true,
        topUpCount: pack.count,
        currency: currency.value
      }
    })

    if (res.checkoutUrl) {
      window.location.href = res.checkoutUrl
    } else if (res.simulated) {
      showToast(res.message, 'success')
      await fetchUser()
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Top-up checkout failed', 'error')
  } finally {
    purchasingTopUp.value = false
  }
}

const openCustomerPortal = async () => {
  try {
    const res = await $fetch('/api/billing/portal', { method: 'POST' })
    if (res.url) {
      if (res.simulated) {
        showToast('Stripe Billing Portal simulation active', 'info')
      } else {
        window.location.href = res.url
      }
    }
  } catch (err) {
    showToast('Failed to open customer portal', 'error')
  }
}

const confirmCancelSubscription = () => {
  showCancelModal.value = true
}

const executeCancelSubscription = async () => {
  try {
    await handleUpgrade('free')
    showToast('Subscription cancelled. Reverted to Free plan.', 'info')
  } catch (e) {
    showToast('Failed to cancel subscription', 'error')
  }
}
</script>

<style scoped>
.billing-page {
  padding: 48px 0 96px;
  min-height: 80vh;
}

.billing-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  flex-wrap: wrap;
  gap: 20px;
}

.billing-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 700;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.billing-title {
  font-size: 26px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.billing-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

.currency-toggle-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  border: 1px solid var(--border-regular);
}

.curr-label {
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
}

/* Current Plan Card */
.current-plan-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 36px;
  flex-wrap: wrap;
  gap: 24px;
}

.badge-plan-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 8px;
}

.status-badge-active {
  font-size: 11px;
  color: var(--status-emerald);
  font-weight: 600;
}

.current-plan-name {
  font-size: 22px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 6px;
}

.current-plan-desc {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.plan-meta-details {
  display: flex;
  gap: 20px;
  font-size: 12px;
  color: var(--text-muted);
  flex-wrap: wrap;
}

.plan-card-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 16px;
}

.price-box {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.price-num {
  font-size: 32px;
  font-weight: 700;
  color: var(--accent-cyan);
}

.price-period {
  font-size: 12px;
  color: var(--text-muted);
}

.plan-card-actions {
  display: flex;
  gap: 10px;
}

.btn-cancel-plan {
  color: var(--status-crimson);
}

/* Quota Store */
.quota-store-section {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px;
  margin-bottom: 40px;
}

.quota-store-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.current-topup-badge {
  border: 1px solid var(--border-subtle);
  padding: 8px 14px;
  border-radius: var(--radius-xs);
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.badge-label {
  font-size: 10px;
  color: var(--text-muted);
}

.badge-val {
  font-size: 13px;
  font-weight: 700;
  color: var(--status-emerald);
}

.topup-packs-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.topup-pack-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-sm);
  padding: 20px 16px;
  text-align: center;
  position: relative;
}
.topup-pack-card.popular {
  border-color: var(--accent-cyan);
}

.pack-badge {
  position: absolute;
  top: -10px;
  right: 12px;
}

.pack-count {
  display: block;
  font-size: 24px;
  font-weight: 700;
  color: #ffffff;
}

.pack-sub {
  display: block;
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 12px;
}

.pack-price-tag {
  font-size: 16px;
  font-weight: 700;
  color: var(--accent-cyan);
  margin-bottom: 16px;
}

.btn-buy-pack {
  width: 100%;
}

/* Tier Switch */
.plan-switch-section {
  margin-bottom: 40px;
}

.tier-cards-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-top: 18px;
}

.tier-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.tier-card.tier-active {
  border-color: var(--status-emerald);
}

.tier-card-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 8px;
}

.tier-title {
  font-size: 16px;
  font-weight: 700;
  color: #ffffff;
}

.tier-price {
  font-size: 15px;
  font-weight: 700;
  color: var(--text-primary);
}

.tier-sub {
  font-size: 10px;
  color: var(--text-muted);
}

.tier-summary {
  font-size: 11px;
  color: var(--text-muted);
  margin-bottom: 14px;
}

.tier-features-mini {
  list-style: none;
  font-size: 11px;
  color: var(--text-secondary);
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 20px;
  margin-top: auto;
}

/* Invoices Table */
.invoices-section {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px;
}

.invoices-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  margin-top: 14px;
}

.invoices-table th,
.invoices-table td {
  padding: 10px 12px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

.invoices-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
}

@media (max-width: 900px) {
  .topup-packs-grid,
  .tier-cards-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .topup-packs-grid,
  .tier-cards-grid {
    grid-template-columns: 1fr;
  }
}
</style>
