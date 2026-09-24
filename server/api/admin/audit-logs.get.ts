import { requireAdmin } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  await requireAdmin(event)

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('admin_audit_logs')
      .select('*, profiles(email, display_name)')
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) throw createError({ statusCode: 500, statusMessage: error.message })
    return { logs: data || [] }
  }

  return { logs: mockDb.auditLogs }
})
