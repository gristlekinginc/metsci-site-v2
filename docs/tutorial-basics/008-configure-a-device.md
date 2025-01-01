---
sidebar_position: 7
title: Configure a LoRaWAN Sensor
---

# Configure a LoRaWAN Sensor

Ok, you just got a new sensor in the mail.  It came with a `DevEUI`, `AppEUI`, `AppKey` and maybe some other fancy stuff.  

It's set to fire off a packet every 4 hours, but you want to test it by running it every minute.  How do you configure it?

Some devices have bluetooth (`BLE`) connectivity.  The manufacturer will have a config app you can use, and it'll usually be pretty easy.

Other devices are a little nerdier...

# Maximum Nerd

We're going full nerd today.

You'll need the following stuff. 

### Hardware

 - Device: I'm going to use a Dragino LDDS75
 - USB-TTL adapter.  I'm going to use a [Bus Pirate v5](https://buspirate.com/get/).  As I write this (late December 2024) there's a v6 out.  Get it if you want to.  
 - DuPont Wires.  These are what you use to connect the Bus Pirate and the device.  You can [get a set here](https://amzn.to/3BYYfPy) for under $10.
 

![Bus Pirate and LDDS75 sensor](/images/tutorial-basics/008-images/bus-pirate-ldds75.png)

### Software
 - Any Terminal emulator.  I'm using [Ghostty](https://ghostty.org/) because it's fun, but you could use Mac's native Terminal or VS Code or anything.  

I'm using a Mac, you can use Windows.  To be honest, Windows is usually easier.  If you're on Windows, try TeraTerm.  If you want to deeply explore your inner nerd, try [Tio](https://github.com/tio/tio).

### 2. Connect to the Bus Pirate 
Follow the docs over at the [BusPirate page](https://firmware.buspirate.com/tutorial-basics/quick-setup) to connect to the BusPirate, then:


### 3. Set Up UART on Bus Pirate

Now that you're talking to the Bus Pirate, we're going to set it up to talk to the LDDS75 over `UART`.   

In your connected terminal (where you should be once you finish the Bus Pirate setup above), type `m` for Menu, then answer `Y` to the VT100 color compatible question.

When you see the `HiZ>` prompt), press `m` again:

```bash
HiZ> m

Mode selection
 1. HiZ
 2. 1-WIRE
 3. UART
 4. HDUART
 5. I2C
 6. SPI
 7. 2WIRE
 8. 3WIRE
 9. DIO
 10. LED
 11. INFRARED
 x. Exit
```
Choose `3` for `UART`.

Now you'll need to enter the correct connection settings for the Dragino.  For each step it'll give you a little hint of what to put.  Use the following as a guide:

```bash
 UART speed: 9600 baud
 Data bits: 8
 Parity: None
 Stop bits: 1
 Hardware flow control: None
 Signal inversion: Non-inverted (Standard)
```
When you finish and save, you'll end up with this:

```UART>```

Enter `W` to set up your power supply.  Enter `3.30` for volts, then just hit `enter` for maximum current.

It'll look like this:
```bash
UART> W
Power supply
Volts (0.80V-5.00V)
x to exit (3.30) > 3.30
Maximum current (0mA-500mA), <enter> for none
x to exit (none) >
3.30V requested, closest value: 3.30V
Current limit:Disabled

Power supply:Enabled
Vreg output: 3.3V, Vref/Vout pin: 3.3V, Current: 1.9mA
```

Finally, type in `bridge` to put it into bridge mode.  

Once you're in `bridge` mode you're flying blind; you won't be able to see what you type in, just the response.

### 3. Physical Connection from Bus Pirate to LDDS75

Whenever you connect a device over UART (which is what we're doing here), you'll need to make the following physical connnections:

- Ground to Ground.  Usually labled`GND`, and is usually a black wire.
- `TX` on device to `RX` on Bus Pirate, wire color on example below is yellow. 
- `RX` on device to `TX` on Bus Pirate, wire color on example below is orange.

Here's what it looks like.  

**LDDS75 Wiring - UART**

![LDDS75 Device wiring](/images/tutorial-basics/008-images/ldds75.png)

To get the layout, use the Dragino docs (which we'll talk about in a sec), for now, here's the relevant image:

![LDDS75 device layout](/images/tutorial-basics/008-images/ldds-dragino-layout.png)

While you're looking at the device, double check all the switches and the jumper are correctly set:

![LDDS75 Set Up](/images/tutorial-basics/008-images/ldds75-settings.png)

**Bus Pirate Wiring - UART**

![Bus Pirate wiring](/images/tutorial-basics/008-images/bus-pirate.png)

### 4. Talk to the Device
Ok, so we're `bridge` mode on the Bus Pirate.  Let's just make sure we have a good connection.  

Type in `AT+VER=?` and hit `Enter`.  You won't see anything when you type, but something like this should show up after you hit `Enter`.
```bash
v1.1.4 US915
```

If you want to poke the bear, now that you've confirmed you're talking to and hearing back what it says, hit the black reset button (shown in the image above).

That should get you something like this:
```bash
Hardware version:LSN50 RS-485-UART-I2C V1.3
LDDS75 LoRaWAN Distance Sensor
Image Version: v1.1.4
LoRaWan Stack: DR-LWS-005
Frequency Band: US915
DevEui= B7 53 16 EP 32 53 20 G1

Please use AT+DEBUG to see debug info

JoinRequest NbTrials= 72

***** UpLinkCounter= 0 *****
TX on freq 903.300 MHz at DR 0
txDone
RX on freq 926.300 MHz at DR 10
rxTimeOut
RX on freq 923.300 MHz at DR 8
rxTimeOut

***** UpLinkCounter= 0 *****
TX on freq 905.100 MHz at DR 0
txDone
RX on freq 926.900 MHz at DR 10
rxDone
Rssi= -114
JOINED

Join Accept:
Rx1DrOffset:0
Rx2Datarate:8
ReceiveDelay1:1000 ms
ReceiveDelay2:2000 ms
distanceSum:3597

***** UpLinkCounter= 0 *****
TX on freq 904.900 MHz at DR 0
txDone
RX on freq 926.300 MHz at DR 10

Received: ADR Message

rxDone
Rssi= -55

***** UpLinkCounter= 1 *****
```

### 5. Configure Your Device

Each device has a set of commands to configure it.  In general, a query for: `AT commands, YOUR-DEVICE-MAKE-MODEL, documentation` on Google will get you started.

For this tutorial, since we're using the `Dragino LDDS75` we've got two sets of command docs.

We'll use the overarching Dragino Commands doc that lists all the "regular commands" for any Dragino device, and then another doc with the commands custom to the device.

In this case, their [general AT command documentation is here](https://wiki.dragino.com/xwiki/bin/view/Main/End%20Device%20AT%20Commands%20and%20Downlink%20Command/).

The [LDDS75 documentation is here](https://wiki.dragino.com/xwiki/bin/view/Main/User%20Manual%20for%20LoRaWAN%20End%20Nodes/LDDS75%20-%20LoRaWAN%20Distance%20Detection%20Sensor%20User%20Manual/#H3.A0ConfigureLDDS75viaATCommandorLoRaWANDownlink), and I've set the link to go right to the `Configure LDDS75 via AT Command or LoRaWAN Downlink` section.

You can go wild from here with commands.  The general pattern will be `AT+<command>=?` will be your "query" command, to figure out what the current setting is, and then `AT+<command>=<value>` will be how you set it.

For example:
```bash
AT+TDC=?
```

Will return how much time in milliseconds we have between transmit intervals (uplinks).

![Query the transmit interval](/images/tutorial-basics/008-images/example-command-transmit-interval.png)

43,200,000 milliseconds is equal to 12 hours.  Depending on what you want to do, that might work.  If, however, you want to do some testing, whether it's just to confirm connectivity or muck about with payloads or something else, you might want to drop down that interval to 1 minute (or 5, or whatever.)

So...
```bash
AT+TDC=43200000 sets a 12 hour interval
AT+TDC=60000 sets a 1 minute interval
```

If you use the `AT+TDC=60000` you'll start seeing data flow through the UART connection, like this:

```bash
***** UpLinkCounter= 0 *****
TX on freq 904.900 MHz at DR 0
txDone
RX on freq 926.300 MHz at DR 10

Received: ADR Message

rxDone
Rssi= -55
```

And that's it, you're off to the races with configuring a device.  From here, you can use those same documents to figure out downlink commands to send over the air, and once your device is deployed in the field you can manage it with those.  

I would strongly suggest that before you deploy any device, you test it both on the bench and in the backyard. 

Enjoy the LoRaWAN journey!


