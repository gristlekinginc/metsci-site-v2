---
sidebar_position: 9
title: Structure Your Data
---


# Good Housekeeping for LoRaWAN Sensor Fleets

This guide is an attempt to have you step neatly past a major mistake I made when first getting into deploying LoRaWAN sensors:  Bolloxing up my data structures.

In the madly exciting journey of actually getting a sensor to connect to the [MetSci LNS](https://console.meteoscientific.com/front/) and then send me data, I added all that data higgledy-piggeldy, using `Distance` or `distance` or `meters` or whatever set of units I had at the time for whatever sensor I was deploying.

This worked at the onesy-twosy level, but as I started adding more sensors and building databases to store the data, it bit me in the ass.

Let the bite marks on my ass be a guide to you.  Whiile chicks dig scars, you don't have to replicate all of mine.

This guide focuses on best practices for writing, modifying, and debugging LoRaWAN codecs to ensure clean, consistent, and reliable data processing. These principles help prevent common issues when integrating with databases like InfluxDB or visualizing data in applications.

---

## **Why Structured Data Matter (Engineer Answer)**

1. **Scalability**: As you add more devices, consistent structures simplify integration and maintenance.
2. **Compatibility**: Adopting standardized fields and tags minimizes schema conflicts in databases like InfluxDB.
3. **Query Efficiency**: Well-structured tags and fields enable faster and more precise queries.

---

### Cardinality Considerations

Cardinality refers to the number of unique values a tag or field can have in your database. While tags are indexed in InfluxDB for fast querying, high-cardinality tags (e.g., unique `device_id` for thousands of devices) can significantly impact database performance.

This may not be a problem for most of us; "cardinality" becomes an issue when you have hundreds of thousands of unique tag values.

#### Why Cardinality Matters
1. **Storage Overhead**: Each unique combination of tags creates a new series in InfluxDB, increasing storage requirements.
2. **Query Performance**: High-cardinality tags slow down queries because the database must search through a larger index.
3. **Management Complexity**: Excessively granular tags make it harder to maintain consistent schemas.

#### Rules of Thumb for High Cardinality
1. Small Deployments (10–1,000 Devices):
 - Using device_id or sensor_serial as tags is acceptable.
 - Use broader tags like sensor_type or region to group data logically.

2. Medium Deployments (1,000–10,000 Devices):
 - Avoid device_id as a tag unless necessary for querying.
 - Consider grouping devices by broader categories (e.g., region, building_id).

3. Large Deployments (10,000+ Devices):
 - Avoid high-cardinality tags entirely.
 - Store unique metadata (e.g., device_id) in external systems or as fields.

#### Best Practices
- Use high-cardinality tags like `device_id` only when you frequently filter or group data by individual devices.
- Favor low-cardinality tags such as `region` or `sensor_type` for broader groupings.
- Move metadata that rarely changes (e.g., `firmware_version`, `manufacturer`) into fields or external metadata stores.

## **Planned Tags and Fields**

This is specifically useful for InfluxDB, but even if you're not using that, it's generally useful to think about how you're going to structure you data.

### **Tags Table**
Tags provide metadata about each measurement and are ideal for filtering and grouping data.

| **Tag**               | **Description**                                           |
|------------------------|-----------------------------------------------------------|
| `device_id`            | Unique identifier for each sensor                        |
| `device_name`          | Human-readable name of the device                        |
| `location`             | Physical location of the sensor (e.g., "Office")         |
| `sensor_type`          | Device type (e.g., "AM319", "LDDS75")                    |
| `tenant_id`            | Identifier for the tenant owning the device              |
| `network`              | The network the sensor is part of (e.g., "helium_iot")   |
| `gateway_id`           | Identifier of the gateway forwarding the data            |
| `gateway_name`         | Human-readable name of the gateway                       |
| `gateway_location`     | Physical location of the gateway (lat, long)             |
| `region`               | LoRaWAN region configuration (e.g., "US915")             |
| `hardware_mode`        | Specific hardware configuration or mode (e.g., "LT22222")|
| `work_mode`            | Operational mode of the device                           |
| `parking_status`       | Parking availability status (e.g., "FREE", "OCCUPIED")   |
| `status_changed`       | Indicates if a status change occurred                    |
| `label`                | Context-specific label for the device                    |

### **Fields Table**
Fields store the actual sensor readings and vary by sensor type.

| **Field**                | **Type**  | **Description**                            |
|--------------------------|-----------|--------------------------------------------|
| `aci1_ma`                | Float     | Analog current input 1 (mA)                |
| `air_humidity`           | Float     | Air humidity percentage (%)                |
| `air_temperature`        | Float     | Air temperature (e.g., °C)                 |
| `avi1_v`                 | Float     | Analog voltage input 1 (V)                 |
| `barometric_pressure`    | Integer   | Atmospheric pressure (Pa)                  |
| `battery_voltage`        | Float     | Battery voltage (e.g., V)                  |
| `co2`                    | Float     | CO2 concentration (e.g., ppm)              |
| `distance`               | Integer   | Distance measurement (e.g., mm)            |
| `humidity`               | Float     | Humidity measurement (e.g., %)             |
| `humidity_error`         | Boolean   | Indicates if there is a humidity error     |
| `lastcolor_blue`         | Integer   | Blue color intensity of a busylight        |
| `lastcolor_green`        | Integer   | Green color intensity of a busylight       |
| `lastcolor_red`          | Integer   | Red color intensity of a busylight         |
| `light_level`            | Integer   | Light level measurement (lux)              |
| `pm10`                   | Float     | PM10 concentration (e.g., µg/m³)           |
| `pm2.5`                  | Float     | PM2.5 concentration (e.g., µg/m³)          |
| `pressure`               | Float     | Atmospheric pressure (e.g., hPa)           |
| `rain_gauge`             | Float     | Precipitation amount (e.g., mm)            |
| `rssi`                   | Integer   | Signal strength of the uplink (dBm)        |
| `snr`                    | Float     | Signal-to-noise ratio (dB)                 |
| `temperature`            | Float     | Temperature measurement (e.g., °C)         |
| `temperature_environment`| Float     | Environmental temperature (e.g., °C)       |
| `tvoc`                   | Float     | Total Volatile Organic Compounds (ppm)     |
| `water_leakage`          | Boolean   | Indicates presence of water leakage        |
| `wind_direction_sensor`  | Integer   | Wind direction measurement (degrees)       |
| `wind_speed`             | Float     | Wind speed (e.g., m/s)                     |

---

### **Example Data Structure for InfluxDB**
```json
{
  "measurement": "sensor_measurements",
  "tags": {
    "device_id": "s2120-001",
    "device_name": "Weather Station S2120",
    "location": "Field",
    "sensor_type": "S2120",
    "tenant_id": "tenant-002",
    "network": "helium_iot",
    "gateway_id": "112qN5DMoTdc4ThFGQHKyg4e3QfuEkkCUEfu5EgZA1QZLNdqb4Cf",
    "gateway_name": "amateur-jade-hare",
    "region": "US915",
    "hardware_mode": "LT22222",
    "work_mode": "2ACI+2AVI",
    "parking_status": "FREE",
    "status_changed": true
  },
  "fields": {
    "temperature": 22.5,
    "humidity": 80.2,
    "wind_speed": 5.4,
    "wind_direction_sensor": 45,
    "air_temperature": 11.2,
    "air_humidity": 81,
    "barometric_pressure": 99880,
    "rain_gauge": 0.0,
    "rssi": -97,
    "snr": 4.5,
    "water_leakage": false
  },
  "timestamp": "2025-01-01T01:38:16.699Z"
}
```

---

## **Integrating Metadata Optimization in Codec Design**

### Caching Metadata for Periodic Updates
You can optimize your codec by caching metadata that rarely changes (e.g., `tenant_id`, `region`, `sensor_type`) and refreshing it periodically. Here's an example approach:

```javascript
function decodeUplink(input) {
    let metadataCache = getMetadataCache(); // Retrieve cached metadata
    const currentTime = Date.now();
    const metadataRefreshInterval = 86400000; // 24 hours in milliseconds

    if (!metadataCache || (currentTime - metadataCache.lastUpdated > metadataRefreshInterval)) {
        // Update metadata cache if expired or not present
        metadataCache = {
            device_id: "12345",
            sensor_type: "AM319",
            tenant_id: "tenant-001",
            region: "US915",
            lastUpdated: currentTime,
        };
        setMetadataCache(metadataCache); // Save updated metadata
    }

    // Decode dynamic measurements
    const measurements = {
        temperature: input.bytes[0] + input.bytes[1] / 100,
        humidity: input.bytes[2] + input.bytes[3] / 100,
    };

    // Combine metadata and measurements
    return {
        data: {
            ...metadataCache,
            ...measurements,
        },
    };
}

// Mocked cache functions for demonstration
function getMetadataCache() {
    return JSON.parse(localStorage.getItem("metadataCache"));
}

function setMetadataCache(cache) {
    localStorage.setItem("metadataCache", JSON.stringify(cache));
}
```

### Explanation:
1. **Metadata Cache:** A local storage object holds metadata like `tenant_id` and `sensor_type`.
2. **Periodic Refresh:** Metadata is refreshed only when its cache has expired (e.g., every 24 hours).
3. **Dynamic Measurements:** Each uplink includes only the dynamic measurements, reducing payload size.

### Advantages
- Reduces repetitive transmission of static data.
- Improves uplink efficiency and database storage.

---

## **Workflow for Aligning Codec Output to Best Practices**

1. **Design Your Schema**: Use the above tag and field guidelines as your reference.
2. **Adapt the Codec**: Modify your ChirpStack codec to output JSON that matches your schema.
3. **Test with Sample Payloads**: Verify that your output adheres to the schema using ChirpStack’s uplink debugger or Node-RED debug nodes.
4. **Validate in Database**: Send test payloads to your InfluxDB instance and run queries to ensure the data is stored and indexed correctly.

---

By following these practices, you’ll create a reliable and scalable system for managing and analyzing your LoRaWAN sensor fleet.