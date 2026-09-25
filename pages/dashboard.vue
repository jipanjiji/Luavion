<template>
  <div class="dashboard-page">
    <div class="dashboard-container">
      <div class="dashboard-head anim-fade-up">
        <div class="head-left">
          <h1 class="dash-title">Overview</h1>
          <p class="dash-sub">
            Welcome back, <strong>{{ user?.displayName || user?.email }}</strong> — telemetry, quota, and outputs at a glance.
          </p>
        </div>
        <NuxtLink to="/app" class="btn btn-primary">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
          </svg>
          New obfuscation
        </NuxtLink>
      </div>

      <div v-if="user?.plan === 'free'" class="upgrade-nudge anim-fade-up" style="animation-delay: 40ms">
        <div class="nudge-text">
          <strong>You're on the Free tier.</strong>
          <span>Unlock higher quotas, batch compilation, and cloud history retention.</span>
        </div>
        <NuxtLink to="/billing" class="btn btn-secondary btn-sm">View plans →</NuxtLink>
      </div>

      <!-- KPI Grid -->
      <div class="kpi-grid">
        <div class="surface kpi-card anim-fade-up" style="animation-delay: 60ms">
          <div class="kpi-header">
            <span class="t-label">Subscription plan</span>
            <span class="badge" :class="({ pro: 'badge-cyan', plus: 'badge-emerald', ultra: 'badge-amber' }[user?.plan] || '')">
              {{ (user?.plan || 'free').toUpperCase() }}
            </span>
          </div>
          <div class="kpi-main-val">{{ user?.planConfig?.name || 'Free Tier' }}</div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">{{ user?.planExpiresAt ? `Renews ${new Date(user.planExpiresAt).toLocaleDateString()}` : 'Free forever' }}</span>
            <NuxtLink to="/billing" class="kpi-action-link">Manage →</NuxtLink>
          </div>
        </div>

        <div class="surface kpi-card anim-fade-up" style="animation-delay: 120ms">
          <div class="kpi-header">
            <span class="t-label">Monthly quota</span>
            <button class="topup-pill-btn mono" @click="showTopUpModal = true">+ top-up</button>
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
            <span class="quota-pct-label mono">{{ quotaPercentage }}%</span>
          </div>
        </div>

        <div class="surface kpi-card anim-fade-up" style="animation-delay: 180ms">
          <div class="kpi-header">
            <span class="t-label">Payload capacity</span>
            <span class="badge">per-file</span>
          </div>
          <div class="kpi-main-val">{{ user?.planConfig?.maxFileSizeLabel || '50 KB' }}</div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">
              Batch: {{ user?.planConfig?.maxBatchFiles > 1 ? `${user.planConfig.maxBatchFiles} files` : 'single file' }}
            </span>
            <NuxtLink v-if="user?.plan !== 'ultra'" to="/pricing" class="kpi-action-link">Upgrade →</NuxtLink>
          </div>
        </div>

        <div class="surface kpi-card anim-fade-up" style="animation-delay: 240ms">
          <div class="kpi-header">
            <span class="t-label">Public REST API</span>
            <span v-if="user?.plan === 'ultra'" class="badge badge-emerald">active</span>
            <span v-else class="badge badge-amber">ultra only</span>
          </div>
          <div class="kpi-main-val">{{ user?.plan === 'ultra' ? '60 req / min' : 'Locked' }}</div>
          <div class="kpi-footer-row">
            <span class="kpi-sub">{{ user?.plan === 'ultra' ? 'Dedicated SLA routing' : 'Requires Ultra subscription' }}</span>
            <NuxtLink to="/keys" class="kpi-action-link">{{ user?.plan === 'ultra' ? 'Manage keys →' : 'Unlock →' }}</NuxtLink>
          </div>
        </div>
      </div>

      <!-- Activity -->
      <div class="dashboard-activity-row">
        <div class="surface chart-card anim-fade-up" style="animation-delay: 300ms">
          <div class="section-card-head">
            <h2 class="card-title">Compilation throughput</h2>
            <span class="badge">last 7 days</span>
          </div>
          <div class="chart-bars-wrap">
            <div class="bar-col" v-for="(day, i) in sampleDailyStats" :key="i">
              <div class="bar-track">
                <div class="bar-fill" :style="{ height: `${day.pct}%`, transitionDelay: 300 + i * 50 + 'ms' }"></div>
              </div>
              <span class="bar-label mono">{{ day.label }}</span>
            </div>
          </div>
          <div class="chart-footer">
            <span class="chart-legend">
              <span class="legend-dot"></span>
              <span>Successful obfuscations · avg latency 42ms</span>
            </span>
          </div>
        </div>

        <div class="surface recent-card anim-fade-up" style="animation-delay: 360ms">
          <div class="section-card-head">
            <h2 class="card-title">Recent outputs</h2>
            <NuxtLink to="/history" class="view-all-link">View all →</NuxtLink>
          </div>

          <div v-if="loadingHistory" class="skeleton-rows">
            <div v-for="i in 4" :key="i" class="skeleton sk-row"></div>
          </div>

          <UiEmptyState
            v-else-if="recentHistory.length === 0"
            title="No obfuscations yet"
            message="Your protected outputs stored in the cloud vault will appear here."
          >
            <NuxtLink to="/app" class="btn btn-secondary btn-sm">Obfuscate your first script</NuxtLink>
          </UiEmptyState>

          <div v-else class="recent-table-wrap">
            <table class="recent-table">
              <thead>
                <tr>
                  <th>Script</th>
                  <th>Preset</th>
                  <th>Ratio</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="h in recentHistory" :key="h.id">
                  <td class="cell-name">
                    <span class="script-title">{{ h.filename }}</span>
                    <span class="script-time mono">{{ new Date(h.created_at).toLocaleDateString() }}</span>
                  </td>
                  <td><span class="badge">{{ h.preset }}</span></td>
                  <td class="cell-ratio mono">{{ h.expansion_ratio }}x</td>
                  <td>
                    <button class="icon-btn" @click="downloadScript(h)" title="Re-download" aria-label="Download output">
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
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

      <TopUpModal v-model="showTopUpModal" />
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'dashboard' })
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
.dashboard-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.dash-title {
  font-size: 22px;
  font-weight: 600;
  letter-spacing: -0.025em;
  margin-bottom: 4px;
}

.dash-sub { font-size: 13px; color: var(--text-muted); }

.dash-sub strong { color: var(--text-primary); font-weight: 600; }

/* Upgrade nudge */
.upgrade-nudge {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 14px 18px;
  margin-bottom: 20px;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-left: 2px solid var(--text-primary);
  border-radius: var(--radius-md);
  flex-wrap: wrap;
}

.nudge-text { display: flex; flex-direction: column; gap: 2px; }

.nudge-text strong { font-size: 13px; font-weight: 600; }

.nudge-text span { font-size: 12px; color: var(--text-muted); }

/* KPI Grid */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 14px;
  margin-bottom: 24px;
}

.kpi-card {
  padding: 18px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 12px;
  border-radius: var(--radius-md);
}

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
}

.kpi-main-val {
  font-family: var(--font-mono);
  font-size: 26px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  position: relative;
  z-index: 1;
}

.val-sub { font-size: 14px; color: var(--text-faint); font-weight: 400; }

.kpi-footer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
}

.kpi-sub { font-size: 11px; color: var(--text-muted); max-width: 75%; }

.kpi-action-link {
  font-size: 11px;
  font-weight: 500;
  color: var(--text-secondary);
  white-space: nowrap;
}

.kpi-action-link:hover { color: var(--text-primary); }

.topup-pill-btn {
  font-size: 10px;
  font-weight: 600;
  color: var(--text-primary);
  background: var(--bg-elevated);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-full);
  padding: 4px 10px;
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.topup-pill-btn:hover { border-color: var(--border-hover); }

.quota-progress-track {
  width: 100%;
  height: 3px;
  background: var(--bg-overlay);
  border-radius: 999px;
  overflow: hidden;
  position: relative;
  z-index: 1;
}

.quota-progress-fill {
  height: 100%;
  background: var(--text-primary);
  border-radius: 999px;
  transition: width 700ms var(--ease-spring);
}

.quota-pct-label { font-size: 10px; color: var(--text-muted); }

/* Activity row */
.dashboard-activity-row {
  display: grid;
  grid-template-columns: 1fr 1.4fr;
  gap: 14px;
}

.chart-card, .recent-card {
  padding: 22px;
  border-radius: var(--radius-md);
}

.section-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.card-title { font-size: 15px; font-weight: 600; letter-spacing: -0.01em; }

.view-all-link { font-size: 12px; font-weight: 500; color: var(--text-muted); }

.view-all-link:hover { color: var(--text-primary); }

/* Chart */
.chart-bars-wrap {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  height: 130px;
  margin-bottom: 14px;
}

.bar-col { flex: 1; display: flex; flex-direction: column; align-items: center; height: 100%; }

.bar-track {
  width: 100%;
  height: calc(100% - 20px);
  background: var(--bg-base);
  border: 1px solid var(--border-faint);
  border-radius: var(--radius-xs);
  position: relative;
  overflow: hidden;
}

.bar-fill {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  background: linear-gradient(to top, rgba(255, 255, 255, 0.16), rgba(255, 255, 255, 0.05));
  border-top: 1px solid rgba(255, 255, 255, 0.35);
  transition: height 600ms var(--ease-spring);
}

.bar-label { font-size: 9px; color: var(--text-faint); margin-top: 8px; }

.chart-footer { display: flex; }

.chart-legend {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  color: var(--text-muted);
}

.legend-dot {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: var(--text-secondary);
}

/* Recent table */
.skeleton-rows { display: flex; flex-direction: column; gap: 10px; }

.sk-row { height: 42px; }

.recent-table-wrap { overflow: hidden; }

.recent-table { width: 100%; border-collapse: collapse; font-size: 13px; }

.recent-table th {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-faint);
  text-align: left;
  padding: 0 10px 10px 0;
  border-bottom: 1px solid var(--border-subtle);
}

.recent-table td { padding: 12px 10px 12px 0; border-bottom: 1px solid var(--border-faint); }

.recent-table tr:last-child td { border-bottom: none; }

.cell-name { display: flex; flex-direction: column; gap: 2px; }

.script-title { color: var(--text-primary); font-weight: 500; }

.script-time { font-size: 10px; color: var(--text-faint); }

.cell-ratio { font-size: 12px; color: var(--text-secondary); }

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  background: transparent;
  border: none;
  color: var(--text-muted);
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.icon-btn:hover {
  color: var(--text-primary);
  background: var(--accent-dimmer);
}

@media (max-width: 1024px) {
  .dashboard-activity-row { grid-template-columns: 1fr; }
}

@media (max-width: 640px) {
  .dashboard-head { margin-bottom: 18px; }
}
</style>
