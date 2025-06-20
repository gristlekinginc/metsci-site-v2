import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import InfoPanes from '@site/src/components/InfoPanes';
import CustomFooter from '@site/src/components/CustomFooter';
import OptimizedImage from '@site/src/components/OptimizedImage';

import Heading from '@theme/Heading';
import styles from './index.module.css';
import taglines from '@site/src/data/taglines';

function getTagline(section) {
  return taglines[section] || taglines.default;
}

function HomepageHeader() {
  return (
    <header className="hero">
      <img 
        src="/img/ms_pro_lettertype_white.svg" 
        alt="MeteoScientific" 
        className="hero__overlay"
      />
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Crush with ${siteConfig.title}`}
      description={getTagline('tutorials')}>
      <HomepageHeader />
      <main>
        <InfoPanes />
      </main>
      <CustomFooter />
    </Layout>
  );
}
