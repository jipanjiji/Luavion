import { obfuscate } from '../engine/engine.js'
import { getUser } from '../utils/auth'
import { getPlanConfig, isPresetAllowed } from '../utils/plans'
import { getSupabaseClient, mockDb, type ObfuscationHistoryRecord } from '../utils/supabase'

interface SyntaxErrorDetail {
  isSyntaxError: boolean
  kind: 'parsing' | 'lexing' | 'general'
  line?: number
  column?: number
  message: string
  context?: string
  friendlyTitle: string
}

function parseEngineError(raw: string): { friendlyError: string; detail: SyntaxErrorDetail } {
  const [firstPart] = (raw || '').split('stack traceback:')
  const clean = firstPart.replace(/^table:\s*0x[0-9a-fA-F]+\s*/, '').trim()

  // Match: (Parsing|Lexing) Error at Position (\d+):(\d+), (.*)
  const posMatch = clean.match(/(?:Parsing|Lexing)\s+Error\s+at\s+Position\s+(\d+):(\d+),\s*([\s\S]*)$/i)
  if (posMatch) {
    const line = parseInt(posMatch[1], 10)
    const column = parseInt(posMatch[2], 10)
    let remainder = posMatch[3].trim()
    let context: string | undefined = undefined

    const ctxIdx = remainder.indexOf('Context:')
    if (ctxIdx !== -1) {
      context = remainder.slice(ctxIdx + 8).trim()
      remainder = remainder.slice(0, ctxIdx).trim()
    }

    const isLex = clean.toLowerCase().startsWith('lexing')
    return {
      friendlyError: `Syntax Error at Line ${line}, Column ${column}: ${remainder}`,
      detail: {
        isSyntaxError: true,
        kind: isLex ? 'lexing' : 'parsing',
        line,
        column,
        message: remainder,
        context,
        friendlyTitle: `Syntax Error (Line ${line}:${column})`
      }
    }
  }

  return {
    friendlyError: clean || 'Obfuscation pipeline failed.',
    detail: {
      isSyntaxError: false,
      kind: 'general',
      message: clean,
      friendlyTitle: 'Engine Execution Error'
    }
  }
}

export default defineEventHandler(async (event) => {
  try {
    const body = await readBody(event)

    const rawSource = body?.source ?? body?.code
    if (typeof rawSource !== 'string' || !rawSource.trim()) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Source script cannot be empty.'
      })
    }

    const source = rawSource
    const preset = String(body.preset || 'BALANCED').toUpperCase()
    const luaVersion = String(body.luaVersion || 'LuaU')
    const seed = Number(body.seed) || Math.floor(Math.random() * 1000000) + 1
    const prettyPrint = Boolean(body.prettyPrint)
    const includeBanner = body.includeBanner !== false
    const filename = String(body.filename || 'script.lua')

    // 1. Authenticate user and verify plan
    const user = await requireAuth(event)
    const userPlan = user.plan
    const planConfig = getPlanConfig(userPlan)

    // 2. Server-Side Enforcement: File size limit
    const origBytes = Buffer.byteLength(source, 'utf8')
    if (origBytes > planConfig.maxFileSizeBytes) {
      throw createError({
        statusCode: 413,
        statusMessage: `File size (${(origBytes / 1024).toFixed(1)} KB) exceeds your ${planConfig.name} plan limit of ${planConfig.maxFileSizeLabel}. Please upgrade to obfuscate larger files.`
      })
    }

    // 3. Server-Side Enforcement: Preset gating
    if (!isPresetAllowed(userPlan, preset)) {
      throw createError({
        statusCode: 403,
        statusMessage: `The preset '${preset}' is locked on your ${planConfig.name} plan. Upgrade to unlock advanced security presets.`
      })
    }

    // 4. Server-Side Enforcement: Quota verification
    if (user) {
      const remainingMonthly = Math.max(0, user.quota_monthly_limit - user.quota_used_this_month)
      const totalRemaining = remainingMonthly + (user.quota_topup_balance || 0)

      if (totalRemaining <= 0) {
        throw createError({
          statusCode: 403,
          statusMessage: 'Monthly quota exhausted. Please upgrade your plan or purchase top-up credits to continue obfuscating.'
        })
      }
    }

    // 5. Execute obfuscation via engine
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
      const { friendlyError, detail } = parseEngineError(result.error || '')
      return {
        ok: false,
        error: friendlyError,
        syntaxError: detail,
        logs: result.logs || []
      }
    }

    const obfBytes = Buffer.byteLength(result.output, 'utf8')
    const ratio = Math.round((obfBytes / (origBytes || 1)) * 10) / 10

    // 6. Deduct Quota and Save History (server-side)
    if (user) {
      const supabase = getSupabaseClient()
      let newUsed = user.quota_used_this_month
      let newTopup = user.quota_topup_balance || 0

      if (newUsed < user.quota_monthly_limit) {
        newUsed += 1
      } else if (newTopup > 0) {
        newTopup -= 1
      }

      // Update quota in database
      if (supabase) {
        try {
          await supabase
            .from('profiles')
            .update({
              quota_used_this_month: newUsed,
              quota_topup_balance: newTopup
            })
            .eq('id', user.id)

          // Save history if plan retention allows
          if (planConfig.historyRetentionDays > 0) {
            const expiresAt = new Date(Date.now() + planConfig.historyRetentionDays * 24 * 3600 * 1000).toISOString()
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
          }
        } catch (e) {
          console.warn('Could not record to Supabase DB, falling back to local memory store')
          user.quota_used_this_month = newUsed
          user.quota_topup_balance = newTopup
        }
      } else {
        // Mock DB store update
        user.quota_used_this_month = newUsed
        user.quota_topup_balance = newTopup

        if (planConfig.historyRetentionDays > 0) {
          const histItem: ObfuscationHistoryRecord = {
            id: `hist_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
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
            created_at: new Date().toISOString()
          }
          mockDb.history.unshift(histItem)
        }
      }
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
        seed: result.seed,
        quotaRemaining: user ? Math.max(0, user.quota_monthly_limit - user.quota_used_this_month) + (user.quota_topup_balance || 0) : null
      },
      logs: result.logs || []
    }
  } catch (err: any) {
    const rawMsg = err?.statusMessage || err?.message || String(err)
    const { friendlyError, detail } = parseEngineError(rawMsg)
    return {
      ok: false,
      error: friendlyError,
      syntaxError: detail,
      logs: []
    }
  }
})
