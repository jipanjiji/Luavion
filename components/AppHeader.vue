<template>
  <header class="app-header">
    <div class="container header-inner">
      <!-- Brand -->
      <NuxtLink to="/" class="brand-link" aria-label="Luavion home">
        <img src="/logo.png" alt="" class="brand-logo" width="26" height="26" />
        <span class="brand-word mono">luavion<span class="brand-cursor" aria-hidden="true"></span></span>
      </NuxtLink>

      <!-- Desktop Nav -->
      <nav class="nav-menu" aria-label="Primary">
        <NuxtLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-item"
          :class="{ active: isActive(item.to) }"
        >{{ item.label }}</NuxtLink>
      </nav>

      <!-- Right -->
      <div class="header-actions">
        <template v-if="!isAuthenticated">
          <NuxtLink to="/login" class="btn btn-ghost btn-sm">Sign in</NuxtLink>
          <NuxtLink to="/pricing" class="btn btn-primary btn-sm">Get Started</NuxtLink>
        </template>

        <div v-else class="user-menu-wrap" ref="userMenuRef">
          <button
            class="user-profile-btn"
            @click="menuOpen = !menuOpen"
            :aria-expanded="menuOpen"
            aria-haspopup="menu"
            aria-label="Account menu"
          >
            <img
              v-if="(user?.avatarUrl || user?.avatar_url) && !avatarError"
              :src="user?.avatarUrl || user?.avatar_url"
              class="user-avatar"
              alt=""
              referrerpolicy="no-referrer"
              @error="avatarError = true"
            />
            <span v-else class="avatar-placeholder">{{ userInitial }}</span>
            <span class="profile-name">{{ user?.displayName || user?.name || user?.email?.split('@')[0] || 'Account' }}</span>
            <svg class="chevron-icon" :class="{ rotated: menuOpen }" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <polyline points="6 9 12 15 18 9" />
            </svg>
          </button>

          <transition name="dropdown">
            <div v-if="menuOpen" class="user-dropdown-card" role="menu">
              <div class="dropdown-header">
                <div class="dropdown-user-info">
                  <span class="dropdown-name">{{ user?.displayName || user?.name || user?.email?.split('@')[0] || 'User' }}</span>
                  <span class="dropdown-email">{{ user?.email }}</span>
                </div>
                <span class="badge" :class="planBadgeClass">{{ user?.plan || 'free' }}</span>
              </div>

              <div class="dropdown-quota-meter">
                <div class="quota-meter-head mono">
                  <span>Monthly quota</span>
                  <span class="quota-numbers">{{ Math.round(quotaPercentage) }}%</span>
                </div>
                <div class="quota-track">
                  <div class="quota-fill" :style="{ width: quotaPercentage + '%' }"></div>
                </div>
                <NuxtLink to="/billing" class="quota-topup-link" @click="menuOpen = false">Manage plan →</NuxtLink>
              </div>

              <div class="dropdown-divider"></div>

              <nav class="dropdown-links" aria-label="Account">
                <NuxtLink v-for="link in accountLinks" :key="link.to" :to="link.to" class="dropdown-link" role="menuitem" @click="menuOpen = false">{{ link.label }}</NuxtLink>
                <NuxtLink v-if="user?.role === 'admin'" to="/admin" class="dropdown-link" @click="menuOpen = false">
                  Admin <span class="badge" style="margin-left:auto">admin</span>
                </NuxtLink>
              </nav>

              <div class="dropdown-divider"></div>

              <button class="logout-btn" @click="handleLogout">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
                </svg>
                Sign out
              </button>
            </div>
          </transition>
        </div>

        <!-- Mobile toggle -->
        <button
          class="mobile-menu-btn"
          @click="mobileDrawerOpen = !mobileDrawerOpen"
          :aria-expanded="mobileDrawerOpen"
          aria-label="Toggle navigation menu"
        >
          <svg v-if="!mobileDrawerOpen" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
            <line x1="3" y1="7" x2="21" y2="7" /><line x1="3" y1="17" x2="21" y2="17" />
          </svg>
          <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
            <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Mobile full-screen drawer -->
    <transition name="drawer">
      <div v-if="mobileDrawerOpen" class="mobile-drawer">
        <nav class="mobile-drawer-links" aria-label="Mobile">
          <NuxtLink
            v-for="(item, i) in navItems"
            :key="item.to"
            :to="item.to"
            class="mobile-nav-link"
            :style="{ transitionDelay: 40 + i * 40 + 'ms' }"
            @click="mobileDrawerOpen = false"
          >
            <span class="mono mobile-link-index">0{{ i + 1 }}</span>{{ item.label }}
          </NuxtLink>

          <template v-if="isAuthenticated">
            <div class="drawer-divider"></div>
            <NuxtLink
              v-for="(link, i) in accountLinks"
              :key="link.to"
              :to="link.to"
              class="mobile-nav-link"
              :style="{ transitionDelay: 280 + i * 40 + 'ms' }"
              @click="mobileDrawerOpen = false"
            >
              <span class="mono mobile-link-index">{{ String(navItems.length + i + 1).padStart(2, '0') }}</span>{{ link.label }}
            </NuxtLink>
            <NuxtLink
              v-if="user?.role === 'admin'"
              to="/admin"
              class="mobile-nav-link"
              :style="{ transitionDelay: 280 + accountLinks.length * 40 + 'ms' }"
              @click="mobileDrawerOpen = false"
            >
              <span class="mono mobile-link-index">{{ String(navItems.length + accountLinks.length + 1).padStart(2, '0') }}</span>Admin
            </NuxtLink>
          </template>
        </nav>

        <div class="mobile-drawer-footer">
          <NuxtLink v-if="!isAuthenticated" to="/login" class="btn btn-secondary btn-lg" @click="mobileDrawerOpen = false">Sign in</NuxtLink>
          <NuxtLink to="/dashboard" class="btn btn-primary btn-lg" @click="mobileDrawerOpen = false">Go to dashboard</NuxtLink>
        </div>
      </div>
    </transition>
  </header>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { useUser } from '~/composables/useUser'

const route = useRoute()
const { user, isAuthenticated, quotaPercentage, logout, fetchUser } = useUser()

const menuOpen = ref(false)
const mobileDrawerOpen = ref(false)
const userMenuRef = ref(null)
const avatarError = ref(false)

const navItems = computed(() => {
  const items = [
    { to: '/pricing', label: 'Pricing' },
    { to: '/docs/api', label: 'API Docs' },
    { to: '/changelog', label: 'Changelog' },
    { to: '/status', label: 'Status' },
  ]
  if (isAuthenticated.value) {
    items.unshift(
      { to: '/dashboard', label: 'Dashboard' },
      { to: '/app', label: 'Studio' }
    )
  }
  return items
})

const accountLinks = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/history', label: 'History' },
  { to: '/billing', label: 'Billing' },
  { to: '/keys', label: 'API Keys' },
  { to: '/settings', label: 'Settings' },
]

const isActive = (to) => to === '/' ? route.path === '/' : route.path.startsWith(to)

const userInitial = computed(() => (user.value?.displayName || user.value?.name || user.value?.email || 'U').charAt(0).toUpperCase())

const planBadgeClass = computed(() => ({
  free: '',
  plus: 'badge-emerald',
  pro: 'badge-cyan',
  ultra: 'badge-amber',
}[user.value?.plan] || ''))

const handleLogout = async () => {
  menuOpen.value = false
  await logout()
}

const handleClickOutside = (e) => {
  if (userMenuRef.value && !userMenuRef.value.contains(e.target)) {
    menuOpen.value = false
  }
}

const handleEscape = (e) => {
  if (e.key === 'Escape') {
    menuOpen.value = false
    mobileDrawerOpen.value = false
  }
}

watch(mobileDrawerOpen, (open) => {
  document.body.style.overflow = open ? 'hidden' : ''
})

watch(() => route.path, () => {
  mobileDrawerOpen.value = false
  menuOpen.value = false
})

onMounted(() => {
  fetchUser()
  document.addEventListener('click', handleClickOutside)
  document.addEventListener('keydown', handleEscape)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  document.removeEventListener('keydown', handleEscape)
  document.body.style.overflow = ''
})
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(10, 10, 11, 0.75);
  backdrop-filter: blur(16px) saturate(1.4);
  -webkit-backdrop-filter: blur(16px) saturate(1.4);
  border-bottom: 1px solid var(--border-subtle);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 58px;
  gap: 24px;
}

/* Brand */
.brand-link { display: flex; align-items: center; gap: 9px; }

.brand-logo {
  width: 26px;
  height: 26px;
  object-fit: contain;
  border-radius: 6px;
  display: block;
}

.brand-word {
  font-size: 15px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  display: inline-flex;
  align-items: center;
}

.brand-cursor {
  display: inline-block;
  width: 7px;
  height: 15px;
  margin-left: 3px;
  background: var(--text-primary);
  animation: blink 1.1s steps(2, start) infinite;
}

@keyframes blink { to { visibility: hidden; } }

/* Desktop nav */
.nav-menu {
  display: flex;
  align-items: center;
  gap: 2px;
  margin-right: auto;
}

.nav-item {
  position: relative;
  color: var(--text-muted);
  font-size: 13px;
  font-weight: 500;
  padding: 7px 12px;
  border-radius: var(--radius-sm);
  transition: color var(--duration-fast) var(--ease-out), background var(--duration-fast) var(--ease-out);
}

.nav-item::after {
  content: '';
  position: absolute;
  left: 12px;
  right: 12px;
  bottom: 2px;
  height: 1.5px;
  border-radius: 2px;
  background: var(--text-primary);
  transform: scaleX(0);
  transform-origin: center;
  transition: transform var(--duration-normal) var(--ease-spring);
}

.nav-item:hover { color: var(--text-primary); background: rgba(255, 255, 255, 0.05); }

.nav-item.active { color: var(--text-primary); }
.nav-item.active::after { transform: scaleX(1); }

/* Right actions */
.header-actions { display: flex; align-items: center; gap: 10px; }

/* User menu */
.user-menu-wrap { position: relative; }

.user-profile-btn {
  display: flex;
  align-items: center;
  gap: 9px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  padding: 5px 12px 5px 5px;
  border-radius: var(--radius-full);
  cursor: pointer;
  color: var(--text-primary);
  transition: border-color var(--duration-fast) var(--ease-out);
  min-height: 36px;
}

.user-profile-btn:hover { border-color: var(--border-hover); }

.user-avatar { width: 26px; height: 26px; border-radius: 50%; object-fit: cover; }

.avatar-placeholder {
  width: 26px; height: 26px;
  border-radius: 50%;
  background: var(--bg-overlay);
  color: var(--text-primary);
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.profile-name {
  font-size: 13px;
  font-weight: 600;
  letter-spacing: -0.01em;
  max-width: 120px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chevron-icon { color: var(--text-muted); transition: transform var(--duration-fast) var(--ease-out); }
.chevron-icon.rotated { transform: rotate(180deg); }

.user-dropdown-card {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  width: 272px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-lg);
  padding: 14px;
  z-index: 200;
}

.dropdown-enter-active { transition: opacity 180ms var(--ease-spring), transform 180ms var(--ease-spring); }
.dropdown-leave-active { transition: opacity 120ms var(--ease-out), transform 120ms var(--ease-out); }
.dropdown-enter-from, .dropdown-leave-to { opacity: 0; transform: translateY(-6px) scale(0.98); }

.dropdown-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 12px;
}

.dropdown-user-info { display: flex; flex-direction: column; min-width: 0; }

.dropdown-name { font-size: 13px; font-weight: 600; }

.dropdown-email {
  font-size: 11px;
  color: var(--text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dropdown-quota-meter {
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  padding: 10px 12px;
  margin-bottom: 10px;
}

.quota-meter-head {
  display: flex;
  justify-content: space-between;
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 7px;
}

.quota-numbers { color: var(--text-primary); }

.quota-track {
  height: 3px;
  background: var(--bg-overlay);
  border-radius: 999px;
  overflow: hidden;
  margin-bottom: 8px;
}

.quota-fill {
  height: 100%;
  background: var(--text-primary);
  border-radius: 999px;
  transition: width 600ms var(--ease-spring);
}

.quota-topup-link { font-size: 11px; color: var(--text-secondary); font-weight: 500; }
.quota-topup-link:hover { color: var(--text-primary); }

.dropdown-divider { height: 1px; background: var(--border-subtle); margin: 8px 0; }

.dropdown-links { display: flex; flex-direction: column; gap: 1px; }

.dropdown-link {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  font-size: 13px;
  transition: all var(--duration-fast) var(--ease-out);
}

.dropdown-link:hover { color: var(--text-primary); background: rgba(255, 255, 255, 0.06); }

.logout-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  background: transparent;
  border: none;
  color: var(--status-crimson);
  font-family: var(--font-sans);
  font-size: 13px;
  cursor: pointer;
  transition: background var(--duration-fast) var(--ease-out);
}

.logout-btn:hover { background: var(--status-crimson-dim); }

/* Mobile */
.mobile-menu-btn {
  display: none;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  cursor: pointer;
  border-radius: var(--radius-sm);
}

.mobile-menu-btn:hover { background: rgba(255, 255, 255, 0.06); }

.mobile-drawer {
  position: fixed;
  inset: 58px 0 0 0;
  z-index: 99;
  background: var(--bg-void);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 32px 24px 32px;
  overflow-y: auto;
}

.drawer-enter-active { transition: opacity 220ms var(--ease-out), transform 220ms var(--ease-out); }
.drawer-leave-active { transition: opacity 160ms var(--ease-out), transform 160ms var(--ease-out); }
.drawer-enter-from, .drawer-leave-to { opacity: 0; transform: translateY(-8px); }

.drawer-enter-active .mobile-nav-link { transition: opacity 350ms var(--ease-spring), transform 350ms var(--ease-spring); }
.drawer-enter-from .mobile-nav-link { opacity: 0; transform: translateY(12px); }

.mobile-drawer-links { display: flex; flex-direction: column; }

.mobile-nav-link {
  display: flex;
  align-items: baseline;
  gap: 14px;
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 500;
  letter-spacing: -0.02em;
  padding: 14px 0;
  min-height: 52px;
  border-bottom: 1px solid var(--border-faint);
}

.mobile-nav-link:active { color: var(--text-secondary); }

.mobile-link-index {
  font-size: 11px;
  color: var(--text-faint);
  font-weight: 400;
}

.drawer-divider { height: 20px; }

.mobile-drawer-footer { display: flex; flex-direction: column; gap: 10px; }

@media (max-width: 900px) {
  .nav-menu { display: none; }
  .profile-name { display: none; }
  .mobile-menu-btn { display: flex; }
}
</style>
