/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    {
      type: 'category',
      label: 'Tutorial Basics',
      items: [
        'tutorial-basics/LoRaWAN-Big-Picture',
        'tutorial-basics/intro-to-console',
        'tutorial-basics/device-profiles',
        'tutorial-basics/set-up-applications',
        'tutorial-basics/adding-a-device',
        'tutorial-basics/metrics-on-chirpstack',
        'tutorial-basics/configure-a-device',
        'tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets',
        'tutorial-basics/chirpstack-integrations',
      ],
    },
    {
      type: 'category',
      label: 'Tutorial Extras',
      items: [
        'tutorial-extras/documentation',
        'tutorial-extras/class_C_kuando_busylight',
        'tutorial-extras/Google_Sheets',
        'tutorial-extras/metsci-demo-dash',
        'tutorial-extras/spreading-factor-chirps',
      ],
    },
    {
      type: 'category',
      label: 'Special Projects',
      items: [
        'special-projects/nanotags',
      ],
    },
    {
      type: 'category',
      label: 'Codec Library',
      items: [
        'codecs/overview',
        {
          type: 'category',
          label: 'Codecs',
          items: ['codecs/codecs/dragino-ldds75'],
        },
      ],
    },
  ],
};

export default sidebars;
