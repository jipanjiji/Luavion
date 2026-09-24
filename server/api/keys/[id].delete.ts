import { requireAuth } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const id = getRouterParam(event, 'id')

  if (!id) {
    throw createError({ statusCode: 400, statusMessage: 'API Key ID is required.' })
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    const { error } = await supabase
      .from('api_keys')
      .delete()
      .eq('id', id)
      .eq('user_id', user.id)

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return { ok: true, message: 'API key revoked successfully.' }
  }

  const index = mockDb.apiKeys.findIndex(k => k.id === id && k.user_id === user.id)
  if (index !== -1) {
    mockDb.apiKeys.splice(index, 1)
  }

  return { ok: true, message: 'API key revoked successfully.' }
})
