# Luavion — Product Requirements Document (PRD)

## 1. Overview

Luavion is a Lua obfuscation product. Today it consists of two pages (a landing page and an obfuscator tool page) with a minimal design and no monetization or account system. This PRD defines a full backend and frontend overhaul to turn Luavion into a serious, sellable SaaS product with tiered pricing, authentication, role management, and a public API for top-tier customers.

**Explicitly out of scope:** the obfuscation engine itself (the core Lua obfuscation logic/algorithms) must NOT be modified, rewritten, or touched. This PRD covers everything around it: product, platform, accounts, billing, API layer, and UI/UX.

**One narrow, explicit exception:** the engine MAY be touched for exactly one purpose — inserting a watermark comment line into every obfuscation output (see Section 6.1 for the exact format). This is the only permitted change to the engine. The AI implementing this should locate the smallest possible insertion point (e.g. where the final obfuscated output string is assembled/returned) and add nothing else — no changes to the obfuscation algorithm, output structure, or performance characteristics beyond adding this one line.

### 1.1 Current & target tech stack

Confirmed from the existing repository:

| Layer | Technology |
|---|---|
| Frontend | Nuxt 3 (Vue 3, Vue Router, Composition API) |
| Backend | Nitro (Nuxt's built-in server engine), running **Wasmoon** (a WebAssembly Luau VM) to execute the obfuscation engine |
| Deployment | Vercel, using native serverless functions (`@vercel/nft`) |
| Database | **None currently** — this overhaul introduces one |
| Design system today | Geist Mono, dark-first Linear/Vercel-style aesthetic |

**Database decision: Supabase.** Use Supabase (Postgres) for all new persistent data introduced by this overhaul: users, roles, plans, subscriptions/billing state, API keys, obfuscation history, quota/usage counters, and any admin/audit data. **Auth decision: Supabase Auth**, using its Google provider, is the confirmed choice for the Google login flow (see Section 5) — do not build a separate custom OAuth implementation.

**Architecture note — serverless execution limits:** because obfuscation runs inside Vercel serverless functions via Nitro, be mindful of function timeout and memory limits, especially for:
- **Batch obfuscation** (Pro: up to 10 files, Ultra: up to 100 files) — a single request obfuscating 100 files sequentially may exceed serverless time limits. Recommend processing batches as multiple smaller function invocations, a queue (e.g. via a Supabase table acting as a simple job queue, or a proper queue service), or client-side orchestration that calls the single-file endpoint repeatedly with progress tracking — pick whichever fits the existing Nitro setup with the least new infrastructure.
- **Large files** (up to 5 MB on Ultra) — verify Wasmoon's obfuscation time for large inputs stays well within the function's timeout; if not, apply the same async/job pattern as batch obfuscation.
- **The API's async job pattern** (Section 8.2) should reuse the same execution strategy as the dashboard's batch obfuscation, rather than building two separate systems.

## 2. Goals

- Turn Luavion into a credible, professional commercial product.
- Introduce a tiered subscription model (Free, Plus, Pro, Ultra) with clear, enforced benefit differences.
- Add authentication (Google login only) and role-based access control.
- Ship a public API, gated to the Ultra plan, with proper documentation.
- Redesign the frontend (landing page + obfuscator page + all new pages) to feel modern, trustworthy, and premium.
- Lay a foundation that can scale: usage limits, abuse prevention, and an admin surface to manage the business.

## 3. Non-goals

- Changing the obfuscation engine's internals, output format, or algorithms.
- Supporting login providers other than Google (for now).
- Team/organization multi-seat accounts (flagged as a possible future phase, not required now).

## 4. Users & Roles

### 4.1 End-user roles
| Role | Description |
|---|---|
| **Guest** | Not logged in. Can view landing page, pricing, docs (read-only), and possibly try a heavily limited/watermarked obfuscation. |
| **Free** | Logged in, default plan after signup. Basic obfuscation, low limits. |
| **Plus** | Paid tier. Higher limits, more obfuscation options. |
| **Pro** | Paid tier. Higher limits still, priority processing, advanced options. |
| **Ultra** | Paid tier. Highest limits, full feature set, **API access included**. |

### 4.2 Internal/admin roles
| Role | Description |
|---|---|
| **Admin** | Full access: manage users, plans, pricing, view analytics, issue refunds/overrides, view system health. |
| **Support** (optional, recommend including) | Can view user accounts and usage/billing status to help with support tickets, cannot change plans/pricing or access billing internals. |

Role management should be handled server-side (never trust client-side role claims). Suggest a simple `role` field on the user record (`user`, `support`, `admin`) plus a separate `plan` field (`free`, `plus`, `pro`, `ultra`) — role and plan are independent concepts (an admin could also have a plan for their own personal use).

## 5. Authentication

- **Login method:** Google OAuth (Sign in with Google) only. No email/password, no other social providers, for this phase. **Confirmed: use Supabase Auth's Google provider** for this — do not build a separate custom OAuth flow.
- On first login, auto-create a user record with `plan = free`, `role = user`.
- Store: Google account ID, email, display name, avatar URL, created_at, last_login_at — in Supabase.
- Session handling: secure, httpOnly cookies with a server-side session or signed JWT, validated in Nitro server middleware on every request, with reasonable expiry and refresh.
- Logout must fully invalidate the session.
- Protect all authenticated routes/pages and all API endpoints with Nitro server middleware; unauthenticated requests to protected routes redirect to login (web) or return 401 (API).

## 6. Pricing Plans & Benefit Matrix

Pricing is decided. Feature differentiation below is a complete recommendation — treat the exact numeric limits as a sensible starting point (tune later based on real server cost per obfuscation), but the structure and gating logic should be implemented as-is.

| Plan | Price |
|---|---|
| Free | $0 |
| Plus | $5/mo (Rp 80,000/mo) |
| Pro | $15/mo (Rp 250,000/mo) |
| Ultra | $30/mo (Rp 500,000/mo) |

| Feature | Free | Plus | Pro | Ultra |
|---|---|---|---|---|
| Obfuscations per month | 50/month | 500/month | 3,000/month | 7,500/month |
| Max file size per obfuscation | 50 KB | 250 KB | 1 MB | 5 MB |
| Batch obfuscation (multiple files at once) | No | No | Up to 10 files/batch | Up to 100 files/batch |
| Obfuscation strength/options | Basic only | Basic + a few advanced options | Most advanced options | All advanced options, incl. any experimental/beta options |
| Custom obfuscation presets (save your own settings) | No | No | Yes (up to 3 saved presets) | Yes (unlimited saved presets) |
| Processing priority | Standard queue | Standard queue | Priority queue | Highest priority queue |
| Obfuscation history/storage | Not saved | 7 days | 30 days | 90 days |
| Output watermark/branding | Yes | Yes | Yes | Yes |
| **API access** | No | No | No | **Yes (only Ultra)** |
| API rate limit | — | — | — | e.g. 60 requests/min, 5,000/day (tune to cost) |
| Webhooks (job-complete notifications) | No | No | No | Yes |
| Quota top-up (pay-as-you-go extra obfuscations) | Available to all plans | Available to all plans | Available to all plans | Available to all plans |
| Support level | Community/self-serve | Email | Priority email | Priority email, fastest SLA |

### 6.1 Watermark (all plans, no exceptions)

Every obfuscation output, regardless of plan (including Ultra), must include this watermark comment line:

```
-- This file was protected using Luavion Obfuscator v[Version] [website link]
```

- `[Version]` = the current obfuscator/engine version string.
- `[website link]` = Luavion's website URL.
- This is a Lua line comment, so it must not affect the obfuscated script's execution.
- This is the one narrow exception to "do not touch the engine" described in Section 1 — the AI should find the minimal point where the final output is assembled and insert this line there, without touching the obfuscation logic itself.
- Since it applies to every plan, this replaces the earlier idea of a Free-only watermark; there is no watermark-removal upsell in this version of the plan.

**Quota top-up pricing:** $0.50 (Rp 5,000) per single extra obfuscation, purchasable by any plan once the monthly quota is used up — this lets occasional heavy users pay only for what they need instead of jumping a full tier.

**Enforcement requirement:** every plan-gated feature (limits, options, API access, batch size, presets) must be enforced server-side on every relevant request — never rely on the frontend to hide a button as the only protection.

**Currency handling:** support both USD and IDR display/checkout if the payment provider allows it, or pick one as the billing currency and display a converted estimate in the other — decide based on the payment provider chosen (see Section 7).

## 7. Billing & Subscriptions

- Integrate a payment/subscription provider (e.g. Stripe, or a regionally appropriate alternative) to handle:
  - Checkout for Plus/Pro/Ultra.
  - Plan upgrades/downgrades.
  - Cancellations and plan expiry (revert to Free at period end).
  - Invoices/receipts accessible to the user.
  - Webhook handling to keep the user's `plan` field in sync with payment status (handle failed payments, retries, and grace periods).
- A billing/account page where the user can see their current plan, renewal date, payment method, and invoice history.

## 8. API (Ultra plan only)

### 8.1 Access control
- API keys are only issuable to users on the Ultra plan.
- If a user downgrades from Ultra, their existing API key(s) should be disabled (not silently left working).
- Users can generate, view (masked), and revoke/regenerate their API key from a dashboard page.

### 8.2 API functionality
- At minimum: an endpoint to submit Lua source for obfuscation and receive the obfuscated result (sync or async — async with a job/result pattern is recommended for larger files).
- Endpoint to check API usage/quota remaining.
- Rate limiting per API key, tuned to the Ultra plan's limits.
- Proper error responses (auth errors, quota exceeded, invalid input, server errors) with clear error codes/messages.

### 8.3 API documentation
- Public docs page (can be visible to everyone, even non-Ultra users, as a sales tool — "see what you get with Ultra").
- Should include: authentication (how to use the API key), endpoint reference, request/response examples, error codes, rate limits, and a quick-start guide.
- Consider auto-generating docs from an OpenAPI/Swagger spec if the stack supports it, for maintainability.

## 9. Pages / Information Architecture

### 9.1 Public pages
- **Landing page** — hero, value proposition, key features, how it works, pricing preview, social proof (if available), CTA to sign up.
- **Pricing page** — full plan comparison table (the benefit matrix above, rendered nicely), FAQ about billing.
- **API docs page** — as described in 8.3.
- **Login page** — Google sign-in.
- **Legal pages** — Terms of Service, Privacy Policy (recommended given this handles user-submitted code and payments).

### 9.2 Authenticated pages
- **Obfuscator page** (existing, redesigned) — where users submit Lua code and get obfuscated output. UI should reflect plan-based limits/options (e.g. locked advanced options for lower tiers, with an upsell prompt).
- **Dashboard/overview** — usage this period, quick access to obfuscator, plan status.
- **Obfuscation history** — list of past obfuscations (where plan allows), with re-download.
- **Account/billing page** — plan details, upgrade/downgrade, payment method, invoices.
- **API keys page** (Ultra only, or visible-but-locked for others as an upsell) — key management as described in 8.1.
- **Settings page** — basic profile info, connected Google account, logout, delete account.

### 9.3 Admin pages (role = admin)
- **User management** — search/view users, see their plan/role, manually adjust plan or role, view usage.
- **Analytics overview** — signups, active users, plan distribution, revenue (if feasible to pull from billing provider), API usage.
- **System/health** (optional) — job queue status, error rates, if useful given the obfuscation processing model.

## 10. Non-functional Requirements

- **Security:** user-submitted Lua code may be sensitive/proprietary — do not log or expose raw submitted code beyond what's needed for processing and (plan-gated) history. Secure API key storage (hashed, not stored in plaintext). Standard web security practices (CSRF protection, input validation, rate limiting, dependency hygiene).
- **Privacy:** clear policy on how long submitted code/history is retained per plan, and a way for users to delete their data/account.
- **Performance:** obfuscation requests should not block the UI; use a queue/async pattern if processing can be slow, with progress feedback.
- **Scalability:** design the plan/quota/API-key system so it can handle growth without a rearchitecture (e.g. don't hardcode limits — store them as configurable values, ideally editable by admins without a code deploy).
- **Observability:** basic logging/metrics for errors, job failures, and abuse patterns (e.g. repeated quota-exceeded attempts).

## 11. Design & Frontend Requirements

Full redesign of the landing page and obfuscator page, plus design of every new page listed in Section 9, as one consistent product — not visually disjointed pieces bolted on. This should feel like a serious, professional, sellable product, not a free tool with a paywall bolted on top.

### 11.1 Visual direction
- **Theme:** dark, elegant, simple, clean, modern. Calm and premium, in the spirit of Vercel / Linear / Raycast / Stripe, but with its own identity for Luavion.
- "Simple" means uncluttered and easy to understand, NOT plain or empty — the product should feel rich in craft: refined details, depth, and life, especially since it now has to justify a paid subscription.
- Avoid generic AI-template looks: no random rainbow gradients, no clutter, no identical boxes repeated everywhere.
- Every screen needs a clear focal point, strong visual hierarchy, and intentional whitespace and rhythm.
- Signature details that give Luavion character (pick 1-2, apply consistently): a refined grid/line/code motif fitting an obfuscation/security product, glowing focus rings, a distinctive nav/header treatment, animated status/progress indicators during obfuscation.

### 11.2 Typography
- Use **Geist Mono** as the primary font across the whole UI (https://vercel.com/font?type=mono) — it fits a developer-facing product especially well. Fallback stack: `'Geist Mono', ui-monospace, SFMono-Regular, Menlo, monospace`.
- Build hierarchy through size, weight, case, letter-spacing, and color rather than mixing fonts. Define a clear type scale. Load with `font-display: swap` and no layout shift.

### 11.3 Motion and animation
- The site should feel alive and smooth: page/route transitions, staggered fade/slide-in on load and scroll, smooth hover/press feedback, animated menus/modals/dropdowns/toasts.
- Specifically for the obfuscator page: an engaging processing/progress animation while a file is being obfuscated (this is the core moment of the product — make it feel fast and trustworthy, not just a spinner).
- Timing: 150-300ms for micro-interactions, up to ~600ms for entrances, natural easing. Nothing slow, bouncy, or distracting. Respect `prefers-reduced-motion`.

### 11.4 Pricing & upsell presentation
- The pricing table must clearly communicate the value gap between tiers, especially the API-access-only-on-Ultra differentiator and the monthly-quota differences (a common upsell hook).
- Locked/gated features (e.g. advanced obfuscation options, batch upload, presets, API keys page) should be visible-but-locked with a clear upgrade prompt, rather than hidden — standard SaaS practice, drives upgrades.
- Quota usage should be visible at a glance in the dashboard (e.g. "320 / 3,000 obfuscations used this month") with a clear top-up or upgrade prompt as it nears the limit.

### 11.5 Trust & credibility
- Because this product now handles payments, accounts, and user-submitted code, the design should actively build trust: clear security/privacy messaging, visible legal pages, a professional footer, and no rough edges anywhere in the checkout or account flows.

### 11.6 Responsiveness
- Mobile-first, designed as its own layout (not just a shrunk desktop): thumb-friendly navigation, touch targets ≥44px, single-column flow, no horizontal scroll.
- Desktop uses space intentionally (sidebar, multi-column, max-width containers) without feeling empty or stretched.
- Verify at 360px, 768px, 1024px, and 1440px.

*(This section can be handed to an AI on its own as the visual/frontend brief; Sections 1-10 and 13 give it the product/feature scope it needs to design against.)*

## 12. Suggested Additional Features (recommendations, not required)

- **Usage dashboard/analytics for the user** — simple charts of their obfuscation usage over time; helps justify upgrading.
- **Email notifications** — payment receipts, plan expiring soon, quota nearing limit, API key created/revoked.
- **Referral program** — e.g. Free users get bonus quota for each referral who signs up; a light, cheap growth lever.
- **Audit trail for admins** — log of admin actions (plan overrides, refunds) for accountability.
- **Rate-limit/abuse protection** — especially important for a Free tier and for the public obfuscator to prevent scripted abuse.
- **Status page** — simple uptime/incident page, builds trust for a paid product.
- **Changelog/roadmap page** — signals active development to prospective customers.
- **Batch/bulk obfuscation** — already included in the plan matrix; upload a whole folder/zip of Lua files at once, a strong Pro/Ultra selling point for real projects.
- **Webhooks** — already included for Ultra; notifies the user's system when an async obfuscation job finishes, useful for anyone wiring Luavion into their own build process via the API.
- **Quota top-ups** — already included (Section 6): $0.50/Rp 5,000 per extra obfuscation, available to every plan once the monthly quota runs out. Useful for occasional heavy users who don't want a full tier upgrade.
- **Annual billing discount** — e.g. 2 months free on yearly plans, improves cash flow and retention.
- **Discord/community server** (optional, not required for launch) — a place for support, announcements, and feedback that feels more personal and immediate than email. Plan-based Discord roles (e.g. an "Ultra" role) can add a sense of status for paying users and double as a lightweight feedback channel. Skip for now if you don't have bandwidth to moderate/maintain it, and add later once there's a user base.
- **Quota top-up / add-on packs** — let a Free or Plus user buy a one-time extra batch of obfuscations without upgrading the whole plan; useful for occasional heavy users.
- **Public changelog of obfuscation engine updates** (without exposing internals) — reassures paying customers the product is actively maintained, without touching the engine itself.
- **Two-factor confirmation for destructive account actions** (e.g. API key regeneration, account deletion) — small trust/security signal for a paid product.

Not recommended for this phase: team/multi-seat workspaces, gamification/leaderboards, additional login providers, a CLI tool, and free trials — these add complexity or support burden without being essential to launching a credible paid product; revisit later if there's demand.

## 13. Complete Feature List (Every Feature On The Site)

A single exhaustive list of everything the website should have, grouped by area, so nothing gets missed during the rebuild.

### 13.1 Marketing / public site
- Landing page: hero, value proposition, feature highlights, "how it works", pricing preview, CTA to sign up.
- Pricing page: full plan comparison table, quota top-up pricing, FAQ.
- API docs page (public, doubles as an Ultra sales page).
- Legal pages: Terms of Service, Privacy Policy.
- Changelog/updates page (engine updates + product updates, without exposing engine internals).
- Status page (uptime/incidents).
- (Optional) Discord/community link in the footer/nav.

### 13.2 Authentication & account
- Google OAuth login/signup.
- Logout.
- Account deletion (with confirmation).
- Two-factor confirmation step for sensitive actions (API key regeneration, account deletion, cancelling a subscription).
- Settings page: profile info (name, avatar, email — from Google), connected account info.

### 13.3 Core product — obfuscator
- Obfuscator page: submit Lua source (paste or upload), choose options, run obfuscation, download/copy result.
- Plan-based option gating (basic vs. advanced vs. all options), shown as visible-but-locked for lower tiers.
- Batch obfuscation (Pro: up to 10 files, Ultra: up to 100 files).
- Custom presets: save/name/reuse obfuscation option sets (Pro: up to 3, Ultra: unlimited).
- Obfuscation history list (retention per plan: Free none, Plus 7 days, Pro 30 days, Ultra 90 days), with re-download of past results.
- Watermark comment line on every obfuscation output, on all plans including Ultra (see Section 6.1 for exact format).
- Progress/status feedback while an obfuscation job runs (especially for larger/batch jobs).

### 13.4 Dashboard & usage
- Dashboard/overview page: current plan, quota used vs. limit this month, quick link to obfuscator.
- Usage analytics: simple chart/breakdown of obfuscations over time.
- Quota top-up purchase flow ($0.50/Rp 5,000 per extra obfuscation).

### 13.5 Billing & subscriptions
- Checkout flow for Plus/Pro/Ultra.
- Upgrade/downgrade plan.
- Cancel subscription (reverts to Free at period end).
- Payment method management.
- Invoice/receipt history.
- Webhook-driven plan sync with the payment provider (handles failed payments, retries, grace periods).

### 13.6 API & developer tools (Ultra only, docs public)
- API key generation, masked display, revoke/regenerate.
- Automatic API key disable on downgrade from Ultra.
- Obfuscation endpoint (submit code, get result — async/job pattern recommended for larger files).
- Usage/quota-check endpoint.
- Webhook support for job-complete notifications.
- Per-key rate limiting.
- Full API documentation (auth, endpoints, examples, errors, rate limits, quick start).

### 13.7 Admin panel (role = admin)
- User management: search/view users, see plan/role, manually override plan or role, view a user's usage.
- Analytics overview: signups, active users, plan distribution, revenue (if available via payment provider), API usage.
- Audit log of admin actions (plan overrides, refunds, role changes).
- (Optional) System/health view: job queue status, error rates.

### 13.8 Cross-cutting / behind the scenes
- Server-side enforcement of every plan limit and gated feature (never trust the frontend alone).
- Rate limiting and abuse protection, especially on the Free tier and public-facing obfuscation endpoint.
- Email notifications: payment receipts, plan expiring soon, quota nearing limit, API key created/revoked.
- Data retention and deletion policy for submitted code, enforced automatically per plan.
- (Optional, future) Referral program for bonus Free-tier quota.
- (Optional, future) Discord community with plan-based roles.

## 14. Open Questions (fill in before implementation)

- Whether the numeric limits in Section 6 (obfuscations/month, file sizes, batch sizes, API rate limits) should be adjusted once real server cost per obfuscation is known.
- Which payment provider to use, and whether to bill in USD, IDR, or both (see "Currency handling" in Section 6).
- Whether a "Support" internal role is needed now or can wait.
- Data retention policy specifics for submitted code.
- Which of the Section 12 suggestions to include in this phase vs. a later phase (recommend at minimum: presets, batch obfuscation, and webhooks for Ultra, since they directly support the pricing differentiation).
- Exact approach for batch/large-file processing under Vercel serverless limits (see the architecture note in Section 1.1) — simple sequential calls, a Supabase-backed job queue, or a dedicated queue service.

## 15. How to use this document

Hand this PRD to the AI/engineer doing the rebuild along with:
1. Access to (or a description of) the current codebase, so it knows what to keep vs. rebuild.
2. Answers to the Open Questions in Section 14, or explicit permission for the AI to propose sensible defaults and note its assumptions.

Instruct the AI to treat Section 1's "do not touch the obfuscation engine" constraint as a hard boundary, with the single narrow exception of the watermark insertion described in Section 1 and Section 6.1. The AI should explicitly flag which existing files/modules it identifies as "the engine" and exactly where it plans to insert the watermark line before making changes, so you can confirm before it starts.
