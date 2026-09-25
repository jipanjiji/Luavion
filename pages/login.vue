<template>
  <div class="login-page">
    <div class="login-ambient" aria-hidden="true"></div>

    <div class="login-card anim-fade-up">
      <div class="login-brand">
        <span class="brand-word mono">
          <img src="/logo.png" alt="" class="brand-logo" width="26" height="26" />
          luavion<span class="brand-cursor" aria-hidden="true"></span>
        </span>
        <h1 class="login-title">Welcome back</h1>
        <p class="login-sub">Sign in to access your obfuscation workspace, cloud history, and billing.</p>
      </div>

      <!-- Provider Error Notice -->
      <div v-if="providerError" class="provider-error-card">
        <div class="error-icon">⚠️</div>
        <div class="error-content">
          <strong>Google Sign-In is not enabled yet</strong>
          <p>Buka <b>Supabase Dashboard</b> &rarr; <b>Authentication</b> &rarr; <b>Providers</b> &rarr; <b>Google</b>, lalu aktifkan switch <i>Enable Google provider</i> dan masukkan Client ID & Secret.</p>
        </div>
      </div>

      <!-- Google OAuth -->
      <button
        class="btn btn-google btn-lg"
        @click="signInWithGoogle"
        :disabled="loading"
      >
        <span v-if="loading" class="spinner" aria-hidden="true"></span>
        <svg v-else width="17" height="17" viewBox="0 0 24 24" aria-hidden="true">
          <path fill="#EA4335" d="M12 5c1.6 0 3 .6 4.1 1.7l3.1-3.1C17.3 1.8 14.8 1 12 1 7.5 1 3.7 3.6 1.9 7.3l3.7 2.9C6.5 7.1 9 5 12 5z"/>
          <path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.7-.2-2.3H12v4.6h6.5c-.3 1.5-1.1 2.8-2.4 3.7l3.7 2.9c2.2-2 3.7-5 3.7-8.9z"/>
          <path fill="#FBBC05" d="M5.6 14.8c-.2-.7-.4-1.5-.4-2.8s.2-2.1.4-2.8L1.9 6.3C.7 8.7 0 10.3 0 12s.7 3.3 1.9 5.7l3.7-2.9z"/>
          <path fill="#34A853" d="M12 23c3.2 0 6-1.1 8-3l-3.7-2.9c-1.1.7-2.5 1.2-4.3 1.2-3 0-5.5-2.1-6.4-5.2L1.9 16C3.7 19.7 7.5 23 12 23z"/>
        </svg>
        <span>Continue with Google</span>
      </button>

      <div class="divider-text mono">
        <span>or sign in with email</span>
      </div>

      <!-- Magic Link Form -->
      <form @submit.prevent="signInWithMagicLink" class="email-form">
        <div class="input-wrap">
          <input
            v-model="emailInput"
            type="email"
            placeholder="name@company.com"
            class="email-input"
            required
            :disabled="loading"
          />
        </div>
        <button type="submit" class="btn btn-secondary btn-lg btn-email" :disabled="loading || !emailInput.trim()">
          <span v-if="emailLoading" class="spinner" aria-hidden="true"></span>
          <span v-else>Send Magic Sign-In Link</span>
        </button>
      </form>

      <p class="terms-notice">
        By signing in, you agree to our
        <NuxtLink to="/terms" class="legal-link">Terms</NuxtLink>
        and
        <NuxtLink to="/privacy" class="legal-link">Privacy Policy</NuxtLink>.
      </p>
    </div>

    <NuxtLink to="/" class="back-home mono anim-fade-up" style="animation-delay: 120ms">
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>
      back to home
    </NuxtLink>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const route = useRoute()
const { showToast } = useUser()

const loading = ref(false)
const emailLoading = ref(false)
const emailInput = ref('')
const providerError = ref(false)

useHead({
  title: 'Sign In | Luavion Bytecode Virtualization',
  meta: [
    { name: 'description', content: 'Sign in to Luavion using your Google account or email to access your Lua obfuscation workspace.' }
  ]
})

onMounted(() => {
  // Check if redirected with error
  if (route.query.error || route.hash.includes('error')) {
    providerError.value = true
  }
})

const signInWithGoogle = async () => {
  try {
    loading.value = true
    providerError.value = false
    const res = await $fetch('/api/auth/login', {
      method: 'POST',
      body: { action: 'google_oauth' }
    })
    if (res.url) {
      window.location.href = res.url
    }
  } catch (err) {
    const msg = err?.data?.statusMessage || 'Google login failed'
    if (msg.includes('provider') || msg.includes('not enabled')) {
      providerError.value = true
    } else {
      showToast(msg, 'error')
    }
  } finally {
    loading.value = false
  }
}

const signInWithMagicLink = async () => {
  if (!emailInput.value.trim()) return
  try {
    emailLoading.value = true
    const res = await $fetch('/api/auth/login', {
      method: 'POST',
      body: {
        action: 'magic_link',
        email: emailInput.value.trim()
      }
    })
    if (res.ok) {
      showToast(res.message, 'success')
      emailInput.value = ''
    }
  } catch (err) {
    showToast(err?.data?.statusMessage || 'Failed to send magic link', 'error')
  } finally {
    emailLoading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: calc(100vh - 58px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 20px;
  position: relative;
}

.login-ambient {
  position: absolute;
  top: 12%;
  width: 480px;
  height: 280px;
  background: radial-gradient(ellipse at center, rgba(56, 189, 248, 0.05), transparent 70%);
  pointer-events: none;
}

.login-card {
  width: 100%;
  max-width: 420px;
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  padding: 36px 32px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.4);
}

.login-brand {
  text-align: center;
  margin-bottom: 26px;
}

.brand-word {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  font-size: 17px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  margin-bottom: 18px;
}

.brand-logo {
  width: 26px;
  height: 26px;
  object-fit: contain;
  border-radius: 6px;
  display: block;
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

.login-title {
  font-size: 20px;
  font-weight: 600;
  letter-spacing: -0.025em;
  color: var(--text-primary);
  margin-bottom: 6px;
}

.login-sub {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.6;
}

.provider-error-card {
  display: flex;
  gap: 12px;
  padding: 14px;
  border-radius: var(--radius-md);
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.25);
  margin-bottom: 20px;
  text-align: left;
}

.error-icon {
  font-size: 18px;
  line-height: 1;
}

.error-content strong {
  display: block;
  font-size: 13px;
  color: #f87171;
  margin-bottom: 4px;
}

.error-content p {
  font-size: 12px;
  color: var(--text-muted);
  line-height: 1.5;
  margin: 0;
}

.btn-google {
  width: 100%;
  background: #ffffff;
  color: #0a0a0b;
  font-weight: 600;
  gap: 12px;
  border-radius: var(--radius-sm);
}

.btn-google:hover:not(:disabled) {
  background: #e8e8e8;
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
}

.divider-text span {
  position: relative;
  background: var(--bg-surface);
  padding: 0 12px;
  font-size: 10px;
  color: var(--text-faint);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.email-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 24px;
}

.email-input {
  width: 100%;
  padding: 12px 14px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 13px;
  outline: none;
  transition: border-color 0.2s;
}

.email-input:focus {
  border-color: var(--accent-cyan);
}

.btn-email {
  width: 100%;
  font-weight: 500;
  font-size: 13px;
}

.terms-notice {
  font-size: 11px;
  color: var(--text-faint);
  text-align: center;
  line-height: 1.6;
}

.legal-link {
  color: var(--text-muted);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.legal-link:hover {
  color: var(--text-primary);
}

.back-home {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  margin-top: 24px;
  font-size: 11px;
  color: var(--text-faint);
  letter-spacing: 0.06em;
  transition: color 0.15s;
}

.back-home:hover {
  color: var(--text-muted);
}
</style>
