---
sidebar_position: 9
title: DRAFT -- Structure Your Data
---
![Draft warning](/images/draft-warning.png)

# Good Housekeeping for LoRaWAN Sensor Fleets

This guide is an attempt to help you step neatly past a major mistake I made when first getting into deploying LoRaWAN sensors:  **Bolloxing up my data structures.**

In the madly exciting journey of actually getting a sensor to connect to the [MetSci LNS](https://console.meteoscientific.com/front/) and then send me data, I added all that data higgledy-piggeldy, using `Distance` or `distance` or `meters` or whatever set of units I had at the time for whatever sensor I was deploying.

This worked at the onesy-twosy level, but as I started adding more sensors and building databases to store the data, it bit me in the ass.

Let the bite marks on my ass be a guide to you.  Whiile chicks dig scars, you don't have to replicate all of mine.

This guide focuses on best practices for writing, modifying, and debugging LoRaWAN codecs to ensure clean, consistent, and reliable data processing. These principles help prevent common issues when integrating with databases like InfluxDB or visualizing data in applications.

---

## **Why Structured Data Matters (Engineer Answer)**

1. **Scalability**: As you add more devices, consistent structures simplify integration and maintenance.
2. **Compatibility**: Adopting standardized fields and tags minimizes schema conflicts in databases like InfluxDB.
3. **Query Efficiency**: Well-structured tags and fields enable faster and more precise queries.

---

### Cardinality Considerations (Nerd Talk)

Cardinality refers to the number of unique values a tag or field can have in your database. While tags are indexed in InfluxDB for fast querying, high-cardinality tags (e.g., unique `deveui` values for thousands of devices) can significantly impact database performance.

This may not be a problem for most of us, as "high cardinality" only becomes an issue when you have hundreds of thousands of unique tag values.

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
|------------------------|----------------------------------------------------------|
| `deveui`               | Unique identifier for each sensor                        |
| `device_name`          | Human-readable name of the device                        |
| `firmware_version`     | For tracking device firmware                             |
| `label`                | Context-specific label for the device                    |
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
| `schema_version`       | For tracking data structure changes                      |
| `status_changed`       | Indicates if a status change occurred                    |



### **Fields Table**
Fields store the actual sensor readings and vary by sensor type.

| **Field**                | **Type**  | **Unit** | **Description** |
|-------------------------|-----------|----------|-----------------|
| `battery_voltage`        | Float     | V        | Battery voltage |
| `distance`              | Integer   | mm       | Distance measurement |
| `air_humidity`          | Float     | %        | Air humidity percentage |
| `air_temperature`       | Float     | °C       | Air temperature |
| `soil_temperature`      | Float     | °C       | Soil temperature |
| `water_temperature`     | Float     | °C       | Water temperature |
| `surface_temperature`   | Float     | °C       | Surface temperature |
| `co2`                   | Float     | ppm      | CO2 concentration |
| `light_level`           | Integer   | lux      | Light level measurement |
| `pm10`                  | Float     | µg/m³    | PM10 concentration |
| `pm2_5`                 | Float     | µg/m³    | PM2.5 concentration |
| `pressure`              | Integer   | Pa       | Atmospheric pressure |
| `rssi`                  | Integer   | dBm      | Signal strength |
| `snr`                   | Float     | dB       | Signal-to-noise ratio |

---

### **Example Data Structure for InfluxDB**
```json
{
  "measurement": "sensor_measurements",
  "tags": {
    "deveui": "BX19skDKS827",
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

:::note Advanced Topic
For large deployments with very different sensor types, you might consider splitting your data into multiple measurements (e.g., `weather_measurements`, `parking_measurements`). This requires more complex codec design but can provide better data organization and query performance. Start with the single measurement approach and refactor if needed.
:::

## Data Structure Planning

### Small Deployments (1-100 devices)
- Use simple, flat data structure
- Store all metadata as tags
- Example implementation:
```javascript
{
    "measurement": "sensor_data",
    "tags": {
        "device_id": "am319_001",
        "location": "office",
        "sensor_type": "AM319"
    },
    "fields": {
        "temperature": 22.5,
        "humidity": 65
    }
}
```

### Medium Deployments (100-1000 devices)
- Group devices by type and location
- Use hierarchical tags
- Consider separating metadata to reduce cardinality
- Example implementation:
```javascript
{
    "measurement": "environmental_sensors",
    "tags": {
        "region": "west",
        "building": "HQ",
        "floor": "3",
        "sensor_type": "AM319"
    },
    "fields": {
        "temperature": 22.5,
        "humidity": 65,
        "device_id": "am319_001"  // Moved to field to reduce tag cardinality
    }
}
```

### Large Deployments (1000+ devices)
- Separate measurements by sensor type
- Use external metadata store
- Implement data retention policies
- Example implementation:
```javascript
// Main data measurement
{
    "measurement": "temperature_sensors",
    "tags": {
        "region": "west",
        "sensor_group": "environmental"
    },
    "fields": {
        "value": 22.5,
        "device_id": "am319_001",
        "metadata_version": "2024.1"
    }
}

// Separate metadata store (updated less frequently)
{
    "measurement": "device_metadata",
    "tags": {
        "device_id": "am319_001",
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
   - Implement downsampling for historical data
   - Use retention policies based on data importance
   - Consider multi-tier storage solutions

2. **Query Optimization**
   - Index frequently queried tags
   - Use time-based partitioning
   - Implement query caching where appropriate

3. **Metadata Management**
   - Store static metadata separately
   - Version control your metadata
   - Implement metadata update procedures

4. **Monitoring and Maintenance**
   - Track database size and growth
   - Monitor query performance
   - Set up alerts for anomalies

## Implementing in ChirpStack
Once you've planned your data structure using these guidelines, see our [Metrics & Decoders guide](/docs/tutorial-basics/007-metrics-on-chirpstack.md) for implementation details.