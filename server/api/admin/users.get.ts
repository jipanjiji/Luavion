import { requireAdmin } from '../../utils/auth'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  await requireAdmin(event)

  const query = getQuery(event)
  const search = String(query.search || '').toLowerCase()

  const supabase = getSupabaseClient()
  if (supabase) {
    let q = supabase.from('profiles').select('*').order('created_at', { ascending: false }).limit(100)
    if (search) {
      q = q.or(`email.ilike.%${search}%,display_name.ilike.%${search}%`)
    }
    const { data, error } = await q
    if (error) throw createError({ statusCode: 500, statusMessage: error.message })
    return { users: data || [] }
  }

  // Fallback to mock store
  let users = Array.from(mockDb.profiles.values())
  if (search) {
    users = users.filter(u => u.email.toLowerCase().includes(search) || u.display_name.toLowerCase().includes(search))
  }

  return { users }
})
