import { getSupabaseClient } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const supabase = getSupabaseClient()
  if (supabase) {
    await supabase.auth.signOut()
  }

  deleteCookie(event, 'luavion_session', { path: '/' })
  deleteCookie(event, 'sb-access-token', { path: '/' })

  return { ok: true, message: 'Logged out successfully' }
})
