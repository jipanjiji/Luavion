import { requireAuth } from '../../utils/auth'
import { getPlanConfig } from '../../utils/plans'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const planConfig = getPlanConfig(user.plan)

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('custom_presets')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return {
      presets: data || [],
      allowedLimit: planConfig.customPresetsLimit
    }
  }

  const userPresets = mockDb.presets.filter(p => p.user_id === user.id)
  return {
    presets: userPresets,
    allowedLimit: planConfig.customPresetsLimit
  }
})
