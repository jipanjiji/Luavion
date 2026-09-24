import Stripe from 'stripe'
import { requireAuth } from '../../utils/auth'
import { getPlanConfig, TOP_UP_PRICING, type PlanTier } from '../../utils/plans'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const body = await readBody(event) || {}
  const {
    plan,
    currency = 'USD',
    isTopUp = false,
    topUpCount = 10
  } = body

  const origin = getRequestHeader(event, 'origin') || 'http://localhost:3000'
  const isIdr = currency.toUpperCase() === 'IDR'

  // =========================================================================
  // 1. QUOTA TOP-UP CHECKOUT FLOW ($0.50 / Rp 5,000 per unit)
  // =========================================================================
  if (isTopUp) {
    const pack = TOP_UP_PRICING.packs.find(p => p.count === topUpCount) || {
      count: topUpCount,
      priceUsd: (topUpCount * TOP_UP_PRICING.unitPriceUsd),
      priceIdr: (topUpCount * TOP_UP_PRICING.unitPriceIdr)
    }

    if (isIdr) {
      // Indonesian Gateway (Midtrans) Flow
      const midtransKey = process.env.MIDTRANS_SERVER_KEY
      const orderId = `LUAV-TOPUP-${Date.now()}-${user.id.substring(0, 5)}`

      if (midtransKey) {
        try {
          const authString = Buffer.from(`${midtransKey}:`).toString('base64')
          const midtransRes = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': `Basic ${authString}`
            },
            body: JSON.stringify({
              transaction_details: {
                order_id: orderId,
                gross_amount: pack.priceIdr
              },
              customer_details: {
                first_name: user.display_name,
                email: user.email
              },
              item_details: [{
                id: `topup-${pack.count}`,
                price: pack.priceIdr,
                quantity: 1,
                name: `Luavion Quota Top-Up (${pack.count} Obfuscations)`
              }]
            })
          })
          const snapData = await midtransRes.json()
          if (snapData.redirect_url) {
            return { ok: true, checkoutUrl: snapData.redirect_url, provider: 'midtrans', orderId }
          }
        } catch (e) {
          console.error('Midtrans API error, falling back to simulated checkout:', e)
        }
      }

      // Simulated local test flow
      const newBalance = (user.quota_topup_balance || 0) + pack.count
      if (getSupabaseClient()) {
        await getSupabaseClient()?.from('profiles').update({ quota_topup_balance: newBalance }).eq('id', user.id)
      } else {
        user.quota_topup_balance = newBalance
      }
      return {
        ok: true,
        simulated: true,
        provider: 'midtrans',
        message: `Successfully credited ${pack.count} extra obfuscations via simulated Midtrans payment.`,
        newBalance
      }
    } else {
      // USD Stripe Flow
      const stripeKey = process.env.STRIPE_SECRET_KEY
      if (stripeKey) {
        const stripe = new Stripe(stripeKey)
        const session = await stripe.checkout.sessions.create({
          payment_method_types: ['card'],
          mode: 'payment',
          customer_email: user.email,
          line_items: [{
            price_data: {
              currency: 'usd',
              product_data: {
                name: `Luavion Top-Up (${pack.count} Obfuscations)`,
                description: `Pay-as-you-go extra obfuscation credits for your Luavion account.`
              },
              unit_amount: Math.round(pack.priceUsd * 100)
            },
            quantity: 1
          }],
          metadata: {
            userId: user.id,
            type: 'topup',
            topUpCount: String(pack.count)
          },
          success_url: `${origin}/dashboard?topup=success&count=${pack.count}`,
          cancel_url: `${origin}/billing?topup=cancelled`
        })
        return { ok: true, checkoutUrl: session.url, provider: 'stripe' }
      }

      // Simulated dev mode
      const newBalance = (user.quota_topup_balance || 0) + pack.count
      if (getSupabaseClient()) {
        await getSupabaseClient()?.from('profiles').update({ quota_topup_balance: newBalance }).eq('id', user.id)
      } else {
        user.quota_topup_balance = newBalance
      }
      return {
        ok: true,
        simulated: true,
        provider: 'stripe',
        message: `Successfully credited ${pack.count} extra obfuscations (Simulated Stripe payment).`,
        newBalance
      }
    }
  }

  // =========================================================================
  // 2. SUBSCRIPTION PLAN CHECKOUT FLOW (Plus, Pro, Ultra)
  // =========================================================================
  const targetPlan = (plan || 'plus').toLowerCase() as PlanTier
  const planConfig = getPlanConfig(targetPlan)

  if (targetPlan === 'free') {
    // Downgrade to Free
    const supabase = getSupabaseClient()
    if (supabase) {
      await supabase.from('profiles').update({
        plan: 'free',
        quota_monthly_limit: 50
      }).eq('id', user.id)
    } else {
      user.plan = 'free'
      user.quota_monthly_limit = 50
    }
    return { ok: true, message: 'Plan adjusted to Free tier.', plan: 'free' }
  }

  if (isIdr) {
    // Midtrans Indonesian Gateway Flow
    const midtransKey = process.env.MIDTRANS_SERVER_KEY
    const orderId = `LUAV-SUB-${targetPlan.toUpperCase()}-${Date.now()}`

    if (midtransKey) {
      try {
        const authString = Buffer.from(`${midtransKey}:`).toString('base64')
        const midtransRes = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': `Basic ${authString}`
          },
          body: JSON.stringify({
            transaction_details: {
              order_id: orderId,
              gross_amount: planConfig.priceIdr
            },
            customer_details: {
              first_name: user.display_name,
              email: user.email
            },
            item_details: [{
              id: `plan-${targetPlan}`,
              price: planConfig.priceIdr,
              quantity: 1,
              name: `Luavion ${planConfig.name} Plan (1 Month)`
            }]
          })
        })
        const snapData = await midtransRes.json()
        if (snapData.redirect_url) {
          return { ok: true, checkoutUrl: snapData.redirect_url, provider: 'midtrans', orderId }
        }
      } catch (e) {
        console.error('Midtrans API error, falling back to simulated checkout:', e)
      }
    }

    // Simulated local upgrade for testing
    const supabase = getSupabaseClient()
    if (supabase) {
      await supabase.from('profiles').update({
        plan: targetPlan,
        plan_currency: 'IDR',
        quota_monthly_limit: planConfig.quotaMonthly,
        plan_expires_at: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
      }).eq('id', user.id)
    } else {
      user.plan = targetPlan
      user.plan_currency = 'IDR'
      user.quota_monthly_limit = planConfig.quotaMonthly
      user.plan_expires_at = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
    }

    return {
      ok: true,
      simulated: true,
      provider: 'midtrans',
      message: `Upgraded to ${planConfig.name} plan via simulated Indonesian Gateway payment (Rp ${planConfig.priceIdr.toLocaleString('id-ID')}/mo).`,
      plan: targetPlan
    }
  } else {
    // Stripe USD Flow
    const stripeKey = process.env.STRIPE_SECRET_KEY
    if (stripeKey) {
      const stripe = new Stripe(stripeKey)
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        mode: 'subscription',
        customer_email: user.email,
        line_items: [{
          price_data: {
            currency: 'usd',
            recurring: { interval: 'month' },
            product_data: {
              name: `Luavion ${planConfig.name} Subscription`,
              description: `Access to ${planConfig.quotaMonthly} obfuscations/month, ${planConfig.maxFileSizeLabel} max file size, ${planConfig.features[2] || ''}`
            },
            unit_amount: planConfig.priceUsd * 100
          },
          quantity: 1
        }],
        metadata: {
          userId: user.id,
          plan: targetPlan
        },
        success_url: `${origin}/billing?payment=success&plan=${targetPlan}`,
        cancel_url: `${origin}/billing?payment=cancelled`
      })
      return { ok: true, checkoutUrl: session.url, provider: 'stripe' }
    }

    // Simulated dev mode
    const supabase = getSupabaseClient()
    if (supabase) {
      await supabase.from('profiles').update({
        plan: targetPlan,
        plan_currency: 'USD',
        quota_monthly_limit: planConfig.quotaMonthly,
        plan_expires_at: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
      }).eq('id', user.id)
    } else {
      user.plan = targetPlan
      user.plan_currency = 'USD'
      user.quota_monthly_limit = planConfig.quotaMonthly
      user.plan_expires_at = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
    }

    return {
      ok: true,
      simulated: true,
      provider: 'stripe',
      message: `Upgraded to ${planConfig.name} plan ($${planConfig.priceUsd}/mo) via simulated Stripe subscription.`,
      plan: targetPlan
    }
  }
})
