import { createClient } from '@supabase/supabase-js'
import crypto from 'crypto'
import { getPlanConfig, type PlanTier, type UserRole } from './plans'

export interface ProfileRecord {
  id: string
  email: string
  display_name: string
  avatar_url: string
  role: UserRole
  plan: PlanTier
  plan_billing_cycle: 'monthly' | 'yearly'
  plan_currency: 'USD' | 'IDR'
  plan_expires_at: string | null
  quota_used_this_month: number
  quota_monthly_limit: number
  quota_topup_balance: number
  stripe_customer_id?: string
  stripe_subscription_id?: string
  midtrans_order_id?: string
  created_at: string
  last_login_at: string
}

export interface ObfuscationHistoryRecord {
  id: string
  user_id: string
  filename: string
  original_bytes: number
  obfuscated_bytes: number
  expansion_ratio: number
  duration_ms: number
  preset: string
  lua_version: string
  seed: number
  status: 'completed' | 'failed'
  obfuscated_code?: string
  created_at: string
  expires_at?: string
}

export interface ApiKeyRecord {
  id: string
  user_id: string
  name: string
  key_prefix: string
  key_hash: string
  is_active: boolean
  rate_limit_per_minute: number
  last_used_at: string | null
  created_at: string
}

export interface CustomPresetRecord {
  id: string
  user_id: string
  name: string
  description?: string
  base_preset: string
  lua_version: string
  pretty_print: boolean
  include_banner: boolean
  settings: Record<string, any>
  created_at: string
}

export interface AdminAuditRecord {
  id: string
  admin_id: string
  admin_email: string
  action: string
  target_user_id?: string
  details: Record<string, any>
  created_at: string
}

// In-Memory Dev Store for fallback when Supabase keys are not in .env
class MockDatabaseStore {
  profiles: Map<string, ProfileRecord> = new Map()
  history: ObfuscationHistoryRecord[] = []
  apiKeys: ApiKeyRecord[] = []
  presets: CustomPresetRecord[] = []
  auditLogs: AdminAuditRecord[] = []

  constructor() {
    this.seedDefaultUsers()
  }

  private seedDefaultUsers() {
    const defaultUser: ProfileRecord = {
      id: 'usr_mock_demo_01',
      email: 'developer@luavion.io',
      display_name: 'Alvin (Dev)',
      avatar_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      role: 'admin',
      plan: 'pro',
      plan_billing_cycle: 'monthly',
      plan_currency: 'USD',
      plan_expires_at: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString(),
      quota_used_this_month: 24,
      quota_monthly_limit: 3000,
      quota_topup_balance: 50,
      created_at: new Date(Date.now() - 60 * 24 * 3600 * 1000).toISOString(),
      last_login_at: new Date().toISOString()
    }
    this.profiles.set(defaultUser.id, defaultUser)

    // Seed sample history
    this.history.push({
      id: 'hist_demo_01',
      user_id: defaultUser.id,
      filename: 'MainCombatEngine.lua',
      original_bytes: 14200,
      obfuscated_bytes: 86400,
      expansion_ratio: 6.1,
      duration_ms: 124.5,
      preset: 'BALANCED',
      lua_version: 'LuaU',
      seed: 849201,
      status: 'completed',
      obfuscated_code: '-- This file was protected using Luavion Obfuscator v9.15.0 https://luavion.com\nprint("Demo Protected Output")',
      created_at: new Date(Date.now() - 2 * 3600 * 1000).toISOString()
    })

    // Seed demo API key for Pro/Ultra testing
    const demoKeyRaw = 'lua_live_7a9f82d1c04e28bf901234'
    const demoKeyHash = crypto.createHash('sha256').update(demoKeyRaw).digest('hex')
    this.apiKeys.push({
      id: 'key_demo_01',
      user_id: defaultUser.id,
      name: 'CI/CD Build Pipeline',
      key_prefix: 'lua_live_7a9f...1234',
      key_hash: demoKeyHash,
      is_active: true,
      rate_limit_per_minute: 60,
      last_used_at: new Date(Date.now() - 3600 * 1000).toISOString(),
      created_at: new Date(Date.now() - 14 * 24 * 3600 * 1000).toISOString()
    })

    // Seed demo custom preset
    this.presets.push({
      id: 'preset_demo_01',
      user_id: defaultUser.id,
      name: 'Roblox Hardened Flight',
      description: 'Maximum Galois scattering with pretty print off and LuaU runtime targeting',
      base_preset: 'HARD',
      lua_version: 'LuaU',
      pretty_print: false,
      include_banner: true,
      settings: {
        antiProxy: true,
        galoisScatter: true,
        mathAttestation: 'STRICT'
      },
      created_at: new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString()
    })
  }

  getProfile(id: string): ProfileRecord | undefined {
    return this.profiles.get(id)
  }

  getProfileByEmail(email: string): ProfileRecord | undefined {
    for (const p of this.profiles.values()) {
      if (p.email.toLowerCase() === email.toLowerCase()) return p
    }
    return undefined
  }

  upsertProfile(profile: Partial<ProfileRecord> & { id: string; email: string }): ProfileRecord {
    const existing = this.profiles.get(profile.id)
    const planConfig = getPlanConfig(profile.plan || existing?.plan || 'free')
    const updated: ProfileRecord = {
      id: profile.id,
      email: profile.email,
      display_name: profile.display_name || existing?.display_name || profile.email.split('@')[0],
      avatar_url: profile.avatar_url || existing?.avatar_url || '',
      role: profile.role || existing?.role || 'user',
      plan: profile.plan || existing?.plan || 'free',
      plan_billing_cycle: profile.plan_billing_cycle || existing?.plan_billing_cycle || 'monthly',
      plan_currency: profile.plan_currency || existing?.plan_currency || 'USD',
      plan_expires_at: profile.plan_expires_at !== undefined ? profile.plan_expires_at : (existing?.plan_expires_at || null),
      quota_used_this_month: profile.quota_used_this_month !== undefined ? profile.quota_used_this_month : (existing?.quota_used_this_month || 0),
      quota_monthly_limit: planConfig.quotaMonthly,
      quota_topup_balance: profile.quota_topup_balance !== undefined ? profile.quota_topup_balance : (existing?.quota_topup_balance || 0),
      stripe_customer_id: profile.stripe_customer_id || existing?.stripe_customer_id,
      stripe_subscription_id: profile.stripe_subscription_id || existing?.stripe_subscription_id,
      midtrans_order_id: profile.midtrans_order_id || existing?.midtrans_order_id,
      created_at: existing?.created_at || new Date().toISOString(),
      last_login_at: new Date().toISOString()
    }
    this.profiles.set(updated.id, updated)
    return updated
  }
}

export const mockDb = new MockDatabaseStore()

export function getSupabaseClient() {
  const supabaseUrl = process.env.SUPABASE_URL
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY

  if (supabaseUrl && supabaseKey) {
    return createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false }
    })
  }
  return null
}
