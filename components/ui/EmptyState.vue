<template>
  <div class="ui-empty">
    <div v-if="$slots.icon" class="ui-empty-icon">
      <slot name="icon" />
    </div>
    <p class="ui-empty-title">{{ title }}</p>
    <p v-if="message" class="ui-empty-msg">{{ message }}</p>
    <div v-if="$slots.default" class="ui-empty-action">
      <slot />
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  message: { type: String, default: '' },
})
</script>

<style scoped>
.ui-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 48px 24px;
}

.ui-empty-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  color: var(--text-muted);
  margin-bottom: 16px;
}

.ui-empty-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.ui-empty-msg {
  font-size: 13px;
  color: var(--text-muted);
  max-width: 340px;
  line-height: 1.6;
}

.ui-empty-action { margin-top: 18px; }
</style>
