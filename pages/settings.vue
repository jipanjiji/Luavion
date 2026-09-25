<template>
  <div class="settings-page">
    <div class="settings-container">
      <div class="settings-header">
        <div class="settings-tag">
          <span class="status-dot dot-cyan"></span>
          <span>USER CONFIGURATION</span>
        </div>
        <h1 class="settings-title">Account Settings</h1>
        <p class="settings-subtitle">Manage your profile, active session, and developer testing options.</p>
      </div>

      <!-- Profile Overview Card -->
      <div class="surface settings-card">
        <h2 class="card-section-title">Google Account Profile</h2>
        <div class="profile-row">
          <img 
            v-if="user?.avatarUrl && !avatarError" 
            :src="user.avatarUrl" 
            :alt="user.displayName" 
            class="profile-avatar"
            referrerpolicy="no-referrer"
            @error="avatarError = true"
          />
          <div v-else class="avatar-fallback">
            {{ (user?.displayName || 'U')[0].toUpperCase() }}
          </div>
          <div class="profile-info">
            <span class="profile-name">{{ user?.displayName || 'User' }}</span>
            <span class="profile-email">{{ user?.email }}</span>
            <span class="google-badge">✓ Connected with Google OAuth</span>
          </div>
        </div>
      </div>

      <!-- Developer Testing Sandbox Card (Admin Only) -->
      <div v-if="user?.role === 'admin'" class="surface settings-card sandbox-card">
        <div class="sandbox-card-header">
          <div>
            <h2 class="card-section-title">Developer Sandbox & Plan Switcher</h2>
            <p class="card-desc">
              Instantly simulate different subscription tiers and roles to verify client/server enforcement.
            </p>
          </div>
          <span class="badge badge-cyan">DEBUG ACTIVE</span>
        </div>

        <div class="sandbox-controls">
          <div class="control-row">
            <span class="control-label">SIMULATE PLAN TIER:</span>
            <div class="pills-grid">
              <button 
                class="btn btn-xs" 
                :class="user?.plan === 'free' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan('free')"
              >
                Free Plan
              </button>
              <button 
                class="btn btn-xs" 
                :class="user?.plan === 'plus' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan('plus')"
              >
                Plus Plan
              </button>
              <button 
                class="btn btn-xs" 
                :class="user?.plan === 'pro' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan('pro')"
              >
                Pro Plan
              </button>
              <button 
                class="btn btn-xs" 
                :class="user?.plan === 'ultra' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan('ultra')"
              >
                Ultra Plan (API)
              </button>
            </div>
          </div>

          <div class="control-row">
            <span class="control-label">SIMULATE ROLE:</span>
            <div class="pills-grid">
              <button 
                class="btn btn-xs" 
                :class="user?.role === 'user' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan(user?.plan, 'user')"
              >
                Standard User
              </button>
              <button 
                class="btn btn-xs" 
                :class="user?.role === 'support' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan(user?.plan, 'support')"
              >
                Support Role
              </button>
              <button 
                class="btn btn-xs" 
                :class="user?.role === 'admin' ? 'btn-accent' : 'btn-secondary'"
                @click="switchPlan(user?.plan, 'admin')"
              >
                Root Admin
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Danger Zone: Account Deletion -->
      <div class="surface settings-card danger-card">
        <h2 class="card-section-title text-danger">Danger Zone</h2>
        <p class="card-desc">
          Permanently delete your Luavion account, all stored obfuscation outputs, custom presets, and revoke any generated API keys.
        </p>
        <button class="btn btn-danger-outline" @click="showDeleteModal = true">
          Delete Account Permanently
        </button>
      </div>

      <!-- Delete 2FA Confirmation Modal -->
      <TwoFactorModal 
        v-model="showDeleteModal"
        title="Permanently Delete Luavion Account"
        message="This action is irreversible. All your cloud data, past scripts, and API credentials will be permanently erased."
        requiredPhrase="DELETE-MY-LUAVION-ACCOUNT"
        @confirm="executeDeleteAccount"
      />
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'dashboard' })
import { ref } from 'vue'
import { useUser } from '~/composables/useUser'

const { user, switchPlan, logout, showToast } = useUser()
const showDeleteModal = ref(false)
const avatarError = ref(false)

useHead({
  title: 'Settings | Luavion Account',
  meta: [
    { name: 'description', content: 'Manage your Luavion user settings, developer tier switcher, and profile information.' }
  ]
})

const executeDeleteAccount = async () => {
  try {
    const res = await $fetch('/api/auth/delete-account', {
      method: 'POST',
      body: { confirmationCode: 'DELETE-MY-LUAVION-ACCOUNT' }
    })
    if (res.ok) {
      showToast('Account deleted successfully', 'info')
      await logout()
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Failed to delete account', 'error')
  }
}
</script>

<style scoped>
.settings-page {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.settings-header {
  margin-bottom: 32px;
}

.settings-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 600;
  color: var(--accent-cyan);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.settings-title {
  font-size: 26px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.settings-subtitle {
  font-size: 13px;
  color: var(--text-secondary);
}

.settings-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 24px;
  margin-bottom: 24px;
}

.card-section-title {
  font-size: 15px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 8px;
}

.card-desc {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.5;
  margin-bottom: 16px;
}

.profile-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-top: 14px;
}

.profile-avatar {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid var(--border-regular);
}

.avatar-fallback {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: var(--accent-cyan-dim);
  color: var(--accent-cyan);
  font-size: 18px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.profile-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.profile-name {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

.profile-email {
  font-size: 12px;
  color: var(--text-muted);
}

.google-badge {
  font-size: 11px;
  color: var(--status-emerald);
  margin-top: 2px;
}

/* Sandbox Card */
.sandbox-card {
  background: var(--bg-surface-raised);
}

.sandbox-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.sandbox-controls {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid var(--border-subtle);
}

.control-row {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.control-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--text-muted);
  min-width: 140px;
}

.pills-grid {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

/* Danger Card */
.danger-card {
  border-color: rgba(244, 63, 94, 0.3);
}

.text-danger {
  color: var(--status-crimson);
}

.btn-danger-outline {
  background: rgba(244, 63, 94, 0.1);
  border: 1px solid rgba(244, 63, 94, 0.4);
  color: var(--status-crimson);
  font-size: 12px;
  font-weight: 600;
  padding: 8px 16px;
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: all var(--duration-fast);
}
.btn-danger-outline:hover {
  background: var(--status-crimson);
  color: #ffffff;
}
</style>
