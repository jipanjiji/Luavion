import { onMounted, onBeforeUnmount } from 'vue'

export function useReveal() {
  let observer = null

  onMounted(() => {
    if (!import.meta.client) return
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      document.querySelectorAll('.reveal').forEach(el => el.classList.add('is-visible'))
      return
    }
    observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible')
          observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' })

    document.querySelectorAll('.reveal:not(.is-visible)').forEach(el => observer.observe(el))
  })

  onBeforeUnmount(() => observer?.disconnect())
}
