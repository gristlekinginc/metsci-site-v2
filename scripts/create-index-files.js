const fs = require('fs');
const path = require('path');

const LANGUAGES = {
  ar: {
    label: 'العربية',
    title: 'ميتيوساينتيفيك',
    tagline: 'تبسيط LoRaWAN للتطبيقات العملية'
  },
  zh: {
    label: '中文',
    title: '气象科学',
    tagline: '简化 LoRaWAN 在实际应用中的使用'
  },
  de: {
    label: 'Deutsch',
    title: 'MeteoScientific',
    tagline: 'LoRaWAN für praktische Anwendungen vereinfacht'
  },
  fr: {
    label: 'Français',
    title: 'MeteoScientific',
    tagline: 'Démystifier LoRaWAN pour les applications réelles'
  },
  es: {
    label: 'Español',
    title: 'MeteoScientific',
    tagline: 'Desmitificando LoRaWAN para aplicaciones del mundo real'
  }
};

const indexTemplate = (lang) => `import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">${LANGUAGES[lang].title}</h1>
        <p className="hero__subtitle">${LANGUAGES[lang].tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/tutorial-basics/LoRaWAN-Big-Picture">
            LoRaWAN Tutorial - 5min ⏱️
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description="${LANGUAGES[lang].tagline}">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
`;

const cssTemplate = `/**
 * CSS files with the .module.css suffix will be treated as CSS modules
 * and scoped locally.
 */

.heroBanner {
  padding: 4rem 0;
  text-align: center;
  position: relative;
  overflow: hidden;
}

@media screen and (max-width: 996px) {
  .heroBanner {
    padding: 2rem;
  }
}

.buttons {
  display: flex;
  align-items: center;
  justify-content: center;
}`;

function createIndexFiles() {
  Object.keys(LANGUAGES).forEach(lang => {
    const langDir = path.join(process.cwd(), 'i18n', lang, 'docusaurus-plugin-content-pages');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(langDir)) {
      fs.mkdirSync(langDir, { recursive: true });
    }

    // Create index.js
    const indexPath = path.join(langDir, 'index.js');
    fs.writeFileSync(indexPath, indexTemplate(lang));
    console.log(`✅ Created index.js for ${LANGUAGES[lang].label}`);

    // Create index.module.css
    const cssPath = path.join(langDir, 'index.module.css');
    fs.writeFileSync(cssPath, cssTemplate);
    console.log(`✅ Created index.module.css for ${LANGUAGES[lang].label}`);
  });

  console.log('\n🎉 All index files created successfully!');
}

// Run the script
createIndexFiles();