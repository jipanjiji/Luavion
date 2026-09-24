import { authenticateApiKey } from '../../utils/auth'

export default defineEventHandler(async (event) => {
  const { user, apiKey } = await authenticateApiKey(event)

  const remainingMonthly = Math.max(0, user.quota_monthly_limit - user.quota_used_this_month)
  const totalRemaining = remainingMonthly + (user.quota_topup_balance || 0)

  return {
    ok: true,
    plan: user.plan,
    keyName: apiKey.name,
    keyPrefix: apiKey.key_prefix,
    rateLimitPerMinute: apiKey.rate_limit_per_minute || 60,
    quota: {
      usedThisMonth: user.quota_used_this_month,
      monthlyLimit: user.quota_monthly_limit,
      topUpBalance: user.quota_topup_balance || 0,
      totalRemaining
    }
  }
})
