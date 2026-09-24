import { getUser } from '../../utils/auth'
import { getPlanConfig } from '../../utils/plans'

export default defineEventHandler(async (event) => {
  const user = await getUser(event)
  if (!user) {
    return {
      authenticated: false,
      user: null
    }
  }

  const planConfig = getPlanConfig(user.plan)
  const remainingMonthly = Math.max(0, user.quota_monthly_limit - user.quota_used_this_month)
  const totalRemaining = remainingMonthly + (user.quota_topup_balance || 0)

  return {
    authenticated: true,
    user: {
      id: user.id,
      email: user.email,
      displayName: user.display_name,
      avatarUrl: user.avatar_url,
      role: user.role,
      plan: user.plan,
      planBillingCycle: user.plan_billing_cycle,
      planCurrency: user.plan_currency,
      planExpiresAt: user.plan_expires_at,
      quotaUsed: user.quota_used_this_month,
      quotaLimit: user.quota_monthly_limit,
      quotaTopUp: user.quota_topup_balance,
      quotaRemaining: totalRemaining,
      planConfig
    }
  }
})
