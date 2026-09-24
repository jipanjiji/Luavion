import { requireAuth } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)

  const isUltra = user.plan === 'ultra'

  if (!isUltra) {
    return {
      allowed: false,
      keys: [],
      notice: 'API access is exclusively available on the Ultra plan ($30/mo or Rp 500,000/mo). Upgrade to Ultra to generate API keys, integrate CI/CD pipelines, and access the public REST API.'
    }
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('api_keys')
      .select('id, name, key_prefix, is_active, rate_limit_per_minute, last_used_at, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return {
      allowed: true,
      keys: data || []
    }
  }

  const userKeys = mockDb.apiKeys
    .filter(k => k.user_id === user.id)
    .map(k => ({
      id: k.id,
      name: k.name,
      key_prefix: k.key_prefix,
      is_active: k.is_active,
      rate_limit_per_minute: k.rate_limit_per_minute,
      last_used_at: k.last_used_at,
      created_at: k.created_at
    }))

  return {
    allowed: true,
    keys: userKeys
  }
})
