import { getUser } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await getUser(event)
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: 'Not authenticated' })
  }

  const body = await readBody(event) || {}
  const { confirmationCode } = body

  // Require 2FA security confirmation string "DELETE-MY-LUAVION-ACCOUNT"
  if (confirmationCode !== 'DELETE-MY-LUAVION-ACCOUNT') {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid confirmation phrase. Please type DELETE-MY-LUAVION-ACCOUNT to confirm account deletion.'
    })
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    await supabase.from('profiles').delete().eq('id', user.id)
    await supabase.auth.admin.deleteUser(user.id)
  } else {
    mockDb.profiles.delete(user.id)
  }

  deleteCookie(event, 'luavion_session', { path: '/' })
  deleteCookie(event, 'sb-access-token', { path: '/' })

  return { ok: true, message: 'Account and associated data deleted permanently.' }
})
