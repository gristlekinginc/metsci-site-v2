---
title: Workflow for Metsci Upgrade
description: Step-by-step guide for upgrading and standardizing data in MetSci
---
# Workflow for Standardizing Data Structure in MetSci

## Step 1: Assess Your Current State

### Review Existing Payloads:
- Identify all device types and the payloads they send.
- For each device:
  - Collect sample uplinks (you can use the Events tab for this).
  - Document the structure, units, and fields present in the payload.

### Map Current Codec Coverage:
- Review existing codecs for each device type.
- Check if any codecs are incomplete, outdated, or inconsistent with the new structure.
- Note gaps (e.g., missing fields, inconsistent naming).

---

## Step 2: Define Your Standardized Structure

### Create a Unified Tag and Field Schema:
- Use the tags and fields table from the `.md` file as your baseline.
- Decide on naming conventions (e.g., `temperature` instead of `temp`).
- Standardize units (e.g., `°C` for temperature, `ppm` for gas concentrations).

### Plan for Metadata Sharing:
- Identify metadata (e.g., `tenant_id`, `region`, `device_id`) that should be consistent across codecs.
- Ensure tags represent static data and fields represent dynamic measurements.

---

## Step 3: Re-Write the Codec

### Test the Existing Codec:
- Run a sample payload through the current codec in the ChirpStack Codec Debugger.
- Note where the output deviates from the standard structure.

### Re-Write the Codec:
- Edit the codec to align with the standardized structure.
- Include:
  - **Tag extraction**: Map static metadata into tags.
  - **Field extraction**: Convert dynamic payload data into fields with standardized names and units.
- Use clear comments to document each section of the codec.

### Validate the New Codec:
- Test the updated codec with various sample payloads in the ChirpStack Codec Debugger.
- Verify that:
  - All expected fields and tags are present.
  - Units and data types are correct.

---

## Step 4: Deploy the Codec

### Make the Codec Tenant-Agnostic:
- Remove any tenant-specific logic (e.g., hardcoded tenant IDs or regions).
- Use dynamic extraction based on the payload or device metadata.

### Associate the Codec with Device Profiles:
- Go to the **Device Profiles** in MetSci.
- Assign the new codec to each profile that uses the corresponding device type.

### Test in Production:
- Send live payloads from devices to verify they are correctly decoded in MetSci.
- Check the application integration (e.g., Node-RED or InfluxDB) for proper output.

---

## Step 5: Share the Codec

### Document the Codec:
- Write clear documentation for the codec, explaining:
  - Input format (e.g., raw payload structure).
  - Output format (tags and fields).
  - Any assumptions or limitations.

### Publish the Codec:
- Add the codec to a shared repository or tenant-wide accessible location in MetSci
- Optionally, contribute it to the open-source community or post it in forums like GitHub or ChirpStack discussions.

---

## Step 6: Monitor and Iterate

### Monitor Data Consistency:
- Periodically review incoming data for anomalies or inconsistencies.
- Run queries in your database (e.g., InfluxDB) to check for schema alignment.

### Iterate as New Devices Are Added:
- Use the standardized workflow to onboard new devices and codecs.
- Ensure they adhere to the schema from the start.

---

## Key Notes:
- **Start Small**: Begin with one device type and scale as you refine the process.
- **Reuse Logic**: Write modular functions in your codec for common transformations (e.g., unit conversions, metadata extraction).
- **Cross-Tenant Compatibility**: Ensure all device profiles and applications across tenants use the same schema.
