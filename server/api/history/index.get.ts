import { requireAuth } from '../../utils/auth'
import { getPlanConfig } from '../../utils/plans'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const planConfig = getPlanConfig(user.plan)

  if (planConfig.historyRetentionDays === 0) {
    return {
      history: [],
      retentionDays: 0,
      notice: 'Obfuscation history is not saved on the Free plan. Upgrade to Plus, Pro, or Ultra to save and re-download past outputs.'
    }
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('obfuscation_history')
      .select('id, filename, original_bytes, obfuscated_bytes, expansion_ratio, duration_ms, preset, lua_version, status, created_at, expires_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return {
      history: data || [],
      retentionDays: planConfig.historyRetentionDays
    }
  }

  // Fallback to mock DB
  const userHistory = mockDb.history
    .filter(h => h.user_id === user.id)
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())

  return {
    history: userHistory,
    retentionDays: planConfig.historyRetentionDays
  }
})
