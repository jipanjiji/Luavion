import { requireAdmin } from '../../utils/auth'
import { getPlanConfig } from '../../utils/plans'
import { getSupabaseClient, mockDb, type AdminAuditRecord } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const admin = await requireAdmin(event)
  const body = await readBody(event) || {}
  const { userId, plan, role, quotaTopupBonus } = body

  if (!userId) {
    throw createError({ statusCode: 400, statusMessage: 'userId is required' })
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    const updateData: Record<string, any> = {}
    if (plan) {
      updateData.plan = plan
      updateData.quota_monthly_limit = getPlanConfig(plan).quotaMonthly
    }
    if (role) {
      updateData.role = role
    }

    if (quotaTopupBonus !== undefined && quotaTopupBonus !== 0) {
      const { data: current } = await supabase.from('profiles').select('quota_topup_balance').eq('id', userId).single()
      updateData.quota_topup_balance = (current?.quota_topup_balance || 0) + Number(quotaTopupBonus)
    }

    const { data, error } = await supabase
      .from('profiles')
      .update(updateData)
      .eq('id', userId)
      .select()
      .single()

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    // Write audit log
    await supabase.from('admin_audit_logs').insert({
      admin_id: admin.id,
      action: 'ADMIN_USER_OVERRIDE',
      target_user_id: userId,
      details: { previous: { plan: data.plan, role: data.role }, updated: updateData }
    })

    return { ok: true, profile: data }
  }

  // Fallback to mock store
  const targetUser = mockDb.getProfile(userId)
  if (!targetUser) {
    throw createError({ statusCode: 404, statusMessage: 'User not found' })
  }

  if (plan) {
    targetUser.plan = plan
    targetUser.quota_monthly_limit = getPlanConfig(plan).quotaMonthly
  }
  if (role) {
    targetUser.role = role
  }
  if (quotaTopupBonus) {
    targetUser.quota_topup_balance = (targetUser.quota_topup_balance || 0) + Number(quotaTopupBonus)
  }

  // Add audit log
  const audit: AdminAuditRecord = {
    id: `audit_${Date.now()}`,
    admin_id: admin.id,
    admin_email: admin.email,
    action: `Modified user ${targetUser.email} (Plan: ${targetUser.plan}, Role: ${targetUser.role})`,
    target_user_id: userId,
    details: { plan, role, quotaTopupBonus },
    created_at: new Date().toISOString()
  }
  mockDb.auditLogs.unshift(audit)

  return { ok: true, profile: targetUser }
})
