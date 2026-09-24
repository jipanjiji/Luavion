<template>
  <div class="login-page">
    <div class="login-card surface">
      <!-- Brand Header -->
      <div class="login-brand">
        <div class="brand-logo">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
            <polyline points="2 17 12 22 22 17"></polyline>
            <polyline points="2 12 12 17 22 12"></polyline>
          </svg>
        </div>
        <h1 class="login-title">Sign In to Luavion</h1>
        <p class="login-sub">Access your obfuscation workspace, cloud history, and billing.</p>
      </div>

      <!-- Primary Google OAuth Button -->
      <div class="auth-action-box">
        <button 
          class="btn btn-google btn-lg" 
          @click="signInWithGoogle"
          :disabled="loading"
        >
          <svg width="18" height="18" viewBox="0 0 24 24">
            <path fill="#EA4335" d="M12 5c1.6 0 3 .6 4.1 1.7l3.1-3.1C17.3 1.8 14.8 1 12 1 7.5 1 3.7 3.6 1.9 7.3l3.7 2.9C6.5 7.1 9 5 12 5z"/>
            <path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.7-.2-2.3H12v4.6h6.5c-.3 1.5-1.1 2.8-2.4 3.7l3.7 2.9c2.2-2 3.7-5 3.7-8.9z"/>
            <path fill="#FBBC05" d="M5.6 14.8c-.2-.7-.4-1.5-.4-2.8s.2-2.1.4-2.8L1.9 6.3C.7 8.7 0 10.3 0 12s.7 3.3 1.9 5.7l3.7-2.9z"/>
            <path fill="#34A853" d="M12 23c3.2 0 6-1.1 8-3l-3.7-2.9c-1.1.7-2.5 1.2-4.3 1.2-3 0-5.5-2.1-6.4-5.2L1.9 16C3.7 19.7 7.5 23 12 23z"/>
          </svg>
          <span>Continue with Google</span>
        </button>
      </div>

      <div class="divider-text">
        <span>OR TEST WITH DEVELOPMENT SANDBOX</span>
      </div>

      <!-- Sandbox Quick Login -->
      <div class="sandbox-box surface-raised">
        <span class="sandbox-title">Instant Sandbox Roles:</span>
        <div class="sandbox-buttons-grid">
          <button class="btn btn-secondary btn-xs" @click="quickLogin('free@luavion.io', 'free', 'user', 'Free Tester')">
            Free Plan
          </button>
          <button class="btn btn-secondary btn-xs" @click="quickLogin('plus@luavion.io', 'plus', 'user', 'Plus Tester')">
            Plus Plan
          </button>
          <button class="btn btn-secondary btn-xs" @click="quickLogin('pro@luavion.io', 'pro', 'user', 'Pro Tester')">
            Pro Plan
          </button>
          <button class="btn btn-secondary btn-xs" @click="quickLogin('ultra@luavion.io', 'ultra', 'user', 'Ultra VIP')">
            Ultra Plan (API)
          </button>
          <button class="btn btn-secondary btn-xs" @click="quickLogin('admin@luavion.io', 'ultra', 'admin', 'Root Admin')">
            Admin Account
          </button>
        </div>
      </div>

      <div class="login-footer">
        <p class="terms-notice">
          By signing in, you agree to our 
          <NuxtLink to="/terms" class="legal-link">Terms of Service</NuxtLink> 
          and 
          <NuxtLink to="/privacy" class="legal-link">Privacy Policy</NuxtLink>.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useUser } from '~/composables/useUser'

const { fetchUser, showToast } = useUser()
const loading = ref(false)

useHead({
  title: 'Sign In | Luavion Bytecode Virtualization',
  meta: [
    { name: 'description', content: 'Sign in to Luavion using your Google account to access your Lua obfuscation workspace and API credentials.' }
  ]
})

const signInWithGoogle = async () => {
  try {
    loading.value = true
    const res = await $fetch('/api/auth/login', {
      method: 'POST',
      body: { action: 'google_oauth' }
    })
    if (res.url) {
      window.location.href = res.url
    } else {
      // Mock login fallback if live Supabase keys not in .env
      quickLogin('developer@luavion.io', 'pro', 'admin', 'Alvin (Dev)')
    }
  } catch (err) {
    // If Supabase OAuth fails or not configured, fall back to dev login
    quickLogin('developer@luavion.io', 'pro', 'admin', 'Alvin (Dev)')
  } finally {
    loading.value = false
  }
}

const quickLogin = async (email, plan, role, name) => {
  try {
    loading.value = true
    const res = await $fetch('/api/auth/login', {
      method: 'POST',
      body: { email, plan, role, name, action: 'dev_login' }
    })
    if (res.ok) {
      await fetchUser()
      showToast(`Signed in as ${name} (${plan.toUpperCase()})`, 'success')
      navigateTo('/dashboard')
    }
  } catch (err) {
    showToast('Failed to sign in', 'error')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 80vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
}

.login-card {
  width: 100%;
  max-width: 440px;
  background: var(--bg-surface);
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-lg);
  padding: 40px 32px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8);
  text-align: center;
}

.login-brand {
  margin-bottom: 28px;
}

.brand-logo {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-cyan);
  margin: 0 auto 16px;
  box-shadow: 0 0 24px rgba(0, 240, 255, 0.15);
}

.login-title {
  font-size: 22px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 8px;
  letter-spacing: -0.02em;
}

.login-sub {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.auth-action-box {
  margin-bottom: 24px;
}

.btn-google {
  width: 100%;
  background: #ffffff;
  color: #05080e;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  border-radius: var(--radius-sm);
  transition: all var(--duration-fast);
}
.btn-google:hover {
  background: #f1f5f9;
  transform: translateY(-1px);
}

.divider-text {
  position: relative;
  text-align: center;
  margin: 24px 0 20px;
}
.divider-text::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 1px;
  background: var(--border-subtle);
  z-index: 1;
}
.divider-text span {
  position: relative;
  z-index: 2;
  background: var(--bg-surface);
  padding: 0 10px;
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.06em;
}

.sandbox-box {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 16px;
  text-align: left;
  margin-bottom: 24px;
}

.sandbox-title {
  display: block;
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 0.05em;
  margin-bottom: 10px;
}

.sandbox-buttons-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.terms-notice {
  font-size: 11px;
  color: var(--text-muted);
  line-height: 1.5;
}

.legal-link {
  color: var(--text-secondary);
  text-decoration: underline;
}
.legal-link:hover {
  color: var(--accent-cyan);
}
</style>
