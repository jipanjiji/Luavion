<template>
  <div class="app-root">
    <NuxtLayout>
      <NuxtPage :transition="{ name: 'page', mode: 'out-in' }" />
    </NuxtLayout>
    <PlanUpgradeModal />
    <AppToast />
    <div class="bg-grid-overlay"></div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'
import AppToast from '~/components/AppToast.vue'
import PlanUpgradeModal from '~/components/PlanUpgradeModal.vue'

const router = useRouter()

const handleKeyDown = (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
    e.preventDefault()
    if (router.currentRoute.value.path === '/app') {
      router.push('/')
    } else {
      router.push('/app')
    }
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
})
</script>

<style>
.app-root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  position: relative;
}

.app-root > .bg-grid-overlay {
  position: fixed;
  z-index: -1;
}
</style>
