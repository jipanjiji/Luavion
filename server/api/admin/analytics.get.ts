import { requireAdmin } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  await requireAdmin(event)

  const supabase = getSupabaseClient()

  if (supabase) {
    const { data: profiles } = await supabase.from('profiles').select('plan, role, quota_used_this_month')
    const { count: totalHistory } = await supabase.from('obfuscation_history').select('*', { count: 'exact', head: true })
    const { count: totalKeys } = await supabase.from('api_keys').select('*', { count: 'exact', head: true })

    const planCounts: Record<string, number> = { free: 0, plus: 0, pro: 0, ultra: 0 }
    let mrrEst = 0
    let totalObfuscationsUsed = 0

    const planPrices: Record<string, number> = { free: 0, plus: 5, pro: 15, ultra: 30 }

    for (const p of (profiles || [])) {
      planCounts[p.plan] = (planCounts[p.plan] || 0) + 1
      mrrEst += planPrices[p.plan] || 0
      totalObfuscationsUsed += p.quota_used_this_month || 0
    }

    return {
      totalUsers: (profiles || []).length,
      planDistribution: planCounts,
      estimatedMrrUsd: mrrEst,
      totalObfuscationsTracked: totalHistory || totalObfuscationsUsed,
      activeApiKeys: totalKeys || 0
    }
  }

  // Fallback mock analytics
  const users = Array.from(mockDb.profiles.values())
  const planCounts: Record<string, number> = { free: 0, plus: 0, pro: 0, ultra: 0 }
  let mrrEst = 0
  let totalUsed = 0

  const planPrices: Record<string, number> = { free: 0, plus: 5, pro: 15, ultra: 30 }
  for (const u of users) {
    planCounts[u.plan] = (planCounts[u.plan] || 0) + 1
    mrrEst += planPrices[u.plan] || 0
    totalUsed += u.quota_used_this_month || 0
  }

  return {
    totalUsers: users.length,
    planDistribution: planCounts,
    estimatedMrrUsd: mrrEst,
    totalObfuscationsTracked: mockDb.history.length + totalUsed,
    activeApiKeys: mockDb.apiKeys.filter(k => k.is_active).length
  }
})
