-- =============================================================================
-- LUAVION DATABASE SCHEMA (Supabase Postgres)
-- Version: 9.15.0
-- Handles: Users, Roles, Plans, Quotas, History, API Keys, Presets, Audit Logs
-- =============================================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'support', 'admin')),
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'plus', 'pro', 'ultra')),
  plan_billing_cycle TEXT NOT NULL DEFAULT 'monthly' CHECK (plan_billing_cycle IN ('monthly', 'yearly')),
  plan_currency TEXT NOT NULL DEFAULT 'USD' CHECK (plan_currency IN ('USD', 'IDR')),
  plan_expires_at TIMESTAMPTZ,
  quota_used_this_month INT NOT NULL DEFAULT 0,
  quota_monthly_limit INT NOT NULL DEFAULT 50,
  quota_topup_balance INT NOT NULL DEFAULT 0,
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  midtrans_order_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_plan ON public.profiles(plan);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer ON public.profiles(stripe_customer_id);

-- 2. OBFUSCATION HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.obfuscation_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  filename TEXT NOT NULL DEFAULT 'script.lua',
  original_bytes INT NOT NULL DEFAULT 0,
  obfuscated_bytes INT NOT NULL DEFAULT 0,
  expansion_ratio NUMERIC(6, 2) NOT NULL DEFAULT 1.0,
  duration_ms NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
  preset TEXT NOT NULL DEFAULT 'BALANCED',
  lua_version TEXT NOT NULL DEFAULT 'LuaU',
  seed BIGINT NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'failed', 'processing')),
  obfuscated_code TEXT, -- Storage of protected script (cleared based on plan retention days)
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_obf_history_user ON public.obfuscation_history(user_id);
CREATE INDEX IF NOT EXISTS idx_obf_history_created ON public.obfuscation_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_obf_history_expires ON public.obfuscation_history(expires_at);

-- 3. API KEYS TABLE (Ultra Tier Only)
CREATE TABLE IF NOT EXISTS public.api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'Default API Key',
  key_prefix TEXT NOT NULL, -- e.g. "lua_live_7a9f...301a" for masked display
  key_hash TEXT NOT NULL UNIQUE, -- SHA-256 hash of secret key
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  rate_limit_per_minute INT NOT NULL DEFAULT 60,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_api_keys_user ON public.api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON public.api_keys(key_hash);

-- 4. CUSTOM OBFUSCATION PRESETS TABLE (Pro & Ultra)
CREATE TABLE IF NOT EXISTS public.custom_presets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  base_preset TEXT NOT NULL DEFAULT 'BALANCED',
  lua_version TEXT NOT NULL DEFAULT 'LuaU',
  pretty_print BOOLEAN NOT NULL DEFAULT FALSE,
  include_banner BOOLEAN NOT NULL DEFAULT TRUE,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_custom_presets_user ON public.custom_presets(user_id);

-- 5. ADMIN AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.admin_audit_logs(created_at DESC);

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obfuscation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Users can read/update their own profile; Admins have full access
DROP POLICY IF EXISTS "Users view own profile" ON public.profiles;
CREATE POLICY "Users view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
CREATE POLICY "Users update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id OR public.is_admin());

-- Obfuscation History: User can view and delete their own history
DROP POLICY IF EXISTS "Users manage own history" ON public.obfuscation_history;
CREATE POLICY "Users manage own history" ON public.obfuscation_history
  FOR ALL USING (auth.uid() = user_id OR public.is_admin());

-- API Keys: User can manage their own API keys
DROP POLICY IF EXISTS "Users manage own api keys" ON public.api_keys;
CREATE POLICY "Users manage own api keys" ON public.api_keys
  FOR ALL USING (auth.uid() = user_id OR public.is_admin());

-- Custom Presets: User can manage their own custom presets
DROP POLICY IF EXISTS "Users manage own presets" ON public.custom_presets;
CREATE POLICY "Users manage own presets" ON public.custom_presets
  FOR ALL USING (auth.uid() = user_id OR public.is_admin());

-- Audit logs: Admins only
DROP POLICY IF EXISTS "Admins view audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins view audit logs" ON public.admin_audit_logs
  FOR SELECT USING (public.is_admin());

-- 7. TRIGGER: Auto-create profile on Auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, avatar_url, role, plan, quota_monthly_limit)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
    CASE WHEN LOWER(NEW.email) = 'alvinraditya101@gmail.com' THEN 'admin' ELSE 'user' END,
    CASE WHEN LOWER(NEW.email) = 'alvinraditya101@gmail.com' THEN 'ultra' ELSE 'free' END,
    CASE WHEN LOWER(NEW.email) = 'alvinraditya101@gmail.com' THEN 7500 ELSE 50 END
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. BACKFILL: Insert profile for any existing user already created in auth.users
INSERT INTO public.profiles (id, email, display_name, avatar_url, role, plan, quota_monthly_limit)
SELECT
  id,
  email,
  COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(email, '@', 1)),
  COALESCE(raw_user_meta_data->>'avatar_url', raw_user_meta_data->>'picture'),
  CASE WHEN LOWER(email) = 'alvinraditya101@gmail.com' THEN 'admin' ELSE 'user' END,
  CASE WHEN LOWER(email) = 'alvinraditya101@gmail.com' THEN 'ultra' ELSE 'free' END,
  CASE WHEN LOWER(email) = 'alvinraditya101@gmail.com' THEN 7500 ELSE 50 END
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
  role = CASE WHEN LOWER(EXCLUDED.email) = 'alvinraditya101@gmail.com' THEN 'admin' ELSE public.profiles.role END,
  plan = CASE WHEN LOWER(EXCLUDED.email) = 'alvinraditya101@gmail.com' THEN 'ultra' ELSE public.profiles.plan END,
  quota_monthly_limit = CASE WHEN LOWER(EXCLUDED.email) = 'alvinraditya101@gmail.com' THEN 7500 ELSE public.profiles.quota_monthly_limit END;

