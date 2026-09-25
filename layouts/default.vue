<template>
  <div>
    <AppHeader />
    <main class="layout-default-main">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>

<script setup>
import AppHeader from '~/components/AppHeader.vue'
import AppFooter from '~/components/AppFooter.vue'
</script>

<style scoped>
.layout-default-main {
  flex: 1;
  display: flex;
  flex-direction: column;
}
</style>
