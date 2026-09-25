import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const body = await readBody(event) || {}
  const { email, password, plan = 'free', role = 'user', name, action = 'login' } = body

  const supabase = getSupabaseClient()

  // 1. Live Supabase Google OAuth Flow
  if (action === 'google_oauth') {
    if (!supabase) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Supabase credentials are not configured in .env'
      })
    }

    const origin = getRequestHeader(event, 'origin') || 'http://localhost:3000'
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${origin}/auth/callback`
      }
    })

    if (error) {
      throw createError({ statusCode: 400, statusMessage: error.message })
    }

    return {
      ok: true,
      url: data.url
    }
  }

  // 2. Live Supabase Magic Link / OTP Flow
  if (action === 'magic_link' && email) {
    if (!supabase) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Supabase credentials are not configured in .env'
      })
    }

    const origin = getRequestHeader(event, 'origin') || 'http://localhost:3000'
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${origin}/auth/callback`
      }
    })

    if (error) {
      throw createError({ statusCode: 400, statusMessage: error.message })
    }

    return {
      ok: true,
      message: `A sign-in link has been sent to ${email}. Please check your inbox.`
    }
  }

  // 3. Fallback dev login (only allowed when Supabase is not configured)
  if (!supabase) {
    const targetEmail = email || 'developer@luavion.io'
    let user = mockDb.getProfileByEmail(targetEmail)

    if (!user) {
      user = mockDb.upsertProfile({
        id: `usr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        email: targetEmail,
        display_name: name || targetEmail.split('@')[0],
        avatar_url: `https://api.dicebear.com/7.x/identicon/svg?seed=${encodeURIComponent(targetEmail)}`,
        role: role as any,
        plan: plan as any
      })
    }

    setCookie(event, 'luavion_session', user.id, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 30,
      path: '/'
    })

    return {
      ok: true,
      user
    }
  }

  throw createError({
    statusCode: 400,
    statusMessage: 'Invalid authentication request.'
  })
})
