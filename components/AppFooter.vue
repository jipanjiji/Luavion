<template>
  <footer class="app-footer">
    <div class="container footer-content">
      <div class="footer-top">
        <div class="footer-brand-col">
          <NuxtLink to="/" class="footer-brand mono">
            <img src="/logo.png" alt="" class="footer-logo" width="22" height="22" />
            luavion<span class="brand-cursor" aria-hidden="true"></span>
          </NuxtLink>
          <p class="footer-mission">
            Next-generation bytecode virtualization for Luau and Lua 5.1.
            Commercial-grade protection with zero frame-drop impact.
          </p>
          <a href="https://discord.gg/luavion" target="_blank" rel="noopener noreferrer" class="social-link">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.929 1.793 8.18 1.793 12.061 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.894.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.028zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
            </svg>
            Discord
          </a>
        </div>

        <div class="footer-links-grid">
          <div class="links-col">
            <span class="col-heading">Product</span>
            <NuxtLink to="/app" class="col-link">Obfuscate</NuxtLink>
            <NuxtLink to="/pricing" class="col-link">Pricing</NuxtLink>
            <NuxtLink to="/docs/api" class="col-link">API Reference</NuxtLink>
            <NuxtLink to="/changelog" class="col-link">Changelog</NuxtLink>
            <NuxtLink to="/status" class="col-link col-status">
              <span class="status-dot dot-emerald" aria-hidden="true"></span>Status
            </NuxtLink>
          </div>

          <div class="links-col">
            <span class="col-heading">Account</span>
            <NuxtLink to="/dashboard" class="col-link">Dashboard</NuxtLink>
            <NuxtLink to="/history" class="col-link">History</NuxtLink>
            <NuxtLink to="/billing" class="col-link">Billing</NuxtLink>
            <NuxtLink to="/keys" class="col-link">API Keys</NuxtLink>
            <NuxtLink to="/settings" class="col-link">Settings</NuxtLink>
          </div>

          <div class="links-col">
            <span class="col-heading">Legal</span>
            <NuxtLink to="/terms" class="col-link">Terms of Service</NuxtLink>
            <NuxtLink to="/privacy" class="col-link">Privacy Policy</NuxtLink>
            <a href="mailto:security@luavion.com" class="col-link">Security</a>
          </div>
        </div>
      </div>

      <div class="footer-bottom">
        <span class="footer-copy">&copy; 2026 Luavion Security Systems</span>
        <span class="footer-tag mono">ephemeral sandbox · zero-retention</span>
      </div>
    </div>
  </footer>
</template>

<script setup>
</script>

<style scoped>
.app-footer {
  border-top: 1px solid var(--border-subtle);
  background: var(--bg-void);
  padding: 64px 0 32px;
}

.footer-content {
  display: flex;
  flex-direction: column;
  gap: 48px;
}

.footer-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 48px;
  flex-wrap: wrap;
}

.footer-brand-col { max-width: 320px; }

.footer-brand {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: var(--text-primary);
  margin-bottom: 14px;
}

.footer-logo {
  width: 22px;
  height: 22px;
  object-fit: contain;
  border-radius: 5px;
  display: block;
}

.brand-cursor {
  display: inline-block;
  width: 7px;
  height: 14px;
  margin-left: 3px;
  background: var(--text-primary);
  animation: blink 1.1s steps(2, start) infinite;
}

@keyframes blink { to { visibility: hidden; } }

.footer-mission {
  font-size: 13px;
  color: var(--text-muted);
  line-height: 1.7;
  margin-bottom: 18px;
}

.social-link {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: var(--text-secondary);
  font-size: 12px;
  font-weight: 500;
  padding: 7px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-subtle);
  transition: all var(--duration-fast) var(--ease-out);
}

.social-link:hover {
  color: var(--text-primary);
  border-color: var(--border-hover);
}

.footer-links-grid {
  display: flex;
  gap: 64px;
  flex-wrap: wrap;
}

.links-col { display: flex; flex-direction: column; gap: 10px; }

.col-heading {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--text-faint);
  margin-bottom: 4px;
}

.col-link {
  color: var(--text-muted);
  font-size: 13px;
  transition: color var(--duration-fast) var(--ease-out);
}

.col-link:hover { color: var(--text-primary); }

.col-status { display: inline-flex; align-items: center; gap: 8px; }

.footer-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 24px;
  border-top: 1px solid var(--border-faint);
  flex-wrap: wrap;
  gap: 12px;
}

.footer-copy { font-size: 12px; color: var(--text-faint); }

.footer-tag {
  font-size: 10px;
  letter-spacing: 0.06em;
  color: var(--text-faint);
  text-transform: uppercase;
}

@media (max-width: 640px) {
  .footer-top { flex-direction: column; gap: 32px; }
  .footer-links-grid { gap: 32px; }
  .app-footer { padding: 48px 0 24px; }
}
</style>
