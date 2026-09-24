import { getUser } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'
import { getPlanConfig } from '../../utils/plans'

export default defineEventHandler(async (event) => {
  const user = await getUser(event)
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'Not authenticated' })
  }

  const body = await readBody(event) || {}
  const { plan, role } = body

  const targetPlan = plan || user.plan
  const targetRole = role || user.role
  const planConfig = getPlanConfig(targetPlan)

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('profiles')
      .update({
        plan: targetPlan,
        role: targetRole,
        quota_monthly_limit: planConfig.quotaMonthly
      })
      .eq('id', user.id)
      .select()
      .single()

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }
    return { ok: true, profile: data }
  }

  // Update in mock store
  const updated = mockDb.upsertProfile({
    ...user,
    plan: targetPlan,
    role: targetRole,
    quota_monthly_limit: planConfig.quotaMonthly
  })

  return { ok: true, profile: updated }
})
