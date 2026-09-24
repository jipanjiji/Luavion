<template>
  <div class="landing-page">
    <!-- Subtle Background Grid Overlay -->
    <div class="bg-grid-overlay" aria-hidden="true"></div>

    <!-- Hero Section -->
    <section class="hero-section">
      <div class="container hero-container">
        <!-- Status Notification Pill -->
        <div class="hero-pill-wrap">
          <div class="hero-pill">
            <span class="pulse-indicator">
              <span class="dot-core"></span>
              <span class="dot-ring"></span>
            </span>
            <span class="pill-text">Luavion Galois Engine v9.15 Active</span>
            <span class="pill-sep">•</span>
            <span class="pill-tag">Roblox Luau & Lua 5.1</span>
          </div>
        </div>

        <h1 class="hero-title">
          Next-Generation Luau <br class="hero-break" />
          <span class="hero-highlight">Bytecode Virtualization</span>
        </h1>

        <p class="hero-subtitle">
          Engineered from first principles with decentralized register micro-ops, cryptographic geometric attestation, and steganographic AI prompt shields. Defeat AST dumpers and neural reverse-engineering with zero frame drops.
        </p>

        <div class="hero-cta-group">
          <NuxtLink to="/app" class="btn btn-accent btn-lg hero-btn-primary">
            <span>Launch Obfuscator Studio</span>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <line x1="5" y1="12" x2="19" y2="12"></line>
              <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
          </NuxtLink>

          <a href="#preview" class="btn btn-secondary btn-lg hero-btn-secondary">
            <span>Explore Interactive Preview</span>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <polyline points="19 12 12 19 5 12"></polyline>
            </svg>
          </a>
        </div>

        <!-- Telemetry Proof Chips -->
        <div class="hero-metrics-bar">
          <div class="metric-item">
            <span class="metric-num">60+ FPS</span>
            <span class="metric-desc">Zero GC Stutter</span>
          </div>
          <div class="metric-divider"></div>
          <div class="metric-item">
            <span class="metric-num">Vector3</span>
            <span class="metric-desc">Engine Attestation</span>
          </div>
          <div class="metric-divider"></div>
          <div class="metric-item">
            <span class="metric-num">Zero-Width</span>
            <span class="metric-desc">AI Prompt Shield</span>
          </div>
          <div class="metric-divider"></div>
          <div class="metric-item">
            <span class="metric-num">100%</span>
            <span class="metric-desc">GUI Framework Match</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Interactive Live Preview Split Slider Section -->
    <section id="preview" class="section preview-section">
      <div class="container">
        <div class="section-heading">
          <div class="section-tag">
            <span class="status-dot dot-cyan"></span>
            <span>INTERACTIVE COMPARISON</span>
          </div>
          <h2 class="section-title">Slide to Compare Bytecode Transformation</h2>
          <p class="section-subtitle">
            Drag the central slider handle left and right to inspect how Luavion converts vulnerable AST source code into decentralized, cryptographic register bytecode.
          </p>
        </div>

        <!-- Embed Custom Interactive Before/After Split Slider -->
        <InteractiveCodeSlider />
      </div>
    </section>

    <!-- Defensive Architectural Pillars Section -->
    <section id="features" class="section pillars-section">
      <div class="container">
        <div class="section-heading">
          <div class="section-tag">
            <span class="status-dot dot-cyan"></span>
            <span>ARCHITECTURE</span>
          </div>
          <h2 class="section-title">Core Defensive Pillars</h2>
          <p class="section-subtitle">
            Standard obfuscators rely on shallow variable mangling and function-array flat loops. Luavion replaces the execution model entirely.
          </p>
        </div>

        <div class="pillars-grid">
          <!-- Pillar 1 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect>
                  <rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect>
                  <line x1="6" y1="6" x2="6.01" y2="6"></line>
                  <line x1="6" y1="18" x2="6.01" y2="18"></line>
                </svg>
              </div>
              <span class="badge badge-cyan">DYNAMIC ISA</span>
            </div>
            <h3 class="pillar-name">Decentralized Register VM</h3>
            <p class="pillar-desc">
              Rather than linear switch statements or slow closure arrays, source expressions are compiled into dynamic micro-ops with Galois polynomial bucket hashing.
            </p>
            <div class="pillar-footer">
              <code>Galois Polynomial Dispatch</code>
            </div>
          </div>

          <!-- Pillar 2 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon pillar-icon-cyan">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"></circle>
                  <polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"></polygon>
                </svg>
              </div>
              <span class="badge badge-emerald">ROBLOX ATTESTATION</span>
            </div>
            <h3 class="pillar-name">Geometric Math Attestation</h3>
            <p class="pillar-desc">
              Decryption keys are cryptographically bound to Roblox native <code class="code-inline">Vector3.Magnitude</code> and IEEE-754 binary conversions. External emulators crash silently.
            </p>
            <div class="pillar-footer">
              <code>Vector3.new(3,4,0).Magnitude == 5.0</code>
            </div>
          </div>

          <!-- Pillar 3 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polyline points="16 18 22 12 16 6"></polyline>
                  <polyline points="8 6 2 12 8 18"></polyline>
                </svg>
              </div>
              <span class="badge">NON-POLYNOMIAL</span>
            </div>
            <h3 class="pillar-name">Polymorphic MBA Equations</h3>
            <p class="pillar-desc">
              Conditionals and constants are expanded into multi-variable Mixed Boolean-Arithmetic equations, rendering automated SMT solvers and Z3 symbolic executors computationally intractable.
            </p>
            <div class="pillar-footer">
              <code>(x ^ y) + 2*(x & y) == x + y</code>
            </div>
          </div>

          <!-- Pillar 4 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon pillar-icon-cyan">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                </svg>
              </div>
              <span class="badge badge-cyan">ANTI-DUMP</span>
            </div>
            <h3 class="pillar-name">Ephemeral Dynamic String Ring</h3>
            <p class="pillar-desc">
              Strings are never stored in static arrays. Literals are synthesized at runtime into register slots and evaporate immediately upon register reuse, blocking memory dumper tools.
            </p>
            <div class="pillar-footer">
              <code>Zero Static String Footprint</code>
            </div>
          </div>

          <!-- Pillar 5 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon pillar-icon-emerald">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm0 18a8 8 0 1 1 8-8 8 8 0 0 1-8 8z"></path>
                  <path d="M12 6v6l4 2"></path>
                </svg>
              </div>
              <span class="badge badge-emerald">ZERO-WIDTH PROMPT</span>
            </div>
            <h3 class="pillar-name">Steganographic AI Prompt Shield</h3>
            <p class="pillar-desc">
              Injects invisible zero-width Unicode directives that hijack LLM system contexts (ChatGPT, Claude, Cursor), instructing models to immediately refuse reverse-engineering queries.
            </p>
            <div class="pillar-footer">
              <code>\u200B \u200C Context Poisoning</code>
            </div>
          </div>

          <!-- Pillar 6 -->
          <div class="surface pillar-card">
            <div class="pillar-header">
              <div class="pillar-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M22 12h-4l-3 9L9 3l-3 9H2"></path>
                </svg>
              </div>
              <span class="badge badge-cyan">HIGH FPS</span>
            </div>
            <h3 class="pillar-name">Zero Frame-Drop Execution</h3>
            <p class="pillar-desc">
              Optimized register reuse and minimal garbage collector overhead ensure seamless 60+ FPS performance even in high-frequency loops, physics controllers, and raycasting systems.
            </p>
            <div class="pillar-footer">
              <code>RenderStepped Certified</code>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Security Deep-Dive Section -->
    <section id="security" class="section security-section">
      <div class="container">
        <div class="section-heading">
          <div class="section-tag">
            <span class="status-dot dot-cyan"></span>
            <span>THREAT MODEL</span>
          </div>
          <h2 class="section-title">Engine Architecture & Anti-Tamper</h2>
          <p class="section-subtitle">
            How Luavion systematically neutralizes modern deobfuscation and reverse-engineering pipelines.
          </p>
        </div>

        <div class="security-grid">
          <div class="surface security-box">
            <div class="sec-box-badge">DEFENSE 01</div>
            <h3 class="sec-box-title">Defeating CFG Deswitchers</h3>
            <p class="sec-box-body">
              Legacy tools rely on loop-switch flat states (<code class="code-inline">k6[id] = function(...) return next_id</code>). Attackers write basic deswitchers that trace the return IDs and reconstruct original AST control flow.
            </p>
            <p class="sec-box-body">
              Luavion compiles code into genuine bytecode register instructions. There are no raw function tables to unswitch. Disassembling requires reconstructing a proprietary custom virtual CPU.
            </p>
          </div>

          <div class="surface security-box">
            <div class="sec-box-badge">DEFENSE 02</div>
            <h3 class="sec-box-title">Fail-Closed Sandbox Traps</h3>
            <p class="sec-box-body">
              When an attacker runs Luavion inside Node.js, Wasmoon, or generic emulators, cryptographic attestation detects subtle IEEE-754 precision differences and missing C-closure tags.
            </p>
            <p class="sec-box-body">
              Instead of throwing identifiable errors, the VM keystream silently desynchronizes, generating invalid opcodes and triggering a natural crash without exploiter-readable traceback.
            </p>
          </div>

          <div class="surface security-box">
            <div class="sec-box-badge">DEFENSE 03</div>
            <h3 class="sec-box-title">Neural Context Poisoning</h3>
            <p class="sec-box-body">
              Automated reverse-engineers increasingly pipe protected scripts into LLMs. Luavion embeds invisible zero-width Unicode directives directly inside headers, comments, and strings.
            </p>
            <p class="sec-box-body">
              When pasted into AI chat interfaces or automated coding agents, the hidden directive triggers model guardrails, halting reverse engineering before analysis begins.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Comparison Matrix Section -->
    <section id="compare" class="section compare-section">
      <div class="container">
        <div class="section-heading">
          <div class="section-tag">
            <span class="status-dot dot-cyan"></span>
            <span>BENCHMARK</span>
          </div>
          <h2 class="section-title">Obfuscator Comparison Matrix</h2>
          <p class="section-subtitle">
            An objective technical comparison between Luavion and existing Lua obfuscation technologies.
          </p>
        </div>

        <div class="matrix-card surface">
          <div class="table-scroller">
            <table class="matrix-table">
              <thead>
                <tr>
                  <th class="col-metric">Security Feature</th>
                  <th class="col-luavion">
                    <span class="brand-text">LUAVION</span>
                    <span class="badge badge-cyan">v9.15</span>
                  </th>
                  <th>Prometheus</th>
                  <th>Moonsec</th>
                  <th>Luraph</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="metric-name">
                    <strong>Steganographic AI Prompt Shields</strong>
                    <span class="metric-desc">Zero-width anti-LLM security directives</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-cyan">Native Shielded</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-no">None</span></td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Underlying Architecture</strong>
                    <span class="metric-desc">Internal VM design model</span>
                  </td>
                  <td class="val-luavion">Decentralized Register VM</td>
                  <td>Macro AST Transform</td>
                  <td>Lua 5.1 Stack VM</td>
                  <td>Proprietary VM</td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Roblox Geometric Attestation</strong>
                    <span class="metric-desc">Vector3 & float bitcast bindings</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-emerald">Native Verified</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-no">None</span></td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Control-Flow Deflattening Resistance</strong>
                    <span class="metric-desc">Resilience against AST deswitchers</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-cyan">Immune (Pure VM)</span></td>
                  <td><span class="tag-mid">Moderate</span></td>
                  <td><span class="tag-no">Vulnerable</span></td>
                  <td><span class="badge badge-emerald">Strong</span></td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Runtime Garbage Collector Impact</strong>
                    <span class="metric-desc">Memory leak & FPS drop probability</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-emerald">Near Zero (&lt;1%)</span></td>
                  <td><span class="tag-mid">High Overhead</span></td>
                  <td><span class="tag-mid">Medium Overhead</span></td>
                  <td><span class="badge badge-emerald">Low Overhead</span></td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Fail-Closed Sandbox Detection</strong>
                    <span class="metric-desc">Neutralizes Node.js / Wasmoon snooping</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-cyan">Cryptographic Fail</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-no">None</span></td>
                  <td><span class="tag-mid">Generic Checks</span></td>
                </tr>
                <tr>
                  <td class="metric-name">
                    <strong>Modern GUI Framework Support</strong>
                    <span class="metric-desc">Fluent, Rayfield, Maclib, Linoria</span>
                  </td>
                  <td class="val-luavion"><span class="badge badge-emerald">100% Compatible</span></td>
                  <td><span class="tag-mid">Frequent Breaks</span></td>
                  <td><span class="tag-no">Broken Closures</span></td>
                  <td><span class="badge badge-emerald">Compatible</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </section>

    <!-- FAQ Accordion Section -->
    <section id="faq" class="section faq-section">
      <div class="container faq-container">
        <div class="section-heading">
          <div class="section-tag">
            <span class="status-dot dot-cyan"></span>
            <span>KNOWLEDGE BASE</span>
          </div>
          <h2 class="section-title">Frequently Asked Questions</h2>
          <p class="section-subtitle">
            Technical answers regarding Luavion security, runtime compatibility, and deployment.
          </p>
        </div>

        <div class="accordion-list">
          <div 
            v-for="(item, idx) in faqItems" 
            :key="idx" 
            class="surface accordion-item"
            :class="{ 'open': openFaq === idx }"
            @click="toggleFaq(idx)"
          >
            <div class="accordion-header">
              <span class="accordion-q">{{ item.q }}</span>
              <div class="accordion-toggle">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <line x1="12" y1="5" x2="12" y2="19" v-if="openFaq !== idx"></line>
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
              </div>
            </div>
            <div v-show="openFaq === idx" class="accordion-body">
              <p class="accordion-a">{{ item.a }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Bottom Conversion Banner -->
    <section class="bottom-cta-section">
      <div class="container">
        <div class="surface-raised bottom-cta-card">
          <div class="cta-inner">
            <div class="cta-badge">
              <span class="status-dot dot-cyan"></span>
              <span>READY FOR PRODUCTION</span>
            </div>
            <h2 class="cta-title">Protect your Luau codebase in milliseconds</h2>
            <p class="cta-desc">
              Experience cryptographic bytecode virtualization with zero setup required. Paste your script and compile directly in the studio.
            </p>
            <div class="cta-actions">
              <NuxtLink to="/app" class="btn btn-accent btn-lg">
                <span>Launch Obfuscator Studio</span>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                  <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
              </NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const openFaq = ref(0)
const toggleFaq = (idx) => {
  openFaq.value = openFaq.value === idx ? -1 : idx
}

const faqItems = [
  {
    q: "What does Luavion protect?",
    a: "Luavion protects all intellectual property inside your Luau / Lua 5.1 scripts, including API endpoints, secret authentication keys, algorithmic mathematics, table structures, and control flow. It compiles your high-level code into virtualized register bytecode so that original variables, strings, and statements no longer exist."
  },
  {
    q: "Will it break my script?",
    a: "No. Luavion's AST parser and bytecode synthesizer rigorously preserve Lua semantic behavior, including vararg (...) propagation, multi-return values, metamethods (__index, __newindex), error handling (pcall/xpcall), coroutines, and task scheduling."
  },
  {
    q: "Will generic deobfuscators crack it?",
    a: "No. Generic deobfuscators target common patterns like function-array loops, simple XOR string loops, or standard Lua 5.1 unluac bytecode. Luavion uses dynamic Galois bucket polynomial dispatching, polymorphic MBA equations, and geometric attestation that completely breaks automated decompilers."
  },
  {
    q: "Is my script uploaded or stored on any external server?",
    a: "Never. Luavion processes your script strictly on-demand in an ephemeral execution sandbox. We do not store, log, cache, or transmit your proprietary source code to any database or third-party server."
  },
  {
    q: "Does Luavion cause any frame drops or execution lag in games?",
    a: "Luavion is built with low-overhead register-based architecture. For performance-critical scripts such as render loops, physics controllers, or high-speed autofarms, our PERFORMANCE and BALANCED presets guarantee smooth 60+ FPS without garbage collection stutter."
  },
  {
    q: "Does it support modern GUI frameworks like Fluent, Rayfield, and Maclib?",
    a: "Yes! Luavion is fully compatible with popular UI libraries including Fluent, Rayfield, Maclib, LinoriaLib, and OrionLib. Metatables, closure bindings, and signal connections are handled without breaking parent-child hierarchy."
  },
  {
    q: "How does the Anti-Dumper defense handle automated reverse engineering tools?",
    a: "Luavion deploys multiple honeypots, closure introspection probes, and geometric math bitcasts. If an automated reverse-engineering tool or emulator attempts to dump registers or hook table calls, the internal decryption seeds desynchronize and the VM fails closed."
  }
]
</script>

<style scoped>
.landing-page {
  position: relative;
  overflow: hidden;
}

/* Hero Section */
.hero-section {
  padding: 96px 0 72px;
  position: relative;
  text-align: center;
}

.hero-container {
  max-width: 900px;
}

.hero-pill-wrap {
  display: flex;
  justify-content: center;
  margin-bottom: 28px;
}

.hero-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: var(--radius-full);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  box-shadow: var(--surface-highlight);
  font-size: 11px;
  font-weight: 500;
  color: var(--text-secondary);
}

.pill-sep {
  color: var(--text-faint);
}

.pill-tag {
  color: var(--accent-cyan);
  font-weight: 600;
}

.hero-title {
  font-size: 48px;
  font-weight: 700;
  line-height: 1.12;
  letter-spacing: -0.035em;
  color: #ffffff;
  margin-bottom: 22px;
}

.hero-highlight {
  color: var(--accent-cyan);
  text-shadow: 0 0 32px rgba(0, 240, 255, 0.35);
}

.hero-subtitle {
  font-size: 15px;
  line-height: 1.65;
  color: var(--text-secondary);
  max-width: 700px;
  margin: 0 auto 36px;
}

.hero-cta-group {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  flex-wrap: wrap;
  margin-bottom: 56px;
}

.hero-btn-primary {
  box-shadow: 0 0 24px rgba(0, 240, 255, 0.3);
}

/* Metrics bar */
.hero-metrics-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 32px;
  padding: 18px 28px;
  border-radius: var(--radius-md);
  background: rgba(14, 20, 34, 0.6);
  border: 1px solid var(--border-subtle);
  backdrop-filter: blur(12px);
  max-width: 740px;
  margin: 0 auto;
}

.metric-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.metric-num {
  font-size: 16px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.02em;
}

.metric-desc {
  font-size: 10px;
  color: var(--text-muted);
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.metric-divider {
  width: 1px;
  height: 28px;
  background: var(--border-subtle);
}

/* General Sections */
.section {
  padding: 80px 0;
}

.section-heading {
  text-align: center;
  max-width: 720px;
  margin: 0 auto 48px;
}

.section-tag {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--accent-cyan);
  margin-bottom: 12px;
}

.section-title {
  font-size: 30px;
  font-weight: 700;
  letter-spacing: -0.025em;
  color: #ffffff;
  margin-bottom: 14px;
}

.section-subtitle {
  font-size: 14px;
  line-height: 1.6;
  color: var(--text-secondary);
}

/* Pillars Grid */
.pillars-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.pillar-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  border-radius: var(--radius-lg);
  transition: transform var(--duration-fast), border-color var(--duration-fast);
}

.pillar-card:hover {
  transform: translateY(-2px);
  border-color: var(--border-hover);
}

.pillar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.pillar-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
}

.pillar-icon-cyan {
  color: var(--accent-cyan);
  border-color: var(--accent-cyan-border);
  box-shadow: 0 0 14px rgba(0, 240, 255, 0.15);
}

.pillar-icon-emerald {
  color: var(--status-emerald);
  border-color: var(--status-emerald-border);
  box-shadow: 0 0 14px rgba(16, 185, 129, 0.15);
}

.pillar-name {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #ffffff;
  margin-bottom: 10px;
}

.pillar-desc {
  font-size: 12.5px;
  line-height: 1.6;
  color: var(--text-secondary);
  flex: 1;
  margin-bottom: 18px;
}

.pillar-footer {
  padding-top: 14px;
  border-top: 1px solid var(--border-faint);
}

.pillar-footer code {
  font-size: 11px;
  color: var(--text-muted);
}

.code-inline {
  font-family: var(--font-mono);
  background: rgba(255, 255, 255, 0.08);
  padding: 1px 4px;
  border-radius: 3px;
  color: var(--accent-cyan);
}

/* Security Grid */
.security-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.security-box {
  padding: 24px;
  border-radius: var(--radius-lg);
}

.sec-box-badge {
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.1em;
  color: var(--accent-cyan);
  margin-bottom: 12px;
}

.sec-box-title {
  font-size: 16px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 12px;
}

.sec-box-body {
  font-size: 12px;
  line-height: 1.6;
  color: var(--text-secondary);
  margin-bottom: 12px;
}

.sec-box-body:last-child {
  margin-bottom: 0;
}

/* Matrix Table */
.matrix-card {
  overflow: hidden;
  border-radius: var(--radius-lg);
}

.table-scroller {
  overflow-x: auto;
}

.matrix-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  text-align: left;
}

.matrix-table th {
  padding: 16px 20px;
  background: var(--bg-surface-raised);
  border-bottom: 1px solid var(--border-subtle);
  font-size: 11px;
  font-weight: 600;
  color: var(--text-secondary);
}

.matrix-table td {
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-faint);
  color: var(--text-secondary);
}

.matrix-table tr:last-child td {
  border-bottom: none;
}

.col-metric {
  width: 32%;
}

.col-luavion {
  width: 26%;
  background: rgba(0, 240, 255, 0.02);
}

.brand-text {
  font-weight: 700;
  color: #ffffff;
  margin-right: 8px;
}

.val-luavion {
  color: #ffffff;
  font-weight: 600;
  background: rgba(0, 240, 255, 0.02);
}

.metric-name strong {
  display: block;
  color: #ffffff;
  font-size: 12px;
  margin-bottom: 2px;
}

.metric-desc {
  font-size: 10px;
  color: var(--text-muted);
}

.tag-no {
  color: var(--text-faint);
}

.tag-mid {
  color: var(--status-amber);
}

/* FAQ Accordion */
.faq-container {
  max-width: 800px;
}

.accordion-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.accordion-item {
  border-radius: var(--radius-md);
  padding: 16px 20px;
  cursor: pointer;
  transition: all var(--duration-fast);
}

.accordion-item:hover {
  border-color: var(--border-hover);
}

.accordion-item.open {
  border-color: var(--accent-cyan-border);
  background: var(--bg-surface-raised);
}

.accordion-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.accordion-q {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
}

.accordion-toggle {
  color: var(--accent-cyan);
  flex-shrink: 0;
}

.accordion-body {
  padding-top: 12px;
  border-top: 1px solid var(--border-faint);
  margin-top: 12px;
}

.accordion-a {
  font-size: 12px;
  line-height: 1.6;
  color: var(--text-secondary);
}

/* Bottom CTA Banner */
.bottom-cta-section {
  padding: 40px 0 96px;
}

.bottom-cta-card {
  border-radius: var(--radius-xl);
  padding: 48px 32px;
  text-align: center;
  background: 
    radial-gradient(ellipse 70% 60% at 50% 0%, rgba(0, 240, 255, 0.1), transparent 70%),
    var(--bg-surface-raised);
}

.cta-inner {
  max-width: 620px;
  margin: 0 auto;
}

.cta-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--accent-cyan);
  margin-bottom: 16px;
}

.cta-title {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.025em;
  color: #ffffff;
  margin-bottom: 14px;
}

.cta-desc {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
  margin-bottom: 28px;
}

.cta-actions {
  display: flex;
  justify-content: center;
}

/* Responsive adjustments */
@media (max-width: 1024px) {
  .pillars-grid,
  .security-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 34px;
  }
  .hero-break {
    display: none;
  }
  .hero-metrics-bar {
    flex-wrap: wrap;
    gap: 16px;
  }
  .metric-divider {
    display: none;
  }
  .pillars-grid,
  .security-grid {
    grid-template-columns: 1fr;
  }
}
</style>
