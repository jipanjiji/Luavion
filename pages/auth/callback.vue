<template>
  <div class="callback-container">
    <div class="callback-card surface">
      <div class="spinner"></div>
      <h2 class="callback-title">Completing Authentication...</h2>
      <p class="callback-desc">Securing session with Luavion platform. Redirecting to workspace.</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useUser } from '~/composables/useUser'

const { fetchUser, showToast } = useUser()

onMounted(async () => {
  try {
    const hash = window.location.hash.substring(1)
    const searchParams = new URLSearchParams(window.location.search)
    const hashParams = new URLSearchParams(hash)

    const errorParam = searchParams.get('error_description') || searchParams.get('error') || hashParams.get('error_description') || hashParams.get('error')
    if (errorParam) {
      throw new Error(decodeURIComponent(errorParam))
    }

    const code = searchParams.get('code') || hashParams.get('code')
    const accessToken = hashParams.get('access_token') || searchParams.get('access_token')
    const refreshToken = hashParams.get('refresh_token') || searchParams.get('refresh_token')

    if (!code && !accessToken) {
      throw new Error('No authorization code or token received from provider')
    }

    const res = await $fetch('/api/auth/callback', {
      method: 'POST',
      body: { code, accessToken, refreshToken }
    })

    if (res.ok) {
      await fetchUser()
      showToast('Signed in successfully!', 'success')
      navigateTo('/dashboard')
    } else {
      throw new Error('Authentication failed')
    }
  } catch (err) {
    console.error('Auth callback failed:', err)
    showToast(err?.data?.statusMessage || err?.message || 'Failed to complete authentication', 'error')
    navigateTo('/login')
  }
})
</script>

<style scoped>
.callback-container {
  min-height: calc(100vh - 58px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
}

.callback-card {
  max-width: 440px;
  width: 100%;
  padding: 40px;
  border-radius: 16px;
  text-align: center;
  border: 1px solid var(--border-color);
  background: rgba(13, 17, 23, 0.8);
  backdrop-filter: blur(16px);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(56, 189, 248, 0.2);
  border-top-color: var(--accent-cyan);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.callback-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.callback-desc {
  font-size: 0.875rem;
  color: var(--text-muted);
}
</style>
