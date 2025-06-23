---
title: Is One Sensor Enough?
authors: [nik]
tags: [lorawan, business, helium]
description: How a single IoT sensor can turn your neighborhood into a playground and get people interested in IoT, featuring a heavy metal sled, LoRaWAN tracking, and community building.
---

What if I told you that a single IoT sensor (yep, just one) could turn your entire neighborhood into a playground that got people interested in IoT?

There's this story in IoT that you need thousands of sensors to make a difference.  Maybe that's true.  <!-- truncate -->

Today I wanted to talk about what you can do with just one sensor.  Before we begin with that, I should give you some context.

## ACTION & IoT

For as far back as I can remember, I've been active.  Running, swimming, wrestling, lacrosse, and just being out in the wild moving through terrain.  Action has been the great restorative for me, both a source of daily joy and a catch net for times of depression.

We are the same in that way, you and I, because we are human.  Humans feel better when they move, when they physically work.  It's in our genes.  A bias for (thinking) action is part of what has made us the dominant species on the planet. 

Over the past few years as I've gotten deeper into IoT, I have set aside much of my old action.  I call it "glueing my face to the computer", and while it has been intensely fascinating to dive into the world of IoT and LoRa and uplinks and routing, it has not been good for action.

In fact, with a few rare exceptions, like this helicopter delivery of a weather station to a mountain top:

<video 
  controls
  preload="metadata"
  poster="/img/blog/video-thumbnails/weather-station-delivery-thumb.png"
  style={{
    width: '100%',
    maxWidth: '800px',
    margin: '20px auto',
    borderRadius: '8px',
    border: '4px solid var(--metsci-primary)',
    boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    backgroundColor: 'var(--metsci-white)',
  }}
>
  <source src="https://video.meteoscientific.com/helicopter-delivery-of-iot-weather-station-el-cajon-mtn.mp4" type="video/mp4" />
  Your browser does not support the video tag.
</video>

or hiking in a giant 915 MHz antenna and half the accoutrements of a LoRaWAN gateway in a 70 lb pack on that same mountain range:

<video 
  controls
  preload="metadata"
  poster="/img/blog/video-thumbnails/giant-antenna-delivery-thumb.png"
  style={{
    width: '100%',
    maxWidth: '800px',
    margin: '20px auto',
    borderRadius: '8px',
    border: '4px solid var(--metsci-primary)',
    boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    backgroundColor: 'var(--metsci-white)',
  }}
>
  <source src="https://video.meteoscientific.com/hiking-in-giant-lorawan-915-antenna.mp4" type="video/mp4" />
  Your browser does not support the video tag.
</video>

IoT and real world human action seldom overlap.  One of the main selling points of IoT is that you actually do less action.  With a network of sensors, you can focus down to only doing the action that matters.

In one sense that's much more efficient, and certainly better for a business.  In the other, that brings us closer to death.  I'm not ready to die yet, and so I sought a way to increase action with two caveats:

First, I would do it with others.  I'm no misanthrope, and while I've had plenty of joyous times alone, there's something genetically satisfying about sharing physical effort with someone else.  It's (part) of what makes sex satisfying, but the joy of joint work is not solely the realm of procreation.

A hard run with a friend, or a climb out of a deep canyon, or crossing a river, or just lifting weights with a group all trigger deep centers of joy.  We evolved to work together; it's how we brought down mammoths, kept the children safe, maintained and grew the tribe.

Together is how we best operate.

Second, I would involve IoT.  I love this tech; I think it's so cool the way we can start to measure the world, record it, and react to the world much faster, more accurately, and over far longer range than ever we could before.  IoT is so clearly the way forward for the way humans sense the world that ignoring it borders on the criminal.  

Still, IoT is a dense thicket.  To use it you typically have to be able to do more than just make text bold or italic; there's code involved, hardware, software, connectivity, and more.  In fact, the deeper you get into IoT, the more that is required you know just to get something simple to work.

How then can we integrate the joy of action together with the barriers of getting something to actually work that surround IoT?

## BEGINNINGS

Years ago, when I was deep in my metal working phase, a buddy of mine came by to give me a couple of heavy iron elongated pyramids that looked like teeth off a robot T-rex.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/dredger_teeth.JPG"
    alt="Heavy iron dredger teeth from San Diego bay dredger, looking like robot T-rex teeth"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

In actual fact they were the worn out teeth of the San Diego bay dredger, the thing that digs out the bottom of the bay so it's deep enough for our various and sundry aircraft carriers, destroyers, and other large ships that dock here in America's Finest city and make up much of the US Pacific fleet.

For the longest time I didn't know what to do with 'em.  Then one day on the internet back in 2015-ish, I saw some football guys pushing a metal sled.

Ah, I thought, those dredger teeth would make excellent sled feet, and I could weld together my own heavy metal sled out of scrap I had laying around that I could push around the neighborhood causing all kinds of grinding-steel-on-concrete noise and generally be very pleased with myself as I bulldogged the thing around the block.

So I did.  I used it a few times because I love action, but other actions called in both real and virtual worlds, and the sled sat next to the weight rack until last Thursday.

Through a longer turn of events, I ended up pushing the sled to a buddy's house about ½ a mile away as a workout and a challenge for him to push back.  

He did, and as I heard it grinding towards me on the street it hit me that I should share this idea, of pushing the sled between houses in a neighborhood, in a way that combined my love of action with my love of IoT, and the rapidly growing capabilities of vibe-coding (which just means working with AI to build something).

## COORDINATION
 
So over the weekend I built a website to coordinate IoT action amongst strangers.  

It relies on the IoT device of a Digital Matter Oyster2, which is a slightly older piece of tech that is enormously stable and delivers on all the promises of IoT & LoRaWAN; long battery life, long communication range, and dead simple to use.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/oyster2-tracker-on-helium.JPG"
    alt="Digital Matter Oyster2 IoT tracker device with Helium branding"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

The Oyster is attached to the sled.  We added a wheels option so you can make it easier if needed, but most of the time the wheels are just mounted on that pin on the back.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/sled-with-tracker.jpg"
    alt="The sled on delivery with the Oyster2 tracker mounted"
    style={{
      maxWidth: '800px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

When the sled is stationary for more than 7 minutes, the Oyster goes to sleep for 24 hours.  When the sled is moving, an accelerometer in the Oyster wakes the device up and it starts transmitting every 20 seconds.

<video 
  controls
  preload="metadata"
  poster="/img/blog/video-thumbnails/get-after-it-sled-pushing-thumb.png"
  style={{
    width: '100%',
    maxWidth: '800px',
    margin: '20px auto',
    borderRadius: '8px',
    border: '4px solid var(--metsci-primary)',
    boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    backgroundColor: 'var(--metsci-white)',
  }}
>
  <source src="https://video.meteoscientific.com/sled-pushing-nik.mp4" type="video/mp4" />
  Your browser does not support the video tag.
</video>

## Nerd Talk

The Oyster sends data packets via uplinks through the Helium Network to a LoRaWAN Network Server, or LNS.  In this case, we're using the MeteoScientific LNS Console. 

The [MetSci Console](https://console.meteoscientific.com) is available for anyone to use, just sign up.  I've written a whole series of [Tutorials](/docs/tutorial-basics/LoRaWAN-Big-Picture) on how to use it if you need help.  You get your first 400 data packets for free, and after they they cost $.0001 each.  Yeah, pretty cheap.

The LNS decodes the packets and sends them on via an http integration to a Cloudflare Worker.

The Worker puts the incoming packets from the Oyster into a Cloudflare D1 database.  It then reads that database and updates the website that coordinates and informs all the human actions.

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/cloudflare-worker-bindings.png"
    alt="Cloudflare Worker bindings showing connections to Assets, R2 bucket, D1 database, and KV namespace for intersections"
    style={{
      maxWidth: '600px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

As I've said, Action is one of my loves.

You can go to the website to see how the rest of it works, but before I send you there, let me walk you through the general workflow.

## The Real World

Let's say you're a reasonably fit person out walking your dog.  If, like me, you want to work out with other people but joining a gym isn't your thing, you might be interested in a flyer you see on a telephone pole that says "Hard Work - Sled Pushing"

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/sled-pushing-flyer.JPG"
    alt="Flyer for sled pushing signup in Normal Heights, San Diego California"
    style={{
      maxWidth: '600px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

You tear off one of the tabs at the bottom which has a QR code and 5 or 6 character password and take it home.

You scan the QR code and find the site, read through the description, and decide to sign up.

The very short version of the description is that you're signing up for a heavy metal sled to be pushed to you by a stranger, then you're responsible for "delivering" (by pushing) the sled to the next stranger.  

The distances are bounded by 300 and 1,000 meters so that the push will be neither too long nor short, and the general rules (during the day, of course you can bring a friend, contact me if anything goes wrong) are laid out.

When you sign up, you enter your email, the handle you want to go by publicly, your address, and the password you entered.

### A Quick Revisit of Nerdville

The Cloudflare Worker receives that information and uses the Haversine formula to calculate both your address latitude and longitude.  It then runs your coordinates through a Cloudflare KV pair of every intersection in the neighborhood so it can give others a general idea of where you are without giving away your address (i.e. "Nik near 35th and Copley just signed up").

The Worker puts all that data into a Cloudflare D1 table.  Once you're in the table, the Worker figures out where you should go in the sled delivery queue.

## The Feedback Loop

You can see where you are in the queue on the website, and when the pusher before you starts their push (calculated by the Oyster recording movement outside of a 15 meter radius from the pusher's address), the Worker fires off an email via Mailgun telling you the sled is coming.

When the sled enters the 15 meter radius around your address, you'll get another email confirming that the sled has been dropped off and giving you the address of where you'll push to.

This continues on for as long as people sign up; at the end of the queue it just loops back to the beginning.

## Making The Map

All of this information about location is displayed on a PMTiles map I generated after downlaading an 80GB map of the entire world and processing out just my little neighborhood using a local machine I call Monstra for the processing (3 x 4070 Super Ti GPUs and a Threadripper). 

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/monstra-gpu-and-threadripper-local-ai.jpg"
    alt="Triple GPU machine with Threadripper for running local LLM and AI tasks"
    style={{
      maxWidth: '600px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

The PMTiles map is stored in a Cloudflare R2 and displayed on the site, with the live tracker of the sled on it:

<div style={{
  display: 'flex',
  justifyContent: 'center',
  margin: '20px auto'
}}>
  <img 
    src="/img/blog/2025-06-22-single-iot-sensor-power-the-sled/sled-tracking-map.png"
    alt="The displayed PMTiles map I built with Monstra"
    style={{
      maxWidth: '600px',
      width: '100%',
      borderRadius: '8px',
      border: '4px solid var(--metsci-primary)',
      boxShadow: '0 4px 12px rgba(217, 74, 24, 0.15)',
    }}
  />
</div>

So that's the combination of nerd workflow and action.

## The Next Steps

If you're in our little neighborhood of Normal Heights, you can [sign up to have the sled "delivered" to you](https://sled.meteoscientific.com), and then you'll be on the hook to deliver it to the next person.
 
As more people sign up, we get two very important things.  

First, we combine IoT and Action, which is a source of deep joy for me.  Every person that participates is using IoT, and many of them will learn just a little bit more about how they're using it just from interacting with the sled website.  I try to answer their questions up front in the [Sled FAQ section](https://sled.meteoscientific.com/faq)) on the sled site; that way they're not afraid to ask.

Second, I get to connect with the section of all the people in my neighborhood (about 5,000 families total according to US Census statistic) who are willing to engage in a string of hot and sweaty deliveries from and to a stranger.  I've got the feeling they'll be my kind of people.

There is one other aspect of this one-sensor project that's pretty cool; this system is repeatable and cheap.  

It runs entirely on the free tiers of Cloudflare Workers, D1, R2, and KV. It's all in a Github repo that I'd be happy to share, though I'll warn you that the Worker is messy and for now, it'll be a bit than just "copy/paste" to get it going.

The only cost is the tracking device.  The Oyster2 is (generally) no longer sold, but you can get the next gen Oyster3 that runs about $130.  I'd recommend getting one from [LoneStar Tracking](https://www.lonestartracking.com/tracking-devices/oyster-lora-gps-tracking-device-915mhz/).  That's where I got my Oyster, and Tommy at LoneStar is good people.

You could get creative here and find a device that gathers more than just GPS data; say, air quality, or temperature, etc. and display that as well.

You may have read this and thought this is all too much, and there's some aspect of it that you just couldn't do.

## Yes, You Can

If you've read this far, you absolutely have the two critical things required to make a project work; the **focus to read** and the **curiosity to keep going**.  Everything else is just action, and humans are built for action!

Those two things are all anyone needs to succeed in the world of IoT, which is, after all, the thing that will change our world.

With those two things and one sensor, you too can expand a new truth about IoT.

What'll your one-sensor project be?

:::info Author

**Nik Hawks** is a LoRaWAN Educator & Builder at [MeteoScientific](https://meteoscientific.com/). He writes to educate and delight people considering IoT, and to inspire other IoT nerds to build and deploy their own projects into the world. He runs a [podcast](https://pod.metsci.show) discussing all things LoRaWAN and is psyched to hear about what you're building, whether it's a one sensor playground or a million sensor rollout.

:::
