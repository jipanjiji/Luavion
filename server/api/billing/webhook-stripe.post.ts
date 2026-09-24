import Stripe from 'stripe'
import { getSupabaseClient, mockDb } from '../../utils/supabase'
import { getPlanConfig } from '../../utils/plans'

export default defineEventHandler(async (event) => {
  const stripeKey = process.env.STRIPE_SECRET_KEY
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET

  if (!stripeKey) {
    return { received: true, simulated: true }
  }

  const stripe = new Stripe(stripeKey)
  const body = await readRawBody(event)
  const signature = getHeader(event, 'stripe-signature')

  let stripeEvent: Stripe.Event
  try {
    if (webhookSecret && signature && body) {
      stripeEvent = stripe.webhooks.constructEvent(body, signature, webhookSecret)
    } else {
      stripeEvent = JSON.parse(body?.toString() || '{}')
    }
  } catch (err: any) {
    throw createError({ statusCode: 400, statusMessage: `Webhook error: ${err.message}` })
  }

  const supabase = getSupabaseClient()

  switch (stripeEvent.type) {
    case 'checkout.session.completed': {
      const session = stripeEvent.data.object as Stripe.Checkout.Session
      const userId = session.metadata?.userId
      const plan = session.metadata?.plan
      const type = session.metadata?.type
      const topUpCount = Number(session.metadata?.topUpCount) || 0

      if (userId) {
        if (type === 'topup' && topUpCount > 0) {
          // Increment top-up quota
          if (supabase) {
            const { data: profile } = await supabase.from('profiles').select('quota_topup_balance').eq('id', userId).single()
            const newBal = (profile?.quota_topup_balance || 0) + topUpCount
            await supabase.from('profiles').update({ quota_topup_balance: newBal }).eq('id', userId)
          } else {
            const profile = mockDb.getProfile(userId)
            if (profile) profile.quota_topup_balance = (profile.quota_topup_balance || 0) + topUpCount
          }
        } else if (plan) {
          const planConfig = getPlanConfig(plan)
          if (supabase) {
            await supabase.from('profiles').update({
              plan,
              quota_monthly_limit: planConfig.quotaMonthly,
              stripe_customer_id: session.customer as string,
              stripe_subscription_id: session.subscription as string
            }).eq('id', userId)
          } else {
            const profile = mockDb.getProfile(userId)
            if (profile) {
              profile.plan = plan as any
              profile.quota_monthly_limit = planConfig.quotaMonthly
            }
          }
        }
      }
      break
    }

    case 'customer.subscription.deleted': {
      const subscription = stripeEvent.data.object as Stripe.Subscription
      const customerId = subscription.customer as string
      // Revert to Free tier at period end / cancellation
      if (supabase) {
        await supabase.from('profiles').update({
          plan: 'free',
          quota_monthly_limit: 50,
          stripe_subscription_id: null
        }).eq('stripe_customer_id', customerId)
      }
      break
    }
  }

  return { received: true }
})
