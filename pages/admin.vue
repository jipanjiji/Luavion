<template>
  <div class="admin-page">
    <div class="container admin-container">
      <div class="admin-header">
        <div>
          <div class="admin-tag">
            <span class="status-dot dot-crimson"></span>
            <span>RESTRICTED ACCESS • ADMIN PANEL</span>
          </div>
          <h1 class="admin-title">System Administration & Telemetry</h1>
          <p class="admin-subtitle">
            Manage registered accounts, plan overrides, usage quotas, and inspect platform analytics.
          </p>
        </div>

        <div v-if="user?.role !== 'admin'" class="admin-switch-prompt surface-raised">
          <span class="prompt-text">You are currently logged in as a standard user.</span>
          <button class="btn btn-accent btn-xs" @click="elevateToAdmin">
            Simulate Admin Access
          </button>
        </div>
      </div>

      <!-- Overview KPI Cards -->
      <div class="kpi-grid">
        <div class="surface kpi-card">
          <span class="kpi-label">TOTAL REGISTERED USERS</span>
          <span class="kpi-val">{{ analytics?.totalUsers || 0 }}</span>
          <span class="kpi-sub">Across all subscription tiers</span>
        </div>

        <div class="surface kpi-card">
          <span class="kpi-label">ESTIMATED MRR (USD)</span>
          <span class="kpi-val text-cyan">${{ analytics?.estimatedMrrUsd || 0 }}</span>
          <span class="kpi-sub">Monthly Recurring Revenue</span>
        </div>

        <div class="surface kpi-card">
          <span class="kpi-label">TOTAL OBFUSCATIONS</span>
          <span class="kpi-val text-emerald">{{ analytics?.totalObfuscationsTracked || 0 }}</span>
          <span class="kpi-sub">Compiler executions tracked</span>
        </div>

        <div class="surface kpi-card">
          <span class="kpi-label">ACTIVE ULTRA API KEYS</span>
          <span class="kpi-val text-purple">{{ analytics?.activeApiKeys || 0 }}</span>
          <span class="kpi-sub">Programmatic keys in production</span>
        </div>
      </div>

      <!-- Plan Distribution Pill Row -->
      <div class="surface plan-dist-card">
        <span class="dist-label">SUBSCRIBER PLAN DISTRIBUTION:</span>
        <div class="dist-pills">
          <div class="dist-pill">
            <span class="pill-dot dot-gray"></span>
            <span>Free: <strong>{{ analytics?.planDistribution?.free || 0 }}</strong></span>
          </div>
          <div class="dist-pill">
            <span class="pill-dot dot-emerald"></span>
            <span>Plus: <strong>{{ analytics?.planDistribution?.plus || 0 }}</strong></span>
          </div>
          <div class="dist-pill">
            <span class="pill-dot dot-cyan"></span>
            <span>Pro: <strong>{{ analytics?.planDistribution?.pro || 0 }}</strong></span>
          </div>
          <div class="dist-pill">
            <span class="pill-dot dot-purple"></span>
            <span>Ultra: <strong>{{ analytics?.planDistribution?.ultra || 0 }}</strong></span>
          </div>
        </div>
      </div>

      <!-- User Management Section -->
      <section class="admin-section">
        <div class="section-head">
          <h2 class="section-title">User Account Management</h2>
          <div class="search-wrap">
            <input 
              type="text" 
              v-model="searchQuery" 
              placeholder="Search user email or name..." 
              class="admin-search-input"
              @input="searchUsers"
            />
          </div>
        </div>

        <div class="surface users-table-card">
          <div v-if="loadingUsers" class="admin-state">
            <span>Loading registered users...</span>
          </div>

          <div v-else class="table-scroller">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>User Profile</th>
                  <th>Current Plan</th>
                  <th>Role</th>
                  <th>Quota Used / Limit</th>
                  <th>Top-Up Credits</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="u in usersList" :key="u.id">
                  <td>
                    <div class="user-cell">
                      <span class="u-name">{{ u.display_name }}</span>
                      <span class="u-email">{{ u.email }}</span>
                    </div>
                  </td>
                  <td>
                    <select 
                      v-model="u.plan" 
                      class="admin-select"
                      @change="updateUser(u)"
                    >
                      <option value="free">Free</option>
                      <option value="plus">Plus</option>
                      <option value="pro">Pro</option>
                      <option value="ultra">Ultra</option>
                    </select>
                  </td>
                  <td>
                    <select 
                      v-model="u.role" 
                      class="admin-select"
                      @change="updateUser(u)"
                    >
                      <option value="user">User</option>
                      <option value="support">Support</option>
                      <option value="admin">Admin</option>
                    </select>
                  </td>
                  <td>
                    <span class="quota-val">{{ u.quota_used_this_month }} / {{ u.quota_monthly_limit }}</span>
                  </td>
                  <td>
                    <span class="topup-val">+{{ u.quota_topup_balance || 0 }}</span>
                  </td>
                  <td>
                    <button class="btn btn-secondary btn-xs" @click="grantBonusQuota(u)">
                      +50 Bonus Quota
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- Audit Logs Section -->
      <section class="admin-section">
        <h2 class="section-title">Security & Administrative Audit Trail</h2>
        <div class="surface logs-table-card">
          <div v-if="loadingLogs" class="admin-state">
            <span>Loading audit log entries...</span>
          </div>
          <div v-else-if="auditLogs.length === 0" class="admin-state">
            <span>No administrative actions recorded yet.</span>
          </div>
          <div v-else class="table-scroller">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Action / Event</th>
                  <th>Target User ID</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="log in auditLogs" :key="log.id">
                  <td class="text-muted">{{ new Date(log.created_at).toLocaleString() }}</td>
                  <td class="font-bold">{{ log.action }}</td>
                  <td class="font-mono text-muted">{{ log.target_user_id || '—' }}</td>
                  <td>
                    <code class="details-json">{{ JSON.stringify(log.details) }}</code>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const { user, switchPlan, showToast } = useUser()

const analytics = ref(null)
const usersList = ref([])
const auditLogs = ref([])
const searchQuery = ref('')
const loadingUsers = ref(true)
const loadingLogs = ref(true)

useHead({
  title: 'Admin Control Panel | Luavion Platform',
  meta: [
    { name: 'description', content: 'Luavion administration control panel: platform analytics, user accounts, and audit log inspection.' }
  ]
})

const elevateToAdmin = async () => {
  await switchPlan(user.value?.plan || 'pro', 'admin')
  loadAllAdminData()
}

const loadAnalytics = async () => {
  try {
    const res = await $fetch('/api/admin/analytics')
    analytics.value = res
  } catch (err) {
    console.error('Failed to load analytics:', err)
  }
}

const loadUsers = async () => {
  try {
    loadingUsers.value = true
    const res = await $fetch(`/api/admin/users?search=${encodeURIComponent(searchQuery.value)}`)
    usersList.value = res.users || []
  } catch (err) {
    console.error('Failed to load users:', err)
  } finally {
    loadingUsers.value = false
  }
}

const loadAuditLogs = async () => {
  try {
    loadingLogs.value = true
    const res = await $fetch('/api/admin/audit-logs')
    auditLogs.value = res.logs || []
  } catch (err) {
    console.error('Failed to load audit logs:', err)
  } finally {
    loadingLogs.value = false
  }
}

const searchUsers = () => {
  loadUsers()
}

const updateUser = async (targetUser) => {
  try {
    const res = await $fetch('/api/admin/user', {
      method: 'PUT',
      body: {
        userId: targetUser.id,
        plan: targetUser.plan,
        role: targetUser.role
      }
    })
    if (res.ok) {
      showToast(`Updated user ${targetUser.email} to ${targetUser.plan.toUpperCase()} (${targetUser.role})`, 'success')
      await loadAnalytics()
      await loadAuditLogs()
    }
  } catch (err) {
    showToast('Failed to update user', 'error')
  }
}

const grantBonusQuota = async (targetUser) => {
  try {
    const res = await $fetch('/api/admin/user', {
      method: 'PUT',
      body: {
        userId: targetUser.id,
        quotaTopupBonus: 50
      }
    })
    if (res.ok) {
      targetUser.quota_topup_balance = (targetUser.quota_topup_balance || 0) + 50
      showToast(`Granted +50 bonus obfuscations to ${targetUser.email}`, 'success')
      await loadAuditLogs()
    }
  } catch (err) {
    showToast('Failed to grant bonus quota', 'error')
  }
}

const loadAllAdminData = () => {
  loadAnalytics()
  loadUsers()
  loadAuditLogs()
}

onMounted(() => {
  loadAllAdminData()
})
</script>

<style scoped>
.admin-page {
  padding: 48px 0 96px;
  min-height: 80vh;
}

.admin-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 32px;
  flex-wrap: wrap;
  gap: 20px;
}

.admin-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 600;
  color: var(--status-crimson);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.admin-title {
  font-size: 26px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.admin-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

.admin-switch-prompt {
  border: 1px solid var(--border-regular);
  padding: 10px 16px;
  border-radius: var(--radius-xs);
  display: flex;
  align-items: center;
  gap: 12px;
}

.prompt-text {
  font-size: 11px;
  color: var(--status-amber);
}

/* KPI Grid */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.kpi-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.kpi-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--text-muted);
  margin-bottom: 8px;
}

.kpi-val {
  font-size: 28px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 6px;
}

.kpi-sub {
  font-size: 11px;
  color: var(--text-muted);
}

.text-cyan { color: var(--accent-cyan); }
.text-emerald { color: var(--status-emerald); }
.text-purple { color: #c084fc; }

/* Plan Dist */
.plan-dist-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 14px 20px;
  display: flex;
  align-items: center;
  gap: 24px;
  margin-bottom: 40px;
  flex-wrap: wrap;
}

.dist-label {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.dist-pills {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.dist-pill {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: var(--text-secondary);
}

.pill-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.dot-gray { background: #64748b; }
.dot-purple { background: #c084fc; }

/* Sections */
.admin-section {
  margin-bottom: 40px;
}

.section-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
  gap: 12px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
}

.admin-search-input {
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 12px;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  width: 240px;
}

.users-table-card,
.logs-table-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.admin-state {
  padding: 48px;
  text-align: center;
  font-size: 12px;
  color: var(--text-muted);
}

.table-scroller {
  overflow-x: auto;
}

.admin-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.admin-table th,
.admin-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
  white-space: nowrap;
}

.admin-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 0.05em;
}

.user-cell {
  display: flex;
  flex-direction: column;
}

.u-name {
  font-weight: 600;
  color: #ffffff;
}

.u-email {
  font-size: 11px;
  color: var(--text-muted);
}

.admin-select {
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  color: var(--text-primary);
  font-family: inherit;
  font-size: 11px;
  padding: 4px 8px;
  border-radius: var(--radius-xs);
}

.quota-val {
  font-weight: 600;
  color: var(--accent-cyan);
}

.topup-val {
  color: var(--status-emerald);
  font-weight: 600;
}

.details-json {
  font-size: 10px;
  color: var(--text-muted);
  max-width: 320px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: inline-block;
}

@media (max-width: 900px) {
  .kpi-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (max-width: 600px) {
  .kpi-grid {
    grid-template-columns: 1fr;
  }
}
</style>
