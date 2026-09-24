import { requireAuth } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const id = getRouterParam(event, 'id')

  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'History ID is required' })
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('obfuscation_history')
      .select('*')
      .eq('id', id)
      .eq('user_id', user.id)
      .single()

    if (error || !data) {
      throw createError({ statusCode: 404, statusMessage: 'Obfuscation record not found or expired' })
    }

    return { ok: true, item: data }
  }

  const item = mockDb.history.find(h => h.id === id && h.user_id === user.id)
  if (!item) {
    throw createError({ statusCode: 404, statusMessage: 'Obfuscation record not found' })
  }

  return { ok: true, item }
})
