import React from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

const FooterLinksList = [
  {
    title: 'Docs',
    icon: '📚',
    items: [
      {
        label: 'Tutorials',
        to: '/docs/tutorial-basics/LoRaWAN-Big-Picture',
        icon: '🎓'
      },
      {
        label: 'YouTube',
        href: 'https://www.youtube.com/@meteoscientific',
        icon: '📺'
      },
      {
        label: 'Blog',
        href: '/blog',
        icon: '📝'
      },
    ],
  },
  {
    title: 'Moar',
    icon: '⚡',
    items: [
      {
        label: 'About',
        to: '/about',
        icon: '🏢'
      },
      {
        label: 'FAQ',
        href: '/faq',
        icon: '❓'
      },
      {
        label: 'Podcast',
        to: '/podcast',
        icon: '🎙️'
      },
    ],
  },
  {
    title: 'Community',
    icon: '👥',
    items: [
      {
        label: 'Discord',
        href: 'https://discord.gg/4fR5QAq6Vc',
        icon: '💬'
      },
      {
        label: 'X',
        href: 'https://x.com/meteoscientific',
        icon: '🐦'
      },
      {
        label: 'Donate',
        href: '/donate',
        icon: '💝'
      },
    ],
  },
  {
    title: 'Owned By',
    icon: '👑',
    items: [
      {
        label: 'X',
        to: 'https://x.com/thegristleking',
        icon: '🔗'
      },
      {
        label: 'LinkedIn',
        href: 'https://www.linkedin.com/in/nikhawks/',
        icon: '💼'
      },
    ],
  },
  {
    title: 'Resources',
    icon: '🔧',
    items: [
      {
        label: 'Media Assets',
        to: '/media',
        icon: '🎨'
      },
      {
        label: 'Email Sign Up',
        to: '/email-sign-up',
        icon: '📧'
      },
      {
        label: 'Contact',
        to: '/contact',
        icon: '📞'
      },
    ],
  },
];

function FooterSection({ title, icon, items }) {
  return (
    <div className={styles.footerSection}>
      <h3 className={styles.footerSectionTitle}>
        <span className={styles.footerSectionIcon}>{icon}</span>
        {title}
      </h3>
      <ul className={styles.footerLinksList}>
        {items.map((item, idx) => (
          <li key={idx} className={styles.footerLinkItem}>
            {item.to ? (
              <Link to={item.to} className={styles.footerLink}>
                <span className={styles.footerLinkIcon}>{item.icon}</span>
                {item.label}
              </Link>
            ) : (
              <a 
                href={item.href} 
                className={styles.footerLink}
                target="_blank" 
                rel="noopener noreferrer"
              >
                <span className={styles.footerLinkIcon}>{item.icon}</span>
                {item.label}
              </a>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function CustomFooter() {
  return (
    <footer className={styles.customFooter}>
      <div className={styles.footerContainer}>
        {/* Logo Section */}
        <div className={styles.footerBrand}>
          <img 
            src="/img/ms_pro_lettertype_white.svg" 
            alt="MeteoScientific" 
            className={styles.footerLogo}
          />
          <p className={styles.footerTagline}>
            The Business of LoRaWAN
          </p>
        </div>

        {/* Links Grid */}
        <div className={styles.footerLinksGrid}>
          {FooterLinksList.map((section, idx) => (
            <FooterSection key={idx} {...section} />
          ))}
        </div>

        {/* Copyright */}
        <div className={styles.footerBottom}>
          <p className={styles.footerCopyright}>
            Copyright © {new Date().getFullYear()} MeteoScientific. 
            <Link to="/terms-of-service" className={styles.footerLegalLink}>
              Terms
            </Link> | 
            <Link to="/privacy-policy" className={styles.footerLegalLink}>
              Privacy
            </Link>
          </p>
        </div>
      </div>
    </footer>
  );
} 