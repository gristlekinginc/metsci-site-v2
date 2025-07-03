---
sidebar_position: 5
title: Add A Device
---

# Add A Device

### Step 1: Gather The Details

Before we get started, you'll need two things for every device on Helium, a `DEVEUI` and an `APPKEY`.  

`DEVEUI` stands for DEVice Extended Unique Identifier, and it's part of what Helium uses to figure out where to send the packets it receives in the Helium Packet Router. 

`APPKEY` stands for `Application Key`, and is the "secret handshake" part of the process that makes sure your data is not only identified (with the `DEVEUI`) but is also secure.

## Want to Watch?
If watching a video is easier for you than reading, I've recorded one for ya.  The video goes through onboarding a soil moisture sensor.  The written tutorial goes through onboarding a Milesight `WS101 SOS` Smart Button.  I've found it useful to have different examples for the same thing when you're learning.

<iframe width="560" height="315" src="https://www.youtube.com/embed/rhNYKyC3Avs?si=1LimXlj78xfzqPb-" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### The Three Key Identifiers

When you get a sensor, every sensor *should* come with three long and complicated numbers:
```
- DevEUI (Device EUI)
- AppEUI (Application EUI)
- AppKey (Application Key)
```

In Chirpstack (which is what the MeteoScientific Console runs on), the AppEUI isn't required.  In fact, there's not even a field for it, so we have to manually make one.  In other LNS versions (say, LORIOT or TTN) the AppEUi can be a critical aspect.

Milesight prints the `DEVEUI` on the box, then uses an app to give you the `APPKEY`.  

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/milesight-ws101-smart-button.jpg"
    alt="Milesight WS101 Smart Button with box and instructions"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

In the case of this Milesight `WS101 SOS`, we turn the device on by removing the battery insulating sheet, then configure via NFC.  

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/milesight-ws101-setup-toolbox.png"
    alt="Milesight WS101 SOS configuration screens in the NFC setup app"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

### Step 2: Add the Device to the ChirpStack Console


1. **Go to Applications:** 
   - Navigate to your application (we've set this up in a previous video).
   - Click on **Add Device**.

2. **Naming Convention:**
   - Use a naming convention that makes sense to you. For example, you might use the name of the device, the last four digits of the DevEUI, and the position of the device.

3. **Fill in Device Details:**
   - Enter any additional details that are important to you, such as a description or location (e.g., "Avocado Tree in the Backyard"). 
   - Set up the date and any other relevant notes.

4. **Input the DevEUI:**
   - Typically, you would copy and paste the DevEUI. Don't bother typing it manually; it's a big hassle.
   - Reputable manufacturers will provide the DevEUI, AppEUI, and AppKey.

5. **Generate EUI and Keys:**
   - ChirpStack allows you to generate these identifiers if needed.
   - Copy and store them in a safe place, like a Google Sheet.

6. **Configure the Device Profile:**
   - If required, add a variable called `app_eui` with the correct value (e.g., 16 zeros in ChirpStack for LoRaWAN).

7. **Submit the Device:**
   - Once all details are filled in, submit the device.

8. **Application Key:**
   - Most devices come with an application key. Add this key to the appropriate field.

9. **Finalize Setup:**
   - Make sure the console is ready before powering on the device.

### Step 3: Power On and Monitor the Device

Once you've set everything up in the console:

1. **Power on the Device:**
   - Wait for the console to recognize the device.

2. **Check the Dashboard:**
   - The console will display various metrics such as received packets (RSSI) and signal-to-noise ratio (SNR). These metrics let you know how well the device is communicating.

3. **Explore Configuration Tabs:**
   - Go through the various tabs such as **Tags and Variables**, **OTA Keys**, **Activation**, **Queue**, **Events**, and **LoRaWAN Frames**.

### Understanding Events and Frames

- **Events:** Contain information from the sensor (e.g., battery status).
- **Frames:** Include both the sensor events and additional information from the gateway.

### Now...wait.  

After a few minutes, you should see events and frames start to populate. You'll see the status, battery level, and other details. The console will show you when the sensor requests to join and when it's accepted.

That's how you add a device to the MeteoScientific ChirpStack console. 
