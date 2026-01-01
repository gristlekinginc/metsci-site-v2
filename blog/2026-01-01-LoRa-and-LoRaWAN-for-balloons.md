---
slug: lora-lorawan-for-pico-balloons
title: "Making Line Of Sight Work 12 Kilometers Up"
authors: [nik]
tags: [pico balloons, meteo science, lorawan, remote sensing, lpwan]
image: /img/blog/2025-11-30-iot-connectivity/NEEDS-AN-IMAGE
description: "Bringing low power wide area networks to the skies in support of atmospheric science."
date: 2026-01-01
---

## Let's Talk LoRa For Atmospheric Science

In the past few decades, citizen scientists have stretched the limit of what's possible for the average person to collect when it comes to atmospheric data.

One of the ways this has happened is through pico balloons.  Unlike the much larger, up-n-burst weather balloons that are released every day by various weather predicting organizations, pico balloons are smaller, far more persistent, and much cheaper. <!-- truncate -->

A pico balloon ranges in size as it goes up, expanding from a flaccid and floppy 0.0325 cubic meters, (think of billowing carry-out plastic shopping bag) to a tight spheroid of about 0.15 cubic meters (a decent sized beach ball) at an altitude of 13 km or 42k feet, about 10,000 feet higher than commercial airliners typically fly.  "We have reached our cruising altitude of 32,000 feet, sit back and enjoy the flight" is something you may have heard before.

### Aircraft Hazards

Of course, commercial flights do go up to 45,000', and one of the first questions you might have is "what happens when a 10,000 lb jet engine ingests a 17 gram circuit board attached to a small balloon filled with hydrogen?"

The answer, so far, is almost nothing. A jet engine can ingest a 5.5 lb (that's just under 2,500 grams) bird, as seen in [this video](https://www.youtube.com/watch?v=jTKfFxwpbUU&t=29s), so a tiny little PCB floating along at the end of a balloon is basically unnoticeable. 

In late 2025, a United flight probably hit a pico balloon, smashing the windshield and giving the pilot mild injuries, and the US Air Force has been scrambled to shoot down a pico balloon, so the chance of injury and damage isn't zero, but driving your car on a wet day in San Diego is about 600,000x more dangerous to you (and others).

### Balloon Connectivity

Of far more interest is how the balloons communicate. At 40,000' feet you've got an exceptional viewshed, but it's also bloody cold, so getting the energy to transmit can be problematic.

I'll deal with the challenges of vacuum and temperature in another article.  For now, we'll focus on connectivity.  Currently, most pico-balloonists ([with exceptions](https://picoballoon.ist/2022/04/24/lorawan-tracker-pbf-23/#more-1264)) use either APRS (Automatic Packet Reporting System) or WSPR (Weak Signal Propagation Reporter).

APRS runs around 144 MHz, which is about a 2 meter wavelength.  WSPR runs on a couple of frequencies, but 14 MHz (20 meter) is the most commonly used.

:::note
My apologies to the ham radio operators reading this who are busy cleaning the spittle off their screens after spluttering about how I'm not being precise here.  

In this case, precision just clutters things up, and we're already mixing up meters and feet, so I'll continue rolling with approximations when it comes to frequencies, at least for this article. 
:::

The giant problem with APRS and WSPR splits into two parts:  Hardware (antenna) fragility, and length of transmission which affects power usage.

### WSPR Antenna Fragility

Pico balloon payloads (what the balloon is lifting) come in under 20 grams, sometimes as low as 10 grams.  That doesn't give you much room for robust antenna wire, and with WSPR payloads you need 33' of wire for a half-wave dipole.  

Even at 34 gauge magnet wire (which is only slightly thicker than a human hair) that antenna still weighs 3 grams and will snap if you sneeze on it. 

The upside is radio waves at that frequency can bounce off the ionosphere and travel halfway around the world, which is helpful when the balloon is over the middle of the ocean. 

Of course, it takes a while to get those transmissions out, just under two minutes, so the power requirements per transmission are higher than if you just need a quick burst.

### Rugged LoRa Antennas

LoRa, on the other hand, is a 33 cm wavelength, so a 1/4 wave antenna can be just 8 cm and printed on a circuit board. 

It also blasts all its information on an uplink that lasts milliseconds, keeping power requirements per transmission low, and opening up opportunities for more frequent, most data-dense uplinks.

The drawback of course is that the normally stunning range of LoRa (400 km and beyond with clear line of sight) still isn't enough to cross oceans, which bend well over the horizon.

### Forbidden Fruit: LoRa x LoRaWAN

Now, most people who pay attention to these things are either LoRa people or LoRaWAN people, busying themselves with building their networks and only occasionally hurling mild epithets about mesh vs global across the radio protocol fence.

Very generally, **LoRa** is the radio protocol used for by those building robust, small, standalone mesh networks with no backhaul, and **LoRaWAN** is for building an internet-connected gateway network that can process thousands to millions of node signals. 

By combining, or rather, alternating between the two, the possibility exists to leverage the best of both.

A pico balloon payload that could form an **ephemeral mesh** with other balloons leverages the range of LoRa at 40,000', transmitting data from one balloon to the next.  Sending that data to every balloon in the mesh network means only one balloon needs to be in contact via LoRaWAN with earth-bound gateways in order to get the data into, ironically, "the cloud".  

:::note
A 60 balloon network could theoretically cover 9 million square miles, or the US, China, and Canada. 
:::

There's another huge advantage to using LoRa; it's license free.  You don't need a ham license to transmit, you just need access to a network.  I'm biased here and think you should use Helium through the [MetSci Console](https://console.meteoscientific.com/front/login) for the LoRaWAN aspect, but you could use any LoRaWAN, and LoRa itself doesn't even require the WAN part; you just set up your own mesh.

All this isn' to claim that a floating point-cloud of balloons would provide reliable coverage of a trade war including an impartial judge, but at under $100 per balloon launch, it's a pretty cheap way to gather lots of atmospheric data over civilizations.

### Data Thickness
Another limitation of WSPR is how thin the data is.  Over a two minute transmission, even [the best of the hams out there are only able to get in 6 bytes on WSPR and a few tens of bytes per frame on QRP Labs telemetry](https://www.youtube.com/watch?v=e-SyV5K_WRc).

This is still incredibly impressive, as they're sending this halfway around the planet with just a few milliwatts.

However, it's not LoRa, which trades raw sensitivity and ionosphere magic for shorter, much thicker slabs of data.  Even at its slowest, a single LoRa uplink can carry tens to hundreds of bytes in milliseconds, not minutes.

To put some rough numbers on it:

| Protocol | Payload Size | Transmission Time | Power | Range/Coverage |
|----------|--------------|-------------------|-------|----------------|
| WSPR | ~6 bytes | ~110 seconds on air | Milliwatts | Global reach via ionospheric propagation |
| APRS | ~30–60 bytes | Tens of milliseconds | Hundreds of milliwatts | Line-of-sight + terrestrial digipeaters |
| LoRa (SF12, 125 kHz) | ~20–50 bytes (practical, reliable payload) | ~1–1.5 seconds on air | Tens of milliwatts | Extreme line-of-sight range |
| LoRa (SF7–SF9) | 100+ bytes | &lt;100 ms on air | Very low energy per bit | Requires stronger link margin |

Even at conservative settings suitable for a solar-powered pico balloon, a single LoRa packet can carry an order of magnitude more data than WSPR, while consuming less total energy per bit.

That fundamentally changes what you can measure.

Instead of encoding altitude into transmit power steps or squeezing pressure into clever bitfields, LoRa allows you to send:

- Full GPS fixes
- Raw pressure, temperature, and humidity values
- Diagnostic voltages
- Sensor health data
- Time-correlated samples

All without heroic compression tricks (although those are admittedly pretty rad.)

### Power: Energy per Bit Matters

Energy per transmitted bit is a useful metric for pico balloons.

WSPR looks extremely efficient because its transmit power is low, but it stays on the air for almost two minutes. LoRa uses slightly higher instantaneous power, but for milliseconds to seconds, not minutes.

From an energy budget perspective:

WSPR spends most of its energy keeping the transmitter alive, while LoRa spends its energy moving information.

For a payload living off thin-film solar cells and supercapacitors, that distinction matters.

It also means LoRa scales better with burst-style sensing: wake up, sample, transmit, sleep — a pattern that aligns very well with stratospheric thermal cycles.

### The Real Trade-Off: Coverage, Not Capability

None of this makes LoRa “better” than WSPR in the absolute sense, and it’s certainly not an argument for replacing the WSPR balloons already in the atmosphere.

The real difference is **what you can move, how far, and under what conditions**.

#### WSPR is unmatched when:

* The balloon is over the open ocean
* There is no ground infrastructure below
* Ultra-long-range reception matters more than resolution
* You’re willing to trade data density for global reach

#### LoRa shines when:

* Line of sight exists (and at 40,000 ft, it often does)
* Ground gateways are reachable — even intermittently
* You want **real measurements**, not encoded hints
* Data richness matters more than absolute range

At altitude, my hypothesis is that those conditions overlap far more often than people expect. A balloon doesn’t need continuous coverage — it just needs **enough opportunities** to get its data out.

That’s why LoRa and LoRaWAN on pico balloons isn’t a replacement for WSPR or APRS. It’s a **different layer in the stack**.

## Mission First, Protocol Second

It’s tempting to frame this as a contest between radio technologies, but that misses the point.

Wireless systems don’t exist in a vacuum — they exist to serve a mission.

Before choosing a protocol, the real questions are:

* Do I care more about **where the balloon is**, or **what it’s measuring**?
* Do I need **global reach**, or **thick data when coverage exists**?
* Is my mission tolerant of gaps, or does it need constant reporting?
* Am I optimizing for **long range low density**, **mid range high resolution**, or **both**?

WSPR answers one set of those questions extraordinarily well.

LoRa answers a different set just as convincingly.

And once you stop treating them as mutually exclusive, hybrid designs start to make sense:

LoRa for dense, local and regional science when line-of-sight and gateways exist; WSPR or other long-haul modes for sparse, ultra-long-range persistence when they don’t.

That isn’t protocol heresy — it’s engineering.

At 12 kilometers up, the sky gives you options. The hard part isn’t choosing the “best” radio, it’s deciding what you want to learn when you have a (literally) 30,000' view.

Let's go have a look!

*****

In addition to the linked sources above, giant thanks to the [Pico Ballon Group](https://groups.io/g/picoballoon), my buddy gradoj over at [StratoSonde](https://stratosonde.org/), and of course, [Dr. Matthew Patrick](https://github.com/mrpatrick1991) for nerd-sniping me into pico balloons in the first place. 
