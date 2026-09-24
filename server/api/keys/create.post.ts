import crypto from 'crypto'
import { requireAuth } from '../../utils/auth'
import { getSupabaseClient, mockDb, type ApiKeyRecord } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)

  if (user.plan !== 'ultra') {
    throw createError({
      statusCode: 403,
      statusMessage: 'API access and key generation are exclusively available on the Ultra plan. Upgrade to Ultra to unlock REST API access.'
    })
  }

  const body = await readBody(event) || {}
  const { name = 'Production API Key' } = body

  // Generate cryptographically secure random API key
  const randomEntropy = crypto.randomBytes(24).toString('hex')
  const secretKey = `lua_live_${randomEntropy}`
  const keyHash = crypto.createHash('sha256').update(secretKey).digest('hex')
  const keyPrefix = `lua_live_${randomEntropy.substring(0, 4)}...${randomEntropy.substring(randomEntropy.length - 4)}`

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data, error } = await supabase
      .from('api_keys')
      .insert({
        user_id: user.id,
        name: name.trim() || 'Production API Key',
        key_prefix: keyPrefix,
        key_hash: keyHash,
        is_active: true,
        rate_limit_per_minute: 60
      })
      .select('id, name, key_prefix, created_at')
      .single()

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return {
      ok: true,
      key: data,
      secretKey // Returned once upon creation only
    }
  }

  // Fallback to mock store
  const mockKey: ApiKeyRecord = {
    id: `key_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
    user_id: user.id,
    name: name.trim() || 'Production API Key',
    key_prefix: keyPrefix,
    key_hash: keyHash,
    is_active: true,
    rate_limit_per_minute: 60,
    last_used_at: null,
    created_at: new Date().toISOString()
  }
  mockDb.apiKeys.unshift(mockKey)

  return {
    ok: true,
    key: {
      id: mockKey.id,
      name: mockKey.name,
      key_prefix: mockKey.key_prefix,
      created_at: mockKey.created_at
    },
    secretKey
  }
})
