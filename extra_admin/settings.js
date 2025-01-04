/**
 * Node-RED Settings created at Fri, 03 Jan 2025 20:16:19 GMT
 *
 * It can contain any valid JavaScript code that will get run when Node-RED
 * is started.
 *
 * Lines that start with // are commented out.
 * Each entry should be separated from the entries above and below by a comma ','
 *
 * For more information about individual settings, refer to the documentation:
 *    https://nodered.org/docs/user-guide/runtime/configuration
 *
 * The settings are split into the following sections:
 *  - Flow File and User Directory Settings
 *  - Security
 *  - Server Settings
 *  - Runtime Settings
 *  - Editor Settings
 *  - Node Settings
 *
 **/

module.exports = {
    // Essential Flow Settings
    flowFile: "flows.json",
    credentialSecret: process.env.NODE_RED_CREDENTIAL_SECRET,
    flowFilePretty: true,

    // Security
    adminAuth: {
        type: "credentials",
        users: [{
            username: process.env.NODE_RED_USERNAME,
            password: process.env.NODE_RED_PASSWORD,
            permissions: "*"
        }]
    },

    // Server Settings
    uiPort: process.env.PORT || 1880,
    
    // Runtime Settings
    diagnostics: {
        enabled: true,
        ui: true,
    },
    
    // Editor Settings
    editorTheme: {
        projects: {
            enabled: false
        },
        codeEditor: {
            lib: "monaco"
        }
    },

    // Node Settings
    functionExternalModules: true,
    functionTimeout: 0,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
}
