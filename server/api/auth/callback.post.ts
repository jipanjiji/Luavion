import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const body = await readBody(event) || {}
  const { code, accessToken, refreshToken } = body

  const supabase = getSupabaseClient()
  if (!supabase) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Supabase client is not configured'
    })
  }

  let sessionAccessToken = accessToken
  let user = null

  // 1. If authorization code provided (PKCE flow)
  if (code) {
    const { data, error } = await supabase.auth.exchangeCodeForSession(code)
    if (error || !data.session) {
      throw createError({
        statusCode: 400,
        statusMessage: error?.message || 'Failed to exchange code for session'
      })
    }
    sessionAccessToken = data.session.access_token
    user = data.session.user
  } else if (sessionAccessToken) {
    const { data, error } = await supabase.auth.getUser(sessionAccessToken)
    if (error || !data.user) {
      throw createError({
        statusCode: 400,
        statusMessage: error?.message || 'Invalid access token'
      })
    }
    user = data.user
  } else {
    throw createError({
      statusCode: 400,
      statusMessage: 'Missing authorization code or access token'
    })
  }

  // 2. Ensure profile exists in public.profiles table or fallback store
  let profile = null
  try {
    const { data: existingProfile, error: profileErr } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (existingProfile && !profileErr) {
      profile = existingProfile
    } else {
      const isAdminUser = user.email?.toLowerCase().trim() === 'alvinraditya101@gmail.com'

      const { data: newProfile, error: insertErr } = await supabase
        .from('profiles')
        .insert({
          id: user.id,
          email: user.email,
          display_name: user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0],
          avatar_url: user.user_metadata?.avatar_url || user.user_metadata?.picture,
          role: isAdminUser ? 'admin' : 'user',
          plan: isAdminUser ? 'ultra' : 'free',
          quota_monthly_limit: isAdminUser ? 7500 : 50,
          quota_used_this_month: 0
        })
        .select()
        .single()

      if (!insertErr && newProfile) {
        profile = newProfile
      }
    }
  } catch (e) {
    console.warn('public.profiles table not ready yet, using memory fallback')
  }

  if (!profile) {
    const isAdminUser = user.email?.toLowerCase().trim() === 'alvinraditya101@gmail.com'
    profile = mockDb.upsertProfile({
      id: user.id,
      email: user.email,
      display_name: user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0],
      avatar_url: user.user_metadata?.avatar_url || user.user_metadata?.picture,
      role: isAdminUser ? 'admin' : 'user',
      plan: isAdminUser ? 'ultra' : 'free',
      quota_monthly_limit: isAdminUser ? 7500 : 50
    })
  }

  // 3. Set secure cookies for session persistence
  setCookie(event, 'sb-access-token', sessionAccessToken, {
    httpOnly: false, // Accessible to client and server
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 30, // 30 days
    path: '/'
  })

  setCookie(event, 'luavion_session', user.id, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 30,
    path: '/'
  })

  return {
    ok: true,
    user: profile
  }
})
