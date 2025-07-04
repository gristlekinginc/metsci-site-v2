# MeteoScientific Documentation

This is the official documentation site for MeteoScientific, providing comprehensive guides and documentation for the [MeteoScientific Chirpstack Console](https://console.meteoscientific.com/front/).

## About

This documentation is built using [Docusaurus](https://docusaurus.io/) and deployed via Vercel. The site provides:
- Setup guides for LoRaWAN devices
- Best practices for sensor deployment
- ChirpStack configuration tutorials
- Device management documentation

## Site Notes
For any new images:

If it's a tutorial or documentation image (screenshots, diagrams, etc.) → put it in /static/images/

If it's a brand asset, icon, or UI element → put it in /static/img/


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

## Contributing

If you find any errors (impossible) or would like to suggest improvements (inconceiveable) to our documentation:

1. Submit an issue describing the problem or suggestion
2. Or contact us via the Contact page on the MetSci site.

## Contact

For technical support or questions about the documentation, you can open an issue or join the [Gristleking Discord](https://discord.gg/PAjUSky9Hp) and post in the #meteoscientific channel.
