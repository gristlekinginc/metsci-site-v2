---
sidebar_position: 1
title: Dragino LDDS75
description: Distance/Level Detection Sensor
tags:
  - dragino
  - distance
  - level
  - liquid level
  - temperature
---

# Dragino LDDS75 Distance Sensor

The LDDS75 is a LoRaWAN ultrasonic distance/level detection sensor. It provides accurate, non-contact measurement of distance or liquid levels up to 75cm, with optional temperature monitoring. Perfect for tank level monitoring, bin fill measurement, or any application requiring precise distance sensing.  

It's not precisely accurate; if you're fine with a 6-8 inch variance this is a great solution.  I've used 'em in the [Vernal Pools Project](https://gristleking.com/how-to-measure-endangered-vernal-pool-depth-using-the-helium-network/)

## Features
- Distance measurement range: 0-75cm
- Temperature monitoring (optional)
- Battery voltage monitoring
- Interrupt and sensor status reporting
- Class A LoRaWAN device

## Codec Implementation

```javascript
// Codec by MeteoScientific
// Feel free to share and modify as needed
// meteoscientific.com

function decodeUplink(input) {
    var decoded = {};

    try {
        var bytes = input.bytes;
        
        // Battery Voltage (naturally a float)
        var batValue = (bytes[0] << 8 | bytes[1]) & 0x3FFF;
        decoded.battery_voltage = parseFloat((batValue / 1000).toFixed(3));  // in V

        // Distance (naturally an integer in mm)
        decoded.distance = bytes[2] << 8 | bytes[3];  // in mm

        // Temperature if present (naturally an integer in °C)
        if (bytes.length > 6) {
            var tempValue = (bytes[5] << 8 | bytes[6]);
            decoded.temperature = (tempValue & 0x8000) ? tempValue - 0x10000 : tempValue;  // in °C
        }

        // Status flags as booleans
        if (bytes.length > 4) {
            decoded.interrupt_status = bytes[4] === 1;
        }
        
        if (bytes.length > 7) {
            decoded.sensor_status = bytes[7] === 1;
        }

        return {
            data: decoded
        };
    } catch (err) {
        return {
            errors: [`Decoder error: ${err.message}`]
        };
    }
}
```

## Output Fields

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `battery_voltage` | Float | V | Battery voltage level |
| `distance` | Integer | mm | Measured distance in millimeters |
| `temperature` | Integer | °C | Temperature (if enabled) |
| `interrupt_status` | Boolean | - | Interrupt flag status |
| `sensor_status` | Boolean | - | Sensor operation status |

## Sample Output

```json
{
    "battery_voltage": 3.395,
    "distance": 1248,
    "temperature": 0,
    "interrupt_status": false,
    "sensor_status": true
}
```

## Device Configuration

The LDDS75 can be configured using a USB-TTL adapter. Key configuration options include:
- Measurement interval
- Temperature monitoring enable/disable
- Interrupt thresholds
- LoRaWAN parameters

For detailed configuration instructions, see our [device configuration guide](/docs/tutorial-basics/configure-a-device).

## Additional Resources
- [Data Structure Guidelines](/docs/tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets)
- [Device Manual](https://www.dragino.com/downloads/downloads/LoRa_End_Node/LDDS75/LDDS75_LoRaWAN_User_Manual_v1.1.0.pdf)
- [Manufacturer Website](https://www.dragino.com/products/lora-lorawan-end-node/item/174-ldds75.html)
- [Configuration Guide](/docs/tutorial-basics/configure-a-device) 