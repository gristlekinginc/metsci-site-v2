import posthog from 'posthog-js'

export const initPostHog = () => {
  if (typeof window !== 'undefined' && process.env.NODE_ENV === 'production') {
    posthog.init(process.env.POSTHOG_API_KEY, {
      api_host: 'https://us.i.posthog.com',
      capture_pageview: true,
      persistence: 'localStorage'
    })
  }
}