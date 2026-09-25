<template>
  <div class="dash-shell">
    <AppHeader />
    <div class="dash-body">
    <aside class="dash-sidebar">
      <nav class="sidebar-nav" aria-label="Account">
        <span class="sidebar-caption mono">workspace</span>
        <NuxtLink v-for="item in navItems" :key="item.to" :to="item.to" class="sidebar-link" :class="{ active: isActive(item.to) }">
          <span class="sl-icon" v-html="item.icon"></span>
          <span class="sl-label">{{ item.label }}</span>
          <span v-if="item.badge" class="sl-badge mono" :class="item.badgeClass">{{ item.badge }}</span>
        </NuxtLink>
      </nav>

      <div class="sidebar-bottom">
        <div class="quota-card">
          <div class="quota-head mono">
            <span>{{ planLabel }} plan</span>
            <span>{{ Math.round(quotaPercentage) }}%</span>
          </div>
          <div class="quota-track">
            <div class="quota-fill" :style="{ width: quotaPercentage + '%' }"></div>
          </div>
          <span class="quota-left mono">{{ quotaLeft }} credits left</span>
          <button class="btn btn-secondary btn-sm quota-topup" @click="showTopUp = true">Top up</button>
        </div>
        <div class="sidebar-user">
          <img
            v-if="(user?.avatarUrl || user?.avatar_url) && !avatarError"
            :src="user?.avatarUrl || user?.avatar_url"
            class="su-avatar"
            alt=""
            referrerpolicy="no-referrer"
            @error="avatarError = true"
          />
          <span v-else class="su-avatar su-initial">{{ userInitial }}</span>
          <div class="su-meta">
            <span class="su-name">{{ user?.displayName || user?.name || user?.email?.split('@')[0] || 'User' }}</span>
            <span class="su-email">{{ user?.email }}</span>
          </div>
          <button class="su-signout" :disabled="copying" @click="handleLogout" aria-label="Sign out" title="Sign out">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
            </svg>
          </button>
        </div>
      </div>
    </aside>

    <div class="dash-main">
      <slot />
    </div>
    </div>

    <nav class="dash-tabbar" aria-label="Account">
      <NuxtLink v-for="item in navItems" :key="item.to" :to="item.to" class="tabbar-link" :class="{ active: isActive(item.to) }">
        <span class="tb-icon" v-html="item.icon"></span>
        <span class="tb-label">{{ item.label }}</span>
      </NuxtLink>
    </nav>

    <TopUpModal v-model="showTopUp" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useUser } from '~/composables/useUser'
import AppHeader from '~/components/AppHeader.vue'
import TopUpModal from '~/components/TopUpModal.vue'

const route = useRoute()
const { user, quotaPercentage, quotaLeft, logout } = useUser()

const showTopUp = ref(false)
const copying = ref(false)
const avatarError = ref(false)

const ic = (d) => `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`

const navItems = computed(() => [
  { to: '/app', label: 'Obfuscate', icon: ic('<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>') },
  { to: '/dashboard', label: 'Overview', icon: ic('<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>') },
  { to: '/history', label: 'History', icon: ic('<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>') },
  { to: '/keys', label: 'API Keys', icon: ic('<path d="m21 2-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0 3 3L22 7l-3-3m-3.5 3.5L19 4"/>') },
  { to: '/billing', label: 'Plan & Billing', icon: ic('<rect x="2" y="5" width="20" height="14" rx="2"/><line x1="2" y1="10" x2="22" y2="10"/>'), badge: user.value?.plan, badgeClass: badgeFor(user.value?.plan) },
  { to: '/settings', label: 'Settings', icon: ic('<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>') },
])

const badgeFor = (p) => ({ pro: 'badge-cyan', plus: 'badge-emerald', ultra: 'badge-amber' }[p] || '')

const isActive = (to) => route.path === to

const planLabel = computed(() => (user.value?.plan || 'free').toUpperCase())

const userInitial = computed(() => (user.value?.displayName || user.value?.name || user.value?.email || 'U').charAt(0).toUpperCase())

const handleLogout = async () => {
  copying.value = true
  try { await logout() } finally { copying.value = false }
}
</script>

<style scoped>
.dash-shell {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.dash-body {
  display: flex;
  flex: 1;
  min-height: calc(100vh - 58px);
}

/* ------- Desktop sidebar ------- */
.dash-sidebar {
  display: flex;
  flex-direction: column;
  width: 236px;
  flex-shrink: 0;
  border-right: 1px solid var(--border-subtle);
  padding: 20px 14px;
  position: sticky;
  top: 58px;
  height: calc(100vh - 58px);
  overflow-y: auto;
}

.sidebar-nav { display: flex; flex-direction: column; gap: 2px; }

.sidebar-caption {
  font-size: 10px;
  letter-spacing: 0.1em;
  color: var(--text-faint);
  text-transform: uppercase;
  padding: 0 10px 8px;
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  color: var(--text-muted);
  font-size: 13px;
  font-weight: 500;
  min-height: 38px;
  transition: all var(--duration-fast) var(--ease-out);
}

.sidebar-link:hover { color: var(--text-primary); background: rgba(255, 255, 255, 0.05); }

.sidebar-link.active {
  color: var(--text-primary);
  background: var(--accent-dim);
  box-shadow: inset 2px 0 0 var(--text-primary);
  border-radius: var(--radius-xs) var(--radius-sm) var(--radius-sm) var(--radius-xs);
}

.sl-icon { display: flex; flex-shrink: 0; opacity: 0.9; }

.sl-badge { margin-left: auto; }

.sidebar-bottom {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 18px;
}

.quota-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.quota-head {
  display: flex;
  justify-content: space-between;
  font-size: 10px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--text-muted);
}

.quota-track {
  height: 3px;
  border-radius: 999px;
  background: var(--bg-overlay);
  overflow: hidden;
}

.quota-fill {
  height: 100%;
  background: var(--text-primary);
  border-radius: 999px;
  transition: width 600ms var(--ease-spring);
}

.quota-left { font-size: 10px; color: var(--text-faint); }

.quota-topup { width: 100%; }

.sidebar-user {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 4px 0;
  border-top: 1px solid var(--border-faint);
  padding-top: 14px;
}

.su-avatar { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; flex-shrink: 0; }

.su-initial {
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-overlay);
  color: var(--text-primary);
  font-size: 12px;
  font-weight: 600;
}

.su-meta { display: flex; flex-direction: column; min-width: 0; flex: 1; }

.su-name {
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.su-email {
  font-size: 10px;
  color: var(--text-faint);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.su-signout {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  border-radius: var(--radius-xs);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
}

.su-signout:hover { color: var(--status-crimson); background: var(--status-crimson-dim); }

/* ------- Main area ------- */
.dash-main {
  flex: 1;
  min-width: 0;
  padding: 32px 36px 64px;
  display: flex;
  flex-direction: column;
}

/* ------- Mobile tab bar ------- */
.dash-tabbar { display: none; }

@media (max-width: 940px) {
  .dash-sidebar { display: none; }

  .dash-main { padding: 20px 16px 96px; }

  .dash-tabbar {
    display: flex;
    position: fixed;
    left: 0; right: 0; bottom: 0;
    z-index: 90;
    background: rgba(10, 10, 11, 0.85);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border-top: 1px solid var(--border-subtle);
    padding: 6px 8px calc(6px + env(safe-area-inset-bottom));
  }

  .tabbar-link {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 3px;
    padding: 7px 2px;
    min-height: 46px;
    justify-content: center;
    color: var(--text-faint);
    border-radius: var(--radius-sm);
    transition: color var(--duration-fast) var(--ease-out);
  }

  .tabbar-link.active { color: var(--text-primary); }

  .tb-icon { display: flex; }

  .tb-label { font-size: 9px; font-weight: 600; letter-spacing: 0.04em; }
}
</style>