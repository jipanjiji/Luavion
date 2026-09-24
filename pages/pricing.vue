<template>
  <div class="pricing-page">
    <div class="container pricing-container">
      <!-- Section Header -->
      <div class="pricing-header">
        <div class="pricing-tag">
          <span class="status-dot dot-cyan"></span>
          <span>TIERED SUBSCRIPTION ARCHITECTURE</span>
        </div>
        <h1 class="pricing-title">Predictable Pricing for High-Assurance Protection</h1>
        <p class="pricing-subtitle">
          From independent script developers to enterprise studios. Choose the right obfuscation throughput, file limits, and API integration for your workflow.
        </p>

        <!-- Currency Toggle -->
        <div class="currency-toggle-wrap">
          <span class="curr-label">CURRENCY:</span>
          <div class="segmented-control currency-control">
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

      <!-- Pricing Tier Cards Grid -->
      <div class="plans-grid">
        <div 
          v-for="p in Object.values(plans)" 
          :key="p.id" 
          class="surface plan-card"
          :class="{ 'card-featured': p.id === 'pro', 'card-ultra': p.id === 'ultra' }"
        >
          <div class="plan-card-top">
            <div class="plan-badge-row">
              <span class="plan-name">{{ p.name }}</span>
              <span v-if="p.badge" class="badge" :class="p.id === 'pro' ? 'badge-cyan' : p.id === 'ultra' ? 'badge-ultra' : 'badge-subtle'">
                {{ p.badge }}
              </span>
            </div>
            
            <div class="plan-price-row">
              <span class="plan-price">{{ formatPrice(p.priceUsd, p.priceIdr) }}</span>
              <span class="plan-cycle">/month</span>
            </div>
            
            <p class="plan-summary">
              {{ p.id === 'free' ? 'Essential protection for hobbyists and community scripts.' :
                 p.id === 'plus' ? 'Expanded file sizes and Anti-Tamper for active developers.' :
                 p.id === 'pro' ? 'Extreme Galois VM, batch compilation, and saved presets.' :
                 'Full programmatic REST API access, webhooks, and enterprise throughput.' }}
            </p>
          </div>

          <div class="plan-cta-wrap">
            <NuxtLink 
              v-if="user?.plan === p.id" 
              to="/app" 
              class="btn btn-secondary btn-block"
            >
              Current Active Plan
            </NuxtLink>
            <NuxtLink 
              v-else-if="p.id === 'free'" 
              to="/app" 
              class="btn btn-secondary btn-block"
            >
              Start Free
            </NuxtLink>
            <NuxtLink 
              v-else 
              :to="`/billing?upgrade=${p.id}`" 
              class="btn btn-block"
              :class="p.id === 'pro' ? 'btn-accent' : p.id === 'ultra' ? 'btn-ultra' : 'btn-primary'"
            >
              <span>Upgrade to {{ p.name }}</span>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
              </svg>
            </NuxtLink>
          </div>

          <div class="plan-features-block">
            <span class="features-label">INCLUDED SPECIFICATIONS:</span>
            <ul class="features-list">
              <li class="feature-item highlight-feat">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span><strong>{{ p.quotaMonthly.toLocaleString() }}</strong> obfuscations / month</span>
              </li>
              <li class="feature-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span>Up to <strong>{{ p.maxFileSizeLabel }}</strong> per file</span>
              </li>
              <li class="feature-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span>
                  {{ p.maxBatchFiles > 1 ? `Batch compilation (up to ${p.maxBatchFiles} files)` : 'Single file compilation' }}
                </span>
              </li>
              <li class="feature-item" :class="{ 'api-locked': !p.hasApiAccess }">
                <svg v-if="p.hasApiAccess" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk chk-ultra">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="cross">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
                <span><strong>Public REST API Access</strong> {{ p.hasApiAccess ? '(60 req/min)' : '—' }}</span>
              </li>
              <li class="feature-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span>{{ p.historyRetentionDays > 0 ? `${p.historyRetentionDays} days cloud history` : 'No history storage' }}</span>
              </li>
              <li class="feature-item">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chk">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span>{{ p.supportLevel }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Quota Top-Up Addon Section -->
      <section class="topup-promo-section surface">
        <div class="topup-promo-content">
          <div class="topup-promo-text">
            <span class="badge badge-emerald">PAY-AS-YOU-GO ADD-ON</span>
            <h2 class="topup-promo-title">Need Extra Obfuscations? Top-Up Anytime</h2>
            <p class="topup-promo-desc">
              All plans can purchase immediate quota top-ups at only <strong>{{ formatUnitRate(topUpPricing.unitPriceUsd, topUpPricing.unitPriceIdr) }}</strong> per script. Top-up credits never expire and roll over indefinitely.
            </p>
          </div>
          <div class="topup-packs-preview">
            <div class="topup-pack-pill" v-for="pack in topUpPricing.packs" :key="pack.count">
              <span class="pack-pill-num">+{{ pack.count }}</span>
              <span class="pack-pill-price">{{ formatPrice(pack.priceUsd, pack.priceIdr) }}</span>
            </div>
            <button class="btn btn-secondary btn-sm" @click="showTopUpModal = true">
              Buy Top-Up Credits
            </button>
          </div>
        </div>
      </section>

      <!-- Detailed Benefit Comparison Matrix -->
      <section class="matrix-section">
        <div class="matrix-heading">
          <h2 class="section-title">Comprehensive Feature Comparison</h2>
          <p class="section-subtitle">A granular technical breakdown of capabilities across all four subscription tiers.</p>
        </div>

        <div class="surface matrix-card">
          <div class="table-scroller">
            <table class="matrix-table">
              <thead>
                <tr>
                  <th class="col-feature">Platform Capability</th>
                  <th class="col-plan">Free</th>
                  <th class="col-plan">Plus</th>
                  <th class="col-plan highlight-col">Pro</th>
                  <th class="col-plan ultra-col">Ultra</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="feature-cell">Monthly Obfuscations</td>
                  <td>50 / mo</td>
                  <td>500 / mo</td>
                  <td class="highlight-cell">3,000 / mo</td>
                  <td class="ultra-cell">7,500 / mo</td>
                </tr>
                <tr>
                  <td class="feature-cell">Maximum File Size</td>
                  <td>50 KB</td>
                  <td>250 KB</td>
                  <td class="highlight-cell">1 MB</td>
                  <td class="ultra-cell">5 MB</td>
                </tr>
                <tr>
                  <td class="feature-cell">Batch Obfuscation</td>
                  <td><span class="cross-icon">✕</span></td>
                  <td><span class="cross-icon">✕</span></td>
                  <td class="highlight-cell">Up to 10 files</td>
                  <td class="ultra-cell">Up to 100 files</td>
                </tr>
                <tr>
                  <td class="feature-cell">Security Presets</td>
                  <td>Basic Presets</td>
                  <td>Basic + Hard</td>
                  <td class="highlight-cell">All Advanced (incl. Extreme)</td>
                  <td class="ultra-cell">All Presets + Experimental</td>
                </tr>
                <tr>
                  <td class="feature-cell">Custom Presets Storage</td>
                  <td><span class="cross-icon">✕</span></td>
                  <td><span class="cross-icon">✕</span></td>
                  <td class="highlight-cell">Up to 3 presets</td>
                  <td class="ultra-cell">Unlimited presets</td>
                </tr>
                <tr>
                  <td class="feature-cell">Processing Queue Priority</td>
                  <td>Standard</td>
                  <td>Standard</td>
                  <td class="highlight-cell">Priority Queue</td>
                  <td class="ultra-cell">Highest Dedicated SLA</td>
                </tr>
                <tr>
                  <td class="feature-cell">Cloud History Retention</td>
                  <td>None (Ephemeral)</td>
                  <td>7 Days</td>
                  <td class="highlight-cell">30 Days</td>
                  <td class="ultra-cell">90 Days</td>
                </tr>
                <tr>
                  <td class="feature-cell">Steganographic AI Prompt Shield</td>
                  <td><span class="check-icon">✓</span></td>
                  <td><span class="check-icon">✓</span></td>
                  <td class="highlight-cell"><span class="check-icon">✓</span></td>
                  <td class="ultra-cell"><span class="check-icon">✓</span></td>
                </tr>
                <tr>
                  <td class="feature-cell">Roblox Vector3 Attestation</td>
                  <td><span class="check-icon">✓</span></td>
                  <td><span class="check-icon">✓</span></td>
                  <td class="highlight-cell"><span class="check-icon">✓</span></td>
                  <td class="ultra-cell"><span class="check-icon">✓</span></td>
                </tr>
                <tr class="api-highlight-row">
                  <td class="feature-cell"><strong>Public REST API Access</strong></td>
                  <td><span class="cross-icon">✕</span></td>
                  <td><span class="cross-icon">✕</span></td>
                  <td class="highlight-cell"><span class="cross-icon">✕</span></td>
                  <td class="ultra-cell"><span class="badge badge-ultra">Included (60 req/min)</span></td>
                </tr>
                <tr>
                  <td class="feature-cell">Webhook Notifications</td>
                  <td><span class="cross-icon">✕</span></td>
                  <td><span class="cross-icon">✕</span></td>
                  <td class="highlight-cell"><span class="cross-icon">✕</span></td>
                  <td class="ultra-cell"><span class="check-icon">✓</span></td>
                </tr>
                <tr>
                  <td class="feature-cell">Quota Top-Up Available</td>
                  <td><span class="check-icon">✓</span></td>
                  <td><span class="check-icon">✓</span></td>
                  <td class="highlight-cell"><span class="check-icon">✓</span></td>
                  <td class="ultra-cell"><span class="check-icon">✓</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- Frequently Asked Questions -->
      <section class="faq-section">
        <div class="faq-heading">
          <h2 class="section-title">Billing & Subscription FAQ</h2>
        </div>

        <div class="faq-grid">
          <div class="surface faq-card">
            <h3 class="faq-q">Can I upgrade or downgrade my plan at any time?</h3>
            <p class="faq-a">
              Yes. You can upgrade instantly to gain access to higher throughput, larger file limits, or API access. Upgrades take effect immediately. Downgrades take effect at the conclusion of your current billing period.
            </p>
          </div>

          <div class="surface faq-card">
            <h3 class="faq-q">What payment methods and currencies do you support?</h3>
            <p class="faq-a">
              We support international credit cards, debit cards, and Apple Pay via Stripe in USD. For customers in Indonesia, we support QRIS, GoPay, and Virtual Accounts via Indonesian Gateway (Midtrans) in IDR.
            </p>
          </div>

          <div class="surface faq-card">
            <h3 class="faq-q">What happens if I exceed my monthly obfuscation quota?</h3>
            <p class="faq-a">
              You can purchase Pay-As-You-Go quota top-up credits ($0.50 / Rp 5,000 per obfuscation) at any time without having to change your overall plan. Top-up credits never expire.
            </p>
          </div>

          <div class="surface faq-card">
            <h3 class="faq-q">Who gets access to the Public REST API?</h3>
            <p class="faq-a">
              REST API access is an exclusive feature of the Ultra plan ($30/mo or Rp 500,000/mo). Ultra customers can generate Bearer API keys to wire Luavion directly into GitHub Actions, GitLab CI/CD, or automated deployment scripts.
            </p>
          </div>
        </div>
      </section>

      <!-- Top-up Modal Component -->
      <TopUpModal v-model="showTopUpModal" />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { usePlans } from '~/composables/usePlans'
import { useUser } from '~/composables/useUser'

const { plans, topUpPricing, currency, formatPrice, formatUnitRate } = usePlans()
const { user } = useUser()

const showTopUpModal = ref(false)

useHead({
  title: 'Pricing & Plans | Luavion Lua Obfuscation',
  meta: [
    { name: 'description', content: 'Transparent tiered pricing for Luavion Luau and Lua 5.1 bytecode virtualization. Free, Plus, Pro, and Ultra tiers with public REST API access.' }
  ]
})
</script>

<style scoped>
.pricing-page {
  padding: 64px 0 96px;
  min-height: 80vh;
}

.pricing-header {
  text-align: center;
  max-width: 680px;
  margin: 0 auto 56px;
}

.pricing-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 700;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 12px;
}

.pricing-title {
  font-size: 36px;
  font-weight: 700;
  letter-spacing: -0.03em;
  color: #ffffff;
  margin-bottom: 16px;
  line-height: 1.2;
}

.pricing-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
  line-height: 1.6;
  margin-bottom: 28px;
}

.currency-toggle-wrap {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  padding: 6px 14px;
  border-radius: var(--radius-full);
}

.curr-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.06em;
}

.currency-control {
  border-radius: var(--radius-full);
}

/* Plans Grid */
.plans-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  margin-bottom: 56px;
}

.plan-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px 24px;
  display: flex;
  flex-direction: column;
  position: relative;
  transition: all var(--duration-fast);
}

.card-featured {
  border-color: var(--accent-cyan-border);
  box-shadow: 0 0 24px rgba(0, 240, 255, 0.1);
}

.card-ultra {
  border-color: rgba(168, 85, 247, 0.4);
  box-shadow: 0 0 24px rgba(168, 85, 247, 0.1);
}

.plan-badge-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.plan-name {
  font-size: 18px;
  font-weight: 700;
  color: #ffffff;
}

.badge-ultra {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.2), rgba(0, 240, 255, 0.2));
  color: #c084fc;
  border: 1px solid rgba(168, 85, 247, 0.4);
}

.plan-price-row {
  display: flex;
  align-items: baseline;
  gap: 4px;
  margin-bottom: 12px;
}

.plan-price {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.plan-cycle {
  font-size: 12px;
  color: var(--text-muted);
}

.plan-summary {
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1.5;
  margin-bottom: 24px;
  min-height: 36px;
}

.plan-cta-wrap {
  margin-bottom: 24px;
}

.btn-block {
  width: 100%;
  display: flex;
  justify-content: center;
}

.btn-ultra {
  background: linear-gradient(135deg, #a855f7, #00f0ff);
  color: var(--bg-void);
  font-weight: 700;
  border: none;
}

.features-label {
  display: block;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--text-muted);
  margin-bottom: 12px;
}

.features-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.feature-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.4;
}

.chk {
  color: var(--status-emerald);
  flex-shrink: 0;
  margin-top: 2px;
}

.chk-ultra {
  color: #c084fc;
}

.cross {
  color: var(--text-faint);
  flex-shrink: 0;
  margin-top: 2px;
}

.api-locked {
  opacity: 0.5;
}

/* Top-Up Section */
.topup-promo-section {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px 32px;
  margin-bottom: 64px;
  background: var(--bg-surface-raised);
}

.topup-promo-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 32px;
  flex-wrap: wrap;
}

.topup-promo-text {
  max-width: 540px;
}

.topup-promo-title {
  font-size: 20px;
  font-weight: 700;
  color: #ffffff;
  margin: 10px 0 8px;
}

.topup-promo-desc {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.topup-packs-preview {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.topup-pack-pill {
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  display: flex;
  flex-direction: column;
  align-items: center;
}

.pack-pill-num {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
}

.pack-pill-price {
  font-size: 11px;
  color: var(--accent-cyan);
}

/* Matrix Table */
.matrix-section {
  margin-bottom: 64px;
}

.matrix-heading {
  text-align: center;
  margin-bottom: 32px;
}

.matrix-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.matrix-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.matrix-table th,
.matrix-table td {
  padding: 14px 18px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

.matrix-table th {
  background: var(--bg-surface-raised);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}

.feature-cell {
  font-weight: 500;
  color: var(--text-primary);
}

.highlight-col,
.highlight-cell {
  background: rgba(0, 240, 255, 0.03);
}

.ultra-col,
.ultra-cell {
  background: rgba(168, 85, 247, 0.03);
}

.check-icon {
  color: var(--status-emerald);
  font-weight: 700;
}

.cross-icon {
  color: var(--text-faint);
}

.api-highlight-row {
  background: rgba(168, 85, 247, 0.05);
}

/* FAQ */
.faq-section {
  margin-top: 56px;
}

.faq-heading {
  text-align: center;
  margin-bottom: 32px;
}

.faq-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.faq-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 24px;
}

.faq-q {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 10px;
}

.faq-a {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
}

@media (max-width: 1024px) {
  .plans-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 680px) {
  .plans-grid {
    grid-template-columns: 1fr;
  }
  .faq-grid {
    grid-template-columns: 1fr;
  }
}
</style>
