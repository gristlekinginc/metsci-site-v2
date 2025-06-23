---
title: Networked Synesthesia
authors: [nik]
tags: [lorawan, government, military, networking, synesthesia]
---

Synethesia is when the expereince of one sense triggers another.  The classic example is seeing colors when hearing music, but you could taste words, smell sounds, or feel textures when you see colors. 

A recent excellent [Freakonomics episode with David Eagleman](https://freakonomics.com/podcast/feeling-sound-and-hearing-color/) sparked an idea on how to combine synthestia with LoRaWAN for spatial awareness in the military context. 
<!-- truncate -->
Dr. Eagleman described the develpment of the NeoSensory vest that captured sound and converted it to vibratory feedback on the torso, allowing deaf people to hear. We're all bathed in sound, but deafness is the inability to translate it into, well, sounds we hear.

By placing vibratory motors through a vest and then translating sounds into a felt experience, the brains of the users "livewired" themselves to hear sound again.  Pretty rad.

Dr. Eagleman managed to get that down from a vest to a bracelet with vibratory motors evenly spaced around the bracelet.  Interestingly, where a vibration is felt can be shifted between 2 motors by changing the power of the buzz in each motor.  The stronger the buzz (comparatively), the closer to that motor the sensation is felt.  This effectively gave them way more "buzz points" which translated into a more granular ability to translate incomin sound waves into signals the brain could use.

Now, if you can hear sounds with a bracelet, it's reasonable to imagine that you could get a sense of other things, including spatial awareness of where other people are if they're transmitting their position.

LoRa is a potential excellent wireless protocol for this; it's robust, low energy, can be encrypted (or could run through [Reticulum](https://reticulum.network/?) so it's definitely encrypted, and long range (that's what LoRa is short for).

Imagine an element of soldiers all wearing a bracelet (or vest, or whatever) who could literally feel where other soldiers in their element were?  

Obviously this could be used by firefighters and other rescue elements in chaotic situations.

By running this over LoRa (or a LoRaWAN) and integrating Reticulum to use multiple communications protocols and integrate other assets (an overhead drone with a LoRaWAN gateway, for example), you could potentially have an extraordinary advantage over a wide area whenever you need to coordinate human activity.

Pretty cool use case, eh?  Keep on crushing out there, and if you need help with IoT sensors, whether it's designed, deployment, or business-fit, please reach out.

:::info Author

**Nik Hawks** is a LoRaWAN Educator & Builder at [MeteoScientific](https://meteoscientific.com/). He writes to educate and delight people considering IoT, and to inspire other IoT nerds to build and deploy their own projects into the world. He runs a [podcast](https://pod.metsci.show) discussing all things LoRaWAN and is psyched to hear about what you're building, whether it's a one sensor playground or a million sensor rollout.

:::