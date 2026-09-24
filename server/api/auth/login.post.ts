import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const body = await readBody(event) || {}
  const { email, plan = 'free', role = 'user', name, action = 'login' } = body

  const supabase = getSupabaseClient()

  // 1. Live Supabase Google OAuth Flow
  if (action === 'google_oauth' && supabase) {
    const origin = getRequestHeader(event, 'origin') || 'http://localhost:3000'
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${origin}/auth/callback`
      }
    })

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return {
      ok: true,
      url: data.url
    }
  }

  // 2. Dev / Testing or Simulated Google Sign-in Flow
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
  } else if (plan && plan !== user.plan) {
    user = mockDb.upsertProfile({
      ...user,
      plan: plan as any
    })
  }

  // Set secure session cookie
  setCookie(event, 'luavion_session', user.id, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 30, // 30 days
    path: '/'
  })

  return {
    ok: true,
    user
  }
})
