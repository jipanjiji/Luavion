<template>
  <div
    class="ui-tabs"
    role="tablist"
    :aria-label="label"
    @keydown.left.prevent="move(-1)"
    @keydown.right.prevent="move(1)"
  >
    <button
      v-for="(item, i) in items"
      :key="item.value"
      class="ui-tab mono"
      :class="{ active: modelValue === item.value }"
      role="tab"
      :aria-selected="modelValue === item.value"
      :tabindex="modelValue === item.value ? 0 : -1"
      :ref="el => tabRefs[i] = el"
      @click="$emit('update:modelValue', item.value)"
    >
      {{ item.label }}
      <span v-if="item.count !== undefined" class="ui-tab-count">{{ item.count }}</span>
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  items: { type: Array, required: true },
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, default: 'Tabs' },
})

const emit = defineEmits(['update:modelValue'])

const tabRefs = ref([])

const move = (dir) => {
  const idx = props.items.findIndex(i => i.value === props.modelValue)
  const next = (idx + dir + props.items.length) % props.items.length
  emit('update:modelValue', props.items[next].value)
  tabRefs.value[next]?.focus()
}
</script>

<style scoped>
.ui-tabs {
  display: inline-flex;
  gap: 2px;
  background: var(--bg-base);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-md);
  padding: 3px;
}

.ui-tab {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: transparent;
  border: none;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 500;
  padding: 7px 14px;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all var(--duration-fast) var(--ease-out);
  white-space: nowrap;
  min-height: 32px;
}

.ui-tab:hover { color: var(--text-secondary); }

.ui-tab.active {
  background: var(--bg-elevated);
  color: var(--text-primary);
  box-shadow: var(--shadow-sm), inset 0 1px 0 rgba(255, 255, 255, 0.06);
}

.ui-tab-count {
  font-size: 10px;
  color: var(--text-faint);
  background: var(--bg-overlay);
  border-radius: var(--radius-full);
  padding: 1px 6px;
}

.ui-tab.active .ui-tab-count { color: var(--text-muted); }

@media (max-width: 640px) {
  .ui-tabs { display: flex; width: 100%; overflow-x: auto; }
  .ui-tab { flex: 1; justify-content: center; }
}
</style>
