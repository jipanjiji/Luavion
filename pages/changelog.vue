<template>
  <div class="changelog-page">
    <div class="container changelog-container">
      <div class="changelog-header">
        <span class="badge badge-cyan">ENGINE & PLATFORM UPDATES</span>
        <h1 class="changelog-title">Product & VM Changelog</h1>
        <p class="changelog-subtitle">
          Continuous updates, anti-tamper enhancements, and performance optimizations for Luavion runtimes.
        </p>
      </div>

      <div class="changelog-timeline">
        <!-- Release 1: v9.15.0 -->
        <article class="surface release-card">
          <div class="release-header">
            <div class="release-version-group">
              <span class="version-tag">v9.15.0</span>
              <span class="badge badge-emerald">LATEST PRODUCTION RELEASE</span>
            </div>
            <span class="release-date">September 2026</span>
          </div>

          <h2 class="release-title">Commercial Platform Overhaul & Public REST API</h2>
          <div class="release-body">
            <p>
              This major milestone transforms Luavion into a full commercial security platform with tiered subscriptions, client-orchestrated batch compilation, persistent cloud history, and a public REST API for enterprise CI/CD automation.
            </p>
            <ul class="release-list">
              <li><strong>Public REST API (Ultra Tier)</strong>: Programmatic execution endpoint with 60 req/min rate limit and secure Bearer token authentication.</li>
              <li><strong>Tiered Subscription Engine</strong>: Introduced Free, Plus, Pro, and Ultra tiers with server-side limit enforcement and Stripe / Indonesian Gateway (Midtrans) integration.</li>
              <li><strong>Client-Side Batch Compiler</strong>: Chunked multi-file compilation (up to 10 on Pro, 100 on Ultra) with real-time per-file progress tracking and 1-click ZIP bundle downloads.</li>
              <li><strong>Cloud History Vault</strong>: Persistent output archiving with tier-based retention schedules (7 days on Plus, 30 on Pro, 90 on Ultra).</li>
              <li><strong>Custom Configuration Presets</strong>: Save, name, and reuse compiler settings.</li>
            </ul>
          </div>
        </article>

        <!-- Release 2: v9.14.0 -->
        <article class="surface release-card">
          <div class="release-header">
            <div class="release-version-group">
              <span class="version-tag">v9.14.0</span>
            </div>
            <span class="release-date">August 2026</span>
          </div>

          <h2 class="release-title">Steganographic AI Prompt Shield & Anti-LLM Protection</h2>
          <div class="release-body">
            <p>
              Neutralizes LLM-assisted reverse-engineering prompts (ChatGPT, Claude, Cursor, DeepSeek) through zero-width Unicode steganography.
            </p>
            <ul class="release-list">
              <li><strong>Zero-Width Directive Injection</strong>: Embeds invisible system security directives directly into headers and literal constants.</li>
              <li><strong>Galois Opcode Permutation</strong>: Scatters register opcodes across non-linear Galois mathematical buckets to thwart CFG deswitchers.</li>
              <li><strong>Roblox Vector3 Geometry Attestation</strong>: Binds decryption keystreams to native Luau Vector3 invariants.</li>
            </ul>
          </div>
        </article>

        <!-- Release 3: v9.10.0 -->
        <article class="surface release-card">
          <div class="release-header">
            <div class="release-version-group">
              <span class="version-tag">v9.10.0</span>
            </div>
            <span class="release-date">June 2026</span>
          </div>

          <h2 class="release-title">Decentralized Register Virtual Machine Initial Release</h2>
          <div class="release-body">
            <p>
              Replaced legacy function-array and loop-switch obfuscation with genuine register micro-ops and randomized operand topologies.
            </p>
            <ul class="release-list">
              <li><strong>6 Randomized Operand Topologies</strong>: Dynamic micro-op layouts generated on every compilation run.</li>
              <li><strong>Polymorphic MBA Synthesis</strong>: Rewrote integer constants into non-polynomial Mixed Boolean-Arithmetic topologies.</li>
              <li><strong>Ephemeral String Ring</strong>: Eradicated static constant string arrays in favor of register-synthesized ephemeral slices.</li>
            </ul>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<script setup>
useHead({
  title: 'Changelog | Luavion Engine & Platform Releases',
  meta: [
    { name: 'description', content: 'Changelog of updates, security enhancements, and new capabilities for Luavion Lua obfuscation platform.' }
  ]
})
</script>

<style scoped>
.changelog-page {
  padding: 64px 0 96px;
  min-height: 80vh;
}

.changelog-container {
  max-width: 800px;
}

.changelog-header {
  margin-bottom: 48px;
}

.changelog-title {
  font-size: 32px;
  font-weight: 700;
  color: #ffffff;
  margin: 12px 0 8px;
  letter-spacing: -0.02em;
}

.changelog-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
}

.changelog-timeline {
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.release-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 32px;
}

.release-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.release-version-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.version-tag {
  font-size: 18px;
  font-weight: 700;
  color: var(--accent-cyan);
}

.release-date {
  font-size: 12px;
  color: var(--text-muted);
}

.release-title {
  font-size: 16px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 12px;
}

.release-body p {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
  margin-bottom: 14px;
}

.release-list {
  padding-left: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.6;
}
</style>
