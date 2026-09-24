import { obfuscate } from '../engine/engine.js'

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
      friendlyError: `Syntax Error pada Baris ${line}, Kolom ${column}: ${remainder}`,
      detail: {
        isSyntaxError: true,
        kind: isLex ? 'lexing' : 'parsing',
        line,
        column,
        message: remainder,
        context,
        friendlyTitle: `Syntax Error (Baris ${line}:${column})`
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

    if (!body || typeof body.source !== 'string' || !body.source.trim()) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Source script cannot be empty.'
      })
    }

    const source = body.source
    const preset = String(body.preset || 'BALANCED').toUpperCase()
    const luaVersion = String(body.luaVersion || 'LuaU')
    const seed = Number(body.seed) || Math.floor(Math.random() * 1000000) + 1
    const prettyPrint = Boolean(body.prettyPrint)
    const includeBanner = body.includeBanner !== false

    const startTime = performance.now()
    const result = await obfuscate(source, {
      preset,
      luaVersion,
      seed,
      prettyPrint,
      includeBanner,
      filename: 'script.lua'
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

    const origBytes = Buffer.byteLength(source, 'utf8')
    const obfBytes = Buffer.byteLength(result.output, 'utf8')
    const ratio = Math.round((obfBytes / (origBytes || 1)) * 10) / 10

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
