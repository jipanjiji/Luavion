<template>
  <div class="dashboard-page">
    <div class="container dashboard-container">
      <!-- Top Welcome Banner -->
      <div class="dashboard-head">
        <div class="head-left">
          <h1 class="dash-title">
            Developer Workspace
          </h1>
          <p class="dash-sub">
            Welcome back, <strong>{{ user?.displayName || user?.email }}</strong>. Monitor compiler telemetry, quota consumption, and active keys.
          </p>
        </div>

        <div class="head-right">
          <NuxtLink to="/app" class="btn btn-accent btn-launch">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polygon points="5 3 19 12 5 21 5 3"></polygon>
            </svg>
            <span>Launch Obfuscator Studio</span>
          </NuxtLink>
        </div>
      </div>

      <!-- KPI Summary Cards Grid -->
      <div class="kpi-grid">
        <!-- Card 1: Subscription Tier -->
        <div class="surface kpi-card">
          <div class="kpi-header">
            <span class="kpi-label">SUBSCRIPTION PLAN</span>
            <span class="badge" :class="`badge-plan-${user?.plan}`">
              {{ (user?.plan || 'free').toUpperCase() }}
            </span>
          </div>
          <div class="kpi-main-val">
            {{ user?.planConfig?.name || 'Free Tier' }}
          </div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">
              {{ user?.planExpiresAt ? `Renews on ${new Date(user.planExpiresAt).toLocaleDateString()}` : 'Free Forever' }}
            </span>
            <NuxtLink to="/billing" class="kpi-action-link">
              Manage Plan →
            </NuxtLink>
          </div>
        </div>

        <!-- Card 2: Quota Meter -->
        <div class="surface kpi-card">
          <div class="kpi-header">
            <span class="kpi-label">MONTHLY QUOTA USAGE</span>
            <button class="topup-pill-btn" @click="showTopUpModal = true">
              + Top-Up
            </button>
          </div>
          <div class="kpi-main-val">
            {{ user?.quotaUsed || 0 }} <span class="val-sub">/ {{ (user?.quotaLimit || 50).toLocaleString() }}</span>
          </div>
          <div class="quota-progress-track">
            <div class="quota-progress-fill" :style="{ width: `${quotaPercentage}%` }"></div>
          </div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">
              {{ user?.quotaRemaining || 0 }} remaining 
              <span v-if="user?.quotaTopUp">({{ user.quotaTopUp }} top-up credits)</span>
            </span>
            <span class="quota-pct-label">{{ quotaPercentage }}% used</span>
          </div>
        </div>

        <!-- Card 3: Max File Size -->
        <div class="surface kpi-card">
          <div class="kpi-header">
            <span class="kpi-label">PAYLOAD CAPACITY</span>
            <span class="badge badge-subtle">PER-FILE</span>
          </div>
          <div class="kpi-main-val">
            {{ user?.planConfig?.maxFileSizeLabel || '50 KB' }}
          </div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">
              Batch limit: {{ user?.planConfig?.maxBatchFiles > 1 ? `${user.planConfig.maxBatchFiles} files` : 'Single file' }}
            </span>
            <NuxtLink v-if="user?.plan !== 'ultra'" to="/pricing" class="kpi-action-link">
              Upgrade →
            </NuxtLink>
          </div>
        </div>

        <!-- Card 4: API Access -->
        <div class="surface kpi-card">
          <div class="kpi-header">
            <span class="kpi-label">PUBLIC REST API</span>
            <span v-if="user?.plan === 'ultra'" class="badge badge-emerald">ACTIVE</span>
            <span v-else class="badge badge-amber">ULTRA ONLY</span>
          </div>
          <div class="kpi-main-val">
            {{ user?.plan === 'ultra' ? '60 req / min' : 'Locked' }}
          </div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">
              {{ user?.plan === 'ultra' ? 'Dedicated SLA routing' : 'Requires Ultra subscription' }}
            </span>
            <NuxtLink to="/keys" class="kpi-action-link">
              {{ user?.plan === 'ultra' ? 'Manage Keys →' : 'Unlock API →' }}
            </NuxtLink>
          </div>
        </div>
      </div>

      <!-- Quick Navigation Hub Cards -->
      <div class="hub-grid">
        <NuxtLink to="/app" class="surface hub-card">
          <div class="hub-icon icon-cyan">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="16 18 22 12 16 6"></polyline>
              <polyline points="8 6 2 12 8 18"></polyline>
            </svg>
          </div>
          <div class="hub-text">
            <h3 class="hub-title">Obfuscator Studio</h3>
            <p class="hub-desc">Open the dual-pane code compiler with Galois micro-ops.</p>
          </div>
        </NuxtLink>

        <NuxtLink to="/history" class="surface hub-card">
          <div class="hub-icon icon-emerald">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"></circle>
              <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
          </div>
          <div class="hub-text">
            <h3 class="hub-title">Obfuscation History</h3>
            <p class="hub-desc">Review and re-download past outputs stored in your cloud vault.</p>
          </div>
        </NuxtLink>

        <NuxtLink to="/billing" class="surface hub-card">
          <div class="hub-icon icon-purple">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
              <line x1="1" y1="10" x2="23" y2="10"></line>
            </svg>
          </div>
          <div class="hub-text">
            <h3 class="hub-title">Billing & Top-Ups</h3>
            <p class="hub-desc">Manage your subscription, invoices, and purchase extra quota.</p>
          </div>
        </NuxtLink>

        <NuxtLink to="/docs/api" class="surface hub-card">
          <div class="hub-icon icon-amber">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
              <polyline points="14 2 14 8 20 8"></polyline>
              <line x1="16" y1="13" x2="8" y2="13"></line>
              <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
          </div>
          <div class="hub-text">
            <h3 class="hub-title">API Documentation</h3>
            <p class="hub-desc">Explore REST endpoint references, cURL examples, and webhooks.</p>
          </div>
        </NuxtLink>
      </div>

      <!-- Activity Telemetry & Recent Jobs Section -->
      <div class="dashboard-activity-row">
        <!-- Left: Telemetry Chart Breakdown -->
        <div class="surface chart-card">
          <div class="section-card-head">
            <h2 class="card-title">Compilation Throughput</h2>
            <span class="badge badge-subtle">Last 7 Days</span>
          </div>

          <!-- CSS Bar Chart Visualization -->
          <div class="chart-bars-wrap">
            <div class="bar-col" v-for="(day, i) in sampleDailyStats" :key="i">
              <div class="bar-track">
                <div class="bar-fill" :style="{ height: `${day.pct}%` }"></div>
              </div>
              <span class="bar-label">{{ day.label }}</span>
            </div>
          </div>
          <div class="chart-footer">
            <span class="chart-legend">
              <span class="legend-dot"></span>
              <span>Successful Obfuscations (Avg latency: 42ms)</span>
            </span>
          </div>
        </div>

        <!-- Right: Recent Obfuscations Table Snippet -->
        <div class="surface recent-card">
          <div class="section-card-head">
            <h2 class="card-title">Recent Outputs</h2>
            <NuxtLink to="/history" class="view-all-link">View All History →</NuxtLink>
          </div>

          <div v-if="loadingHistory" class="history-loading">
            Loading cloud vault...
          </div>
          <div v-else-if="recentHistory.length === 0" class="history-empty">
            <p>No past obfuscations in your history yet.</p>
            <NuxtLink to="/app" class="btn btn-secondary btn-xs" style="margin-top: 8px;">
              Obfuscate Your First Script
            </NuxtLink>
          </div>
          <div v-else class="recent-table-wrap">
            <table class="recent-table">
              <thead>
                <tr>
                  <th>Script</th>
                  <th>Preset</th>
                  <th>Ratio</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="h in recentHistory" :key="h.id">
                  <td class="cell-name">
                    <span class="script-title">{{ h.filename }}</span>
                    <span class="script-time">{{ new Date(h.created_at).toLocaleDateString() }}</span>
                  </td>
                  <td>
                    <span class="badge badge-subtle">{{ h.preset }}</span>
                  </td>
                  <td class="cell-ratio">{{ h.expansion_ratio }}x</td>
                  <td>
                    <button class="btn btn-ghost btn-xs" @click="downloadScript(h)" title="Re-download">
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                      </svg>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Top Up Modal Component -->
      <TopUpModal v-model="showTopUpModal" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const { user, quotaPercentage, showToast } = useUser()

const showTopUpModal = ref(false)
const loadingHistory = ref(false)
const recentHistory = ref([])

const sampleDailyStats = [
  { label: 'Mon', pct: 25 },
  { label: 'Tue', pct: 45 },
  { label: 'Wed', pct: 80 },
  { label: 'Thu', pct: 60 },
  { label: 'Fri', pct: 90 },
  { label: 'Sat', pct: 40 },
  { label: 'Sun', pct: 70 }
]

useHead({
  title: 'Workspace Dashboard | Luavion',
  meta: [
    { name: 'description', content: 'Luavion user workspace dashboard: monitor compilation quota, manage subscription tier, and review recent cloud outputs.' }
  ]
})

const fetchRecentHistory = async () => {
  try {
    loadingHistory.value = true
    const res = await $fetch('/api/history')
    recentHistory.value = (res.history || []).slice(0, 5)
  } catch (err) {
    console.error('Failed to load history:', err)
  } finally {
    loadingHistory.value = false
  }
}

const downloadScript = async (item) => {
  try {
    const res = await $fetch(`/api/history/${item.id}`)
    if (res?.item?.obfuscated_code) {
      const blob = new Blob([res.item.obfuscated_code], { type: 'text/plain;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = item.filename.replace(/\.lua$/i, '') + '.protected.lua'
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
      showToast('Downloaded script output', 'success')
    } else {
      showToast('Script content has expired or is not stored for this tier.', 'info')
    }
  } catch (err) {
    showToast('Failed to download script', 'error')
  }
}

onMounted(() => {
  fetchRecentHistory()
})
</script>

<style scoped>
.dashboard-page {
  padding: 48px 0 96px;
  min-height: 80vh;
}

.dashboard-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 36px;
  flex-wrap: wrap;
  gap: 20px;
}

.dash-title {
  font-size: 26px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.dash-sub {
  font-size: 13px;
  color: var(--text-secondary);
}

.btn-launch {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
}

/* KPI Grid */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 18px;
  margin-bottom: 28px;
}

.kpi-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.kpi-label {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}

.topup-pill-btn {
  background: rgba(16, 185, 129, 0.12);
  border: 1px solid rgba(16, 185, 129, 0.3);
  color: #10b981;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: var(--radius-full);
  cursor: pointer;
}
.topup-pill-btn:hover {
  background: rgba(16, 185, 129, 0.2);
}

.kpi-main-val {
  font-size: 24px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 10px;
  letter-spacing: -0.02em;
}

.val-sub {
  font-size: 14px;
  font-weight: 400;
  color: var(--text-muted);
}

.quota-progress-track {
  height: 5px;
  background: var(--bg-surface-raised);
  border-radius: 999px;
  overflow: hidden;
  margin-bottom: 12px;
}

.quota-progress-fill {
  height: 100%;
  background: var(--accent-cyan);
  transition: width 0.3s;
}

.kpi-footer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  font-size: 11px;
}

.kpi-sub {
  color: var(--text-muted);
}

.kpi-action-link {
  color: var(--accent-cyan);
  text-decoration: none;
  font-weight: 600;
}
.kpi-action-link:hover {
  text-decoration: underline;
}

.quota-pct-label {
  color: var(--accent-cyan);
  font-weight: 600;
}

/* Hub Grid */
.hub-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 36px;
}

.hub-card {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 18px;
  display: flex;
  align-items: flex-start;
  gap: 14px;
  text-decoration: none;
  transition: all var(--duration-fast);
}
.hub-card:hover {
  border-color: var(--border-hover);
  background: var(--bg-elevated);
  transform: translateY(-2px);
}

.hub-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-xs);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.icon-cyan { background: rgba(0, 240, 255, 0.1); color: var(--accent-cyan); }
.icon-emerald { background: rgba(16, 185, 129, 0.1); color: var(--status-emerald); }
.icon-purple { background: rgba(168, 85, 247, 0.1); color: #c084fc; }
.icon-amber { background: rgba(245, 158, 11, 0.1); color: #fbbf24; }

.hub-title {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 4px;
}

.hub-desc {
  font-size: 11px;
  color: var(--text-muted);
  line-height: 1.4;
}

/* Activity Row */
.dashboard-activity-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.chart-card,
.recent-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 24px;
}

.section-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card-title {
  font-size: 15px;
  font-weight: 700;
  color: #ffffff;
}

.view-all-link {
  font-size: 11px;
  color: var(--accent-cyan);
  text-decoration: none;
}
.view-all-link:hover {
  text-decoration: underline;
}

/* Chart */
.chart-bars-wrap {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  height: 140px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border-subtle);
  margin-bottom: 14px;
}

.bar-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.bar-track {
  width: 24px;
  height: 100px;
  background: var(--bg-surface-raised);
  border-radius: 4px;
  display: flex;
  align-items: flex-end;
  overflow: hidden;
}

.bar-fill {
  width: 100%;
  background: var(--accent-cyan);
  border-radius: 4px 4px 0 0;
  transition: height 0.5s ease;
}

.bar-label {
  font-size: 10px;
  color: var(--text-muted);
}

.chart-footer {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: var(--text-muted);
}

.chart-legend {
  display: flex;
  align-items: center;
  gap: 6px;
}

.legend-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent-cyan);
}

/* Recent Table */
.recent-table-wrap {
  overflow-x: auto;
}

.recent-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.recent-table th,
.recent-table td {
  padding: 8px 10px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

.recent-table th {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}

.cell-name {
  display: flex;
  flex-direction: column;
}

.script-title {
  font-weight: 500;
  color: var(--text-primary);
}

.script-time {
  font-size: 10px;
  color: var(--text-muted);
}

.cell-ratio {
  color: var(--status-emerald);
  font-weight: 600;
}

.history-loading,
.history-empty {
  padding: 36px 12px;
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
}

@media (max-width: 1024px) {
  .kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .hub-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .dashboard-activity-row {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 680px) {
  .kpi-grid {
    grid-template-columns: 1fr;
  }
  .hub-grid {
    grid-template-columns: 1fr;
  }
}
</style>
