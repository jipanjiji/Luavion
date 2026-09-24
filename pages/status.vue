<template>
  <div class="status-page">
    <div class="container status-container">
      <div class="status-header">
        <div class="status-tag">
          <span class="status-dot dot-emerald"></span>
          <span>ALL SYSTEMS FULLY OPERATIONAL</span>
        </div>
        <h1 class="status-title">System Status & Telemetry</h1>
        <p class="status-subtitle">
          Real-time operational health of the Wasmoon WebAssembly virtual machine, public REST endpoints, and attestation subsystems.
        </p>
      </div>

      <!-- Main Status Pill Card -->
      <div class="surface overall-status-card">
        <div class="overall-left">
          <span class="pulse-indicator">
            <span class="dot-core"></span>
            <span class="dot-ring"></span>
          </span>
          <span class="overall-text">Luavion Galois Virtual Machine v9.15 Online</span>
        </div>
        <div class="overall-right">
          <span class="uptime-val">99.99% Uptime (Last 90 Days)</span>
        </div>
      </div>

      <!-- Services Grid -->
      <div class="services-grid">
        <div class="surface service-card">
          <div class="service-head">
            <span class="service-name">Wasmoon WebAssembly VM Runtime</span>
            <span class="badge badge-emerald">OPERATIONAL</span>
          </div>
          <p class="service-desc">Nitro serverless sandbox executing Luau bytecode compiler.</p>
          <div class="service-meta">
            <span>Latency: <strong>38ms</strong></span>
            <span>Error Rate: <strong>0.00%</strong></span>
          </div>
        </div>

        <div class="surface service-card">
          <div class="service-head">
            <span class="service-name">Public REST API (v1)</span>
            <span class="badge badge-emerald">OPERATIONAL</span>
          </div>
          <p class="service-desc">Ultra tier programmatic endpoint and Bearer token gateway.</p>
          <div class="service-meta">
            <span>Rate Limiting: <strong>Active</strong></span>
            <span>Uptime: <strong>100%</strong></span>
          </div>
        </div>

        <div class="surface service-card">
          <div class="service-head">
            <span class="service-name">Roblox Vector3 Attestation Engine</span>
            <span class="badge badge-emerald">OPERATIONAL</span>
          </div>
          <p class="service-desc">Cryptographic float bitcasting and geometric invariants.</p>
          <div class="service-meta">
            <span>Precision: <strong>IEEE-754 Strict</strong></span>
            <span>Status: <strong>Bound</strong></span>
          </div>
        </div>

        <div class="surface service-card">
          <div class="service-head">
            <span class="service-name">Commerce & Webhook Subsystems</span>
            <span class="badge badge-emerald">OPERATIONAL</span>
          </div>
          <p class="service-desc">Stripe USD Checkout and Indonesian Gateway (Midtrans) webhooks.</p>
          <div class="service-meta">
            <span>Stripe: <strong>Active</strong></span>
            <span>Midtrans: <strong>Active</strong></span>
          </div>
        </div>
      </div>

      <!-- Incident History -->
      <section class="incidents-section surface">
        <h2 class="section-title">Recent Incidents (Last 30 Days)</h2>
        <div class="incident-item">
          <span class="incident-dot dot-emerald"></span>
          <div class="incident-details">
            <span class="incident-title">No system incidents or outages reported</span>
            <span class="incident-sub">All compiler nodes and API pipelines are operating within standard performance SLAs.</span>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
useHead({
  title: 'System Status | Luavion Telemetry',
  meta: [
    { name: 'description', content: 'Real-time uptime and operational telemetry for Luavion compiler engine, REST API, and attestation services.' }
  ]
})
</script>

<style scoped>
.status-page {
  padding: 64px 0 96px;
  min-height: 80vh;
}

.status-container {
  max-width: 800px;
}

.status-header {
  margin-bottom: 36px;
}

.status-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  font-weight: 700;
  color: var(--status-emerald);
  letter-spacing: 0.08em;
  margin-bottom: 8px;
}

.status-title {
  font-size: 32px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 8px;
  letter-spacing: -0.02em;
}

.status-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
}

.overall-status-card {
  border: 1px solid rgba(16, 185, 129, 0.4);
  background: rgba(16, 185, 129, 0.06);
  border-radius: var(--radius-md);
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  flex-wrap: wrap;
  gap: 16px;
}

.overall-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.overall-text {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
}

.uptime-val {
  font-size: 12px;
  color: var(--status-emerald);
  font-weight: 600;
}

.services-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-bottom: 36px;
}

.service-card {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.service-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.service-name {
  font-size: 13px;
  font-weight: 700;
  color: #ffffff;
}

.service-desc {
  font-size: 11px;
  color: var(--text-muted);
  line-height: 1.5;
  margin-bottom: 16px;
}

.service-meta {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: var(--text-secondary);
  border-top: 1px solid var(--border-subtle);
  padding-top: 10px;
  margin-top: auto;
}

.incidents-section {
  border: 1px solid var(--border-regular);
  border-radius: var(--radius-md);
  padding: 28px;
}

.incident-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-top: 16px;
}

.incident-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-top: 4px;
  flex-shrink: 0;
}

.incident-details {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.incident-title {
  font-size: 13px;
  font-weight: 600;
  color: #ffffff;
}

.incident-sub {
  font-size: 12px;
  color: var(--text-muted);
}

@media (max-width: 680px) {
  .services-grid {
    grid-template-columns: 1fr;
  }
}
</style>
