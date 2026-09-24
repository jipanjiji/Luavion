<template>
  <footer class="app-footer">
    <div class="container footer-content">
      <div class="footer-top">
        <!-- Brand & Description -->
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
            Next-generation decentralized register bytecode virtualization for Luau and Lua 5.1 runtimes. Commercial cryptographic protection with zero frame drop impact.
          </p>
          <div class="footer-social-links">
            <a href="https://discord.gg/luavion" target="_blank" rel="noopener noreferrer" class="social-link" title="Join Discord Community">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.929 1.793 8.18 1.793 12.061 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.894.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.028zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
              </svg>
              <span>Discord Community</span>
            </a>
          </div>
        </div>

        <!-- Links Columns -->
        <div class="footer-links-grid">
          <div class="links-col">
            <span class="col-heading">PRODUCT</span>
            <NuxtLink to="/app" class="col-link">Obfuscator Studio</NuxtLink>
            <NuxtLink to="/pricing" class="col-link">Pricing & Plans</NuxtLink>
            <NuxtLink to="/docs/api" class="col-link">Developer REST API</NuxtLink>
            <NuxtLink to="/changelog" class="col-link">Engine Changelog</NuxtLink>
            <NuxtLink to="/status" class="col-link">System Status</NuxtLink>
          </div>

          <div class="links-col">
            <span class="col-heading">ACCOUNT</span>
            <NuxtLink to="/dashboard" class="col-link">Dashboard</NuxtLink>
            <NuxtLink to="/history" class="col-link">Obfuscation History</NuxtLink>
            <NuxtLink to="/billing" class="col-link">Billing & Top-Ups</NuxtLink>
            <NuxtLink to="/keys" class="col-link">API Keys</NuxtLink>
            <NuxtLink to="/settings" class="col-link">Settings</NuxtLink>
          </div>

          <div class="links-col">
            <span class="col-heading">LEGAL & PRIVACY</span>
            <NuxtLink to="/terms" class="col-link">Terms of Service</NuxtLink>
            <NuxtLink to="/privacy" class="col-link">Privacy & Retention</NuxtLink>
            <a href="mailto:security@luavion.com" class="col-link">Security Inquiries</a>
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
  gap: 40px;
}

.footer-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 48px;
  flex-wrap: wrap;
}

.footer-brand-col {
  max-width: 360px;
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
  color: var(--text-muted);
  line-height: 1.6;
  margin-bottom: 16px;
}

.footer-social-links {
  display: flex;
  gap: 12px;
}

.social-link {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 12px;
  padding: 6px 12px;
  border-radius: var(--radius-xs);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  transition: all var(--duration-fast);
}
.social-link:hover {
  color: var(--accent-cyan);
  border-color: var(--accent-cyan);
}

.footer-links-grid {
  display: flex;
  gap: 48px;
  flex-wrap: wrap;
}

.links-col {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.col-heading {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: #ffffff;
  margin-bottom: 4px;
}

.col-link {
  color: var(--text-muted);
  text-decoration: none;
  font-size: 12px;
  transition: color var(--duration-fast);
}
.col-link:hover {
  color: var(--text-primary);
}

.footer-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 24px;
  border-top: 1px solid var(--border-subtle);
  flex-wrap: wrap;
  gap: 16px;
}

.footer-copy {
  font-size: 11px;
  color: var(--text-faint);
}

.footer-tags {
  display: flex;
  gap: 8px;
}

.footer-pill {
  font-size: 10px;
  color: var(--text-muted);
  background: var(--bg-surface-raised);
  border: 1px solid var(--border-subtle);
  padding: 3px 8px;
  border-radius: var(--radius-xs);
}
</style>
