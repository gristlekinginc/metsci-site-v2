"use strict";(self.webpackChunkmeteoscientific=self.webpackChunkmeteoscientific||[]).push([[470],{4892:(e,n,t)=>{t.r(n),t.d(n,{assets:()=>l,contentTitle:()=>d,default:()=>h,frontMatter:()=>a,metadata:()=>i,toc:()=>c});const i=JSON.parse('{"id":"tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets","title":"DRAFT -- Structure Your Data","description":"Draft warning","source":"@site/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md","sourceDirName":"tutorial-basics","slug":"/tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets","permalink":"/docs/tutorial-basics/good-housekeeping-for-LoRaWAN-sensor-fleets","draft":false,"unlisted":false,"editUrl":"https://github.com/meteoscientific/website/tree/main/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md","tags":[],"version":"current","sidebarPosition":9,"frontMatter":{"sidebar_position":9,"title":"DRAFT -- Structure Your Data"},"sidebar":"tutorialSidebar","previous":{"title":"Configure A Device","permalink":"/docs/tutorial-basics/configure-a-device"},"next":{"title":"Tutorial - Extras","permalink":"/docs/category/tutorial---extras"}}');var s=t(4848),r=t(8453);const a={sidebar_position:9,title:"DRAFT -- Structure Your Data"},d="Good Housekeeping for LoRaWAN Sensor Fleets",l={},c=[{value:"<strong>Why Structured Data Matters (Engineer Answer)</strong>",id:"why-structured-data-matters-engineer-answer",level:2},{value:"Cardinality Considerations (Nerd Talk)",id:"cardinality-considerations-nerd-talk",level:3},{value:"Why Cardinality Matters",id:"why-cardinality-matters",level:4},{value:"Rules of Thumb for High Cardinality",id:"rules-of-thumb-for-high-cardinality",level:4},{value:"Best Practices",id:"best-practices",level:4},{value:"<strong>Planned Tags and Fields</strong>",id:"planned-tags-and-fields",level:2},{value:"<strong>Tags Table</strong>",id:"tags-table",level:3},{value:"<strong>Fields Table</strong>",id:"fields-table",level:3},{value:"<strong>Example Data Structure for InfluxDB</strong>",id:"example-data-structure-for-influxdb",level:3},{value:"<strong>Integrating Metadata Optimization in Codec Design</strong>",id:"integrating-metadata-optimization-in-codec-design",level:2},{value:"Caching Metadata for Periodic Updates",id:"caching-metadata-for-periodic-updates",level:3},{value:"Explanation:",id:"explanation",level:3},{value:"Advantages",id:"advantages",level:3},{value:"<strong>Workflow for Aligning Codec Output to Best Practices</strong>",id:"workflow-for-aligning-codec-output-to-best-practices",level:2},{value:"Data Structure Planning",id:"data-structure-planning",level:2},{value:"Small Deployments (1-100 devices)",id:"small-deployments-1-100-devices",level:3},{value:"Medium Deployments (100-1000 devices)",id:"medium-deployments-100-1000-devices",level:3},{value:"Large Deployments (1000+ devices)",id:"large-deployments-1000-devices",level:3},{value:"Implementing in ChirpStack",id:"implementing-in-chirpstack",level:2}];function o(e){const n={a:"a",admonition:"admonition",code:"code",h1:"h1",h2:"h2",h3:"h3",h4:"h4",header:"header",hr:"hr",img:"img",li:"li",ol:"ol",p:"p",pre:"pre",strong:"strong",table:"table",tbody:"tbody",td:"td",th:"th",thead:"thead",tr:"tr",ul:"ul",...(0,r.R)(),...e.components};return(0,s.jsxs)(s.Fragment,{children:[(0,s.jsx)(n.p,{children:(0,s.jsx)(n.img,{alt:"Draft warning",src:t(8678).A+"",width:"1200",height:"400"})}),"\n",(0,s.jsx)(n.header,{children:(0,s.jsx)(n.h1,{id:"good-housekeeping-for-lorawan-sensor-fleets",children:"Good Housekeeping for LoRaWAN Sensor Fleets"})}),"\n",(0,s.jsxs)(n.p,{children:["This guide is an attempt to help you step neatly past a major mistake I made when first getting into deploying LoRaWAN sensors:  ",(0,s.jsx)(n.strong,{children:"Bolloxing up my data structures."})]}),"\n",(0,s.jsxs)(n.p,{children:["In the madly exciting journey of actually getting a sensor to connect to the ",(0,s.jsx)(n.a,{href:"https://console.meteoscientific.com/front/",children:"MetSci LNS"})," and then send me data, I added all that data higgledy-piggeldy, using ",(0,s.jsx)(n.code,{children:"Distance"})," or ",(0,s.jsx)(n.code,{children:"distance"})," or ",(0,s.jsx)(n.code,{children:"meters"})," or whatever set of units I had at the time for whatever sensor I was deploying."]}),"\n",(0,s.jsx)(n.p,{children:"This worked at the onesy-twosy level, but as I started adding more sensors and building databases to store the data, it bit me in the ass."}),"\n",(0,s.jsx)(n.p,{children:"Let the bite marks on my ass be a guide to you.  Whiile chicks dig scars, you don't have to replicate all of mine."}),"\n",(0,s.jsx)(n.p,{children:"This guide focuses on best practices for writing, modifying, and debugging LoRaWAN codecs to ensure clean, consistent, and reliable data processing. These principles help prevent common issues when integrating with databases like InfluxDB or visualizing data in applications."}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.h2,{id:"why-structured-data-matters-engineer-answer",children:(0,s.jsx)(n.strong,{children:"Why Structured Data Matters (Engineer Answer)"})}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Scalability"}),": As you add more devices, consistent structures simplify integration and maintenance."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Compatibility"}),": Adopting standardized fields and tags minimizes schema conflicts in databases like InfluxDB."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Query Efficiency"}),": Well-structured tags and fields enable faster and more precise queries."]}),"\n"]}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.h3,{id:"cardinality-considerations-nerd-talk",children:"Cardinality Considerations (Nerd Talk)"}),"\n",(0,s.jsxs)(n.p,{children:["Cardinality refers to the number of unique values a tag or field can have in your database. While tags are indexed in InfluxDB for fast querying, high-cardinality tags (e.g., unique ",(0,s.jsx)(n.code,{children:"deveui"})," values for thousands of devices) can significantly impact database performance."]}),"\n",(0,s.jsx)(n.p,{children:'This may not be a problem for most of us, as "high cardinality" only becomes an issue when you have hundreds of thousands of unique tag values.'}),"\n",(0,s.jsx)(n.h4,{id:"why-cardinality-matters",children:"Why Cardinality Matters"}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Storage Overhead"}),": Each unique combination of tags creates a new series in InfluxDB, increasing storage requirements."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Query Performance"}),": High-cardinality tags slow down queries because the database must search through a larger index."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Management Complexity"}),": Excessively granular tags make it harder to maintain consistent schemas."]}),"\n"]}),"\n",(0,s.jsx)(n.h4,{id:"rules-of-thumb-for-high-cardinality",children:"Rules of Thumb for High Cardinality"}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsx)(n.li,{children:"Small Deployments (10\u20131,000 Devices):"}),"\n"]}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsx)(n.li,{children:"Using device_id or sensor_serial as tags is acceptable."}),"\n",(0,s.jsx)(n.li,{children:"Use broader tags like sensor_type or region to group data logically."}),"\n"]}),"\n",(0,s.jsxs)(n.ol,{start:"2",children:["\n",(0,s.jsx)(n.li,{children:"Medium Deployments (1,000\u201310,000 Devices):"}),"\n"]}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsx)(n.li,{children:"Avoid device_id as a tag unless necessary for querying."}),"\n",(0,s.jsx)(n.li,{children:"Consider grouping devices by broader categories (e.g., region, building_id)."}),"\n"]}),"\n",(0,s.jsxs)(n.ol,{start:"3",children:["\n",(0,s.jsx)(n.li,{children:"Large Deployments (10,000+ Devices):"}),"\n"]}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsx)(n.li,{children:"Avoid high-cardinality tags entirely."}),"\n",(0,s.jsx)(n.li,{children:"Store unique metadata (e.g., device_id) in external systems or as fields."}),"\n"]}),"\n",(0,s.jsx)(n.h4,{id:"best-practices",children:"Best Practices"}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsxs)(n.li,{children:["Use high-cardinality tags like ",(0,s.jsx)(n.code,{children:"device_id"})," only when you frequently filter or group data by individual devices."]}),"\n",(0,s.jsxs)(n.li,{children:["Favor low-cardinality tags such as ",(0,s.jsx)(n.code,{children:"region"})," or ",(0,s.jsx)(n.code,{children:"sensor_type"})," for broader groupings."]}),"\n",(0,s.jsxs)(n.li,{children:["Move metadata that rarely changes (e.g., ",(0,s.jsx)(n.code,{children:"firmware_version"}),", ",(0,s.jsx)(n.code,{children:"manufacturer"}),") into fields or external metadata stores."]}),"\n"]}),"\n",(0,s.jsx)(n.h2,{id:"planned-tags-and-fields",children:(0,s.jsx)(n.strong,{children:"Planned Tags and Fields"})}),"\n",(0,s.jsx)(n.p,{children:"This is specifically useful for InfluxDB, but even if you're not using that, it's generally useful to think about how you're going to structure you data."}),"\n",(0,s.jsx)(n.h3,{id:"tags-table",children:(0,s.jsx)(n.strong,{children:"Tags Table"})}),"\n",(0,s.jsx)(n.p,{children:"Tags provide metadata about each measurement and are ideal for filtering and grouping data."}),"\n",(0,s.jsxs)(n.table,{children:[(0,s.jsx)(n.thead,{children:(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Tag"})}),(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Description"})})]})}),(0,s.jsxs)(n.tbody,{children:[(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"deveui"})}),(0,s.jsx)(n.td,{children:"Unique identifier for each sensor"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"device_name"})}),(0,s.jsx)(n.td,{children:"Human-readable name of the device"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"firmware_version"})}),(0,s.jsx)(n.td,{children:"For tracking device firmware"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"label"})}),(0,s.jsx)(n.td,{children:"Context-specific label for the device"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"location"})}),(0,s.jsx)(n.td,{children:'Physical location of the sensor (e.g., "Office")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"sensor_type"})}),(0,s.jsx)(n.td,{children:'Device type (e.g., "AM319", "LDDS75")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"tenant_id"})}),(0,s.jsx)(n.td,{children:"Identifier for the tenant owning the device"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"network"})}),(0,s.jsx)(n.td,{children:'The network the sensor is part of (e.g., "helium_iot")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"gateway_id"})}),(0,s.jsx)(n.td,{children:"Identifier of the gateway forwarding the data"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"gateway_name"})}),(0,s.jsx)(n.td,{children:"Human-readable name of the gateway"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"gateway_location"})}),(0,s.jsx)(n.td,{children:"Physical location of the gateway (lat, long)"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"region"})}),(0,s.jsx)(n.td,{children:'LoRaWAN region configuration (e.g., "US915")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"hardware_mode"})}),(0,s.jsx)(n.td,{children:'Specific hardware configuration or mode (e.g., "LT22222")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"work_mode"})}),(0,s.jsx)(n.td,{children:"Operational mode of the device"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"parking_status"})}),(0,s.jsx)(n.td,{children:'Parking availability status (e.g., "FREE", "OCCUPIED")'})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"schema_version"})}),(0,s.jsx)(n.td,{children:"For tracking data structure changes"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"status_changed"})}),(0,s.jsx)(n.td,{children:"Indicates if a status change occurred"})]})]})]}),"\n",(0,s.jsx)(n.h3,{id:"fields-table",children:(0,s.jsx)(n.strong,{children:"Fields Table"})}),"\n",(0,s.jsx)(n.p,{children:"Fields store the actual sensor readings and vary by sensor type."}),"\n",(0,s.jsxs)(n.table,{children:[(0,s.jsx)(n.thead,{children:(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Field"})}),(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Type"})}),(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Unit"})}),(0,s.jsx)(n.th,{children:(0,s.jsx)(n.strong,{children:"Description"})})]})}),(0,s.jsxs)(n.tbody,{children:[(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"battery_voltage"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"V"}),(0,s.jsx)(n.td,{children:"Battery voltage"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"distance"})}),(0,s.jsx)(n.td,{children:"Integer"}),(0,s.jsx)(n.td,{children:"mm"}),(0,s.jsx)(n.td,{children:"Distance measurement"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"air_humidity"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"%"}),(0,s.jsx)(n.td,{children:"Air humidity percentage"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"air_temperature"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb0C"}),(0,s.jsx)(n.td,{children:"Air temperature"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"soil_temperature"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb0C"}),(0,s.jsx)(n.td,{children:"Soil temperature"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"water_temperature"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb0C"}),(0,s.jsx)(n.td,{children:"Water temperature"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"surface_temperature"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb0C"}),(0,s.jsx)(n.td,{children:"Surface temperature"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"co2"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"ppm"}),(0,s.jsx)(n.td,{children:"CO2 concentration"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"light_level"})}),(0,s.jsx)(n.td,{children:"Integer"}),(0,s.jsx)(n.td,{children:"lux"}),(0,s.jsx)(n.td,{children:"Light level measurement"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"pm10"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb5g/m\xb3"}),(0,s.jsx)(n.td,{children:"PM10 concentration"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"pm2_5"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"\xb5g/m\xb3"}),(0,s.jsx)(n.td,{children:"PM2.5 concentration"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"pressure"})}),(0,s.jsx)(n.td,{children:"Integer"}),(0,s.jsx)(n.td,{children:"Pa"}),(0,s.jsx)(n.td,{children:"Atmospheric pressure"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"rssi"})}),(0,s.jsx)(n.td,{children:"Integer"}),(0,s.jsx)(n.td,{children:"dBm"}),(0,s.jsx)(n.td,{children:"Signal strength"})]}),(0,s.jsxs)(n.tr,{children:[(0,s.jsx)(n.td,{children:(0,s.jsx)(n.code,{children:"snr"})}),(0,s.jsx)(n.td,{children:"Float"}),(0,s.jsx)(n.td,{children:"dB"}),(0,s.jsx)(n.td,{children:"Signal-to-noise ratio"})]})]})]}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.h3,{id:"example-data-structure-for-influxdb",children:(0,s.jsx)(n.strong,{children:"Example Data Structure for InfluxDB"})}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-json",children:'{\n  "measurement": "sensor_measurements",\n  "tags": {\n    "deveui": "BX19skDKS827",\n    "device_name": "Weather Station S2120",\n    "location": "Field",\n    "sensor_type": "S2120",\n    "tenant_id": "tenant-002",\n    "network": "helium_iot",\n    "gateway_id": "112qN5DMoTdc4ThFGQHKyg4e3QfuEkkCUEfu5EgZA1QZLNdqb4Cf",\n    "gateway_name": "amateur-jade-hare",\n    "region": "US915",\n    "hardware_mode": "LT22222",\n    "work_mode": "2ACI+2AVI",\n    "parking_status": "FREE",\n    "status_changed": true\n  },\n  "fields": {\n    "temperature": 22.5,\n    "humidity": 80.2,\n    "wind_speed": 5.4,\n    "wind_direction_sensor": 45,\n    "air_temperature": 11.2,\n    "air_humidity": 81,\n    "barometric_pressure": 99880,\n    "rain_gauge": 0.0,\n    "rssi": -97,\n    "snr": 4.5,\n    "water_leakage": false\n  },\n  "timestamp": "2025-01-01T01:38:16.699Z"\n}\n'})}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.h2,{id:"integrating-metadata-optimization-in-codec-design",children:(0,s.jsx)(n.strong,{children:"Integrating Metadata Optimization in Codec Design"})}),"\n",(0,s.jsx)(n.h3,{id:"caching-metadata-for-periodic-updates",children:"Caching Metadata for Periodic Updates"}),"\n",(0,s.jsxs)(n.p,{children:["You can optimize your codec by caching metadata that rarely changes (e.g., ",(0,s.jsx)(n.code,{children:"tenant_id"}),", ",(0,s.jsx)(n.code,{children:"region"}),", ",(0,s.jsx)(n.code,{children:"sensor_type"}),") and refreshing it periodically. Here's an example approach:"]}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-javascript",children:'function decodeUplink(input) {\n    let metadataCache = getMetadataCache(); // Retrieve cached metadata\n    const currentTime = Date.now();\n    const metadataRefreshInterval = 86400000; // 24 hours in milliseconds\n\n    if (!metadataCache || (currentTime - metadataCache.lastUpdated > metadataRefreshInterval)) {\n        // Update metadata cache if expired or not present\n        metadataCache = {\n            device_id: "12345",\n            sensor_type: "AM319",\n            tenant_id: "tenant-001",\n            region: "US915",\n            lastUpdated: currentTime,\n        };\n        setMetadataCache(metadataCache); // Save updated metadata\n    }\n\n    // Decode dynamic measurements\n    const measurements = {\n        temperature: input.bytes[0] + input.bytes[1] / 100,\n        humidity: input.bytes[2] + input.bytes[3] / 100,\n    };\n\n    // Combine metadata and measurements\n    return {\n        data: {\n            ...metadataCache,\n            ...measurements,\n        },\n    };\n}\n\n// Mocked cache functions for demonstration\nfunction getMetadataCache() {\n    return JSON.parse(localStorage.getItem("metadataCache"));\n}\n\nfunction setMetadataCache(cache) {\n    localStorage.setItem("metadataCache", JSON.stringify(cache));\n}\n'})}),"\n",(0,s.jsx)(n.h3,{id:"explanation",children:"Explanation:"}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Metadata Cache:"})," A local storage object holds metadata like ",(0,s.jsx)(n.code,{children:"tenant_id"})," and ",(0,s.jsx)(n.code,{children:"sensor_type"}),"."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Periodic Refresh:"})," Metadata is refreshed only when its cache has expired (e.g., every 24 hours)."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Dynamic Measurements:"})," Each uplink includes only the dynamic measurements, reducing payload size."]}),"\n"]}),"\n",(0,s.jsx)(n.h3,{id:"advantages",children:"Advantages"}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsx)(n.li,{children:"Reduces repetitive transmission of static data."}),"\n",(0,s.jsx)(n.li,{children:"Improves uplink efficiency and database storage."}),"\n"]}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.h2,{id:"workflow-for-aligning-codec-output-to-best-practices",children:(0,s.jsx)(n.strong,{children:"Workflow for Aligning Codec Output to Best Practices"})}),"\n",(0,s.jsxs)(n.ol,{children:["\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Design Your Schema"}),": Use the above tag and field guidelines as your reference."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Adapt the Codec"}),": Modify your ChirpStack codec to output JSON that matches your schema."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Test with Sample Payloads"}),": Verify that your output adheres to the schema using ChirpStack\u2019s uplink debugger or Node-RED debug nodes."]}),"\n",(0,s.jsxs)(n.li,{children:[(0,s.jsx)(n.strong,{children:"Validate in Database"}),": Send test payloads to your InfluxDB instance and run queries to ensure the data is stored and indexed correctly."]}),"\n"]}),"\n",(0,s.jsx)(n.hr,{}),"\n",(0,s.jsx)(n.p,{children:"By following these practices, you\u2019ll create a reliable and scalable system for managing and analyzing your LoRaWAN sensor fleet."}),"\n",(0,s.jsx)(n.admonition,{title:"Advanced Topic",type:"note",children:(0,s.jsxs)(n.p,{children:["For large deployments with very different sensor types, you might consider splitting your data into multiple measurements (e.g., ",(0,s.jsx)(n.code,{children:"weather_measurements"}),", ",(0,s.jsx)(n.code,{children:"parking_measurements"}),"). This requires more complex codec design but can provide better data organization and query performance. Start with the single measurement approach and refactor if needed."]})}),"\n",(0,s.jsx)(n.h2,{id:"data-structure-planning",children:"Data Structure Planning"}),"\n",(0,s.jsx)(n.h3,{id:"small-deployments-1-100-devices",children:"Small Deployments (1-100 devices)"}),"\n",(0,s.jsxs)(n.ul,{children:["\n",(0,s.jsx)(n.li,{children:"Use simple, flat data structure"}),"\n",(0,s.jsx)(n.li,{children:"Example implementation:"}),"\n"]}),"\n",(0,s.jsx)(n.pre,{children:(0,s.jsx)(n.code,{className:"language-javascript",children:'{\n    "measurement": "sensor_data",\n    "tags": {\n        "device_id": "am319_001",\n        "location": "office"\n    },\n    "fields": {\n        "temperature": 22.5,\n        "humidity": 65\n    }\n}\n'})}),"\n",(0,s.jsx)(n.h3,{id:"medium-deployments-100-1000-devices",children:"Medium Deployments (100-1000 devices)"}),"\n",(0,s.jsx)(n.p,{children:"// ... scaling patterns ..."}),"\n",(0,s.jsx)(n.h3,{id:"large-deployments-1000-devices",children:"Large Deployments (1000+ devices)"}),"\n",(0,s.jsx)(n.p,{children:"// ... enterprise patterns ..."}),"\n",(0,s.jsx)(n.h2,{id:"implementing-in-chirpstack",children:"Implementing in ChirpStack"}),"\n",(0,s.jsxs)(n.p,{children:["Once you've planned your data structure using these guidelines, see our ",(0,s.jsx)(n.a,{href:"/docs/tutorial-basics/metrics-on-chirpstack",children:"Metrics & Decoders guide"})," for implementation details."]})]})}function h(e={}){const{wrapper:n}={...(0,r.R)(),...e.components};return n?(0,s.jsx)(n,{...e,children:(0,s.jsx)(o,{...e})}):o(e)}},8678:(e,n,t)=>{t.d(n,{A:()=>i});const i=t.p+"assets/images/draft-warning-e836cb52cc996d105d82cff81033b29a.png"},8453:(e,n,t)=>{t.d(n,{R:()=>a,x:()=>d});var i=t(6540);const s={},r=i.createContext(s);function a(e){const n=i.useContext(r);return i.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function d(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(s):e.components||s:a(e.components),i.createElement(r.Provider,{value:n},e.children)}}}]);