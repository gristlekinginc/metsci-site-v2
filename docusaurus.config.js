// @ts-check

// Load environment variables from .env file
require('dotenv').config(); // This line loads the environment variables from your .env file

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'MetSci',
  tagline: 'Integrating Sensors Into Your World',
  favicon: 'img/metsci_favicon.ico',
  url: 'https://www.meteoscientific.com',
  baseUrl: '/',
  organizationName: 'gristlekinginc',
  projectName: 'metsci-site-v2',
  deploymentBranch: 'main',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/gristlekinginc/metsci-site-v2/tree/main/', 
        },
        blog: {
          path: './blog', 
          routeBasePath: 'blog',
          showReadingTime: true,
          feedOptions: {
            type: 'all',
          },
          editUrl: 'https://github.com/gristlekinginc/metsci-site-v2/tree/main/', 
          blogSidebarCount: 'ALL',
          blogSidebarTitle: 'All Blog Posts',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/metsci_200x200.png',
      navbar: {
        title: 'MeteoScientific',
        logo: {
          alt: 'MetSci Logo',
          src: 'img/metsci_logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Tutorials',
          },
          { to: '/pricing', label: 'Pricing', position: 'left' }, 
          { to: 'https://console.meteoscientific.com/front/login', label: 'Console', position: 'left' },
          {
            href: 'https://github.com/gristlekinginc/metsci-site-v2', 
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      metadata: [
        { name: 'og:image', content: '/img/meteoscientific-social-card_1200x630.png' },
        { name: 'twitter:card', content: 'summary_large_image' },
      ],
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Tutorials',
                to: '/docs/tutorial-basics/LoRaWAN-Big-Picture',
              },
              {
                label: 'YouTube',
                href: 'https://www.youtube.com/@meteoscientific',
              },
              {
                label: 'Blog',
                href: '/blog',
              },  
            ],
          },
          {
            title: 'Moar',
            items: [
              {
                label: 'About',
                to: '/about',
              },
              {
                label: 'FAQ',
                href: '/faq',
              }, 
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'Discord',
                href: 'https://discord.gg/4fR5QAq6Vc',
              },
              {
                label: 'Twitter',
                href: 'https://x.com/meteoscientific',
              },
              {
                label: 'Donate',
                href: '/donate',
              },
            ],
          },
          {
            title: 'Owned By',
            items: [
              {
                label: 'X',
                to: 'https://x.com/thegristleking',
              },
              {
                label: 'LinkedIn',
                href: 'https://www.linkedin.com/in/nikhawks/', 
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} MeteoScientific, Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;
