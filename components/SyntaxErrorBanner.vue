<template>
  <div class="syntax-error-banner surface">
    <div class="banner-header">
      <div class="error-badge-title">
        <div class="error-icon-box">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
        </div>
        <div class="error-titles">
          <div class="title-row">
            <span class="error-kind-badge" v-if="syntaxError?.kind">
              {{ syntaxError.kind === 'lexing' ? 'LEXER FAULT' : 'PARSER FAULT' }}
            </span>
            <span class="error-heading">{{ syntaxError?.friendlyTitle || 'Compiler Diagnostic Error' }}</span>
          </div>
          <p class="error-subheading" v-if="syntaxError?.isSyntaxError">
            Syntax parsing failed at <strong class="pos-highlight">Line {{ syntaxError.line }}, Column {{ syntaxError.column }}</strong>. Fix the Lua source before compiling.
          </p>
          <p class="error-subheading" v-else>
            {{ errorMessage || 'Pipeline execution failed.' }}
          </p>
        </div>
      </div>

      <button class="btn btn-ghost btn-sm close-btn" @click="$emit('close')" title="Dismiss diagnostic">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="18" y1="6" x2="6" y2="18"></line>
          <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
      </button>
    </div>

    <!-- Error Context / Code Token Preview -->
    <div class="banner-body" v-if="syntaxError?.context || errorMessage">
      <div v-if="syntaxError?.context" class="context-container">
        <div class="context-header">
          <span class="context-label">OFFENDING TOKEN CONTEXT:</span>
          <span class="token-pos">Line {{ syntaxError.line }}:{{ syntaxError.column }}</span>
        </div>
        <div class="context-code">
          <code>{{ syntaxError.context }}</code>
        </div>
      </div>

      <div class="error-raw-message" v-if="!syntaxError?.context">
        <code>{{ errorMessage }}</code>
      </div>

      <div class="remediation-row" v-if="syntaxError?.line">
        <span class="remediation-icon">💡</span>
        <span class="remediation-text">
          Navigate to <strong>Line {{ syntaxError.line }}</strong> in your input code on the left and check for unmatched brackets, missing <code class="inline-code">then</code> / <code class="inline-code">end</code>, or invalid operators.
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  syntaxError: {
    type: Object,
    default: null
  },
  errorMessage: {
    type: String,
    default: ''
  }
})

defineEmits(['close'])
</script>

<style scoped>
.syntax-error-banner {
  border-radius: var(--radius-md);
  border: 1px solid var(--status-crimson-border);
  background: radial-gradient(circle at 10% 20%, rgba(244, 63, 94, 0.08), transparent 70%), var(--bg-surface-raised);
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(244, 63, 94, 0.15), var(--surface-highlight);
  animation: slideDown 250ms var(--ease-spring);
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.banner-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 14px 18px;
  border-bottom: 1px solid rgba(244, 63, 94, 0.15);
  gap: 14px;
}

.error-badge-title {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.error-icon-box {
  width: 28px;
  height: 28px;
  border-radius: var(--radius-xs);
  background: var(--status-crimson-dim);
  border: 1px solid var(--status-crimson-border);
  color: var(--status-crimson);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 0 12px rgba(244, 63, 94, 0.3);
}

.error-titles {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.error-kind-badge {
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 2px 6px;
  border-radius: var(--radius-xs);
  background: var(--status-crimson-dim);
  border: 1px solid var(--status-crimson-border);
  color: var(--status-crimson);
}

.error-heading {
  font-size: 13px;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.01em;
}

.error-subheading {
  font-size: 11px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.pos-highlight {
  color: var(--status-crimson);
}

.close-btn {
  padding: 4px;
  color: var(--text-muted);
}

.close-btn:hover {
  color: #ffffff;
}

.banner-body {
  padding: 12px 18px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  background: rgba(5, 8, 14, 0.4);
}

.context-container {
  background: var(--bg-void);
  border: 1px solid rgba(244, 63, 94, 0.2);
  border-radius: var(--radius-xs);
  padding: 10px 14px;
}

.context-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.context-label {
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}

.token-pos {
  font-size: 10px;
  color: var(--status-crimson);
  font-weight: 600;
}

.context-code {
  font-family: var(--font-mono);
  font-size: 12px;
  color: #fca5a5;
  white-space: pre-wrap;
  word-break: break-all;
}

.error-raw-message {
  font-family: var(--font-mono);
  font-size: 11px;
  color: #fca5a5;
  background: var(--bg-void);
  padding: 8px 12px;
  border-radius: var(--radius-xs);
  border: 1px solid rgba(244, 63, 94, 0.2);
}

.remediation-row {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 11px;
  color: var(--text-secondary);
  background: rgba(255, 255, 255, 0.02);
  padding: 8px 12px;
  border-radius: var(--radius-xs);
  border: 1px solid var(--border-faint);
}

.remediation-icon {
  flex-shrink: 0;
}

.remediation-text strong {
  color: #ffffff;
}

.inline-code {
  font-family: var(--font-mono);
  background: rgba(255, 255, 255, 0.08);
  padding: 1px 4px;
  border-radius: 3px;
  color: var(--accent-cyan);
}
</style>
