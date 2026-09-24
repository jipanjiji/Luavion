import Stripe from 'stripe'
import { requireAuth } from '../../utils/auth'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const stripeKey = process.env.STRIPE_SECRET_KEY
  const origin = getRequestHeader(event, 'origin') || 'http://localhost:3000'

  if (stripeKey && user.stripe_customer_id) {
    const stripe = new Stripe(stripeKey)
    const portalSession = await stripe.billingPortal.sessions.create({
      customer: user.stripe_customer_id,
      return_url: `${origin}/billing`
    })
    return { ok: true, url: portalSession.url }
  }

  // Fallback if not configured
  return {
    ok: true,
    url: `${origin}/billing?portal=simulated`,
    simulated: true,
    message: 'Stripe Customer Portal simulated.'
  }
})
