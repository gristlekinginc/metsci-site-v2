---
sidebar_position: 1
title: Overview
description: Guide to MetSci's codec library organization and usage
---

# Codec Library Overview

Welcome to the MeteoScientific Codec Library. This collection of codecs is organized to help you quickly find and implement the right decoder for your sensor.

Many of these codecs are available in the [MetSci Console](https://console.meteoscientific.com/front/), where you can easily import them when in your account.

![Choosing from a template in the MetSci Console](/images/codecs/device-profile-templates.png)

## Organization
Our codecs are organized by manufacturer and sensor type, making it easy to find exactly what you need. Each codec includes:
- Brief sensor description
- Manufacturer and type tags
- Ready-to-use codec implementation

For best practices on implementing these codecs, see our [Data Structure Guidelines](/docs/tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets).

## Finding Codecs
You can find codecs by:
1. **Manufacturer**: Dragino, Milesight, Seeed Studio, etc.
2. **Sensor Type**: Weather, Soil Moisture, Air Quality, etc.
3. **Search**: Use the search bar above to find specific sensors

## Adding New Codecs
Contributing a new codec? Use our [Codec Template](./codec-template) to ensure consistent documentation. 