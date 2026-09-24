import { requireAuth } from '../../utils/auth'
import { getPlanConfig } from '../../utils/plans'
import { getSupabaseClient, mockDb, type CustomPresetRecord } from '../../utils/supabase'

export default defineEventHandler(async (event) => {
  const user = await requireAuth(event)
  const planConfig = getPlanConfig(user.plan)

  if (planConfig.customPresetsLimit <= 0) {
    throw createError({
      statusCode: 403,
      statusMessage: 'Custom presets are available on the Pro (up to 3) and Ultra (unlimited) plans. Please upgrade to save custom settings.'
    })
  }

  const body = await readBody(event) || {}
  const { name, description = '', basePreset = 'BALANCED', luaVersion = 'LuaU', prettyPrint = false, includeBanner = true, settings = {} } = body

  if (!name || !name.trim()) {
    throw createError({ statusCode: 400, statusMessage: 'Preset name is required.' })
  }

  const supabase = getSupabaseClient()
  if (supabase) {
    // Count existing presets
    const { count, error: countError } = await supabase
      .from('custom_presets')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)

    if (countError) {
      throw createError({ statusCode: 500, statusMessage: countError.message })
    }

    if ((count || 0) >= planConfig.customPresetsLimit) {
      throw createError({
        statusCode: 403,
        statusMessage: `You have reached the maximum of ${planConfig.customPresetsLimit} saved presets for the ${planConfig.name} plan. Upgrade to Ultra for unlimited presets.`
      })
    }

    const { data, error } = await supabase
      .from('custom_presets')
      .insert({
        user_id: user.id,
        name: name.trim(),
        description: description.trim(),
        base_preset: basePreset,
        lua_version: luaVersion,
        pretty_print: prettyPrint,
        include_banner: includeBanner,
        settings
      })
      .select()
      .single()

    if (error) {
      throw createError({ statusCode: 500, statusMessage: error.message })
    }

    return { ok: true, preset: data }
  }

  // Fallback to mock store
  const existingCount = mockDb.presets.filter(p => p.user_id === user.id).length
  if (existingCount >= planConfig.customPresetsLimit) {
    throw createError({
      statusCode: 403,
      statusMessage: `You have reached the maximum of ${planConfig.customPresetsLimit} saved presets for the ${planConfig.name} plan. Upgrade to Ultra for unlimited presets.`
    })
  }

  const newPreset: CustomPresetRecord = {
    id: `preset_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
    user_id: user.id,
    name: name.trim(),
    description: description.trim(),
    base_preset: basePreset,
    lua_version: luaVersion,
    pretty_print: prettyPrint,
    include_banner: includeBanner,
    settings,
    created_at: new Date().toISOString()
  }
  mockDb.presets.unshift(newPreset)

  return { ok: true, preset: newPreset }
})
