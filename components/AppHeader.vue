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

      <!-- Desktop Navigation Links (shown when on landing page) -->
      <nav class="nav-menu" v-if="route.path === '/'" aria-label="Main Navigation">
        <a href="#preview" class="nav-item">Preview</a>
        <a href="#features" class="nav-item">Pillars</a>
        <a href="#security" class="nav-item">Anti-Tamper</a>
        <a href="#compare" class="nav-item">Compare</a>
        <a href="#faq" class="nav-item">FAQ</a>
      </nav>

      <!-- Right Header Actions -->
      <div class="header-actions">
        <!-- Live Status Pulse -->
        <div class="engine-badge" title="Luau Galois Register VM 9.15 Active">
          <span class="pulse-indicator">
            <span class="dot-core"></span>
            <span class="dot-ring"></span>
          </span>
          <span class="engine-text">VM ONLINE</span>
        </div>

        <NuxtLink v-if="route.path === '/'" to="/app" class="btn btn-accent btn-studio">
          <span>Studio</span>
          <span class="btn-kbd">⌘K</span>
        </NuxtLink>

        <NuxtLink v-else to="/" class="btn btn-secondary btn-docs">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
          </svg>
          <span>Overview</span>
        </NuxtLink>

        <!-- Mobile Menu Toggle Button -->
        <button 
          v-if="route.path === '/'"
          class="mobile-menu-btn"
          @click="mobileMenuOpen = !mobileMenuOpen"
          aria-label="Toggle navigation menu"
        >
          <svg v-if="!mobileMenuOpen" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
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
      <div v-if="mobileMenuOpen && route.path === '/'" class="mobile-drawer">
        <div class="mobile-drawer-links">
          <a href="#preview" class="mobile-nav-link" @click="mobileMenuOpen = false">Live Preview</a>
          <a href="#features" class="mobile-nav-link" @click="mobileMenuOpen = false">Defensive Pillars</a>
          <a href="#security" class="mobile-nav-link" @click="mobileMenuOpen = false">Anti-Tamper</a>
          <a href="#compare" class="mobile-nav-link" @click="mobileMenuOpen = false">Comparison Matrix</a>
          <a href="#faq" class="mobile-nav-link" @click="mobileMenuOpen = false">FAQ</a>
        </div>
        <div class="mobile-drawer-footer">
          <NuxtLink to="/app" class="btn btn-accent" style="width: 100%;" @click="mobileMenuOpen = false">
            Launch Obfuscator Studio
          </NuxtLink>
        </div>
      </div>
    </transition>
  </header>
</template>

<script setup>
import { ref } from 'vue'

const route = useRoute()
const mobileMenuOpen = ref(false)
</script>

<style scoped>
.app-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(5, 8, 14, 0.8);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border-subtle);
  transition: border-color var(--duration-normal);
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
}

.brand-mark {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-cyan);
  box-shadow: 0 0 16px rgba(0, 240, 255, 0.18), var(--surface-highlight);
  transition: transform var(--duration-fast), border-color var(--duration-fast);
}

.brand-link:hover .brand-mark {
  transform: translateY(-1px);
  border-color: var(--accent-cyan-border);
}

.brand-details {
  display: flex;
  align-items: center;
  gap: 8px;
}

.brand-title {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #ffffff;
}

.brand-version {
  font-size: 10px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: var(--radius-xs);
  background: var(--accent-cyan-dim);
  color: var(--accent-cyan);
  border: 1px solid var(--accent-cyan-border);
  letter-spacing: 0.05em;
}

/* Nav Menu */
.nav-menu {
  display: flex;
  align-items: center;
  gap: 24px;
}

.nav-item {
  font-size: 12px;
  font-weight: 500;
  color: var(--text-secondary);
  transition: color var(--duration-fast);
  padding: 4px 0;
  position: relative;
}

.nav-item:hover {
  color: #ffffff;
}

/* Header Actions */
.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.engine-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.06em;
  padding: 5px 10px;
  border-radius: var(--radius-xs);
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  color: var(--status-emerald);
}

.btn-studio {
  font-size: 12px;
  padding: 7px 14px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-kbd {
  font-size: 9px;
  font-weight: 700;
  padding: 2px 4px;
  background: rgba(0, 0, 0, 0.25);
  border-radius: 3px;
  color: #05080e;
}

.mobile-menu-btn {
  display: none;
  background: transparent;
  border: 1px solid var(--border-subtle);
  color: var(--text-secondary);
  padding: 6px;
  border-radius: var(--radius-sm);
  cursor: pointer;
}

.mobile-menu-btn:hover {
  color: #ffffff;
  border-color: var(--border-regular);
}

/* Mobile Drawer */
.mobile-drawer {
  background: var(--bg-base);
  border-bottom: 1px solid var(--border-regular);
  padding: 18px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.mobile-drawer-links {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.mobile-nav-link {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
  padding: 6px 0;
}

.mobile-nav-link:hover {
  color: var(--accent-cyan);
}

.drawer-enter-active,
.drawer-leave-active {
  transition: all 200ms var(--ease-spring);
}

.drawer-enter-from,
.drawer-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

@media (max-width: 860px) {
  .nav-menu {
    display: none;
  }
  .mobile-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}

@media (max-width: 520px) {
  .engine-text {
    display: none;
  }
  .engine-badge {
    padding: 6px;
  }
  .btn-kbd {
    display: none;
  }
}
</style>
