---
sidebar_position: 7
title: "Setting Up Metrics & Decoders"
---

# Setting Up Metrics & Decoders

This guide walks you through the practical steps of configuring decoders and measurements in ChirpStack. Before diving in, we recommend reading our [Data Structure Planning Guide](/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md) to understand how to organize your data effectively.

## Prerequisites

Before starting, ensure you have:
- A MileSight AM319 device added to your ChirpStack.
- Basic understanding of ChirpStack console navigation.
> Note: You can use any device you'd like, the AM319 is just the demo I have handy for this.

## Step 1: Planning Your Data Structure
1. Review the [Data Structure Planning Guide](/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md)
2. Identify which measurements you need
3. Decide on your tag structure
4. Plan your field names and types

## Step 2: Implementing in ChirpStack

### Configuring Device Profiles
1. Navigate to Device Profiles
2. Add or modify codec based on your planned structure
3. Configure measurements to match your data plan

### Setting Up Measurements
1. Define measurements using consistent naming from your plan
2. Configure correct measurement types:
   - Use `gauge` for continuous values (temperature, humidity)
   - Use `string` for status values (occupancy)
   - Use `counter` for cumulative values

### Example Implementation
Here's a real-world example using the AM319 indoor air quality sensor:

```javascript
// Codec by MeteoScientific
// Feel free to share and modify as needed
// https://www.meteoscientific.com

function decodeUplink(input) {
    const bytes = input.bytes;
    let decoded = {};
    let i = 0;

    while (i < bytes.length) {
        const channel = bytes[i++];
        const type = bytes[i++];

        try {
            switch (channel) {
                case 0x03: // Air Temperature
                    if (type !== 0x67) throw "Unexpected type for Temperature";
                    decoded.air_temperature = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 10.0).toFixed(1));  // in °C
                    i += 2;
                    break;

                case 0x04: // Air Humidity
                    if (type !== 0x68) throw "Unexpected type for Humidity";
                    decoded.air_humidity = parseFloat((bytes[i++] / 2.0).toFixed(1));  // in %
                    break;

                case 0x05: // PIR status (Occupied / Vacant)
                    if (type !== 0x00) throw "Unexpected type for PIR Status";
                    decoded.occupancy_status = (bytes[i++] === 1) ? "Occupied" : "Vacant";
                    break;

                case 0x06: // Light level
                    if (type !== 0xCB) throw "Unexpected type for Light Level";
                    const llIndex = bytes[i++];
                    const luxRanges = [
                        [0, 5],
                        [6, 50],
                        [51, 100],
                        [101, 500],
                        [501, 2000],
                        [2001, 99999],
                    ];
                    if (llIndex < luxRanges.length) {
                        const [lower, upper] = luxRanges[llIndex];
                        const avgValue = (lower + upper) / 2;
                        decoded.light_level = parseFloat(avgValue.toFixed(1));  // in lux
                    } else {
                        decoded.light_level = 0.0;  // Explicit float
                    }
                    break;

                case 0x07: // CO2
                    if (type !== 0x7D) throw "Unexpected type for CO2";
                    decoded.co2 = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 100.0).toFixed(2));  // in ppm
                    i += 2;
                    break;

                case 0x08: // TVOC
                    if (type !== 0x7D) throw "Unexpected type for TVOC";
                    decoded.tvoc = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 100.0).toFixed(2));  // in ppm
                    i += 2;
                    break;

                case 0x09: // Pressure
                    if (type !== 0x73) throw "Unexpected type for Pressure";
                    decoded.barometric_pressure = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 10.0).toFixed(1));  // in hPa
                    i += 2;
                    break;

                case 0x0B: // PM2.5
                    if (type !== 0x7D) throw "Unexpected type for PM2.5";
                    decoded.pm2_5 = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 100.0).toFixed(2));  // in µg/m³
                    i += 2;
                    break;

                case 0x0C: // PM10
                    if (type !== 0x7D) throw "Unexpected type for PM10";
                    decoded.pm10 = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 100.0).toFixed(2));  // in µg/m³
                    i += 2;
                    break;

                case 0x0D: // O3
                    if (type !== 0x7D) throw "Unexpected type for O3";
                    decoded.o3 = parseFloat(((bytes[i] | (bytes[i + 1] << 8)) / 100.0).toFixed(2));  // in ppm
                    i += 2;
                    break;

                default:
                    console.warn("Ignoring unknown channel: " + channel);
                    break;
            }
        } catch (err) {
            console.warn("Error decoding channel " + channel + ": " + err);
        }
    }

    return { data: decoded };
}
```

Example output from a real device:
```json
{
    "data": {
        "air_temperature": 19.1,
        "air_humidity": 59.5,
        "occupancy_status": "Vacant",
        "light_level": 2.5,
        "co2": 5.04,
        "tvoc": 1.00,
        "barometric_pressure": 1005.6,
        "pm2_5": 0.43,
        "pm10": 0.72,
        "o3": 0.07
    }
}
```

This example demonstrates:
- Domain-specific field naming (`air_temperature`, `air_humidity` for air quality sensors)
- Consistent unit handling (°C, %, ppm, µg/m³, hPa)
- Error handling for malformed payloads
- InfluxDB-compatible data types:
  - All numerical values as explicit floats with appropriate decimal places
  - String values for status fields
- Type validation for each channel

## Step 3: Testing and Verification

To expedite testing, you may want to adjust the uplink interval on your device so that it sends data more frequently. This allows for quicker debugging and verification of your setup.

## Configured, Congrats!

Following these steps, you should now have your MileSight AM319 device correctly configured within ChirpStack, with device metrics and measurements properly displayed. This guide also provides a basic workflow for troubleshooting and modifying device codecs using tools like ChatGPT.

For any questions or further assistance, feel free to reach out or consult the relevant documentation.

