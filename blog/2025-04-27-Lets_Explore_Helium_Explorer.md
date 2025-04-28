---
title: Let's Explore The Helium IoT Explorer
authors: [nik]
tags: [lorawan, business, helium]
---

One of the very first questions any reasonable business owner will have when they’re deciding whether or not to use LoRaWAN to connect their sensors to the internet is, “How do I get coverage?”<!-- truncate -->

With LoRaWAN, you can deploy your own gateways and provide your own coverage, but as I've discussed on [this episode of the MetSci podcast](https://pod.metsci.show/episode/primer-lora-vs-lorawan-how-to-use-it) a few networks exist that already provide coverage and will give you free or very cheap access to it.  One of those is the [Helium network](https://world.helium.com/en/iot/hotspots), a global LoRaWAN.  

We’ll take a look at how to assess whether or not there is already Helium coverage in your area, and if it’s acceptable for your project. Let’s start at their coverage map, found at [`world.helium.com`](https://world.helium.com/en/mobile), which will default to Mobile.

![Helium World Mobile Map](/img/blog/2025-04-27-lets-explore-helium-explorer/world-helium-mobile.png)

Helium has 2 networks.  One is for IoT, and one is for phones.  We’re going to focus on the IoT network, which is the largest LoRaWAN network in the world with over 250,000 LoRaWAN gateways.  

Helium calls these gateways “Hotspots” in an attempt to make this technology relatable to the average person.  I’ll use “gateway” and “hotspot” interchangeably here.

### The Hotspot Map

We’ll start by exploring the Hotspot map, which you can find by [going to the green IoT button on the Helium IoT Explorer](https://world.helium.com/en/iot/hotspots), then clicking it to get dropdown options and selecting “Hotspot Map”.

![Choose IoT Explorer](/img/blog/2025-04-27-lets-explore-helium-explorer/chose-green-iot-then-hotspot-map.png)

You should easily recognize the basic stats, like number of Hotspots and Daily Messages, but “DC burned” may be new to you.  

![Helium IoT Basic Stats](/img/blog/2025-04-27-lets-explore-helium-explorer/helium-basic-stats.png)

Helium is a network powered by cryptocurrency.  The currency, or token, is called an HNT, or Helium Network Token.  It is used to [pay for data credits, or DCs, which allow you to transfer on the network](https://docs.helium.com/tokens/data-credit/).


If you’d like, **you can skip the whole cryptocurrency thing** and just buy DCs with whatever currency you’re used to; dollars, euros, yen, whatever.  If you'd like to try that, you can do it over on the [MeteoScientific Console](https://console.meteoscientific.com/front/login), although I give you the first 400 DC for free. 

### The Cost Of Using The Helium Network

One DC covers up to a 24 byte message and equals `$0.00001` USD.  Yes, that’s a thousandth of a penny.  Over on the MetSci Console (one of many LNS on Helium) I charge a 10x premium, which means you can still run a sensor sending **a packet an hour for a year and spend less than a dollar.**

If you’re sending less than 24 bytes you still get charged for all 24.  If you’re sending more, you’ll get charged multiple DC per message.

You could also buy multiple copies of that message from multiple gateways.

Unlike traditional wireless networks, there is no subscription fee.  You just pay for the data you successfully transfer.

Helium is a permissionless network; there’s no sales staff to talk to first if you want to use it, no crazy sign up process, and if you’ve ever used LoRaWAN before, not much new to learn; you can just use it.  If you need help, check out my [tutorials](https://www.meteoscientific.com/docs/tutorial-basics/LoRaWAN-Big-Picture).

As you can see, Helium is staggeringly transparent.  On April 27th 2025 when I wrote this, 6.3 million messages had been transferred across the network in the last 24 hours at a cost of 10.4 million DC, or $104.81.

![Transparent Data on Helium](/img/blog/2025-04-27-lets-explore-helium-explorer/staggeringly-transparent-costs.png)

You can also see how many Hotspots (gateways) are currently serving the network, about 287,000 as of the time of writing.  If we just do some fast back-of-the-envelope math, you can see that what Helium did using token incentives to build a global LoRaWAN could not have been done in any traditional way.  

If we price a gateway at $100 to buy and deploy, which is on the (very) cheap side, it would have cost a traditional network builder $28,740,000 to deploy today’s network.  Not every company has a cool $27 million to roll out a network.

That number, by the way, will probably shrink over time, stabilizing at (my GUESS) about 150,000 active gateways at any given time, probably providing the same coverage as you currently see with less redundancy.  

:::note
The reasons for the network's changing size go well beyond the scope of this article; if we meet for a coffee sometime I'll walk you through the whole arc of growth and all the deets.  For now, let's stick with exploring coverage.
:::

The ongoing maintenance for gateways on the network is paid for by the people who deployed them, just like any network.  Many are run off their provided internet, but some (including some of mine) are on mountain tops and require a cell backhaul.  

Those are ongoing costs borne by those who either want to earn cryptocurrency by adding something to their home network as well as those who, like me, use the network every day to pull in IoT data about my world, from weather stations to rain tank gauges to soil moisture.

Of course, you might zoom in on an area that doesn’t have a gateway and you want coverage there.  You can always deploy your own.  LoRaWAN gateways can be onboarded onto the Helium network, or you can buy a pre-onboarded one from a manufacturer like [RAK Wireless](https://store.rakwireless.com/products/rak-hotspot-v2-with-free-rak2270-sticker-the-ultimate-tracking-bundle?variant=43023959523526) and deploy it, in which case you’ll be able to use your coverage AND earn a little cryptocurrency.

That leads us to the Coverage map, which you’ll find by going to the green IoT tab at the top right, clicking on it to get the dropdown, and selecting “Coverage Map”.

![Coverage Explorer on Helium](/img/blog/2025-04-27-lets-explore-helium-explorer/helium-coverage-map.png)

### What Does a Gateway Cover?

On the `IoT` --> `Hotspot Map`, you can look for a specific Hotspot if you know its name. For example, `Quick Red Cobra` is one in downtown San Diego California, where I live.  Hotspots are assigned three-word names (Adjective-Color-Animal) randomly when they join the network.  This makes it easier for non-technical people to remember (and refer to) their hotspot.  Not everyone likes calling 'em a `UG56` or `SX1302 based` or the ol' `LPS8N`.

Let’s take a look at Quick Red Cobra and see what we can learn about the coverage this one gateway provides.

![Quick Red Cobra Helium Hotspot](/img/blog/2025-04-27-lets-explore-helium-explorer/quick-red-cobra.png)

The first thing you'll probably notice is all the green hexes.  Helium uses the Uber h3 hex system to map out coverage, focusing on the resolution 8, or `res 8` sized hex, which is about .73 square kilometers.  

Uber has written about this system extensively and open sourced it; you can [learn more about it here](https://www.uber.com/blog/h3/).

The very short version is that a hexagonal shape does a great job of consistently mapping a globe like our planet.  Using different size hexes allows you to map out an area of the world in any level of detail.

The sizes, or "resolutions", range from a `res 0` hex, of which there are only 110 in the world, each covering about 4.3 million square kilometers, all the way down to a `res 15` which has over 569 billion hexagons and maps to just under a square meter.

If you want to check out all the res sizes, [here’s the list](https://h3geo.org/docs/core-library/restable).

If it’s good enough for Uber to find you at the airport among the other hundred people waiting in the rideshare lot, it's good enough to provide an excellent map of coverage for a LoRaWAN.

Every hotspot (or gateway, as you like) will cover a given number of `res 8` hexes.  Quick Red Cobra has reported coverage from 500 hexes with at least a -130 dBm signal.  Not bad! 

![Quick Red Cobra Hexes covered](/img/blog/2025-04-27-lets-explore-helium-explorer/quick-red-cobra-hexes-covered.png)

How do you know a hex is covered?  

You can use three methods; the easy way, the paid way, or the DIY way.

#### The Easy Way To Check Coverage

The easy way is to just look at what’s reported on this image.  In this case, the hotspot Quick Red Cobra has received data from 500 hexes.  This reported coverage data comes from a project called DIMO, which sells a vehicle data device called a Macaron that transmits information about a vehicle gathered from its OBD port via the Helium LoRaWAN.

If a vehicle with a DIMO Macaron has transmitted data from a hex covered by a gateway, that hex will show you the coverage strength and what gateways received the data.  

#### The Paid Way to Check Coverage

The paid way is to use your own device, like a [GLAMOS mapper](https://glamos.eu/).  You'd use your GLAMOS (or any mapper) to map a specific location, then assess the readings from your device using the GLAMOS app.

#### The DIY Way to Check Coverage

The DIY way is to build your own mapping solution.  That's fun and rewarding, but for most instances, especially in the developed world where a ton of Hotspots are already deployed with plenty of DIMO vehicle traffic to map out signal, the Helium Coverage map is good enough, or for places where you're not sure (or need specific indoor coverage) the GLAMOS app fills in any gaps.

### What About Coverage...HERE?

Now, it’s likely that you’re more interested in actual coverage than which gateway is providing it.  For that, you can go [back to the coverage map](https://world.helium.com/en/iot/coverage) and zoom in on any given area.

![Grenoble Helium Coverage](/img/blog/2025-04-27-lets-explore-helium-explorer/grenoble-helium-coverage.png)

We’ll use the town of Grenoble in France for our example. I’ve zoomed in to it, and clicked on one of the green hexes in the Les Charmettes area.  

Here we can see that 17 gateways provide coverage at better than -130 dBM for this hex, with a best RSSI of -83 dBm.

![17 Gateways In Grenoble](/img/blog/2025-04-27-lets-explore-helium-explorer/17-gateways-in-grenoble.png)

If you have specific dBm requirements, you can use the slider at the bottom right of the screen to set those.  For example, with a minimum RSSI of -108 dBm our redundancy drops to 9 gateways.  This is pretty much what I’d expect in the birthplace of LoRa; excellent coverage all around town.

Now, a global network does not equal ubiquitous coverage, and you’ll notice plenty of spots on the map where no coverage by a vehicle with a DIMO unit has been recorded.

If you need coverage in the mountains, or anywhere a vehicle can’t go, you can always grab any LoRaWAN device and fire off a few packets, or use the GLAMOS app, or buy a Helium Mapper from [RAK](https://store.rakwireless.com/products/field-mapper-for-helium-with-plug-play-and-3rd-party-mode-rak10701-h?variant=43920609444038) or [Seeed](https://www.seeedstudio.com/WioField-Tester-Kit-p-5282.html) to see what specific coverage is like. 

![Helium Field Mappers](/img/blog/2025-04-27-lets-explore-helium-explorer/helium-mappers.png)

You can also build your own Mapper [following instructions](https://docs.helium.com/iot/coverage-mapping/quickstart) over on the Helium Docs site. 

That wraps it for how to assess LoRaWAN coverage for anywhere in the world on the Helium network.  If you’d like to see coverage on other networks, excellent websites like [Coverage Map](https://www.coveragemap.net/) offer maps of [TTN](https://www.thethingsnetwork.org/) and other networks.  

Not every LoRaWAN offers public mapping information like this (many of them have their own internal tools to manage and monitor their private networks), but if you’re looking for an easy way to see if there’s the kind of LoRaWAN coverage you need for your IoT solution, the Helium World Explorer is an excellent place to start.

Happy coverage hunting!