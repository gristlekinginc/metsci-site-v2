import React from 'react';
// Importing the original mapper + our components according to the Docusaurus doc
import MDXComponents from '@theme-original/MDXComponents';
import Button from '@site/src/components/Button';
import ConsoleButton from '@site/src/components/ConsoleButton';

export default {
  // Reusing the default mapping
  ...MDXComponents,
  Button,
  ConsoleButton,
}; 