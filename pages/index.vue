<template>
  <div class="landing-page">
    <div class="hero-ambient" aria-hidden="true"></div>

    <!-- HERO -->
    <section class="hero-section">
      <div class="container">
        <div class="hero-inner">
          <h1 class="hero-title anim-fade-up" style="animation-delay: 80ms">
            Next-generation Luau<br class="desktop-br" />
            bytecode virtualization.
          </h1>

          <p class="hero-subtitle anim-fade-up" style="animation-delay: 160ms">
            Commercial-grade script protection with decentralized register micro-ops,
            cryptographic attestation, and zero frame-drop impact. Defeat AST dumpers
            and neural reverse-engineering.
          </p>

          <div class="hero-cta-group anim-fade-up" style="animation-delay: 240ms">
            <NuxtLink to="/dashboard" class="btn btn-primary btn-lg">
              Open Dashboard
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
              </svg>
            </NuxtLink>
            <NuxtLink to="/pricing" class="btn btn-secondary btn-lg">View pricing</NuxtLink>
          </div>

          <div class="hero-metrics mono anim-fade-up" style="animation-delay: 320ms">
            <div class="hm-item"><strong>60+ FPS</strong><span>zero GC stutter</span></div>
            <div class="hm-item"><strong>Vector3</strong><span>engine attestation</span></div>
            <div class="hm-item"><strong>zero-width</strong><span>AI prompt shield</span></div>
            <div class="hm-item"><strong>100%</strong><span>GUI framework match</span></div>
          </div>
        </div>
      </div>

      <!-- Live transformation demo â€” hero focal point -->
      <div class="container hero-demo anim-fade-up" style="animation-delay: 400ms">
        <InteractiveCodeSlider />
        <p class="demo-hint mono">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <polyline points="15 18 9 12 15 6"></polyline>
            <polyline points="21 18 15 12 21 6"></polyline>
          </svg>
          Drag the handle â€” source AST on the left, protected VM bytecode on the right
        </p>
      </div>
    </section>

    <!-- PILLARS -->
    <section id="features" class="section">
      <div class="container">
        <div class="section-head reveal">
          <span class="t-label">[ architecture ]</span>
          <h2 class="t-h2">Core defensive pillars</h2>
          <p class="t-body section-sub">
            Standard obfuscators rely on shallow variable mangling. Luavion replaces
            the execution model entirely.
          </p>
        </div>

        <div class="pillars-rows">
          <div class="pillar-row reveal">
            <span class="pillar-index mono">01</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Decentralized Register VM</h3>
                <span class="badge badge-cyan">Dynamic ISA</span>
              </div>
              <p>Source expressions compile into dynamic micro-ops with Galois polynomial bucket hashing â€” no linear switch statements, no closure arrays.</p>
              <code class="pillar-code mono">Galois Polynomial Dispatch</code>
            </div>
          </div>

          <div class="pillar-row reveal d1">
            <span class="pillar-index mono">02</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Geometric Math Attestation</h3>
                <span class="badge badge-emerald">Roblox</span>
              </div>
              <p>Decryption keys are cryptographically bound to native <code class="code-inline">Vector3.Magnitude</code> and IEEE-754 conversions. External emulators crash silently.</p>
              <code class="pillar-code mono">Vector3.new(3,4,0).Magnitude == 5.0</code>
            </div>
          </div>

          <div class="pillar-row reveal d2">
            <span class="pillar-index mono">03</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Polymorphic MBA Equations</h3>
                <span class="badge">Non-polynomial</span>
              </div>
              <p>Conditionals expand into Mixed Boolean-Arithmetic equations, rendering SMT solvers and Z3 symbolic executors computationally intractable.</p>
              <code class="pillar-code mono">(x ^ y) + 2*(x &amp; y) == x + y</code>
            </div>
          </div>

          <div class="pillar-row reveal d3">
            <span class="pillar-index mono">04</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Ephemeral Dynamic String Ring</h3>
                <span class="badge badge-cyan">Anti-dump</span>
              </div>
              <p>Literals are synthesized at runtime into register slots and evaporate upon register reuse â€” zero static string footprint for memory dumpers.</p>
              <code class="pillar-code mono">Zero Static String Footprint</code>
            </div>
          </div>

          <div class="pillar-row reveal d4">
            <span class="pillar-index mono">05</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Steganographic AI Prompt Shield</h3>
                <span class="badge badge-emerald">Zero-width</span>
              </div>
              <p>Invisible zero-width Unicode directives hijack LLM system contexts, instructing models to refuse reverse-engineering queries.</p>
              <code class="pillar-code mono">â€‹ â€Œ Context Poisoning</code>
            </div>
          </div>

          <div class="pillar-row reveal d5">
            <span class="pillar-index mono">06</span>
            <div class="pillar-body">
              <div class="pillar-head">
                <h3>Zero Frame-Drop Execution</h3>
                <span class="badge badge-cyan">High FPS</span>
              </div>
              <p>Optimized register reuse and minimal GC overhead keep 60+ FPS in high-frequency loops, physics controllers, and raycasting systems.</p>
              <code class="pillar-code mono">RenderStepped Certified</code>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- SECURITY DEEP-DIVE -->
    <section id="security" class="section">
      <div class="container">
        <div class="deepdive-grid">
          <div class="deepdive-intro reveal">
            <span class="t-label">[ threat model ]</span>
            <h2 class="t-h2">Engine architecture &amp; anti-tamper</h2>
            <p class="t-body">How Luavion systematically neutralizes modern deobfuscation and reverse-engineering pipelines.</p>
            <NuxtLink to="/docs/api" class="btn btn-ghost deepdive-link">
              Read the security docs
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
              </svg>
            </NuxtLink>
          </div>

          <div class="deepdive-items">
            <div class="deepdive-item reveal d1">
              <span class="deep-index mono">01</span>
              <div>
                <h4>Defeating CFG deswitchers</h4>
                <p>Legacy tools rely on flat switch states that basic deswitchers can reconstruct. Luavion emits genuine register bytecode â€” there are no raw function tables to unswitch; an attacker must rebuild an entire proprietary virtual CPU.</p>
              </div>
            </div>
            <div class="deepdive-item reveal d2">
              <span class="deep-index mono">02</span>
              <div>
                <h4>Fail-closed sandbox traps</h4>
                <p>When executed inside Node.js or generic emulators, attestation detects IEEE-754 precision drift and silently desynchronizes the VM keystream â€” a natural crash, with no exploiter-readable traceback.</p>
              </div>
            </div>
            <div class="deepdive-item reveal d3">
              <span class="deep-index mono">03</span>
              <div>
                <h4>Neural context poisoning</h4>
                <p>Protected scripts embed invisible directives inside headers and strings. When pasted into AI coding agents, model guardrails trigger and analysis halts before it begins.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- COMPARISON MATRIX -->
    <section id="compare" class="section">
      <div class="container">
        <div class="section-head reveal">
          <span class="t-label">[ benchmark ]</span>
          <h2 class="t-h2">Luavion vs the public market</h2>
          <p class="t-body section-sub">An objective technical comparison with existing Lua obfuscation technologies.</p>
        </div>

        <div class="matrix-wrap reveal d1">
          <table class="matrix-table">
            <thead>
              <tr>
                <th class="col-metric" scope="col">Security feature</th>
                <th class="col-luavion" scope="col">
                  <span class="brand-mark">LUAVION</span>
                  <span class="badge badge-cyan">v9.15</span>
                </th>
                <th scope="col">Prometheus</th>
                <th scope="col">Moonsec</th>
                <th scope="col">Luraph</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td class="metric-name"><strong>Steganographic AI prompt shields</strong><span>Zero-width anti-LLM directives</span></td>
                <td class="val-luavion"><span class="badge badge-cyan">Native shielded</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-no">None</span></td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Underlying architecture</strong><span>Internal VM design model</span></td>
                <td class="val-luavion">Decentralized Register VM</td>
                <td>Macro AST Transform</td>
                <td>Lua 5.1 Stack VM</td>
                <td>Proprietary VM</td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Roblox geometric attestation</strong><span>Vector3 &amp; float bitcast bindings</span></td>
                <td class="val-luavion"><span class="badge badge-emerald">Native verified</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-no">None</span></td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Control-flow deflattening resistance</strong><span>Against AST deswitchers</span></td>
                <td class="val-luavion"><span class="badge badge-cyan">Immune (pure VM)</span></td>
                <td><span class="tag-mid">Moderate</span></td>
                <td><span class="tag-no">Vulnerable</span></td>
                <td><span class="badge badge-emerald">Strong</span></td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Runtime GC impact</strong><span>FPS drop probability</span></td>
                <td class="val-luavion"><span class="badge badge-emerald">Near zero (&lt;1%)</span></td>
                <td><span class="tag-mid">High overhead</span></td>
                <td><span class="tag-mid">Medium overhead</span></td>
                <td><span class="badge badge-emerald">Low overhead</span></td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Fail-closed sandbox detection</strong><span>Node.js / Wasmoon snooping</span></td>
                <td class="val-luavion"><span class="badge badge-cyan">Cryptographic fail</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-no">None</span></td>
                <td><span class="tag-mid">Generic checks</span></td>
              </tr>
              <tr>
                <td class="metric-name"><strong>Modern GUI framework support</strong><span>Fluent, Rayfield, Maclib, Linoria</span></td>
                <td class="val-luavion"><span class="badge badge-emerald">100% compatible</span></td>
                <td><span class="tag-mid">Frequent breaks</span></td>
                <td><span class="tag-no">Broken closures</span></td>
                <td><span class="badge badge-emerald">Compatible</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- API SHOWCASE -->
    <section id="api" class="section">
      <div class="container">
        <div class="api-split">
          <div class="api-copy reveal">
            <span class="badge">Ultra tier</span>
            <h2 class="t-h2" style="margin: 14px 0 10px">Automate virtualization in CI/CD</h2>
            <p class="t-body">
              Wire Luavion into GitHub Actions, GitLab CI, or automated Roblox release
              pipelines. Bearer API keys with 60 req/min dedicated throughput.
            </p>
            <div class="api-actions">
              <NuxtLink to="/docs/api" class="btn btn-primary btn-sm">Explore REST API docs</NuxtLink>
              <NuxtLink to="/pricing" class="btn btn-ghost btn-sm">Ultra pricing</NuxtLink>
            </div>
          </div>

          <div class="terminal-frame api-terminal reveal d2">
            <div class="tf-header">
              <div class="tf-dots"><span></span><span></span><span></span></div>
              <span>obfuscate.sh</span>
              <span class="status-dot dot-emerald" style="margin-left: auto"></span>
            </div>
            <pre class="api-pre mono">curl -X POST https://luavion.com/api/v1/obfuscate \
  -H "Authorization: Bearer lua_live_..." \
  -H "Content-Type: application/json" \
  -d '{"source": "...", "preset": "EXTREME"}'</pre>
          </div>
        </div>
      </div>
    </section>

    <!-- PRICING PREVIEW -->
    <section id="pricing" class="section">
      <div class="container">
        <div class="section-head center reveal">
          <span class="t-label">[ pricing ]</span>
          <h2 class="t-h2">Transparent, scalable pricing</h2>
          <p class="t-body section-sub">Choose the throughput and feature tier designed for your scale.</p>
          <div class="segmented-control" role="group" aria-label="Currency">
            <button class="seg-btn mono" :class="{ active: currency === 'USD' }" @click="currency = 'USD'">USD $</button>
            <button class="seg-btn mono" :class="{ active: currency === 'IDR' }" @click="currency = 'IDR'">IDR Rp</button>
          </div>
        </div>

        <div class="pricing-grid">
          <div
            v-for="p in Object.values(plans)"
            :key="p.id"
            class="price-card"
            :class="{ featured: p.id === 'pro', reveal: true }"
          >
            <div class="price-head">
              <span class="plan-title">{{ p.name }}</span>
              <span v-if="p.badge" class="badge" :class="p.id === 'pro' ? 'badge-cyan' : ''">{{ p.badge }}</span>
            </div>
            <div class="price-amount-wrap">
              <span class="price-amount mono">{{ formatPrice(p.priceUsd, p.priceIdr) }}</span>
              <span class="price-period">/mo</span>
            </div>
            <ul class="plan-bullets">
              <li><strong>{{ p.quotaMonthly.toLocaleString() }}</strong> obfuscations / mo</li>
              <li>Up to <strong>{{ p.maxFileSizeLabel }}</strong> per file</li>
              <li>Batch: {{ p.maxBatchFiles > 1 ? `up to ${p.maxBatchFiles} files` : 'single file' }}</li>
              <li>API: {{ p.hasApiAccess ? 'full REST API' : 'none' }}</li>
              <li>History: {{ p.historyRetentionDays > 0 ? `${p.historyRetentionDays} days cloud` : 'ephemeral' }}</li>
            </ul>
            <NuxtLink
              :to="p.id === 'free' ? '/dashboard' : `/billing?upgrade=${p.id}`"
              class="btn btn-sm btn-block"
              :class="p.id === 'pro' ? 'btn-primary' : 'btn-secondary'"
            >
              {{ p.id === 'free' ? 'Start free' : `Upgrade to ${p.name}` }}
            </NuxtLink>
          </div>
        </div>

        <div class="full-pricing-cta">
          <NuxtLink to="/pricing" class="btn btn-ghost">
            Full feature comparison &amp; FAQ
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
              <line x1="5" y1="12" x2="19" y2="12"></line>
              <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- FAQ -->
    <section id="faq" class="section">
      <div class="container faq-container">
        <div class="section-head reveal">
          <span class="t-label">[ knowledge base ]</span>
          <h2 class="t-h2">Frequently asked questions</h2>
        </div>

        <div class="faq-list">
          <div
            v-for="(item, idx) in faqItems"
            :key="idx"
            class="faq-item"
            :class="{ open: openFaq === idx }"
          >
            <button
              class="faq-q"
              :aria-expanded="openFaq === idx"
              @click="toggleFaq(idx)"
            >
              <span>{{ item.q }}</span>
              <svg class="faq-chev" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                <polyline points="6 9 12 15 18 9"></polyline>
              </svg>
            </button>
            <div class="faq-a-wrap">
              <p class="faq-a">{{ item.a }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- BOTTOM CTA -->
    <section class="cta-section">
      <div class="container">
        <div class="cta-panel reveal">
          <div class="cta-glow" aria-hidden="true"></div>
          <span class="t-label" style="color: var(--text-secondary)">[ ready for production ]</span>
          <h2 class="cta-title">Protect your Luau codebase in milliseconds</h2>
          <p class="cta-desc">Zero setup required. Paste your script and compile directly in the Studio.</p>
          <NuxtLink to="/dashboard" class="btn btn-primary btn-lg" style="margin-top: 26px">
            Open the Obfuscator
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true">
              <line x1="5" y1="12" x2="19" y2="12"></line>
              <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
          </NuxtLink>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { usePlans } from '~/composables/usePlans'
import { useReveal } from '~/composables/useReveal'

useReveal()

const { plans, currency, formatPrice } = usePlans()

const openFaq = ref(0)
const toggleFaq = (idx) => {
  openFaq.value = openFaq.value === idx ? -1 : idx
}

const faqItems = [
  {
    q: 'Does Luavion work with modern Roblox GUI frameworks like Fluent or Rayfield?',
    a: "Yes. Luavion maintains 100% bytecode compliance with modern UI libraries. By avoiding the outdated closure metamethod hooking used by legacy obfuscators, we prevent the closure destruction that breaks frameworks."
  },
  {
    q: 'Will the Ephemeral String Ring leak memory or drop framerates?',
    a: 'No. The ring utilizes aggressive runtime register reuse protocols. String pointers are dereferenced and collected within the microsecond of their execution. Zero GC stutters, even in RenderStepped loops.'
  },
  {
    q: 'How exactly does the AI Prompt Shield stop reverse engineering?',
    a: 'We embed zero-width Unicode directives throughout your protected script. When an exploiter pastes the code into ChatGPT, Claude, or Cursor, the invisible text acts as a context override, causing the AI to hallucinate or refuse analysis.'
  },
  {
    q: 'If keys are bound to Roblox math, can I run scripts in Node.js?',
    a: 'Noâ€”and that is by design. The geometric attestation ensures your decryption keys literally cannot resolve outside of a true Roblox Luau engine. External sandboxes mathematically fail, preventing pre-execution dumping.'
  },
  {
    q: 'Do you store my source code on your servers?',
    a: 'Absolutely not. We operate on a strict Zero-Retention execution mandate. Your source travels over 256-bit TLS, is compiled strictly in-memory by ephemeral WASM sandboxes, and is permanently destroyed upon buffer flush.'
  }
]
</script>

<style scoped>
.landing-page { position: relative; }

/* Ambient hero glow */
.hero-ambient {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 900px;
  height: 480px;
  background: radial-gradient(ellipse 60% 50% at 50% 0%, rgba(255, 255, 255, 0.05), transparent 70%);
  pointer-events: none;
  z-index: 0;
}

/* ---------- Hero ---------- */
.hero-section { padding: 84px 0 24px; position: relative; }

.hero-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  max-width: 820px;
  margin: 0 auto;
}

.hero-title {
  font-size: clamp(38px, 6vw, 64px);
  font-weight: 600;
  letter-spacing: -0.04em;
  line-height: 1.05;
  color: var(--text-primary);
  margin-bottom: 20px;
}

.hero-subtitle {
  font-size: 16px;
  line-height: 1.7;
  color: var(--text-secondary);
  max-width: 560px;
  margin-bottom: 32px;
}

.hero-cta-group { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; }

.hero-metrics {
  display: flex;
  gap: 0;
  margin-top: 44px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  background: rgba(255, 255, 255, 0.015);
  overflow: hidden;
  flex-wrap: wrap;
}

.hm-item {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  padding: 14px 22px;
  border-right: 1px solid var(--border-subtle);
  flex: 1;
  min-width: 140px;
}

.hm-item:last-child { border-right: none; }

.hm-item strong { font-size: 13px; font-weight: 600; color: var(--text-primary); }

.hm-item span { font-size: 10px; color: var(--text-faint); letter-spacing: 0.04em; }

.hero-demo { margin-top: 56px; }

.demo-hint {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 14px;
  font-size: 10px;
  color: var(--text-faint);
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

/* ---------- Sections ---------- */
.section { padding: 96px 0; }

.section-head { margin-bottom: 48px; max-width: 640px; }

.section-head.center {
  margin-left: auto;
  margin-right: auto;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.section-head .t-label { display: block; margin-bottom: 14px; }

.section-sub { margin-top: 12px; }

/* ---------- Pillars ---------- */
.pillars-rows {
  display: grid;
  grid-template-columns: 1fr 1fr;
  column-gap: 48px;
  border-top: 1px solid var(--border-subtle);
}

.pillar-row {
  display: flex;
  gap: 22px;
  padding: 28px 8px 28px 0;
  border-bottom: 1px solid var(--border-subtle);
  transition: background var(--duration-normal) var(--ease-out);
}

.pillar-row:hover { background: rgba(255, 255, 255, 0.015); }

.pillar-index {
  font-size: 12px;
  color: var(--text-faint);
  padding-top: 4px;
  flex-shrink: 0;
}

.pillar-head {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}

.pillar-head h3 { font-size: 16px; font-weight: 600; letter-spacing: -0.015em; }

.pillar-body p {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
  margin-bottom: 12px;
}

.pillar-code {
  display: inline-block;
  font-size: 11px;
  color: var(--text-muted);
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xs);
  padding: 4px 10px;
}

.code-inline {
  font-family: var(--font-mono);
  font-size: 0.9em;
  background: var(--bg-elevated);
  padding: 1px 5px;
  border-radius: 4px;
  color: var(--text-primary);
}

/* ---------- Security deep-dive ---------- */
.deepdive-grid {
  display: grid;
  grid-template-columns: minmax(280px, 380px) 1fr;
  gap: 64px;
  align-items: start;
}

.deepdive-intro { position: sticky; top: 96px; }

.deepdive-intro .t-label { display: block; margin-bottom: 14px; }

.deepdive-intro .t-body { margin-top: 12px; }

.deepdive-link { margin-top: 20px; }

.deepdive-items { display: flex; flex-direction: column; }

.deepdive-item {
  display: flex;
  gap: 24px;
  padding: 26px 0;
  border-top: 1px solid var(--border-subtle);
}

.deepdive-item:last-child { border-bottom: 1px solid var(--border-subtle); }

.deep-index {
  font-size: 24px;
  font-weight: 300;
  color: var(--text-faint);
  flex-shrink: 0;
  letter-spacing: -0.02em;
}

.deepdive-item h4 { font-size: 15px; font-weight: 600; margin-bottom: 6px; }

.deepdive-item p { font-size: 13px; color: var(--text-secondary); line-height: 1.7; }

/* ---------- Matrix ---------- */
.matrix-wrap {
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  overflow: hidden;
  background: var(--bg-surface);
}

.matrix-table { width: 100%; border-collapse: collapse; font-size: 13px; }

.matrix-table thead { background: var(--bg-base); }

.matrix-table th {
  padding: 14px 18px;
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--text-muted);
  border-bottom: 1px solid var(--border-subtle);
  white-space: nowrap;
}

.matrix-table td {
  padding: 16px 18px;
  border-bottom: 1px solid var(--border-faint);
  color: var(--text-secondary);
  vertical-align: top;
}

.matrix-table tbody tr:last-child td { border-bottom: none; }

.matrix-table tbody tr { transition: background var(--duration-fast) var(--ease-out); }

.matrix-table tbody tr:hover { background: rgba(255, 255, 255, 0.015); }

.col-luavion {
  background: var(--accent-dimmer);
  color: var(--text-primary) !important;
  border-left: 1px solid var(--border-subtle);
  border-right: 1px solid var(--border-subtle);
}

.brand-mark {
  font-family: var(--font-mono);
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--text-primary);
  display: block;
  margin-bottom: 6px;
}

.val-luavion {
  background: var(--accent-dimmer);
  color: var(--text-primary) !important;
  border-left: 1px solid var(--border-subtle);
  border-right: 1px solid var(--border-subtle);
  font-weight: 500;
}

.matrix-table tfoot td.col-luavion,
.matrix-table tr:last-child .val-luavion { border-bottom: none; }

.metric-name strong { display: block; color: var(--text-primary); font-size: 13px; font-weight: 600; }

.metric-name span { display: block; font-size: 11px; color: var(--text-faint); margin-top: 3px; }

.tag-no { color: var(--status-crimson); font-size: 12px; }

.tag-mid { color: var(--status-amber); font-size: 12px; }

/* ---------- API ---------- */
.api-split {
  display: grid;
  grid-template-columns: minmax(280px, 420px) 1fr;
  gap: 56px;
  align-items: center;
}

.api-actions { display: flex; gap: 10px; margin-top: 24px; flex-wrap: wrap; }

.api-terminal { overflow: hidden; }

.api-pre {
  padding: 20px 22px;
  font-size: 12.5px;
  line-height: 1.8;
  color: var(--text-secondary);
  overflow-x: auto;
  white-space: pre;
}

/* ---------- Pricing preview ---------- */
.pricing-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.price-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  padding: 24px 22px;
  display: flex;
  flex-direction: column;
  transition: border-color var(--duration-normal) var(--ease-out), transform var(--duration-normal) var(--ease-out);
}

.price-card:hover { border-color: var(--border-regular); transform: translateY(-2px); }

.price-card.featured {
  border-color: var(--border-focus);
  background: var(--bg-surface-raised);
  box-shadow: var(--surface-highlight), 0 0 40px rgba(255, 255, 255, 0.05);
}

.price-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 14px; }

.plan-title { font-size: 15px; font-weight: 600; }

.price-amount-wrap { display: flex; align-items: baseline; gap: 6px; margin-bottom: 18px; }

.price-amount { font-size: 26px; font-weight: 600; letter-spacing: -0.02em; }

.price-period { font-size: 12px; color: var(--text-muted); }

.plan-bullets {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 12px;
  color: var(--text-secondary);
  margin-bottom: 22px;
  flex: 1;
}

.plan-bullets strong { color: var(--text-primary); font-weight: 600; }

.btn-block { width: 100%; }

.full-pricing-cta { display: flex; justify-content: center; margin-top: 32px; }

/* ---------- Segmented currency ---------- */
.segmented-control {
  display: inline-flex;
  gap: 2px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 3px;
  margin-top: 8px;
}

.seg-btn {
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 500;
  padding: 7px 16px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
  min-height: 32px;
}

.seg-btn.active {
  background: var(--bg-elevated);
  color: var(--text-primary);
  box-shadow: var(--shadow-sm), inset 0 1px 0 rgba(255, 255, 255, 0.06);
}

/* ---------- FAQ ---------- */
.faq-container { max-width: 760px; }

.faq-list { border-top: 1px solid var(--border-subtle); }

.faq-item { border-bottom: 1px solid var(--border-subtle); }

.faq-q {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 4px;
  background: transparent;
  border: none;
  color: var(--text-primary);
  font-family: inherit;
  font-size: 14.5px;
  font-weight: 500;
  letter-spacing: -0.01em;
  text-align: left;
  cursor: pointer;
  transition: color var(--duration-fast) var(--ease-out);
}

.faq-q:hover { color: var(--text-secondary); }

.faq-chev {
  flex-shrink: 0;
  color: var(--text-muted);
  transition: transform var(--duration-normal) var(--ease-spring);
}

.faq-item.open .faq-chev { transform: rotate(180deg); color: var(--text-primary); }

.faq-a-wrap {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows var(--duration-normal) var(--ease-spring);
}

.faq-item.open .faq-a-wrap { grid-template-rows: 1fr; }

.faq-a {
  overflow: hidden;
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
  padding: 0 4px;
  max-width: 640px;
}

.faq-item.open .faq-a { padding-bottom: 22px; }

/* ---------- Bottom CTA ---------- */
.cta-section { padding: 96px 0 120px; }

.cta-panel {
  position: relative;
  text-align: center;
  padding: 72px 32px;
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-xl);
  background: var(--bg-surface);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.cta-glow {
  position: absolute;
  top: -40%;
  left: 50%;
  transform: translateX(-50%);
  width: 560px;
  height: 320px;
  background: radial-gradient(ellipse 60% 60% at 50% 0%, rgba(255, 255, 255, 0.07), transparent 70%);
  pointer-events: none;
}

.cta-title {
  font-size: clamp(26px, 4vw, 40px);
  font-weight: 600;
  letter-spacing: -0.03em;
  margin: 16px 0 10px;
}

.cta-desc { font-size: 14px; color: var(--text-secondary); }

/* ---------- Responsive ---------- */
@media (max-width: 960px) {
  .pillars-rows { grid-template-columns: 1fr; }
  .deepdive-grid { grid-template-columns: 1fr; gap: 32px; }
  .deepdive-intro { position: static; }
  .api-split { grid-template-columns: 1fr; gap: 32px; }
  .pricing-grid { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 640px) {
  .hero-section { padding: 56px 0 16px; }
  .section { padding: 64px 0; }
  .pricing-grid { grid-template-columns: 1fr; }
  .hm-item { min-width: 45%; border-bottom: 1px solid var(--border-subtle); }
  .hero-metrics { width: 100%; }
  .desktop-br { display: none; }
  .matrix-wrap { overflow-x: auto; }
  .cta-panel { padding: 48px 20px; }
}
</style>


