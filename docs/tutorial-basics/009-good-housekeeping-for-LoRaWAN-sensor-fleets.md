---
sidebar_position: 9
title: Structure Your Data
---

# Good Housekeeping for Data Structures

This guide is an attempt to help you step neatly past a major mistake I made when first getting into deploying LoRaWAN sensors: **Bolloxing up my data structures.**

In the madly exciting journey of actually getting a sensor to connect to the [MetSci LNS](https://console.meteoscientific.com/front/) and then send me data, I added all that data higgledy-piggeldy, using `Distance` or `distance` or `meters` or whatever set of units I had at the time for whatever sensor I was deploying.

This worked at the onesy-twosy level, but as I started adding more sensors and building databases to store the data, it bit me in the ass.

Let the bite marks on my ass be a guide to you. While scars add character, you don’t have to replicate all of mine.

This guide focuses on best practices for writing, modifying, and debugging LoRaWAN codecs to ensure clean, consistent, and reliable data processing. These principles help prevent common issues when integrating with databases like InfluxDB or visualizing data in applications.

---

## **Why Structured Data Matters (Engineer Answer)**

1. **Scalability**: As you add more devices, consistent structures simplify integration and maintenance.  
2. **Compatibility**: Adopting standardized fields and tags minimizes schema conflicts in databases like InfluxDB.  
3. **Query Efficiency**: Well-structured tags and fields enable faster and more precise queries.

---

### Cardinality Considerations (Nerd Talk)

Cardinality refers to the number of unique values a tag or field can have in your database. While tags are indexed in InfluxDB for fast querying, high-cardinality tags (e.g., unique `devEui` values for thousands of devices) can significantly impact database performance.

This may not be a problem for most of us, as "high cardinality" only becomes an issue when you have hundreds of thousands of unique tag values.

#### Why Cardinality Matters
1. **Storage Overhead**: Each unique combination of tags creates a new series in InfluxDB, increasing storage requirements.  
2. **Query Performance**: High-cardinality tags slow down queries because the database must search through a larger index.  
3. **Management Complexity**: Excessively granular tags make it harder to maintain consistent schemas.

#### Rules of Thumb for High Cardinality
1. **Small Deployments (10–1,000 Devices)**  
   - Using `device_id` or `devEui` as tags is acceptable.  
   - Use broader tags like `sensor_type` or `region` to group data logically.

2. **Medium Deployments (1,000–10,000 Devices)**  
   - Avoid `devEui` as a tag unless necessary for querying.  
   - Consider grouping devices by broader categories (e.g., `region`, `building_id`).

3. **Large Deployments (10,000+ Devices)**  
   - Avoid high-cardinality tags entirely.  
   - Store unique metadata (e.g., `device_id`) in external systems or as fields.

#### Best Practices
- Use high-cardinality tags like `devEui` only when you frequently filter or group data by individual devices.  
- Favor low-cardinality tags such as `region` or `sensor_type` for broader groupings.  
- Move metadata that rarely changes (e.g., `firmware_version`, `manufacturer`) into fields or external metadata stores.

---

## **Inspiration From Six Real LoRaWAN Payloads**

To illustrate consistent naming, consider the following top-level fields from **six sample LoRaWAN payloads** commonly seen on the MetSci LNS. This structure helps ensure each payload is parsed and stored in a standardized way:

### Common Top-Level Fields

1. **deduplicationId**  
2. **time**  
3. **deviceInfo**  
   - `tenantId`, `tenantName`, `applicationId`, `applicationName`,  
   - `deviceProfileId`, `deviceProfileName`, `deviceName`,  
   - `devEui`, `deviceClassEnabled`, `tags`  
4. **devAddr**  
5. **adr**  
6. **dr**  
7. **fCnt**  
8. **fPort**  
9. **confirmed**  
10. **data**  
11. **object** (contains sensor readings; may vary by device)  
12. **rxInfo** (array detailing gateways, RSSI, SNR, etc.)  
13. **txInfo** (frequency, modulation, etc.)

### Example Device Payload Structures

- **LDDS75** (Liquid Level Sensor):  
  - `object` includes keys like `Distance`, `TempC_DS18B20`, `log.distance`, etc.
- **AM319** (Indoor Conditions Sensor):  
  - `object` includes `pm2.5`, `co2`, `lightLevel`, `temperature`, etc.
- **S2120** (Weather Station):  
  - `object` includes `wind_speed`, `barometric_pressure`, `air_temperature`, etc.
- **Senzemo SMC30 Stick**:  
  - *No top-level `object`*; raw data is in `data`.  
- **PIR Sensor**:  
  - `object` includes `capacity`, `roomStatusTime`, `roomStatusOccupied`, etc.
- **Water Leak Sensor**:  
  - `object` includes `waterLeakage`, `temperature`, `humidity`, etc.

This consistency makes it easier to write and maintain decoders, store data in databases, and query for sensor metrics.

---

## **Planned Tags and Fields**

For InfluxDB or other time-series databases, plan your structure around tags (metadata for grouping/ filtering) and fields (actual measurements). Even if you’re not using InfluxDB, this general approach applies well to other databases.

### **Tags Table**
Tags provide metadata about each measurement and are ideal for filtering and grouping data.

| **Tag**             | **Description**                                                           |
|---------------------|---------------------------------------------------------------------------|
| `devEui`           | Unique identifier for each sensor                                         |
| `device_name`      | Human-readable name of the device                                         |
| `firmware_version` | For tracking device firmware                                              |
| `label`            | Context-specific label for the device                                     |
| `location`         | Physical location of the sensor (e.g., "Office")                          |
| `sensor_type`      | Device type (e.g., "AM319", "LDDS75", "PIR", "S2120")                     |
| `tenant_id`        | Identifier for the tenant owning the device                               |
| `network`          | The network the sensor is part of (e.g., "helium_iot")                    |
| `gateway_id`       | Identifier of the gateway forwarding the data                             |
| `gateway_name`     | Human-readable name of the gateway                                        |
| `gateway_location` | Physical location of the gateway (lat, long)                              |
| `region`           | LoRaWAN region configuration (e.g., "US915")                              |
| `hardware_mode`    | Specific hardware configuration or mode (e.g., "CLASS_A", "LT22222")       |
| `work_mode`        | Operational mode of the device                                            |
| `parking_status`   | Parking availability status (e.g., "FREE", "OCCUPIED")                    |
| `schema_version`   | For tracking data structure changes                                       |
| `status_changed`   | Indicates if a status change occurred                                     |

### **Fields Table**
Fields store the actual sensor readings and vary by sensor type. Below are some examples inspired by the payloads above.

| **Field**                 | **Type** | **Unit** | **Description**                              |
|--------------------------|----------|----------|----------------------------------------------|
| `battery_voltage`        | Float    | V        | Battery voltage (e.g., from LDDS75 or PIR)   |
| `distance`               | Integer  | mm       | Distance measurement (LDDS75)                |
| `air_humidity`           | Float    | %        | Air humidity (AM319, S2120)                  |
| `air_temperature`        | Float    | °C       | Air temperature (AM319, S2120)               |
| `co2`                    | Float    | ppm      | CO2 concentration (AM319)                    |
| `light_level`            | Integer  | lux      | Light level measurement (AM319)              |
| `pm10`                   | Float    | µg/m³    | PM10 concentration (AM319)                   |
| `pm2_5`                  | Float    | µg/m³    | PM2.5 concentration (AM319)                  |
| `pressure`               | Integer  | Pa       | Atmospheric pressure (S2120)                 |
| `wind_speed`             | Float    | m/s      | Wind speed (S2120)                           |
| `wind_direction_sensor`  | Float    | degrees  | Wind direction (S2120)                       |
| `rain_gauge`             | Float    | mm       | Rain gauge reading (S2120)                   |
| `temperature`            | Float    | °C       | Basic temperature reading (could be from PIR or Water Leak) |
| `roomStatusOccupied`     | Boolean  | N/A      | Occupancy status (PIR)                       |
| `water_leakage`          | Boolean  | N/A      | Leak status (Water Leak Sensor)              |
| `rssi`                   | Integer  | dBm      | Signal strength                              |
| `snr`                    | Float    | dB       | Signal-to-noise ratio                       |

---

## **Example Data Structure for InfluxDB**

Below is a sample representation of how you might structure one of your sensor payloads (for example, a S2120 Weather Station) when sending it to InfluxDB:

```json
{
  "measurement": "sensor_measurements",
  "tags": {
    "devEui": "6081f905e7de05d7",
    "device_name": "S2120 - Sensecap WX 001",
    "location": "Field",
    "sensor_type": "S2120",
    "tenant_id": "2f78609d-a859-41b9-8d19-2c06e2edd5b4",
    "network": "helium_iot",
    "gateway_id": "112kwtzsie4hAujhtyjPuZdRZ8kKLvLqhXn63wuyDqkxFN2Q7noo",
    "gateway_name": "acidic-punch-copperhead",
    "region": "US915",
    "hardware_mode": "CLASS_A",
    "work_mode": "default",
    "parking_status": "FREE",
    "status_changed": true
  },
  "fields": {
    "wind_speed": 0.0,
    "air_humidity": 37.0,
    "barometric_pressure": 100160.0,
    "light_intensity": 0.0,
    "uv_index": 0.0,
    "air_temperature": 12.6,
    "rain_gauge": 0.0,
    "wind_direction_sensor": 302.0,
    "rssi": -114,
    "snr": -6.0
  },
  "timestamp": "2025-01-06T04:24:41.409Z"
}
```

This example is based on the fields from the **S2120** Weather Station payload. Notice how we are using the top-level metadata (like `region`, `network`, etc.) as tags and the sensor readings (like `air_temperature`, `wind_speed`, and `snr`) as fields.

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
            devEui: "0004a30b012d3577",
            sensor_type: "SMC30",
            tenant_id: "2f78609d-a859-41b9-8d19-2c06e2edd5b4",
            region: "US915",
            lastUpdated: currentTime
        };
        setMetadataCache(metadataCache); // Save updated metadata
    }

    // Decode dynamic measurements
    const measurements = {
        // Hypothetical Senzemo SMC30 decoding
        // Suppose input.bytes = [0xAA, 0xE2, 0x10, ...]
        // Typically you'd parse actual sensor data here
        some_measurement: 42,
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
1. **Metadata Cache**: A local storage object holds metadata like `tenant_id` and `sensor_type`.  
2. **Periodic Refresh**: Metadata is refreshed only when its cache has expired (e.g., every 24 hours).  
3. **Dynamic Measurements**: Each uplink includes only the dynamic measurements, reducing payload size.

### Advantages
- Reduces repetitive transmission of static data.  
- Improves uplink efficiency and database storage.

---

## **Workflow for Aligning Codec Output to Best Practices**

1. **Design Your Schema**: Use the above tag and field guidelines (plus the top-level fields from real sensor payloads) as your reference.  
2. **Adapt the Codec**: Modify your ChirpStack codec to output JSON that matches your schema (paying attention to consistent naming for `object` fields like `distance`, `air_humidity`, etc.).  
3. **Test with Sample Payloads**: Verify that your output adheres to the schema using ChirpStack’s uplink debugger or Node-RED debug nodes.  
4. **Validate in Database**: Send test payloads to your InfluxDB instance and run queries to ensure the data is stored and indexed correctly.

---

By following these practices, you’ll create a reliable and scalable system for managing and analyzing your LoRaWAN sensor fleet.

:::note Advanced Topic
For large deployments with very different sensor types, you might consider splitting your data into multiple measurements (e.g., `weather_measurements`, `parking_measurements`). This requires more complex codec design but can provide better data organization and query performance. Start with the single measurement approach and refactor if needed.
:::

## **Data Structure Planning**

### Small Deployments (1–100 devices)
- Use a simple, flat data structure.  
- Store all metadata as tags.  
- Example implementation:
```json
{
  "measurement": "sensor_data",
  "tags": {
    "devEui": "a84041d000000001",
    "location": "office",
    "sensor_type": "AM319"
  },
  "fields": {
    "air_temperature": 22.5,
    "air_humidity": 65
  }
}
```

### Medium Deployments (100–1,000 devices)
- Group devices by type and location.  
- Use hierarchical tags.  
- Consider separating metadata to reduce cardinality.  
- Example implementation:
```json
{
  "measurement": "environmental_sensors",
  "tags": {
    "region": "west",
    "building": "HQ",
    "floor": "3",
    "sensor_type": "AM319"
  },
  "fields": {
    "air_temperature": 22.5,
    "air_humidity": 65,
    "devEui": "a84041d000000001" // Moved to field to reduce tag cardinality
  }
}
```

### Large Deployments (1,000+ devices)
- Separate measurements by sensor type.  
- Use external metadata store for rarely changing info.  
- Implement data retention policies.  
- Example implementation:
```json
// Main data measurement
{
  "measurement": "temperature_sensors",
  "tags": {
    "region": "west",
    "sensor_group": "environmental"
  },
  "fields": {
    "value": 22.5,
    "devEui": "a84041d000000001",
    "metadata_version": "2024.1"
  }
}

// Separate metadata store (updated less frequently)
{
  "measurement": "device_metadata",
  "tags": {
    "devEui": "a84041d000000001",
    "sensor_type": "AM319"
  },
  "fields": {
    "location": "HQ-3F-Room301",
    "install_date": "2024-01-15",
    "firmware": "1.2.3",
    "calibration_date": "2024-01-01"
  }
}
```

### Key Scaling Considerations
1. **Data Volume Management**  
   - Implement downsampling for historical data.  
   - Use retention policies based on data importance.  
   - Consider multi-tier storage solutions.

2. **Query Optimization**  
   - Index frequently queried tags.  
   - Use time-based partitioning.  
   - Implement query caching where appropriate.

3. **Metadata Management**  
   - Store static metadata separately.  
   - Version control your metadata.  
   - Implement metadata update procedures.

4. **Monitoring and Maintenance**  
   - Track database size and growth.  
   - Monitor query performance.  
   - Set up alerts for anomalies.

---

## **Implementing in the MetSci Chirpstack Console**

Once you've planned your data structure using these guidelines—and referenced real payloads like **LDDS75**, **AM319**, **S2120**, **Senzemo SMC30**, **PIR**, and **Water Leak** sensors—see our [Metrics & Decoders guide](/docs/tutorial-basics/007-metrics-on-chirpstack.md) for detailed implementation steps in ChirpStack or other LoRaWAN servers.
