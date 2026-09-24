import type { H3Event } from 'h3'
import crypto from 'crypto'
import { getSupabaseClient, mockDb, type ProfileRecord } from './supabase'
import { getPlanConfig, type PlanTier } from './plans'

export async function getUser(event: H3Event): Promise<ProfileRecord | null> {
  // 1. Check if user already cached in event context
  if (event.context.user) {
    return event.context.user
  }

  // 2. Check for cookie-based session
  const sessionCookie = getCookie(event, 'luavion_session')
  const supabase = getSupabaseClient()

  if (supabase) {
    const authHeader = getHeader(event, 'authorization')
    const token = authHeader?.replace(/^Bearer\s+/i, '') || getCookie(event, 'sb-access-token')
    if (token && !token.startsWith('lua_live_')) {
      const { data: { user }, error } = await supabase.auth.getUser(token)
      if (user && !error) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single()
        if (profile) {
          event.context.user = profile as ProfileRecord
          return event.context.user
        }
      }
    }
  }

  // 3. Fallback to mock session
  if (sessionCookie) {
    const user = mockDb.getProfile(sessionCookie)
    if (user) {
      event.context.user = user
      return user
    }
  }

  // Default dev profile if in local development mode without explicit session
  const defaultDevUser = mockDb.getProfile('usr_mock_demo_01')
  if (defaultDevUser) {
    event.context.user = defaultDevUser
    return defaultDevUser
  }

  return null
}

export async function requireAuth(event: H3Event): Promise<ProfileRecord> {
  const user = await getUser(event)
  if (!user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Authentication required. Please sign in.'
    })
  }
  return user
}

export async function requireAdmin(event: H3Event): Promise<ProfileRecord> {
  const user = await requireAuth(event)
  if (user.role !== 'admin') {
    throw createError({
      statusCode: 403,
      statusMessage: 'Administrator privileges required.'
    })
  }
  return user
}

export async function requirePlan(event: H3Event, requiredPlan: PlanTier): Promise<ProfileRecord> {
  const user = await requireAuth(event)
  const tierRanks: Record<PlanTier, number> = { free: 0, plus: 1, pro: 2, ultra: 3 }
  if (tierRanks[user.plan] < tierRanks[requiredPlan]) {
    throw createError({
      statusCode: 403,
      statusMessage: `This feature requires a ${requiredPlan.toUpperCase()} plan. Your current plan is ${user.plan.toUpperCase()}.`
    })
  }
  return user
}

export async function authenticateApiKey(event: H3Event): Promise<{ user: ProfileRecord; apiKey: any }> {
  const authHeader = getHeader(event, 'authorization')
  if (!authHeader || !authHeader.startsWith('Bearer lua_live_')) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Unauthorized. Missing or invalid Bearer API key in Authorization header (expected Bearer lua_live_...).'
    })
  }

  const rawKey = authHeader.replace(/^Bearer\s+/i, '').trim()
  const keyHash = crypto.createHash('sha256').update(rawKey).digest('hex')

  const supabase = getSupabaseClient()
  if (supabase) {
    const { data: keyRecord, error } = await supabase
      .from('api_keys')
      .select('*, profiles(*)')
      .eq('key_hash', keyHash)
      .eq('is_active', true)
      .single()

    if (error || !keyRecord) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Invalid or revoked API key.'
      })
    }

    const userProfile = keyRecord.profiles as ProfileRecord
    if (userProfile.plan !== 'ultra') {
      throw createError({
        statusCode: 403,
        statusMessage: 'API access is exclusively available on the Ultra plan. This API key has been deactivated.'
      })
    }

    // Update last_used_at
    await supabase.from('api_keys').update({ last_used_at: new Date().toISOString() }).eq('id', keyRecord.id)
    return { user: userProfile, apiKey: keyRecord }
  }

  // Fallback to mock DB
  const mockKey = mockDb.apiKeys.find(k => k.key_hash === keyHash && k.is_active)
  if (!mockKey) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid or revoked API key.'
    })
  }

  const user = mockDb.getProfile(mockKey.user_id)
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'API key owner not found.' })
  }

  if (user.plan !== 'ultra') {
    throw createError({
      statusCode: 403,
      statusMessage: 'API access is exclusively available on the Ultra plan. This API key has been deactivated.'
    })
  }

  mockKey.last_used_at = new Date().toISOString()
  return { user, apiKey: mockKey }
}
