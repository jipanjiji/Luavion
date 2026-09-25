export default defineNuxtRouteMiddleware(async (to, from) => {
  // Routes that require authentication
  const protectedRoutes = ['/app', '/dashboard', '/history', '/keys', '/billing', '/settings', '/admin']
  const isProtected = protectedRoutes.some(p => to.path === p || to.path.startsWith(`${p}/`))

  if (isProtected) {
    const { isAuthenticated, fetchUser, user } = useUser()

    // If user state is not loaded yet, fetch it
    if (!isAuthenticated.value) {
      await fetchUser()
    }

    // If still not authenticated, redirect to /login
    if (!isAuthenticated.value) {
      return navigateTo({
        path: '/login',
        query: { redirect: to.fullPath }
      })
    }

    // Restrict admin panel to admin role
    if (to.path.startsWith('/admin') && user.value?.role !== 'admin') {
      return navigateTo('/dashboard')
    }
  }

  // If user is already authenticated and visits /login, redirect to /dashboard
  if (to.path === '/login') {
    const { isAuthenticated } = useUser()
    if (isAuthenticated.value) {
      return navigateTo('/dashboard')
    }
  }
})
