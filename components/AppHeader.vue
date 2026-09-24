<template>
  <header class="app-header">
    <div class="container header-inner">
      <!-- Brand Logo / Identity -->
      <NuxtLink to="/" class="brand-link" aria-label="Luavion Home">
        <div class="brand-mark">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
            <polyline points="2 17 12 22 22 17"></polyline>
            <polyline points="2 12 12 17 22 12"></polyline>
          </svg>
        </div>
        <div class="brand-details">
          <span class="brand-title">LUAVION</span>
          <span class="brand-version">v9.15</span>
        </div>
      </NuxtLink>

      <!-- Desktop Navigation Menu -->
      <nav class="nav-menu" aria-label="Main Navigation">
        <NuxtLink to="/app" class="nav-item" :class="{ active: route.path === '/app' }">Studio</NuxtLink>
        <NuxtLink to="/pricing" class="nav-item" :class="{ active: route.path === '/pricing' }">Pricing</NuxtLink>
        <NuxtLink to="/docs/api" class="nav-item" :class="{ active: route.path.startsWith('/docs') }">API Docs</NuxtLink>
        <NuxtLink to="/changelog" class="nav-item" :class="{ active: route.path === '/changelog' }">Changelog</NuxtLink>
        <NuxtLink to="/status" class="nav-item" :class="{ active: route.path === '/status' }">Status</NuxtLink>
      </nav>

      <!-- Right Header Actions -->
      <div class="header-actions">
        <!-- Live Engine Pulse -->
        <div class="engine-badge" title="Luau Galois Register VM 9.15 Active">
          <span class="pulse-indicator">
            <span class="dot-core"></span>
            <span class="dot-ring"></span>
          </span>
          <span class="engine-text">VM ONLINE</span>
        </div>

        <!-- Authenticated User Menu Dropdown -->
        <div v-if="isAuthenticated && user" class="user-menu-wrap" ref="userMenuRef">
          <button 
            class="user-profile-btn" 
            @click="menuOpen = !menuOpen" 
            :aria-expanded="menuOpen"
            title="User Account Menu"
          >
            <img 
              v-if="user.avatarUrl" 
              :src="user.avatarUrl" 
              :alt="user.displayName" 
              class="user-avatar" 
            />
            <div v-else class="avatar-placeholder">
              {{ (user.displayName || user.email)[0].toUpperCase() }}
            </div>
            <div class="user-btn-details">
              <span class="user-name">{{ user.displayName || user.email.split('@')[0] }}</span>
              <span class="badge" :class="`badge-plan-${user.plan}`">{{ user.plan.toUpperCase() }}</span>
            </div>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="chevron-icon" :class="{ rotated: menuOpen }">
              <polyline points="6 9 12 15 18 9"></polyline>
            </svg>
          </button>

          <!-- Dropdown Card -->
          <transition name="dropdown">
            <div v-if="menuOpen" class="user-dropdown-card surface">
              <div class="dropdown-header">
                <div class="dropdown-user-info">
                  <span class="dropdown-name">{{ user.displayName }}</span>
                  <span class="dropdown-email">{{ user.email }}</span>
                </div>
                <span class="badge" :class="`badge-plan-${user.plan}`">{{ user.plan.toUpperCase() }}</span>
              </div>

              <!-- Mini Quota Progress Meter -->
              <div class="dropdown-quota-meter">
                <div class="quota-meter-head">
                  <span>Monthly Quota</span>
                  <span class="quota-numbers">{{ user.quotaUsed }} / {{ user.quotaLimit }}</span>
                </div>
                <div class="quota-track">
                  <div class="quota-fill" :style="{ width: `${quotaPercentage}%` }"></div>
                </div>
                <NuxtLink to="/billing" class="quota-topup-link" @click="menuOpen = false">
                  <span>+ Top Up Credits</span>
                </NuxtLink>
              </div>

              <div class="dropdown-divider"></div>

              <!-- Menu Navigation Links -->
              <div class="dropdown-links">
                <NuxtLink to="/dashboard" class="dropdown-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="3" width="7" height="7"></rect>
                    <rect x="14" y="3" width="7" height="7"></rect>
                    <rect x="14" y="14" width="7" height="7"></rect>
                    <rect x="3" y="14" width="7" height="7"></rect>
                  </svg>
                  <span>Dashboard</span>
                </NuxtLink>

                <NuxtLink to="/history" class="dropdown-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <polyline points="12 6 12 12 16 14"></polyline>
                  </svg>
                  <span>Obfuscation History</span>
                </NuxtLink>

                <NuxtLink to="/billing" class="dropdown-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
                    <line x1="1" y1="10" x2="23" y2="10"></line>
                  </svg>
                  <span>Billing & Subscriptions</span>
                </NuxtLink>

                <NuxtLink to="/keys" class="dropdown-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"></path>
                  </svg>
                  <span>API Keys (Ultra)</span>
                </NuxtLink>

                <NuxtLink to="/settings" class="dropdown-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="3"></circle>
                    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
                  </svg>
                  <span>Account Settings</span>
                </NuxtLink>

                <!-- Admin Link -->
                <NuxtLink v-if="user.role === 'admin'" to="/admin" class="dropdown-link admin-link" @click="menuOpen = false">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                  </svg>
                  <span>Admin Panel</span>
                </NuxtLink>
              </div>

              <div class="dropdown-divider"></div>

              <div class="dropdown-footer">
                <button class="logout-btn" @click="handleLogout">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                    <polyline points="16 17 21 12 16 7"></polyline>
                    <line x1="21" y1="12" x2="9" y2="12"></line>
                  </svg>
                  <span>Sign Out</span>
                </button>
              </div>
            </div>
          </transition>
        </div>

        <!-- Unauthenticated CTA Group -->
        <div v-else class="auth-btn-group">
          <NuxtLink to="/login" class="btn btn-secondary btn-sm">
            Sign In
          </NuxtLink>
          <NuxtLink to="/app" class="btn btn-accent btn-sm">
            <span>Studio</span>
            <span class="btn-kbd">⌘K</span>
          </NuxtLink>
        </div>

        <!-- Mobile Drawer Toggle -->
        <button 
          class="mobile-menu-btn" 
          @click="mobileDrawerOpen = !mobileDrawerOpen" 
          aria-label="Toggle navigation drawer"
        >
          <svg v-if="!mobileDrawerOpen" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="12" x2="21" y2="12"></line>
            <line x1="3" y1="6" x2="21" y2="6"></line>
            <line x1="3" y1="18" x2="21" y2="18"></line>
          </svg>
          <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>
      </div>
    </div>

    <!-- Mobile Drawer -->
    <transition name="drawer">
      <div v-if="mobileDrawerOpen" class="mobile-drawer">
        <div class="mobile-drawer-links">
          <NuxtLink to="/" class="mobile-nav-link" @click="mobileDrawerOpen = false">Home Overview</NuxtLink>
          <NuxtLink to="/app" class="mobile-nav-link" @click="mobileDrawerOpen = false">Obfuscator Studio</NuxtLink>
          <NuxtLink to="/pricing" class="mobile-nav-link" @click="mobileDrawerOpen = false">Pricing & Plans</NuxtLink>
          <NuxtLink to="/docs/api" class="mobile-nav-link" @click="mobileDrawerOpen = false">Developer API Docs</NuxtLink>
          <NuxtLink to="/changelog" class="mobile-nav-link" @click="mobileDrawerOpen = false">Engine Changelog</NuxtLink>
          <NuxtLink to="/status" class="mobile-nav-link" @click="mobileDrawerOpen = false">System Status</NuxtLink>
          
          <div class="drawer-divider" v-if="isAuthenticated"></div>
          
          <template v-if="isAuthenticated">
            <NuxtLink to="/dashboard" class="mobile-nav-link" @click="mobileDrawerOpen = false">Dashboard</NuxtLink>
            <NuxtLink to="/history" class="mobile-nav-link" @click="mobileDrawerOpen = false">Obfuscation History</NuxtLink>
            <NuxtLink to="/billing" class="mobile-nav-link" @click="mobileDrawerOpen = false">Billing & Subscriptions</NuxtLink>
            <NuxtLink to="/keys" class="mobile-nav-link" @click="mobileDrawerOpen = false">API Keys</NuxtLink>
            <NuxtLink to="/settings" class="mobile-nav-link" @click="mobileDrawerOpen = false">Account Settings</NuxtLink>
            <NuxtLink v-if="user?.role === 'admin'" to="/admin" class="mobile-nav-link" @click="mobileDrawerOpen = false">Admin Control Panel</NuxtLink>
          </template>
        </div>

        <div class="mobile-drawer-footer">
          <NuxtLink v-if="!isAuthenticated" to="/login" class="btn btn-secondary" style="width: 100%; margin-bottom: 8px;" @click="mobileDrawerOpen = false">
            Sign In with Google
          </NuxtLink>
          <NuxtLink to="/app" class="btn btn-accent" style="width: 100%;" @click="mobileDrawerOpen = false">
            Launch Obfuscator Studio
          </NuxtLink>
        </div>
      </div>
    </transition>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useUser } from '~/composables/useUser'

const route = useRoute()
const { user, isAuthenticated, quotaPercentage, logout, fetchUser } = useUser()

const menuOpen = ref(false)
const mobileDrawerOpen = ref(false)
const userMenuRef = ref(null)

const handleLogout = async () => {
  menuOpen.value = false
  await logout()
}

// Close dropdown on outside click
const handleClickOutside = (e) => {
  if (userMenuRef.value && !userMenuRef.value.contains(e.target)) {
    menuOpen.value = false
  }
}

onMounted(() => {
  fetchUser()
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(5, 8, 14, 0.85);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border-subtle);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 60px;
}

/* Brand */
.brand-link {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
}

.brand-mark {
  width: 28px;
  height: 28px;
  border-radius: var(--radius-xs);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-cyan);
  transition: all var(--duration-fast);
}
.brand-link:hover .brand-mark {
  border-color: var(--accent-cyan);
  box-shadow: 0 0 16px rgba(0, 240, 255, 0.2);
}

.brand-details {
  display: flex;
  align-items: baseline;
  gap: 6px;
}

.brand-title {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #ffffff;
}

.brand-version {
  font-size: 10px;
  color: var(--text-muted);
}

/* Navigation Links */
.nav-menu {
  display: flex;
  align-items: center;
  gap: 4px;
}

.nav-item {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 12px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  transition: all var(--duration-fast);
}
.nav-item:hover,
.nav-item.active {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.05);
}

/* Right Actions */
.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.engine-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  padding: 4px 10px;
  border-radius: var(--radius-xs);
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.auth-btn-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* User Menu & Dropdown */
.user-menu-wrap {
  position: relative;
}

.user-profile-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  padding: 4px 10px 4px 6px;
  border-radius: var(--radius-xs);
  cursor: pointer;
  color: var(--text-primary);
  transition: all var(--duration-fast);
}
.user-profile-btn:hover {
  border-color: var(--border-hover);
}

.user-avatar {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  object-fit: cover;
}

.avatar-placeholder {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--accent-cyan-dim);
  color: var(--accent-cyan);
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-btn-details {
  display: flex;
  align-items: center;
  gap: 6px;
}

.user-name {
  font-size: 12px;
  font-weight: 600;
  max-width: 100px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chevron-icon {
  color: var(--text-muted);
  transition: transform var(--duration-fast);
}
.chevron-icon.rotated {
  transform: rotate(180deg);
}

/* Dropdown Card */
.user-dropdown-card {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: 260px;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.7);
  padding: 12px;
  z-index: 200;
}

.dropdown-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.dropdown-user-info {
  display: flex;
  flex-direction: column;
}

.dropdown-name {
  font-size: 13px;
  font-weight: 700;
  color: #ffffff;
}

.dropdown-email {
  font-size: 11px;
  color: var(--text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 170px;
}

.dropdown-quota-meter {
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xs);
  padding: 8px 10px;
  margin-bottom: 8px;
}

.quota-meter-head {
  display: flex;
  justify-content: space-between;
  font-size: 10px;
  color: var(--text-muted);
  margin-bottom: 6px;
}

.quota-numbers {
  font-weight: 600;
  color: var(--text-primary);
}

.quota-track {
  height: 4px;
  background: var(--bg-base);
  border-radius: 999px;
  overflow: hidden;
  margin-bottom: 6px;
}

.quota-fill {
  height: 100%;
  background: var(--accent-cyan);
  transition: width 0.3s;
}

.quota-topup-link {
  font-size: 10px;
  color: var(--accent-cyan);
  text-decoration: none;
  font-weight: 600;
  display: inline-block;
}
.quota-topup-link:hover {
  text-decoration: underline;
}

.dropdown-divider {
  height: 1px;
  background: var(--border-subtle);
  margin: 6px 0;
}

.dropdown-links {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.dropdown-link {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 10px;
  border-radius: var(--radius-xs);
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 12px;
  transition: all var(--duration-fast);
}
.dropdown-link:hover {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.05);
}

.admin-link {
  color: #38bdf8;
}

.dropdown-footer {
  padding-top: 4px;
}

.logout-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 10px;
  border-radius: var(--radius-xs);
  background: transparent;
  border: none;
  color: var(--status-crimson);
  font-size: 12px;
  cursor: pointer;
  font-family: inherit;
}
.logout-btn:hover {
  background: rgba(244, 63, 94, 0.1);
}

/* Badge colors */
.badge-plan-free {
  background: rgba(255, 255, 255, 0.08);
  color: var(--text-muted);
}
.badge-plan-plus {
  background: rgba(16, 185, 129, 0.15);
  color: #10b981;
}
.badge-plan-pro {
  background: rgba(0, 240, 255, 0.15);
  color: #00f0ff;
}
.badge-plan-ultra {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.2), rgba(0, 240, 255, 0.2));
  color: #c084fc;
  border: 1px solid rgba(168, 85, 247, 0.4);
}

/* Mobile */
.mobile-menu-btn {
  display: none;
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
}

.mobile-drawer {
  background: var(--bg-void);
  border-bottom: 1px solid var(--border-regular);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mobile-drawer-links {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.mobile-nav-link {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 14px;
  padding: 6px 0;
}
.mobile-nav-link:hover {
  color: var(--accent-cyan);
}

.drawer-divider {
  height: 1px;
  background: var(--border-subtle);
  margin: 6px 0;
}

@media (max-width: 860px) {
  .nav-menu {
    display: none;
  }
  .engine-badge {
    display: none;
  }
  .mobile-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}
</style>
