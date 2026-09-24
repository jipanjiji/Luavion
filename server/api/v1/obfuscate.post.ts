import { authenticateApiKey } from '../../utils/auth'
import { obfuscate } from '../../engine/engine.js'
import { getPlanConfig } from '../../utils/plans'
import { getSupabaseClient, mockDb } from '../../utils/supabase'

// Rate limiter map: keyHash -> { count: number, windowStart: number }
const rateLimitMap = new Map<string, { count: number; windowStart: number }>()

function checkRateLimit(keyId: string, limitPerMin: number = 60): boolean {
  const now = Date.now()
  const windowMs = 60 * 1000
  const record = rateLimitMap.get(keyId)

  if (!record || now - record.windowStart > windowMs) {
    rateLimitMap.set(keyId, { count: 1, windowStart: now })
    return true
  }

  if (record.count >= limitPerMin) {
    return false
  }

  record.count += 1
  return true
}

export default defineEventHandler(async (event) => {
  // 1. Authenticate API Key & Ultra plan requirement
  const { user, apiKey } = await authenticateApiKey(event)

  // 2. Rate limiting (60 req/min)
  if (!checkRateLimit(apiKey.id, apiKey.rate_limit_per_minute || 60)) {
    throw createError({
      statusCode: 429,
      statusMessage: 'Rate limit exceeded. Ultra plan API limit is 60 requests per minute.'
    })
  }

  // 3. Read request body
  const body = await readBody(event)
  const rawSource = body?.source ?? body?.code
  if (typeof rawSource !== 'string' || !rawSource.trim()) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid input: "source" (Lua script string) is required.'
    })
  }

  const source = rawSource
  const preset = String(body.preset || 'BALANCED').toUpperCase()
  const luaVersion = String(body.luaVersion || 'LuaU')
  const seed = Number(body.seed) || Math.floor(Math.random() * 1000000) + 1
  const prettyPrint = Boolean(body.prettyPrint)
  const filename = String(body.filename || 'script.lua')
  const includeBanner = body.includeBanner !== false

  // 4. File size check (5 MB for Ultra)
  const origBytes = Buffer.byteLength(source, 'utf8')
  const planConfig = getPlanConfig(user.plan)
  if (origBytes > planConfig.maxFileSizeBytes) {
    throw createError({
      statusCode: 413,
      statusMessage: `Payload too large. File size exceeds Ultra plan limit of 5 MB.`
    })
  }

  // 5. Quota check
  const remainingMonthly = Math.max(0, user.quota_monthly_limit - user.quota_used_this_month)
  const totalRemaining = remainingMonthly + (user.quota_topup_balance || 0)
  if (totalRemaining <= 0) {
    throw createError({
      statusCode: 403,
      statusMessage: 'Quota exceeded. Monthly obfuscation limit reached. Please purchase top-up credits.'
    })
  }

  // 6. Execute Obfuscation
  const startTime = performance.now()
  const result = await obfuscate(source, {
    preset,
    luaVersion,
    seed,
    prettyPrint,
    includeBanner,
    filename
  })
  const durationMs = Math.round((performance.now() - startTime) * 10) / 10

  if (!result.ok) {
    throw createError({
      statusCode: 422,
      statusMessage: `Obfuscation failed: ${result.error}`
    })
  }

  const obfBytes = Buffer.byteLength(result.output, 'utf8')
  const ratio = Math.round((obfBytes / (origBytes || 1)) * 10) / 10

  // 7. Deduct Quota
  let newUsed = user.quota_used_this_month
  let newTopup = user.quota_topup_balance || 0

  if (newUsed < user.quota_monthly_limit) {
    newUsed += 1
  } else if (newTopup > 0) {
    newTopup -= 1
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    await supabase.from('profiles').update({
      quota_used_this_month: newUsed,
      quota_topup_balance: newTopup
    }).eq('id', user.id)

    // Save history (Ultra retains 90 days)
    const expiresAt = new Date(Date.now() + 90 * 24 * 3600 * 1000).toISOString()
    await supabase.from('obfuscation_history').insert({
      user_id: user.id,
      filename,
      original_bytes: origBytes,
      obfuscated_bytes: obfBytes,
      expansion_ratio: ratio,
      duration_ms: durationMs,
      preset,
      lua_version: luaVersion,
      seed: result.seed,
      status: 'completed',
      obfuscated_code: result.output,
      expires_at: expiresAt
    })
  } else {
    user.quota_used_this_month = newUsed
    user.quota_topup_balance = newTopup
  }

  return {
    ok: true,
    output: result.output,
    stats: {
      originalBytes: origBytes,
      obfuscatedBytes: obfBytes,
      expansionRatio: ratio,
      durationMs,
      preset,
      luaVersion,
      seed: result.seed
    },
    quota: {
      used: newUsed,
      limit: user.quota_monthly_limit,
      remaining: Math.max(0, user.quota_monthly_limit - newUsed) + newTopup
    }
  }
})
