// Input: msg.payload contains the JSON structure
const data = msg.payload;

// Validate required fields
if (!data.measurement || !data.tags || !data.fields) {
    node.error("Missing required fields in payload: 'measurement', 'tags', or 'fields'");
    return null;
}

// Prepare InfluxDB payload
const measurement = data.measurement;
const tags = data.tags;
const fields = data.fields;
let timestamp = data.timestamp;

// Convert timestamp to a numeric format if it exists
if (timestamp) {
    timestamp = new Date(timestamp).getTime(); // Convert to milliseconds since epoch
}

// Build the InfluxDB point
const influxPoint = {
    measurement: measurement,
    tags: {},
    fields: {},
};

// Add tags
for (const [key, value] of Object.entries(tags)) {
    influxPoint.tags[key] = value.toString(); // Convert all tags to strings
}

// Add fields
for (const [key, value] of Object.entries(fields)) {
    if (typeof value === "boolean") {
        influxPoint.fields[key] = value ? 1 : 0; // Convert boolean to 1/0
    } else {
        influxPoint.fields[key] = value;
    }
}

// Add timestamp if available
if (timestamp) {
    influxPoint.timestamp = timestamp; // InfluxDB expects time in nanoseconds
}

// Set output payload for InfluxDB output node
msg.payload = influxPoint;

// Debugging: Uncomment the next line to log the point
// node.warn(influxPoint);

return msg;
