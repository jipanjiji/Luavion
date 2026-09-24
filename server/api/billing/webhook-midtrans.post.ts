import crypto from 'crypto'
import { getSupabaseClient, mockDb } from '../../utils/supabase'
import { getPlanConfig } from '../../utils/plans'

export default defineEventHandler(async (event) => {
  const body = await readBody(event) || {}
  const {
    order_id,
    status_code,
    gross_amount,
    signature_key,
    transaction_status
  } = body

  const serverKey = process.env.MIDTRANS_SERVER_KEY

  // Validate Midtrans SHA-512 signature if server key is present
  if (serverKey && signature_key) {
    const rawSignature = `${order_id}${status_code}${gross_amount}${serverKey}`
    const expectedSignature = crypto.createHash('sha512').update(rawSignature).digest('hex')
    if (signature_key !== expectedSignature) {
      throw createError({ statusCode: 403, statusMessage: 'Invalid Midtrans signature.' })
    }
  }

  const supabase = getSupabaseClient()

  if (transaction_status === 'settlement' || transaction_status === 'capture') {
    // Determine whether this was top-up or plan subscription from order_id:
    // e.g. LUAV-TOPUP-<ts>-<userId> or LUAV-SUB-PRO-<ts>
    if (order_id?.startsWith('LUAV-TOPUP-')) {
      const parts = order_id.split('-')
      const userId = parts[parts.length - 1]
      // Add top-up balance
      if (supabase && userId) {
        const { data: profile } = await supabase.from('profiles').select('quota_topup_balance').ilike('id', `${userId}%`).single()
        if (profile) {
          await supabase.from('profiles').update({
            quota_topup_balance: (profile.quota_topup_balance || 0) + 10
          }).eq('id', profile.id)
        }
      }
    } else if (order_id?.startsWith('LUAV-SUB-')) {
      const parts = order_id.split('-')
      const plan = (parts[2] || 'plus').toLowerCase()
      const planConfig = getPlanConfig(plan)
      // Update plan
      // Handled via order reference
    }
  }

  return { status: 'OK' }
})
