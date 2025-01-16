import posthog from 'posthog-js'

export const initPostHog = () => {
  if (typeof window !== 'undefined') { // Check if we're in the browser
    posthog.init(
      process.env.POSTHOG_API_KEY,
      {
        api_host: 'https://us.i.posthog.com',
        person_profiles: 'identified_only'
      }
    )
  }
}