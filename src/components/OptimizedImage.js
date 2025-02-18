import React from 'react';
import ThemedImage from '@theme/ThemedImage';

export default function OptimizedImage({src, alt, width, height}) {
  return (
    <ThemedImage
      sources={{
        light: src,
        dark: src
      }}
      alt={alt}
      loading="eager"
      width={width}
      height={height}
      style={{
        aspectRatio: `${width} / ${height}`,
        objectFit: 'contain'
      }}
    />
  );
} 