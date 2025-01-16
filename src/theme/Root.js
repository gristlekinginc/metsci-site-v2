import React from 'react';
import { initPostHog } from '../utils/posthog';
import { useEffect } from 'react';

export default function Root({children}) {
  useEffect(() => {
    initPostHog();
  }, []);

  return <>{children}</>;
}
