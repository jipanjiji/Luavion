import { getUser } from '../utils/auth'

export default defineEventHandler(async (event) => {
  // Attach user to event context if available
  const user = await getUser(event)
  if (user) {
    event.context.user = user
  }
})
