<template>
  <div class="app-root">
    <!-- Top Global Sticky Navbar -->
    <AppHeader />

    <!-- Main Page Content With Transition -->
    <main class="app-main">
      <NuxtPage />
    </main>

    <!-- Global Engineered Footer -->
    <AppFooter />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'

const router = useRouter()

// Global keyboard shortcut: Cmd+K / Ctrl+K jumps to Studio / Home
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

<style scoped>
.app-root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: var(--bg-void);
  position: relative;
}

.app-main {
  flex: 1;
  display: flex;
  flex-direction: column;
}
</style>
