// @ts-check

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'MeteoScientific',
  tagline: 'Sense & Conquer',
  favicon: 'img/metsci_pro_favicon.svg',
  url: 'https://meteoscientific.com',
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
          blogSidebarCount: 'ALL',
          blogSidebarTitle: 'All Blog Posts',
          sortPosts: 'descending',
          postsPerPage: 'ALL',
          blogListComponent: '@theme/BlogListPage',
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
        { name: 'description', content: 'Sense & Conquer' },
        
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: 'MeteoScientific - The Business of LoRaWAN' },
        { property: 'og:description', content: 'Sense & Conquer' },
        { property: 'og:image', content: 'https://meteoscientific.com/img/metsci-pro-social-card_1200x630.png' },
        { property: 'og:image:secure_url', content: 'https://meteoscientific.com/img/metsci-pro-social-card_1200x630.png' },
        { property: 'og:image:width', content: '1200' },
        { property: 'og:image:height', content: '630' },
        { property: 'og:image:type', content: 'image/png' },
        
        { name: 'twitter:card', content: 'summary_large_image' },
        { name: 'twitter:title', content: 'MeteoScientific - The Business of LoRaWAN' },
        { name: 'twitter:description', content: 'Sense & Conquer' },
        { name: 'twitter:image', content: 'https://meteoscientific.com/img/metsci-pro-social-card-x_800x418.png' },
        
        { property: 'og:site_name', content: 'MeteoScientific' },
        
        { name: 'keywords', content: 'LoRaWAN, business IoT, massive IoT, LPWAN sensors' },
        { name: 'author', content: 'MeteoScientific' },
        
        // SMS/Text Message Preview
        { property: 'og:image:mobile', content: 'https://meteoscientific.com/img/metsci-pro-social-card-sms_300x200.png' },
        { property: 'og:image:mobile:width', content: '300' },
        { property: 'og:image:mobile:height', content: '200' },
        
        // Ensure mobile-first loading
        { property: 'og:image:type', content: 'image/png' },
        { property: 'og:image:alt', content: 'MeteoScientific - The Business of LoRaWAN' },
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
  scripts: [
    {
      src: 'https://www.googletagmanager.com/gtag/js?id=G-VNEKDSD64E',
      async: true,
    },
    {
      src: '/js/ga.js',  // We'll create this file
      async: true,
    },
  ],
  plugins: typeof process !== 'undefined' && process.env.NODE_ENV === 'production' 
    ? [
        [
          "posthog-docusaurus",
          {
            apiKey: process.env.POSTHOG_API_KEY || 'default-key',
            appUrl: "https://us.i.posthog.com",
            loaded: (posthog) => {
              posthog.register({
                $set_once: {
                  environment: process.env.NODE_ENV,
                  source: window.location.hostname
                }
              });
            }
          },
        ],
      ]
    : [],
};

export default config;
