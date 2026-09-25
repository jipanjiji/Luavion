<template>
  <div class="legal-page">
    <div class="container legal-container">
      <div class="legal-header">
        <span class="badge badge-subtle">LEGAL COMPLIANCE</span>
        <h1 class="legal-title">Terms of Service</h1>
        <p class="legal-date">Last Updated: September 2026 • Version 9.15</p>
      </div>

      <div class="surface legal-content">
        <section class="legal-section">
          <h2>1. Acceptance of Terms</h2>
          <p>
            By accessing or using Luavion ("the Platform"), including our web studio, public REST APIs, and command-line interfaces, you agree to be bound by these Terms of Service. If you do not agree to these terms, you must discontinue use of the Platform immediately.
          </p>
        </section>

        <section class="legal-section">
          <h2>2. Description of Service & Intellectual Property</h2>
          <p>
            Luavion provides high-assurance Lua 5.1 and Roblox Luau bytecode virtualization, cryptographic geometric attestation, and anti-tamper code hardening. You retain all ownership and copyright rights to the original Lua source scripts you submit to the Platform. Luavion claims zero ownership rights over user-submitted code.
          </p>
        </section>

        <section class="legal-section">
          <h2>3. Acceptable Use Policy</h2>
          <p>
            You agree not to use Luavion to protect, distribute, or execute:
          </p>
          <ul>
            <li>Malicious software, remote access trojans (RATs), credential stealers, or ransomware.</li>
            <li>Code designed to attack, disrupt, or exploit network infrastructure or third-party computing systems.</li>
            <li>Scripts that violate applicable local or international laws and regulations.</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>4. Subscription Tiers & Quota Accounting</h2>
          <p>
            Paid subscriptions (Plus, Pro, Ultra) are billed on a recurring monthly cycle. Obfuscations are accounted on a per-compilation basis against your monthly limit. Unused monthly quota does not roll over; however, purchased Pay-As-You-Go quota top-up credits never expire.
          </p>
        </section>

        <section class="legal-section">
          <h2>5. Public REST API Terms (Ultra Plan)</h2>
          <p>
            Ultra customers are granted access to programmatic REST API endpoints. You are responsible for safeguarding your secret API keys. Sharing API keys or exceeding the 60 requests per minute rate limit may result in temporary throttling or key suspension.
          </p>
        </section>

        <section class="legal-section">
          <h2>6. Limitation of Liability</h2>
          <p>
            Luavion is provided on an "AS IS" and "AS AVAILABLE" basis. While our cryptographic virtual machine is engineered to defeat modern reverse-engineering pipelines and LLM deswitchers, no obfuscation technology guarantees complete impenetrability against all theoretical attack vectors. Luavion shall not be liable for indirect, incidental, or consequential damages resulting from the use or inability to use the Platform.
          </p>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
useHead({
  title: 'Terms of Service | Luavion',
  meta: [
    { name: 'description', content: 'Luavion Terms of Service, licensing, acceptable use policy, and subscription terms.' }
  ]
})
</script>

<style scoped>
.legal-page {
  padding: 64px 0 96px;
  min-height: 80vh;
}

.legal-container {
  max-width: 800px;
}

.legal-header {
  margin-bottom: 36px;
}

.legal-title {
  font-size: 32px;
  font-weight: 600;
  color: #ffffff;
  margin: 12px 0 6px;
  letter-spacing: -0.02em;
}

.legal-date {
  font-size: 12px;
  color: var(--text-muted);
}

.legal-content {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 40px;
  display: flex;
  flex-direction: column;
  gap: 28px;
}

.legal-section h2 {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 10px;
}

.legal-section p,
.legal-section li {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
}

.legal-section ul {
  padding-left: 20px;
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
</style>
