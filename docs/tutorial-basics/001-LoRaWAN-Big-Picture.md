---
sidebar_position: 1
---

# LoRaWAN - The Big Picture

# Lesson Overview: Understanding How LoRaWAN Works

Let's start with a map of the territory. You're going to hear some terms for the first time. If you don't understand them at first, don't worry about it—we're just getting some reps in so that you have a chance to hear all these terms multiple times.

If you'd prefer a video walk through, go here:

<iframe width="560" height="315" src="https://www.youtube.com/embed/_VSy5-AQe7E?si=GjTkUVBOlMdWQbLZ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Introduction to the Network

For this tutorial series, we are going to use what's called the **Helium Network**. The Helium Network is a global **LoRaWAN**, which stands for Long Range Wide Area Network. It's a wireless or radio network that anyone can use, without first asking permission or going through a giant setup process.

There are lots of LoRaWAN networks that you can use, both public and private.  Helium may not be the best fit for your use case, but it's an excellent way to get started easily

## How It Works

We start with where the data is actually gathered, via **sensors** on a **device** that you **deploy**.  
The words *sensor* and *devices* generally mean the same thing, although nitpickers will call you out on proper lexicon if they have no other way to demonstrate superiority.

**Deploy** is how all the cool people in telecoms say they set something up.  

Devices can be things that only gather data, or they can be things that do physical work in the real world, like switch off a light or actuate a water pump.

For our example today, we'll use a soil moisture sensor. That sensor picks up data, like how moist the soil is. It then takes that data and puts it into what's called a **packet**. Packets in LoRaWAN are small, less than 222 bytes (usually much less.)

This packet is sent wirelessly over the radio waves to a local **Gateway**. 

:::info
In the world of LoRaWAN, `gateway` is a standard term.  Because Helium was designed to be a public-facing and newbie-friendly LoRaWAN, in the world of Helium the gateways are called *Hotspots*.  We use those two words interchangeably here.
:::

There are LoRaWAN gateways all over the world.  In fact, in the urban and suburban developed world, there are very few places NOT covered by a LoRaWAN, of which Helium is the largest.  If you want to check if you have Helium coverage, check out their [World Explorer](https://world.helium.com/en/network/iot/coverage)

:::tip
If you don't have LoRaWAN coverage where you need it, you'll need to deploy a gateway.
:::

Back to the sensor.  The sensor sends the packet up to the gateway.  Gateways are connected to the internet by what's called **backhaul** which is just a fancy way of saying "connection to the internet".  Backhaul can be via cell, satellite, cable, fiber, or even an old school dial up modem.   

The gateway receives the packet and sends it via backhaul to an **LNS**, or a LoRaWAN Network Server.  

Once the packet gets to the LNS, it gets decoded. When the packet goes over the air, it's sent in really short form and it might look like something random, such as `AAcyF0InPJw=`. Whatever it is, it needs to be decoded. It'll get decoded to something like "the soil moisture is 72%," "the temperature is 82 degrees," or "the relative humidity is XYZ."

Once that packet is decoded in the LNS (one of which is run by [MeteoScientific](https://console.meteoscientific.com/front/)) it is then sent to an **integration**, where you or your customers get to see the data or an action is triggered. 

Integrations could drive the display of a graph of the temperature over time, trigger irrigation to turn on or off, or really, anything you can think of to do with your data.

The reverse data flow also exists; if you want to send something back to the sensor then the data will follow that same route.  From your integration to the LNS, from the LNS to a gateway, and from a gateway back down to the sensor.

# The 30,000' View

Obviously it's more complicated in the execution, but at the 30,000-foot view of the network that we're going to be using, you now know everything you need to start your journey into LoRaWAN.

## Next Steps

<div className="next-steps-container">

1. Open a free [LNS Account with MeteoScientific](https://console.meteoscientific.com/front/login) on the MetSci Console.  

2. Poke around, name it something cool, then come back here and hit the next tutorial.

</div>

Rock and roll!

