import React from 'react';
import { PostHogProvider } from 'posthog-js/react'

export default function Root({children}) {
  const options = {
    api_host: process.env.POSTHOG_HOST,
  }

  return (
    <PostHogProvider 
      apiKey={process.env.POSTHOG_API_KEY}
      options={options}
    >
      {children}
    </PostHogProvider>
  );
}
