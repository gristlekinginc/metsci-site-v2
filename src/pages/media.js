import React from 'react';
import Layout from '@theme/Layout';
import styles from './media.module.css';

function MediaAssets() {
  const brandColors = [
    { name: 'Troposphere Red', hex: '#D94A18', class: 'primary' },
    { name: 'Solar Haze', hex: '#FA7F2A', class: 'red' },
    { name: 'Jet Stream Blue', hex: '#18A7D9', class: 'blue' },
    { name: 'Cirrus White', hex: '#FCF5F0', class: 'white' },
    { name: 'Stratosphere Black', hex: '#000000', class: 'black' }
  ];

  const logoSections = [
    {
      title: 'Standard Logos',
      logos: [
        { name: 'Black Logo', image: '/img/metsci_pro_media/MS Black.svg', download: '/img/metsci_pro_media/MS Black@2x.png' },
        { name: 'White Logo', image: '/img/metsci_pro_media/MS White.svg', download: '/img/metsci_pro_media/MS White@2x.png' },
        { name: 'Orange Logo', image: '/img/metsci_pro_media/MS Orange.svg', download: '/img/metsci_pro_media/MS Orange@2x.png' }
      ]
    },
    {
      title: 'Type Logos',
      logos: [
        { name: 'Black Type Logo', image: '/img/metsci_pro_media/MS Type Black.svg', download: '/img/metsci_pro_media/MS Type Black@2x.png' },
        { name: 'White Type Logo', image: '/img/metsci_pro_media/MS Type White.svg', download: '/img/metsci_pro_media/MS Type White@2x.png' },
        { name: 'Orange Type Logo', image: '/img/metsci_pro_media/MS Type Orange.svg', download: '/img/metsci_pro_media/MS Type Orange@2x.png' }
      ]
    },
    {
      title: 'Lettertype Logos',
      logos: [
        { name: 'Black Lettertype', image: '/img/metsci_pro_media/MS Lettertype Black.svg', download: '/img/metsci_pro_media/MS Lettertype Black@2x.png' },
        { name: 'White Lettertype', image: '/img/metsci_pro_media/MS Lettertype White.svg', download: '/img/metsci_pro_media/MS Lettertype White@2x.png' },
        { name: 'Orange Lettertype', image: '/img/metsci_pro_media/MS Lettertype Orange.svg', download: '/img/metsci_pro_media/MS Lettertype Orange@2x.png' },
        { name: 'Orange & Black Lettertype', image: '/img/metsci_pro_media/MS Lettertype Orange and Black.svg', download: '/img/metsci_pro_media/MS Lettertype Orange and Black@2x.png' },
        { name: 'Orange & White Lettertype', image: '/img/metsci_pro_media/MS Lettertype Orange and White.svg', download: '/img/metsci_pro_media/MS Lettertype Orange and White@2x.png' }
      ]
    },
    {
      title: 'Overunder Logos',
      logos: [
        { name: 'Black Overunder', image: '/img/metsci_pro_media/MS Overunder Black.svg', download: '/img/metsci_pro_media/MS Overunder Black@2x.png' },
        { name: 'White Overunder', image: '/img/metsci_pro_media/MS Overunder White.svg', download: '/img/metsci_pro_media/MS Overunder White@2x.png' },
        { name: 'Orange Overunder', image: '/img/metsci_pro_media/MS Overunder Orange.svg', download: '/img/metsci_pro_media/MS Overunder Orange@2x.png' },
        { name: 'Orange & Black Overunder', image: '/img/metsci_pro_media/MS Overunder Orange and Black.svg', download: '/img/metsci_pro_media/MS Overunder Orange and Black@2x.png' },
        { name: 'Orange & White Overunder', image: '/img/metsci_pro_media/MS Overunder Orange and White.svg', download: '/img/metsci_pro_media/MS Overunder Orange and White@2x.png' }
      ]
    }
  ];

  return (
    <Layout title="Media Assets">
      <div className={styles.mediaContainer}>
        <div className={styles.header}>
          <h1>MeteoScientific Media Assets</h1>
          <p className={styles.intro}>
            This is the official MeteoScientific media assets page. Please use these approved assets when working with MeteoScientific.
            All logos are available in both SVG and high-resolution PNG formats.
          </p>
        </div>

        <section className={styles.colorSection}>
          <h2>Brand Colors</h2>
          <div className={styles.colorGrid}>
            {brandColors.map((color) => (
              <div key={color.hex} className={styles.colorCard}>
                <div 
                  className={styles.colorSwatch} 
                  style={{ backgroundColor: color.hex }}
                />
                <div className={styles.colorInfo}>
                  <h3>{color.name}</h3>
                  <p>{color.hex}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {logoSections.map((section) => (
          <section key={section.title} className={styles.logoSection}>
            <h2>{section.title}</h2>
            <div className={styles.logoGrid}>
              {section.logos.map((logo) => (
                <div key={logo.name} className={styles.logoCard}>
                  <div className={styles.logoPreview}>
                    <img src={logo.image} alt={logo.name} />
                  </div>
                  <div className={styles.logoInfo}>
                    <h3>{logo.name}</h3>
                    <div className={styles.downloadLinks}>
                      <a href={logo.image} download>Download SVG</a>
                      <a href={logo.download} download>Download PNG</a>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        ))}
      </div>
    </Layout>
  );
}

export default MediaAssets; 