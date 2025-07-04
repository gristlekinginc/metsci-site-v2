---
sidebar_position: 4
---
# Applications 

## Introduction to Applications

When you're in your [Console](https://console.meteoscientific.com/front/login) and first sign in, go down to **Applications** on the left-hand side. 

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/004-set-up-applications/chirpstack-applications.png"
    alt="Adding a pre-loaded Device Profile Template in the Chirpstack MeteoScientific LNS"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

I've already set up a couple of applications, but before we jump into those, let's take a look at what an application actually is.

## Want to Watch?

If learning by watching is easier for you, the video for this is here:
<iframe width="560" height="315" src="https://www.youtube.com/embed/if3FsIUoInk?si=hyjZ2ct_pzykOtks" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

### What is an Application?

It's really simple:  An **application** is a way to organize a group of the same devices used for a specific purpose, and typically for a specific project.  Remember how we used Device Profiles to set up multiple devices?  Now we're going a step further and grouping those devices together, usually to do a specific job.

You might use different applications for different clients if you're a running a LoRaWAN business for monitoring soil moisture at different nurseries.   You'd use the same device profile, but split them out in different Applications to keep it organized.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/004-set-up-applications/rosemary-vs-blueberry-soil-moisture-application-chirpstack-helium.png"
    alt="Using different applications in Helium Chirpstack to have the same device do different jobs and organize your devices. "
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

You might have you own projects where you want to use the same device type (like an Oyster tracker) for different things, like tracking a bike vs tracking a car vs [tracking a sled](https://sled.meteoscientific.com).

Applications also allow us to set up an `Integration`, which is what allows us to connect our device data to the rest of the world.  Before we get to the Integration section, let's talk about naming our Applications.

### Naming Your Application

I started off with crazy organized naming conventions, like `Client-Location-Device-Purpose`.  Over time, I've simplified to just naming the thing for what it does and/or where it is, or something that makes sense to me.  I'll put in amplifying information in the Description to help me remember why I set this device up.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/004-set-up-applications/application-name-description.png"
    alt="The name and description in a ChirpStack application can be really helpful for you to keep things organized and remember why you set it up in the first place."
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

### Creating a New Application

Let's go ahead and add a new application. Using the example I just gave, you might name it "Acme Occupancy Franklin Daily." You can also add a description, like:

```This is the Acme account using parking sensors to measure occupancy at the Franklin garage.```

Once you've filled in the details, hit Submit, and the new application will be created. 

You can see it listed in the Applications section. If you need to make changes, just click on the application again, and go over to Application Configuration. For example, if you made a typo like "garag" instead of "garage," just correct it and hit the Submit button to save the changes.

### Adding Devices
We'll add devices in the [next tutorial](./adding-a-device). 

### Multicast Groups
The next tab you'll see is Multicast Groups. A multicast group is a way to send the same downlink to every device in an application. For instance, if you want to tell all the parking sensors to report every five minutes instead of every ten minutes, you would send a downlink using a multicast group.  We'll cover Multicast in a separate tutorial.

### Integrations
Finally, let's discuss `Integrations`. Integrations are the main reason you'll use Applications.  An Integration is what lets you set up a connection from a device (or devices) on your Console to the the rest of world; it's how you "integrate" your devices into the real world.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/images/tutorial-basics/004-set-up-applications/application-integrations.png"
    alt="Integrations are the critical part of a Chirpstack instance that allow you to send information from your devices out to the outside world."
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

Natively, ChirpStack offers a bunch of different integrations. We'll deal with the first and most confusing, which is `MQTT`. 

In a normal (non-Helium) ChirpStack instance, you can use MQTT without any issue; it's how most "normal" LNS operators send data off their Console. 

However, in a Helium ChirpStack instance like the one we're using with Console, we have a problem.  The Chirpstack native MQTT integration uses an internal MQTT broker, which would mean your broker is also my broker.  That's not a safe way set things up.  As much as we trust each other to swap MQTT spit, I can't trust every asshole on the internet to not try any funny business on a public, permissionless Console.  This means that for security reasons, we don't offer a native MQTT integration. 

This means you'll need to use an `http integration` forwarding to an MQTT broker YOU own and control.  

Because Integrations are so intregral (couldn't resist) to what we do, they're getting their own Tutorial.  For now, just now that the way you get to an Integration is via your Application.

That's it for now, head over to the Console and try creating an Application for yourself.

Rock 'n roll!


<ConsoleButton />
