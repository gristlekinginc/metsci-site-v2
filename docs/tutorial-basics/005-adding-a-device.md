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
If watching a video is easier for you than reading, I've recorded one for ya.  The video goes through onboarding a soil moisture sensor.  

This written tutorial goes through onboarding a Milesight `WS101 SOS` Smart Button.  I've found it useful to have different examples for the same thing when you're learning.

<iframe width="560" height="315" src="https://www.youtube.com/embed/rhNYKyC3Avs?si=1LimXlj78xfzqPb-" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### The Three Key Identifiers

When you get a sensor it *should* come with three long and complicated numbers:
```
- DevEUI (Device EUI)
- AppEUI (Application EUI)
- AppKey (Application Key)
```

In Chirpstack (which is what the MeteoScientific Console runs on), **the AppEUI isn't required**.  

In fact, there's not even a field for it, so we'll have to manually make one.  In other LNS versions (say, LORIOT or TTN) the AppEUi can be a critical aspect.

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

### Step 2: Add the Device to the ChirpStack Console

In the case of this Milesight `WS101 SOS`, we turn the device on by removing the battery insulating sheet, then we'll configure it via NFC.  Some devices use BLE, some use USB.  Check the manual that came with it (or run the ol' Googs search on it.)

Here's what the Milesight app looks like when we connect via NFC:

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

In this case, the Milesight app doesn't show the Application Key, so we'll create our own in Chirpstack, then assign our AppKey to the device.

With the device on and the DEVEUI and APPKEY ready, let's head to the MetSci Console!

1. **Go to Applications:** 
   - Navigate to your application (we've set this up in the previous tutorial.)
   - Click on **Add Device**.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/add-device-in-metsci-console.png"
    alt="Adding a new device in the MeteoScientific Console"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

2. **Naming Convention:**
   - Use a naming convention that makes sense to you. For example, you might use the name of the device and the last few digits of the DevEUI, or its position; whatever.  Just be consistent.

3. **Fill in Device Details:**
   - Enter any additional details that are important to you, such as a description or location.  For this I'll use something like `Table Service button for table 1 at [redacted restaurant]`.
   - For your first couple of devices, err on the side of more information, not less.  


<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/add-device-details-page-1.png"
    alt="Device details configuration page showing name and description fields"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

4. **Enter the DevEUI:**
   - Typically, you would copy and paste the DevEUI. Avoid manually typing it.  
   - Incorrect DevEUI/AppKey is the number one cause of LoRaWAN join frustration.
:::tip
Most manufacturers will have a QR code with the device that'll give you the DevEUI so you can copy/paste from there.
:::
   - With some devices (like the soil moisture sensor in the video) you generate your own DevEUI, but for most of them the DevEUI is burned in when you get it.

5. **Add the AppEUI**
   - Chirpstack doesn't use an `APPEUI` but Helium likes it.  Go to the `Variable` tab and add a new variable.
   - Use key `app_eui` and the value of 16 zeros, like this: `0000000000000000`

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/add-app-eui-16-zeros.png"
    alt="Adding the AppEUI with sixteen zeros in the device configuration"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

6. **Fill in or Generate AppKeys:**
   - ChirpStack allows you to generate these.  It's good security practice to generate your own.
   - Copy and store them in a safe place.  

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/generate-app-key-in-metsci-helium-console.png"
    alt="Generating an AppKey in the MeteoScientific Helium Console"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

7. **Submit the Device:**
   - Once all details are filled in, submit the device.  
   - This is the point of anticipation/frustration, I know.
   - Head over to the `LoRaWAN frames` tab to watch the Join.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/005-add-a-device/join-request-join-accept.png"
    alt="LoRaWAN frames showing successful join request and accept messages"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

:::warning
If you don't see a frame come through, it is VERY likely you fat-fingered something.  The most common support request I get is "My device isn't joining."  

With one exception (lookin' at you Scott W), it has ALWAYS been one of those, "Oh, I forgot a zero in the APPEUI" or "It used the wrong AppKey", whatever that means.

While the MetSci console isn't AWS, it runs on the same platform as most other LNS in Helium and processes hundreds of thousands of packets.  

I know you're special, but the most special thing about you right now if you're reading this and cursing is probably that you have fingers the size of German bratwurst, not that the LNS is broken.  Just sayin'.
:::

That's how you add a device to the MeteoScientific ChirpStack console.  From here you can muck about with downlinks, dial in your decoder, grab network or application session IDs from the `Activation` tab and generally enjoy the geekery.  

Rock 'n roll!

:::tip Understanding Events vs Frames

- **Events:** Contain information from the sensor (e.g., battery status).
- **Frames:** Include both the sensor events and additional information from the gateway.

:::




