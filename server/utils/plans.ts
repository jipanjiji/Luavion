export type PlanTier = 'free' | 'plus' | 'pro' | 'ultra'
export type UserRole = 'user' | 'support' | 'admin'
export type CurrencyCode = 'USD' | 'IDR'

export interface PlanConfig {
  id: PlanTier
  name: string
  badge?: string
  priceUsd: number
  priceIdr: number
  billingPeriod: 'month'
  quotaMonthly: number
  maxFileSizeBytes: number
  maxFileSizeLabel: string
  maxBatchFiles: number
  allowedPresets: string[]
  customPresetsLimit: number
  historyRetentionDays: number
  hasApiAccess: boolean
  apiRateLimitPerMin: number
  hasWebhooks: boolean
  priority: 'standard' | 'priority' | 'highest'
  supportLevel: string
  features: string[]
}

export const TOP_UP_PRICING = {
  unitPriceUsd: 0.50,
  unitPriceIdr: 5000,
  packs: [
    { count: 10, priceUsd: 5.00, priceIdr: 50000, popular: false },
    { count: 50, priceUsd: 25.00, priceIdr: 250000, popular: true, discountLabel: 'Most Popular' },
    { count: 100, priceUsd: 45.00, priceIdr: 450000, popular: false, discountLabel: '10% OFF' },
    { count: 500, priceUsd: 200.00, priceIdr: 2000000, popular: false, discountLabel: '20% OFF' }
  ]
}

export const PLANS: Record<PlanTier, PlanConfig> = {
  free: {
    id: 'free',
    name: 'Free',
    priceUsd: 0,
    priceIdr: 0,
    billingPeriod: 'month',
    quotaMonthly: 50,
    maxFileSizeBytes: 50 * 1024, // 50 KB
    maxFileSizeLabel: '50 KB',
    maxBatchFiles: 1, // Single file only
    allowedPresets: ['BALANCED', 'PERFORMANCE', 'COMPATIBLE', 'MINIFY'],
    customPresetsLimit: 0,
    historyRetentionDays: 0,
    hasApiAccess: false,
    apiRateLimitPerMin: 0,
    hasWebhooks: false,
    priority: 'standard',
    supportLevel: 'Community & Self-Serve',
    features: [
      '50 obfuscations / month',
      'Up to 50 KB per file',
      'Single file obfuscation',
      'Basic security presets',
      'Steganographic AI Prompt Shield',
      'Standard processing queue',
      'Community Discord support'
    ]
  },
  plus: {
    id: 'plus',
    name: 'Plus',
    badge: 'Popular for Hobbyists',
    priceUsd: 5,
    priceIdr: 80000,
    billingPeriod: 'month',
    quotaMonthly: 500,
    maxFileSizeBytes: 250 * 1024, // 250 KB
    maxFileSizeLabel: '250 KB',
    maxBatchFiles: 1,
    allowedPresets: ['BALANCED', 'HARD', 'PERFORMANCE', 'COMPATIBLE', 'MINIFY'],
    customPresetsLimit: 0,
    historyRetentionDays: 7,
    hasApiAccess: false,
    apiRateLimitPerMin: 0,
    hasWebhooks: false,
    priority: 'standard',
    supportLevel: 'Standard Email Support',
    features: [
      '500 obfuscations / month',
      'Up to 250 KB per file',
      'Access to Hard Anti-Tamper preset',
      '7 days cloud obfuscation history',
      'Re-download past obfuscations',
      'Standard processing queue',
      'Email customer support'
    ]
  },
  pro: {
    id: 'pro',
    name: 'Pro',
    badge: 'Most Popular',
    priceUsd: 15,
    priceIdr: 250000,
    billingPeriod: 'month',
    quotaMonthly: 3000,
    maxFileSizeBytes: 1024 * 1024, // 1 MB
    maxFileSizeLabel: '1 MB',
    maxBatchFiles: 10, // Up to 10 files
    allowedPresets: ['BALANCED', 'HARD', 'EXTREME', 'PERFORMANCE', 'COMPATIBLE', 'MINIFY'],
    customPresetsLimit: 3,
    historyRetentionDays: 30,
    hasApiAccess: false,
    apiRateLimitPerMin: 0,
    hasWebhooks: false,
    priority: 'priority',
    supportLevel: 'Priority Email Support',
    features: [
      '3,000 obfuscations / month',
      'Up to 1 MB per file',
      'Batch obfuscation (up to 10 files)',
      'Extreme Galois Virtualization preset',
      'Save up to 3 custom presets',
      '30 days cloud obfuscation history',
      'Priority processing queue',
      'Priority email support'
    ]
  },
  ultra: {
    id: 'ultra',
    name: 'Ultra',
    badge: 'Enterprise & Teams',
    priceUsd: 30,
    priceIdr: 500000,
    billingPeriod: 'month',
    quotaMonthly: 7500,
    maxFileSizeBytes: 5 * 1024 * 1024, // 5 MB
    maxFileSizeLabel: '5 MB',
    maxBatchFiles: 100, // Up to 100 files
    allowedPresets: ['BALANCED', 'HARD', 'EXTREME', 'PERFORMANCE', 'COMPATIBLE', 'MINIFY'],
    customPresetsLimit: 999999, // Unlimited
    historyRetentionDays: 90,
    hasApiAccess: true, // Only Ultra
    apiRateLimitPerMin: 60,
    hasWebhooks: true,
    priority: 'highest',
    supportLevel: 'Dedicated SLA Priority Support',
    features: [
      '7,500 obfuscations / month',
      'Up to 5 MB per file',
      'Batch obfuscation (up to 100 files)',
      'Full Public REST API Access',
      'API rate limit: 60 req/min (5k/day)',
      'Webhook completion events',
      'Unlimited saved presets',
      '90 days cloud obfuscation history',
      'Highest priority processing queue',
      'Fastest SLA support channel'
    ]
  }
}

export function getPlanConfig(plan: string = 'free'): PlanConfig {
  const normalized = (plan || 'free').toLowerCase() as PlanTier
  return PLANS[normalized] || PLANS.free
}

export function isPresetAllowed(plan: string, presetId: string): boolean {
  const config = getPlanConfig(plan)
  return config.allowedPresets.includes(presetId.toUpperCase())
}

export function canAccessApi(plan: string): boolean {
  const config = getPlanConfig(plan)
  return config.hasApiAccess
}
