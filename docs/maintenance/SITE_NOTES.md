For any new images:

If it's a tutorial or documentation image (screenshots, diagrams, etc.) → put it in /static/images/

If it's a brand asset, icon, or UI element → put it in /static/img/

Latest Updates

### Standard Image Styling

For consistency across the site, use this format for images in documentation and tutorials:

```jsx
<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/path/to/your-image.png"
    alt="Descriptive alt text for accessibility"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>
```

Key points:
- Tutorial/documentation images go in `/static/images/`
- Brand assets and UI elements go in `/static/img/`
- Always include descriptive alt text
- The styling provides:
  - Centered layout with margin
  - Responsive width (100% up to 800px max)
  - Rounded corners (8px radius)
  - MeteoScientific brand-colored border
  - Subtle orange-tinted shadow
