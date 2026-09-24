<template>
  <div class="legal-page">
    <div class="container legal-container">
      <div class="legal-header">
        <span class="badge badge-emerald">SECURITY & PRIVACY</span>
        <h1 class="legal-title">Privacy Policy & Data Retention</h1>
        <p class="legal-date">Effective: September 2026 • Luavion Security Infrastructure</p>
      </div>

      <div class="surface legal-content">
        <section class="legal-section">
          <h2>1. Proprietary Code Confidentiality</h2>
          <p>
            We recognize that the Lua scripts submitted to Luavion frequently contain trade secrets, custom game state logic, combat algorithms, and commercial anti-cheat mechanisms. Luavion treats all user-submitted source code as strictly confidential. Your source code is never used to train machine learning models, never shared with third parties, and never logged in plaintext.
          </p>
        </section>

        <section class="legal-section">
          <h2>2. Data Retention Policy by Subscription Tier</h2>
          <p>
            Data retention is enforced strictly according to your active subscription plan:
          </p>
          <div class="retention-table-wrap">
            <table class="retention-table">
              <thead>
                <tr>
                  <th>Plan Tier</th>
                  <th>Source Script Processing</th>
                  <th>Protected Output Retention</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><strong>Free</strong></td>
                  <td>Ephemeral (In-memory WebAssembly only)</td>
                  <td><strong>0 Days (Not Stored)</strong></td>
                </tr>
                <tr>
                  <td><strong>Plus</strong></td>
                  <td>Ephemeral compilation</td>
                  <td><strong>7 Days</strong> (Purged automatically)</td>
                </tr>
                <tr>
                  <td><strong>Pro</strong></td>
                  <td>Ephemeral compilation</td>
                  <td><strong>30 Days</strong> (Purged automatically)</td>
                </tr>
                <tr>
                  <td><strong>Ultra</strong></td>
                  <td>Ephemeral compilation</td>
                  <td><strong>90 Days</strong> (Purged automatically)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="legal-section">
          <h2>3. Cryptographic Storage of API Keys</h2>
          <p>
            API secret tokens are generated using cryptographically secure pseudorandom entropy. Luavion never stores secret API keys in plaintext. Only salted SHA-256 hashes are persisted in our database for authentication lookup. If an API key is revoked or an account is deleted, the hash is permanently expunged.
          </p>
        </section>

        <section class="legal-section">
          <h2>4. User Rights & Account Erasure</h2>
          <p>
            You have the right to permanently delete your Luavion account and all associated metadata, cloud history records, and custom presets at any time through the <NuxtLink to="/settings" class="link-cyan">Account Settings</NuxtLink> page. Account deletion requires two-factor phrase verification and executes an immediate hard cascade delete across all database tables.
          </p>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
useHead({
  title: 'Privacy Policy & Data Retention | Luavion',
  meta: [
    { name: 'description', content: 'Luavion Privacy Policy: strict code confidentiality, tier-based data retention policies, and cryptographic security.' }
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
  font-weight: 700;
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
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 10px;
}

.legal-section p {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.7;
}

.retention-table-wrap {
  margin-top: 14px;
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-xs);
  overflow-x: auto;
}

.retention-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.retention-table th,
.retention-table td {
  padding: 10px 14px;
  text-align: left;
  border-bottom: 1px solid var(--border-subtle);
}

.retention-table th {
  background: var(--bg-surface-raised);
  font-size: 10px;
  font-weight: 700;
  color: var(--text-muted);
}

.link-cyan {
  color: var(--accent-cyan);
  text-decoration: underline;
}
</style>
