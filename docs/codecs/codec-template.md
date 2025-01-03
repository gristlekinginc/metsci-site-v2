---
sidebar_position: 3
title: Codec Template
description: Template for creating new codec documentation
tags:
  - template
  - guide
---

# Device Codec Template

Use this template when adding new device codecs to the documentation.

```markdown
---
sidebar_position: 1
title: [Manufacturer] [Model]
description: [Brief description]
tags:
  - [manufacturer]
  - [sensor type]
  - [measurement type]
---

# [Manufacturer] [Model] Codec

Brief description of the device and its primary use case.

## Codec Implementation

```javascript
// Codec implementation here
```

## Output Format

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `field_name` | Type | Unit | Description |

## Sample Output

```json
{
    "sample": "output"
}
```

## Device Configuration

Configuration instructions or link to configuration guide.

## Additional Resources
- [Data Structure Guidelines](/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets)
- [Device Manual](link)
- [Manufacturer Website](link)
``` 