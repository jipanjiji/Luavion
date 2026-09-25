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
    let authUser: any = null

    // Try verifying Supabase JWT access token
    if (token && !token.startsWith('lua_live_')) {
      try {
        const { data, error } = await supabase.auth.getUser(token)
        if (data?.user && !error) {
          authUser = data.user
        }
      } catch (e) {
        // Token might be invalid or expired
      }
    }

    // If no valid token from JWT, check sessionCookie against Supabase auth.users
    if (!authUser && sessionCookie && sessionCookie.includes('-')) {
      try {
        const { data, error } = await supabase.auth.admin.getUserById(sessionCookie)
        if (data?.user && !error) {
          authUser = data.user
        }
      } catch (e) {
        // Not a Supabase user or failed lookup
      }
    }

    if (authUser) {
      let profile: ProfileRecord | null = null

      // Attempt to load from public.profiles table in Supabase
      try {
        const { data: dbProfile, error: profileErr } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', authUser.id)
          .single()

        if (dbProfile && !profileErr) {
          profile = dbProfile as ProfileRecord
        } else {
          // Check if user is system admin
          const isAdminUser = authUser.email?.toLowerCase().trim() === 'alvinraditya101@gmail.com'

          const { data: newProfile, error: insertErr } = await supabase
            .from('profiles')
            .insert({
              id: authUser.id,
              email: authUser.email,
              display_name: authUser.user_metadata?.full_name || authUser.user_metadata?.name || authUser.email?.split('@')[0],
              avatar_url: authUser.user_metadata?.avatar_url || authUser.user_metadata?.picture,
              role: isAdminUser ? 'admin' : 'user',
              plan: isAdminUser ? 'ultra' : 'free',
              quota_monthly_limit: isAdminUser ? 7500 : 50,
              quota_used_this_month: 0
            })
            .select()
            .single()

          if (newProfile && !insertErr) {
            profile = newProfile as ProfileRecord
          }
        }
      } catch (err) {
        console.warn('public.profiles table not ready yet, using memory store fallback')
      }

      // Resilient fallback: If public.profiles table does not exist or failed,
      // create a memory profile in mockDb so user is never locked out of their authenticated session!
      if (!profile) {
        const isAdminUser = authUser.email?.toLowerCase().trim() === 'alvinraditya101@gmail.com'
        profile = mockDb.getProfile(authUser.id) || mockDb.upsertProfile({
          id: authUser.id,
          email: authUser.email || '',
          display_name: authUser.user_metadata?.full_name || authUser.user_metadata?.name || authUser.email?.split('@')[0] || 'User',
          avatar_url: authUser.user_metadata?.avatar_url || authUser.user_metadata?.picture || '',
          role: isAdminUser ? 'admin' : 'user',
          plan: isAdminUser ? 'ultra' : 'free',
          quota_monthly_limit: isAdminUser ? 7500 : 50,
          quota_used_this_month: 0
        })
      }

      event.context.user = profile
      return event.context.user
    }

    // Also check session cookie directly against Supabase profiles table if it wasn't a UUID
    if (sessionCookie) {
      try {
        const { data: profile } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', sessionCookie)
          .single()
        if (profile) {
          event.context.user = profile as ProfileRecord
          return event.context.user
        }
      } catch (e) {
        // Table may not exist
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
