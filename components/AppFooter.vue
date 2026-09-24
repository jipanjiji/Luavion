<template>
  <footer class="app-footer">
    <div class="container footer-content">
      <div class="footer-top">
        <div class="footer-brand-col">
          <div class="footer-brand">
            <div class="footer-logo">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
                <polyline points="2 17 12 22 22 17"></polyline>
                <polyline points="2 12 12 17 22 12"></polyline>
              </svg>
            </div>
            <span class="footer-brand-title">LUAVION</span>
            <span class="badge badge-cyan">v9.15.0</span>
          </div>
          <p class="footer-mission">
            Next-generation decentralized register bytecode virtualization for Luau and Lua 5.1 runtimes. Cryptographic geometric attestation with zero frame drop impact.
          </p>
        </div>

        <div class="footer-stats-col">
          <div class="telemetry-card surface">
            <div class="telemetry-header">
              <span class="telemetry-title">SECURITY ATTESTATION</span>
              <span class="pulse-indicator">
                <span class="dot-core"></span>
                <span class="dot-ring"></span>
              </span>
            </div>
            <div class="telemetry-grid">
              <div class="telemetry-item">
                <span class="item-lbl">TARGET RUNTIME</span>
                <span class="item-val">Roblox Luau / 5.1</span>
              </div>
              <div class="telemetry-item">
                <span class="item-lbl">DISPATCH ISA</span>
                <span class="item-val item-val-cyan">Galois Dynamic</span>
              </div>
              <div class="telemetry-item">
                <span class="item-lbl">AI PROMPT SHIELD</span>
                <span class="item-val item-val-emerald">Zero-Width Active</span>
              </div>
              <div class="telemetry-item">
                <span class="item-lbl">ATTESTATION</span>
                <span class="item-val">Vector3 Invariant</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="footer-bottom">
        <div class="footer-copy">
          <span>&copy; 2026 Luavion Security Systems. Commercial High-Assurance Code Virtualization.</span>
        </div>
        <div class="footer-tags">
          <span class="footer-pill">Production Ready</span>
          <span class="footer-pill">Ephemeral Sandbox</span>
          <span class="footer-pill">Roblox Compatible</span>
        </div>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.app-footer {
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-void);
  padding: 56px 0 32px;
  position: relative;
}

.footer-content {
  display: flex;
  flex-direction: column;
  gap: 36px;
}

.footer-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 32px;
  flex-wrap: wrap;
}

.footer-brand-col {
  max-width: 480px;
}

.footer-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 14px;
}

.footer-logo {
  width: 26px;
  height: 26px;
  border-radius: var(--radius-xs);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-regular);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent-cyan);
}

.footer-brand-title {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #ffffff;
}

.footer-mission {
  font-size: 12px;
  line-height: 1.6;
  color: var(--text-secondary);
}

.footer-stats-col {
  flex-shrink: 0;
}

.telemetry-card {
  padding: 16px;
  border-radius: var(--radius-md);
  min-width: 320px;
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
}

.telemetry-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.telemetry-title {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}

.telemetry-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.telemetry-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.item-lbl {
  font-size: 9px;
  letter-spacing: 0.05em;
  color: var(--text-faint);
  font-weight: 600;
}

.item-val {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-primary);
}

.item-val-cyan {
  color: var(--accent-cyan);
}

.item-val-emerald {
  color: var(--status-emerald);
}

.footer-bottom {
  border-top: 1px solid var(--border-faint);
  padding-top: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  font-size: 11px;
  color: var(--text-muted);
}

.footer-tags {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.footer-pill {
  font-size: 10px;
  padding: 2px 7px;
  border-radius: var(--radius-xs);
  background: var(--bg-surface);
  border: 1px solid var(--border-faint);
  color: var(--text-muted);
}

@media (max-width: 768px) {
  .telemetry-card {
    min-width: 100%;
  }
}
</style>
