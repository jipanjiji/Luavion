import { ref, computed } from 'vue'
import type { PlanConfig } from './usePlans'

export interface UserProfile {
  id: string
  email: string
  displayName: string
  avatarUrl: string
  role: 'user' | 'support' | 'admin'
  plan: 'free' | 'plus' | 'pro' | 'ultra'
  planBillingCycle: 'monthly' | 'yearly'
  planCurrency: 'USD' | 'IDR'
  planExpiresAt: string | null
  quotaUsed: number
  quotaLimit: number
  quotaTopUp: number
  quotaRemaining: number
  planConfig: PlanConfig
}

export function useUser() {
  const user = useState<UserProfile | null>('auth_user', () => null)
  const isAuthenticated = useState<boolean>('auth_authenticated', () => false)
  const loading = useState<boolean>('auth_loading', () => true)
  const activeUpgradeModal = useState<{ show: boolean; targetTier: string; reason: string }>('upgrade_modal', () => ({
    show: false,
    targetTier: 'pro',
    reason: ''
  }))

  const toast = useState<{ show: boolean; message: string; type: 'success' | 'error' | 'info' }>('app_toast', () => ({
    show: false,
    message: '',
    type: 'info'
  }))

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    toast.value = { show: true, message, type }
    setTimeout(() => {
      if (toast.value.message === message) {
        toast.value.show = false
      }
    }, 4000)
  }

  const promptUpgrade = (targetTier: string = 'pro', reason: string = '') => {
    activeUpgradeModal.value = {
      show: true,
      targetTier,
      reason
    }
  }

  const fetchUser = async () => {
    try {
      loading.value = true
      const res = await $fetch<any>('/api/auth/me')
      if (res && res.authenticated) {
        user.value = res.user
        isAuthenticated.value = true
      } else {
        user.value = null
        isAuthenticated.value = false
      }
    } catch (e) {
      console.error('Failed to fetch user profile:', e)
    } finally {
      loading.value = false
    }
  }

  const switchPlan = async (plan: string, role?: string) => {
    try {
      const res = await $fetch<any>('/api/auth/switch-tier', {
        method: 'POST',
        body: { plan, role }
      })
      if (res.ok) {
        await fetchUser()
        showToast(`Switched plan to ${plan.toUpperCase()}`, 'success')
      }
    } catch (e: any) {
      showToast(e?.data?.statusMessage || 'Failed to switch plan', 'error')
    }
  }

  const logout = async () => {
    try {
      await $fetch('/api/auth/logout', { method: 'POST' })
      user.value = null
      isAuthenticated.value = false
      showToast('Logged out successfully', 'info')
      navigateTo('/')
    } catch (e) {
      console.error(e)
    }
  }

  const quotaPercentage = computed(() => {
    if (!user.value) return 0
    const limit = user.value.quotaLimit || 50
    return Math.min(100, Math.round((user.value.quotaUsed / limit) * 100))
  })

  return {
    user,
    isAuthenticated,
    loading,
    quotaPercentage,
    activeUpgradeModal,
    toast,
    fetchUser,
    switchPlan,
    logout,
    showToast,
    promptUpgrade
  }
}
