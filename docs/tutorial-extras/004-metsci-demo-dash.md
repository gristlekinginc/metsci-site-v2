---
sidebar_position: 4
title: MetSci Demo Dashboard 
---

# Build a Custom Dashboard

Ok nerds, let's do something rad with [Helium](https://www.helium.com/) and build a dashboard for a sensor.

**You don't actually have to be a nerd to do this.** As long as you can get the hardware listed below, follow directions, and copy/paste, you're going to end up with a working dashboard.

When you're done, this'll be something you can share with your friends to let them know when the rain barrel is full (or if you're Joey's friends, when the sauna is hot)!  

I know, I know, you could use a ready-made service like [Datacake](https://datacake.de) for public dashbaords, but...we're nerds, and wherever possible we build our own things.

Relax, it won't be super hard.  We'll use a few scripts to make installing things secure and easy, so they just "work".  

My goal here is to enable a non-technical person to build your own "no-subscription" public or private dashboards for about $200, most of which you'll spend on equipment you'll use in every other IoT project you do.  

IoT stuff has been super fun for me to explore, and I'm pumped to share it with you.  This is pretty much a love letter to you from me about IoT.  

Final note: This tutorial was made possible by a generous grant from the Helium Foundation's IOTWG; huge thanks to them for the support.

Enjoy!

### Get After It

Make sure you have the following on hand:

### Hardware

#### Core Development Hardware, ~$150 (use this for your next 50 projects)
 - [Rasbperry Pi 4 with 4 or 8 GB RAM](https://amzn.to/3DAVCnO), about $60. 
 - [SD Card for Pi](https://amzn.to/40ha8K5), about $10 
 - External SSD for the Pi, about $30.  IoT data sets can get pretty big and you'll want plenty of space beyond the SD card on the Pi.  SD cards can also wear out if you write to 'em a bunch. Something like [this](https://amzn.to/3PbhbNY) is fine.
 - USB-TTL adapter (the thing that allows you to communicate directly over-the-wire with the sensor)
    - [BusPirate](https://buspirate.com/)  This is what the mighty Teague uses, and I recommend it. I used the v5 for this, but the v6 is already out!  $40-80
    - Cheapie [Amazon Kit](https://www.amazon.com/dp/B07VNVVXW6?ref=ppx_pop_mob_ap_share) (thanks to GreyHat for the rec) $14
    - [Segger J-Link EDU Mini](https://www.sparkfun.com/products/24078) - $60 on Sparkfun
 - 2 x [USB A to USB C cables](https://amzn.to/4aoqS5N) (connecting the Pi to the SD card and the Bus Pirate to your computer)
 - [Dupont wires](https://amzn.to/4h0Jn2w) for connecting the Bus Pirate to the sensor - $7

:::tip
If you want a fancy case for your Pi (NOT needed), this is what I use: [FLIRC case](https://amzn.to/3E9OEpM) for Raspberry Pi 4B, about $16
::: 

#### Sensor, $60-80
- Dragino LDDS 75 sensor.  You can buy one at [RobotShop](https://www.robotshop.com/products/dragino-ldds75-lorawan-distance-detection-sensor-915-mhz) for $60-80.

:::note
1. The Pi, SD, SSD, and USB cables are Amazon affiliate links.  If 300 of you use those I'll probably be able to pay half my annual $12 domain name bill with the commissions.
2. I'm doing this whole thing on a Mac.  If you're on Windows, there'll be a couple commands that are slightly different, usually stuff like using `CMD` instead of `CTRL`.  I'll try to call them out as we go.
:::

### Not-Hardware
    - Custom domain.  For this tutorial I'll be using mine, `gristleking.dev`.  If you don't already have a domain, I'd **strongly** recommend buying one at [Cloudflare](https://cloudflare.com).  They're about $12/year and buying it there makes everything else a little bit easier.
    - If you have a domain already, you'll need to set up your domain's name servers to point to Cloudflare.

### Notes on what you "Need"
You don't actually NEED a USB-TTL adapter, but it's generally good practice to have one hanging around the work bench if you're any kind of aspiring nerd.  You could use downlinks instead of the adapter to make changes to your sensor, but in practice I've found that to add both complication and time (especially if you have to wait for the next uplink & you get your downlink command wrong...ask me how I know)

You *could* do this without a custom domain by hosting in the cloud and managing tunnels with Cloudflare, but then you're on the hook for cloud hosting, which is probably $6/month at the cheapest.  A domain is something like $70/year for an expensive `.ai` one and $12/year for a cheap one. Trust me, just buy a domain. 

Having your own domain makes part of this workflow way simpler, plus it's just cool to have your own domain.  Ask Larry at Google or Steve at Apple.  Having a custom domain is cool. 

## Set Up Overview

1. **Set Up Your Rasbperry Pi:** Basic setup and security

2. **Install Services:** Node-RED, InfluxDB, Grafana, integrate external SSD.

3. **Cloudflare:** Set up tunnels, tokens, applications, and policies.

4. **Sensor:** Get the sensor sending data through MetSci

5. **Local Integration Testing:** Node-RED flows, integrate InfluxDB, create Grafana dashboards.

6. **System Maintenance & Troubleshooting:** Keep it rolling smooth, yo.

---
## 1. **Setting Up Your Rasbperry Pi**
### A. Basic Setup
Rather than re-writing (and constantly updating) this part, I'm going to suggest you [follow the official docs](https://www.raspberrypi.com/software/) for the first part of this and load **Raspberry Pi OS Lite (64-bit)**.  If you've never done it before, that's ok. 

The basic flow is to write (or "flash") the OS onto an SD card using your computer, then plug the SD card into your Pi.  After that you'll find the Pi on your local network and you can SSH in.  All of those things have lots of tutorials on the internet already.  

:::tip
Starting with a fresh OS install is recommended to avoid conflicts with existing packages.
:::

Once you've set up your Pi, connect it to your local network (Ethernet/LAN cable strongly preferred over WiFi).  SSH in using Terminal, then update/upgrade with:

```bash
sudo apt update && sudo apt dist-upgrade -y && sudo apt autoremove -y
```

### B. Securing Your Pi

Your Pi can be made a bit more secure with a few commands.  We're going to wrap them all up into one.  This is going to get the latest security patches, make sure everything is up to date, then set some basic firewall rules. 

There's nothing ultra fancy in here, just generally good Pi housekeeping.  Answer `y` when it asks you about the SSH port. 

```bash 
curl -sSL meteoscientific.com/scripts/secure-pi.sh -o secure.sh && chmod +x secure.sh && sudo ./secure.sh
```

Once you've run it to the end, it'll ask you if you want to reboot.  Just type in `y` and hit `Enter`.


## 2. **Install Services (Node-RED, InfluxDB, Grafana)**

### A. Service Install Script

Copy & paste the following command into your Pi's Terminal:

```bash
curl -sSL meteoscientific.com/scripts/install-dashboard-v3.sh -o dashboard.sh && chmod +x dashboard.sh && sudo ./dashboard.sh
```

During the installation you'll get a few questions and warnings. 

:::note
If you have a 4GB RAM Pi, you'll see a warning message about performance.  This is just to clarify that if you want to run a shitload of sensors frequently you'll probablly be better with an 8GB RAM Pi.  For most people, **4GB is fine** and **8GB is overkill**.
:::

The script will set up your "Organization" name (used in the database).  The default is `MeteoScientific`, feel free to change that if you'd like.  This is mostly a structural thing, so just use something descriptive.

It'll also set up a bunch of random sci-fi usernames for the various services.  

You can accept all the defaults and be fine, or feel free to change them if you want different user names.  Don't get too twisted up with it; again, the defaults are fine.

:::warning
Make sure you copy down your credentials when you see 'em at the end.  They'll be saved to a file in your home directory just in case, but you really should copy them down and then delete that file before you move on.
:::

After installation, visit your shiny new setups:
   - Node-RED: http://your-pi:1880
   - InfluxDB: http://your-pi:8086
   - Grafana: http://your-pi:3000


**DON'T skip copying down your credentials** (instructions are at the end of the script) and then deleting that file.  

```bash
cat /home/<YOUR-USER>/metsci-credentials.txt
```
That will print out your credentials, which you'll need to use later.  Save those somewhere safe, then delete the file with:
```bash
rm -rf /home/<YOUR-USER>/metsci-credentials.txt
```

### B. Integrate External SSD 
Now that your services are installed, let's make sure InfluxDB is using the SSD.

Using a USB cable, connect your external SSD to one of the USB 3.0 ports on your Pi. Here I'm using PoE to power and connect the Pi, and the SSD is just laid on top.  The case is a 3D print so I can mount the Pi on the wall in my server (and clothes) closet.

![Raspberry Pi mounted on closet wall with SSD](/images/tutorial-extras/004-images/raspberry-pi-with-ssd-closet.png)

Then, in your Terminal:

1. Verify the SSD is detected:
   ```bash
   lsblk
   ```
   You should see something like this:
   ```bash
   core@myrmytron:~ $ lsblk
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sda           8:0    0 111.8G  0 disk 
    └─sda1        8:1    0 111.8G  0 part 
    mmcblk0     179:0    0 116.2G  0 disk 
    ├─mmcblk0p1 179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2 179:2    0 115.7G  0 part /
   ```
See how my sda lists `sda1`?  We'll use that `sda1` in this next command; yours may be named differently.

2. Mount the SSD to a permanent location, e.g., `/mnt/ssd`:
   ```bash
   sudo mkdir -p /mnt/ssd
   sudo mount /dev/sda1 /mnt/ssd
   ```
3. Set the ownership for your user.  In my case, that's `core`.  You may have named yours different.  Replace **core:core** with your user name.
   ```bash
   sudo chown -R core:core /mnt/ssd
   ```
4. Open up `/etc/fstab` so we can set this up for persistence.
   ```bash
   sudo nano /etc/fstab
   ```
   In your `/etc/fstab`, add a line like this, replacing `sda1` with the correct partition identifier from `lsblk` above.
   ```bash
   /dev/sda1 /mnt/ssd ext4 defaults 0 2
   ```
   Save and exit with `CTRL-X`, then `y`, then `Enter`.

Nice work!

Now make sure you did that right. Verify SSD with the following commands:

After mounting:

1. Check mount: `lsblk`
   ```bash
   # You should see your SSD mounted at /mnt/ssd
   NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
   sda           8:0    0 111.8G  0 disk 
   └─sda1        8:1    0 111.8G  0 part /mnt/ssd
   ```

2. Verify permissions:
```bash
ls -l /mnt/ssd`
```
You should see something like this:
   ```bash
   total 16
   drwx------ 2 core core 16384 Nov 30 14:41 lost+found
   ```
The `lost+found` directory is normal for a fresh ext4 filesystem.

3. Test write access:
```bash
   touch /mnt/ssd/test.txt
```
 
Verify it was created
```bash
ls -l /mnt/ssd/test.txt
```

You should see something like:
```bash
-rw-r--r-- 1 core core 0 Jan 4 22:45 test.txt
```
   
Clean up
```bash
rm /mnt/ssd/test.txt
   ```

If any of these commands fail with "permission denied", your ownership isn't set correctly.

Nice work, you've set up the major components of your dashboard.  Now let's set up the Cloudflare tunnel to securely move data between your Pi and the internet.


## 3. **Cloudflare:** Tunnels, Applications, and Tokens

Cloudflare provides a secure connection called a "tunnel" between your Pi and the internet.  Within a tunnel will be different public hostnames for different services, like one for Node-RED to send data there from the MetSci LNS.  You could also setup a public hostname for Grafana to display data from your Pi onto a public dashboard, or something directly to InfluxDB.

For this tutorial, we're going to set up two public hostnames, one for Node-RED and one for Grafana.  

We're not going to set one up for InfluxDB (because it's not needed).  The point here is to expose you a bit to what you can do with Cloudflare.

Ok, back to tunnels.  Think of a tunnel like a big PVC pipe that connects your Pi to the internet.  Within that pipe are lots of little straws that carry separate types of information.  Each straw is a public hostname in the tunnel, and within those straws you'll have different types of data (from different types of sensors) moving through.  Each type of data needs to get authenticated before it can get sent through the straw; it needs a token to authenticate it.

Within a public hostname, each sensor type you set up in MetSci will need its own token to keep the http integration secure.  

To start this off, login to [Cloudflare](https://www.cloudflare.com/). I'm assuming you've already set up your domain with Cloudflare, so when you log in you'll see something like this:

![Cloudflare Dashboard](/images/tutorial-extras/004-images/cloudflare-dashboard.png)

### A. Set Up Zero Trust

You'll need to set up your Zero Trust account in Cloudflare (yes, you can use the free option.)  

If you haven't set up Zero Trust yet, you may not see "Zero Trust" in your menu.  If that's the case, navigate to your domain name, look for `Access` in the left menu, then hit the `Launch Zero Trust` blue button on the right, then click it and set up ZT.

![Cloudflare Zero Trust](/images/tutorial-extras/004-images/set-up-zero-trust.png)

Once you have it, you'll see it in your **main** (not your domain) Cloudflare menu, like this.

![Cloudflare Zero Trust](/images/tutorial-extras/004-images/go-to-zero-trust.png)

With Zero Trust on and ready to go, let's set up the Pi.

### B. Prepare Your Pi for Cloudflare

In the Pi terminal, install Cloudflare Tunnel. As always, kick things off with a system update:
```bash
sudo apt update && sudo apt upgrade -y
```
Next, download the Cloudflare binary to the Pi.  I'm running a Pi 4B with 64-bit ARM architecture (use `uname -m` to check yours if you're unsure)
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared
```
That may take a few minutes depending on your connection speed.

When it's done, let's do a few nerdy things (making the binary executable, moving it to a system path, then verifying the installation).
Make it executable:
```bash
chmod +x cloudflared
```
Move it to a system directory:
```bash
sudo mv cloudflared /usr/local/bin/cloudflared
```
Verify the installation:
```bash
cloudflared --version
```

That should get you here on your Pi:

![Cloudflare tunnel installed and ready to set up](/images/tutorial-extras/004-images/set-up-cloudflare-tunnel.png)

### C. Create a Tunnel In Cloudflare Zero Trust

With Cloudflare's Zero Trust on and our Pi set up, we're going to set up the actual tunnel. 

Back in your Cloudflare account, in Zero Trust, go to `Networks --> Tunnels --> Add a tunnel`.

![Zero Trust Network Tunnels](/images/tutorial-extras/004-images/zero-trust-networks-tunnels.png)

On the next page (not shown here), select `Cloudflared`, **NOT** `WARP Connector`, then choose a tunnel name.

![Name your Cloudflare tunnel](/images/tutorial-extras/004-images/choose-tunnel-name.png)

Save it and you'll be taken to the Configure page.  Go down to `Install and Run Connector` and copy the one on the right.

![Install and run connector](/images/tutorial-extras/004-images/install-and-run-connector.png)

### D. Add The Tunnel To Your Raspberry Pi
We've already installed Cloudflare on our Pi, so on your Pi just run the command they gave us:

`sudo cloudflared service install super-duper-alpha-numeric-string`

You should see a success message, like this. 

![Tunnel successfully installed](/images/tutorial-extras/004-images/tunnel-success.png)

Double check that on your Pi with a status request: 

```bash
sudo systemctl status cloudflared
```

That should give you something like this:

![Cloudflare tunnel running on Pi](/images/tutorial-extras/004-images/cloudflare-tunnel-running.png)

You can use `CTRL-C` on a Mac to stop the output; it won't stop the tunnel.

### E. Setting Up Routes

Hit `Next` at the bottom right of your Cloudflare Configure tunnel screen.

![Cloudflare tunnel configured](/images/tutorial-extras/004-images/cloudflare-next-after-installing-connector.png)

#### 1. Node-RED

Add `node-red` in the Subdomain field, choose your domain (I'm using `gristleking.dev`)

For Type choose `HTTP`, then set the URL to `localhost:1880`.

Then the blue `Save tunnel` button at the bottom right. 

![Configure your initial public hostname](/images/tutorial-extras/004-images/cloudflare-initial-tunnel-setup-route-setup.png)

You'll be taken back to the Tunnels page.  Click on the three stacked dots on the right side of the row for your tunnel, then click `Configure`.

![Adding a new public hostname to a Cloudflare Tunnel](/images/tutorial-extras/004-images/cloudflare-add-route-to-tunnel.png)

Now select `Public Hostname` and click `Add a public hostname`.

![Add a new public hostname](/images/tutorial-extras/004-images/cloudflare-select-add-public-hostname-for-new-route.png)

Set it up as follows, noting the new addition of a `Path` using `d/*` to allow access to the Grafana dashboard.

```
-Subdomain: grafana
-Domain: <YOUR-DOMAIN>.com
-Path: d/*
-Type: HTTP
-URL: localhost:3000
```

It should look like this when you're done.  

![Add the hostname and post for Grafana](/images/tutorial-extras/004-images/cloudflare-add-public-hostname-grafana.png)

Click `Save hostname`.

You can now see both your public hostnames for your tunnel.  Cool, right?

![Confirm both your public hostnames](/images/tutorial-extras/004-images/cloudflare-both-public-hostnames-added.png)


### F. Check Your Subdomain in Cloudflare
Head back to the Cloudflare main menu and choose your domain, then `DNS`, then look for the subdomain you just set up.  I usually add a note to mine, something like `this is for Node-RED for the MetSci Demo Dash project`, just so future me has a clue as to what's going on. 

![Add notes to your DNS records](/images/tutorial-extras/004-images/cloudflare-dns-route-note.png)

#### 1. Node-RED Application & Token

Now that we have our sub-domain of `node-red.gristleking.dev` set up, we'll need to create three things specific for our LDDS75 MetSci LNS Application:

```
1. A Service Token
2. A Zero Trust Application
3. An HTTP Integration in MetSci
```

Remember, a `MetSci Application` is a group of sensors that share the same data structure.  If you were monitoring 30 rainwater tanks with 30 LDDS75 sensors, all of the sensors would be in one MetSci Application, which would map to one `Cloudflare Application`.  

Each Cloudflare Application will need a `Service Token` and a `Cloudflare Zero Trust Application` to secure the data flow between the MetSci LNS and the Pi.  If we quickly zoom out, one way to visualize it is like this:

```
\ sensor -- sensor -- sensor -- sensor /
 \ ------- MetSci Application ------- /
  \ ------- HTTP Integration ------- /
   \ ------- Cloudflare Tunnel ---- /
    \ ---- Cloudflare Subdomain -- /
     \ ------- Service Token ---- / <--We are here
      \  Zero Trust Application  /
       \ ----- Raspberry Pi --- /
```


### G. Create A Service Token for NODE-RED

In Cloudflare, back in Zero Trust, go to `Access-->Service Auth` and click `Create Service Token`.  

Name your token something descriptive (I'm using `ldds75`) and set the duration to `Non-expiring`.

![Add a Service Token in Zero Trust](/images/tutorial-extras/004-images/cloudflare-configure-service-auth-token-ldds75.png)

That will give you an `Access ID` and an `Access secret`.  Save **both the headers and the access codes** in a secure place.  We'll need them when we set up the HTTP integration in MetSci.  What you save should look like this:

```
CF-Access-Client-Id: 5xxxxxxxxxxxxxxxxxxxxxxxx3.access

CF-Access-Client-Secret: ffxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx2
```
Hit the `Save` button at the bottom right.


### H. Add A Zero Trust Application

#### Node-RED Applications

With our Service Token set up, go to `Access-->Applications` and add a new Cloudflare Application.  

![Add a Zero Trust Application](/images/tutorial-extras/004-images/zero-trust-applications.png)

Select `Self Hosted`

#### Application Details 

We're going to set up 3 Applications to start.  Two are for NOD-RED, we'll start with those:

 - a "global" applications that references all tokens for Node-RED. 
 - a specific application that references the `ldds75` token and restricts access to the `node-red/metsci-ldds75-data` path.

#### Global Node-RED Application
Let's start with the global Node-RED application. 

Set the Application name to `Node-RED` and set the `Session Duration` to `24 hours`.  Then set the subdomain to `node-red`, the `domain` to `<YOUR-DOMAIN>.com`, and the `path` to `*`.

![Add a global application](/images/tutorial-extras/004-images/cloudflare-global-application.png)

Scroll down to the bottom and click `Next` to proceed to the `Policies` section.  Here we'll set up a Policy rule that requires anything using this Application to have a valid token.

Set the policy name to `Node-RED` and set the Action to `Service Auth`, leave the duration as is.

Scroll down a bit until you see `Configure rules`.  On the Selector choose `Any Access Service Token`.  It will automatically fill in a value of `Any non expired Service Token will be matched`.

![Add a policy rule](/images/tutorial-extras/004-images/cloudflare-global-application-policy.png)

Hit `Next` and scroll down to the bottom of the next page (past `CORS`, `Cookies`, and `Additional Settings`), then click `Add Application`.

#### LDDS75 Application

Now you'll create the LDDS75 Application.  Hit the `Add Application`, then `Self Hosted` (just like last time), then give it a descriptive name like `ldds75`.  

Leave the session duration at `24 hours` then enter the subdomain, domain, and path it'll use.

In this case, use `node-red`.`gristleking.dev`/`metsci-ldds75-data`.  We'll use that path later when we set up our Node-RED flow.

![Configure Zero Trust Appication](/images/tutorial-extras/004-images/cloudflare-configure-application-details.png)

Scroll down past `Application Appearances` and `Tags` etc to the bottom.

Click `Next` to proceed to the `Policies` section.  

#### Policy Rule

We'll use the same `Service Auth` policy as the global application, but this time we'll restrict it to the `ldds75` token.

Set the policy name to `ldds75` and set the Action to `Allow`, leave the duration as is.

![Set up your policy](/images/tutorial-extras/004-images/cloudflare-policy-configure.png)

Scroll down to `Configure rules`.  On the Selector choose `Service Token`, then select the Service Token you just created. 

![Configure rules for your Zero Trust policy](/images/tutorial-extras/004-images/cloudflare-set-service-token-rule.png)

Click `Next`, then scroll through the next page, past CORS settings, Cookies settings, and Additional settings. Click `Add Application` at the bottom right to finish setting up your Zero Trust Application.

### I. Setup Grafana Application

Ok, now we'll set up a Grafana Service Auth token and a Grafana Application.  This will allow us to share our Grafana dashboards while protecting the rest of our Grafana instance.

#### Grafana Service Auth Token

`Access-->Service Auth` and click `Create Service Token`.  

Service Token Name: `grafana admin`
Service Token Duration: `Non-expiring`

Save the `Access ID` and `Access Secret` in a secure place in case you decide to open up some part of your Grafana admin side later (like the Grafana API).  What you save should look like this:

```
CF-Access-Client-Id: xxxxxxxxxxxxxxxxxxxxxxxxx.access

CF-Access-Client-Secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```


#### Grafana Application for Access Control

Use the same process as the Node-RED application.  We'll set up two Cloudflare Applications, one for access control and one for the Grafana dashboard.

Ok, you've done this before, so I'll go a little faster:

```Zero Trust --> Access --> Applications --> Add Application --> Self Hosted```

```
Application name: `Grafana Access Control`
Session Duration: `24 hours`
Subdomain: `grafana`
Domain: `<YOUR-DOMAIN>.com`
Path: `*`
```

Scroll down to the bottom and click `Next` to proceed to the `Policies` section.  

Add a policy with the following:
```
Policy name: Service Auth
Action: Service Auth
Session Duration: Same as application session timeout

Scroll down and

Configure rules:
Include: Any Access Service Token
Value: Any non expired Service Token will be matched
```

![Grafana Access Control Application](/images/tutorial-extras/004-images/cloudflare-grafana-access-control.png)

Scroll down to the bottom of the next page and click `Add Application`.

#### Grafana Dashboard Application


```Zero Trust --> Access --> Applications --> Add Application --> Self Hosted```

```
Application name: `Grafana Public Access`
Session Duration: `24 hours`
Subdomain: `grafana`
Domain: `<YOUR-DOMAIN>.com`
Path: `public*`
```

Then add two more domains, with two different paths:

```
- Subdomain: `grafana`
- Domain: `<YOUR-DOMAIN>.com`
- Path: `public-dashboards*`
```
and
```
- Subdomain: `grafana`
- Domain: `<YOUR-DOMAIN>.com`
- Path: `api/public*`
```

Scroll down to the bottom and click `Next` to proceed to the `Policies` section.  

Add a policy with the following:
```
Policy name: Bypass
Action: Bypass
Session Duration: Same as application session timeout

Scroll down and

Configure rules:
Include: Everyone
Value: Everyone (will fill in automatically)
```

Now you've set it up so that you can share a dashboard via your Cloudflare tunnel, but the rest of your Grafana instance is still protected.

:::note
The Cloudflare Zero Trust integration with Grafana is a little odd here; you'd think you could just set an Application & Policyto allow access to your /public-dashboards path and block access to everything else like we did with Node-RED, but Policies can't be applied to paths, and Grafana is fussy with the access it requires for the /public-dashboards.  Setting it up using the `/d/*` is a decent workaround, but I'm hoping someone from Cloudflare reads this and improves their already superb service.
:::

---

## 4. **Setting Up Your LDDS 75 Sensor**

Whether this is your first device ever or your 100th, now is a good time to think about how you're going to structure your data.  I've written a [separate tutorial just on structuring data](/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md). If you've never thought about this before, it's a good idea to read through that.  You can also just YOLO and follow along, trusting that my data structure is good enough for you.  

I'm not going to tell you what to do, but I will tell you that if you're going to be doing anything with your data, you're going to want to think about it.

### A. Provision That Sucker!

Use the [Add A Device](/docs/tutorial-basics/adding-a-device) tutorial on this site to walk you through it.  A working codec for the device is in MetSci already. When you're done, it should look like this:

![LDDS 75 reporting in the MetSci Chirpstack](/images/tutorial-extras/004-images/LDDS75-working-on-MetSci.png)

### B. Check Link Metrics

Ok, assuming you've got your data structure set up, after a while (for me this is about 3 weeks) your Link Metrics for the device will be pretty boring flat lines, like this:

![LDDS 75 Link Metrics](/images/tutorial-extras/004-images/link-metrics-ldds75.png)

Quick note:  You *can't* see the **Device Metrics** properly in Chirpstack, which is what we're using for an LNS, as both the Battery Voltage and the Distance will be off the chart, which is 0 - 1.0, and unless you have the optional extra temp sensor you won't see that either.  Don't worry about seeing anything here; that's why we're setting up a dashboard.  🔧 

![LDDS 75 Link Metrics](/images/tutorial-extras/004-images/device-metrics-dont-worry.png)

### C. Configure For Fast Firing
We're going to need some data coming through the tunnel in a bit, so let's set up the LDDS75 to fire every minute for now, then we'll pull the power until we're ready to test.

Use [this guide](https://github.com/gristlekinginc/metsci-site-v2/blob/main/docs/tutorial-basics/008-configure-a-device.md
) to set up the LDDS75 to fire every minute.  You "could" theoretically do all this with downlinks, but A) I'm not covering that here and B) I want you to have the ability to wire into a sensor and tell it what to do.

However you do it...

Once you've got it set up and seen a few packets come through, pull the power on your LDDS75 using the yellow jumper; we'll use it again in a bit.

![LDDS 75 jumper](/images/tutorial-extras/004-images/ldds-75-jumper-power-off.jpeg)

### C. Set Up The HTTP Integration In MetSci

Head back over to the [MeteoScientific Console](https://console.meteoscientific.com/front/login) and in `Applications`-->`LDDS 75` (or whatever you called it), look for the `Integrations` tab.  

![MetSci LDDS 75 Integrations](/images/tutorial-extras/004-images/metsci-applications-integrations-tab.png)

Find 'HTTP Integrations" and hit the `+`.  

Leave the payload encoding set to JSON. 

Change the event endpoint to `https://node-red.<YOUR-DOMAIN>/metsci-ldds75-data/` then add two headers:

```
CF-Access-Client-ID <your-access-id>
CF-Access-Client-Secret <your-access-secret>
```

Use the `Access ID` and `Access Secret` from the Service Token you set up for the LDDS75 in Cloudflare. 

![Set up your http integration in MetSci Chirpstack](/images/tutorial-extras/004-images/metsci-http-integration.png)

Now you've set it up so the MetSci LNS can securely send data through a Zero Trust Cloudflare tunnel to Node-RED on your Raspberry Pi.  Cool, right?

Nice work!  The NSA can prolly still get in, but the rest of the screaming hordes should be kept at bay for now.

:::tip Future Integrations
For each new sensor type you add:
1. Create a new Service Token in Cloudflare named for that sensor
2. Configure the HTTP integration with the new token's credentials

This maintains consistent security across all your sensor data routes.
:::

---
## 5. **Local Integration Setup**

At the beginning of the tutorial we ran a script to set up all the services we'll need.  Now we'll go through and configure 'em.

### A. Node-RED Flows

Node-RED is a flow-based programming tool that allows you to create data flows between nodes. In this case, our nodes represent the data flow between MetSci, the InfluxDB database on our Pi, and Grafana.  

Visit Node-RED at `http://<YOUR-PI-IP>:1880` in a browser.  

If you haven't already logged in (back when we set up the services), you'll see a login screen.  Use the user & pass that was setup during the service setup.  You DID save those credentials, right?

Let me show you the whole "flow" first, it'll help you understand how it works.

![Node-RED flow](/images/tutorial-extras/004-images/node-red-full-flow.png)

#### 1. HTTP In

We'll start with an **HTTP In** node, labeled on the image above as `MetSci LDDS75 Input`.  Think of it as the greeter at Wal-Mart.  "Hey, how you doing, are you decent and sober? Come on in!" 

To add a node, you find it in the left menu bar, or just start typing in the name of the node at the top.  Once you see it, drag it onto the workspace. 

![Adding an HTTP In node](/images/tutorial-extras/004-images/node-red-drag-in-node.png)

Once you've dragged a node in, double click it to configure it.  For the HTTP In node:

- Method: `POST`
- URL: `/metsci-ldds75-data`
- Name: `MetSci LDDS75 Input`

![Configuring the HTTP In node](/images/tutorial-extras/004-images/node-red-configure-http-in-ldds75.png)

#### 2. HTTPS Response

Next we'll add in a **https response** node.  This node will let the tunnel know everything is working and follow the best practices of always responding to http requests.  It's like when someone says "Hi" to you in the street; just say "Hi" back.

![Adding an https response node](/images/tutorial-extras/004-images/node-red-http-response-node.png)

Just make sure you name it; leave everything else blank.

With two nodes in the workspace, you can start connecting 'em.  Drag a "wire" from the grey dot on the right side of the HTTP In node to the grey dot on the left side of the HTTPS Response node.

#### 3. JSON

Now we'll add and configure a **JSON** node.  JSON nodes standardize the incoming data, parse errors, and make sure the next node in the flow gets the right data.

   - Search for `json` and add it to your workspace
   - Double-click to configure:
     - Action: `Always Conver to JavaScript Object`
     - Property: `msg.payload`
     - Name: `Parse JSON`
   - Click Done to save

This ensures our data is in the right format for processing, whether it comes from our test Inject node or the HTTP In node.

Now drag a wire from the **HTTP IN** node to the **Parse JSON** node. At this point, you'll have a wire from the `HTTP In` node to the `Parse JSON` node, and a wire from the `Parse JSON` node to the `HTTPS Response` node.

#### 4. Switch

Next we'll add a **Switch** node to route the data to the correct sensor function.
   - Search for `switch` and add it to your workspace
   - Double-click to configure:
     - Name: `Route by Device Type`
     - Property: `msg.` `payload.deviceInfo.deviceProfileName`
     - Rules:
       1. First rule:
          - Operator: `contains`
          - Value: `LDDS75`
       2. Click `+` to add second rule:
          - Operator: `contains`
          - Value: `AM319` (just a demo for this tutorial)
     - Check "otherwise" to catch unknown devices
   - Click Done to save

This node examines the device profile name in the incoming message and routes it to the appropriate function node. 

If the incoming message contains "LDDS75", it goes to output 1, if it contains "AM319" (which we haven't set up yet), it goes to output 2, and any unknown devices go to the "otherwise" output where you can handle them (e.g., with a debug node to see what arrived).

![Configuring the switch node](/images/tutorial-extras/004-images/node-red-switch-node-config.png)

Wire the `Parse JSON` node to the `Switch` node.  

#### 5. Function

Add a **Function** node for the LDDS75.  Function nodes are what allow us to correctly setup the data for insertion into InfluxDB.  A JSON node cleans up the data, the Switch node routes it to the correct sensor function, and a Function node formats it for InfluxDB.

Search for a `function` node and add it to your workspace.  
    - Double-click to configure:
        - Name it `LDDS75 Function`  
        - Paste the following code into the `Message` tab of the Function node:

```javascript
try {
    // Log receipt of message
    node.warn("LDDS75 function processing message");
    
    const originalPayload = msg.payload;
    const gateway = originalPayload.rxInfo?.[0] || {};
    
    // Create payload array with fields and tags objects
    msg.payload = [
        // Fields object (numeric measurements)
        {
            // Sensor data
            distance: parseInt(originalPayload.object?.distance || 0),
            battery: parseFloat(originalPayload.object?.battery_voltage || 0),
            temperature: parseFloat(originalPayload.object?.temperature || 0),
            
            // RF metrics
            rssi: parseInt(gateway.rssi || 0),
            snr: parseFloat(gateway.snr || 0),
            frequency: parseInt(originalPayload.txInfo?.frequency || 0),
            spreading_factor: parseInt(originalPayload.dr || 0),
            
            // Status flags
            sensor_status: Boolean(originalPayload.object?.sensor_status),
            interrupt_status: Boolean(originalPayload.object?.interrupt_status),
            
            // Frame counter and port
            frame_counter: parseInt(originalPayload.fCnt || 0),
            port: parseInt(originalPayload.fPort || 0),
            
            // ADR status
            adr_enabled: Boolean(originalPayload.adr),
            
            // Bandwidth
            bandwidth: parseInt(originalPayload.txInfo?.modulation?.lora?.bandwidth || 0)
        },
        // Tags object (metadata for filtering and grouping)
        {
            // Device info
            device: String(originalPayload.deviceInfo?.deviceName || ""),
            device_eui: String(originalPayload.deviceInfo?.devEui || ""),
            device_addr: String(originalPayload.devAddr || ""),
            device_class: String(originalPayload.deviceInfo?.deviceClassEnabled || ""),
            device_profile: String(originalPayload.deviceInfo?.deviceProfileName || ""),
            
            // Application info
            application: String(originalPayload.deviceInfo?.applicationName || ""),
            application_id: String(originalPayload.deviceInfo?.applicationId || ""),
            
            // Gateway info
            gateway: String(gateway.metadata?.gateway_name || ""),
            gateway_id: String(gateway.gatewayId || ""),
            gateway_hash: String(gateway.metadata?.gateway_id || ""),
            
            // Network info
            region: String(gateway.metadata?.region_common_name || ""),
            network: String(gateway.metadata?.network || ""),
            tenant: String(originalPayload.deviceInfo?.tenantName || ""),
            tenant_id: String(originalPayload.deviceInfo?.tenantId || "")
        }
    ];
    
    // Set measurement name for MetSci LDDS75 sensors
    msg.measurement = "ldds75_metsci";
    
    // Add timestamp if not present (convert to nanoseconds for InfluxDB)
    if (!msg.payload[0].timestamp) {
        msg.payload[0].timestamp = new Date(originalPayload.time).getTime() * 1000000;
    }
    
    // Log the attempt for debugging
    node.warn("Preparing InfluxDB write for device: " + msg.payload[1].device);
    node.warn("Distance reading: " + msg.payload[0].distance + " mm");
    
    return msg;
} catch(err) {
    node.error("LDDS75 Processing Error: " + err.message);
    node.error("Failed payload: " + JSON.stringify(msg.payload, null, 2));
    node.status({fill:"red", shape:"dot", text:"Processing Error"});
    return null;
}
```

Make sure you drag the wire from the correct connector on the Switch node (the top one, but you can hover over the node to see which connector is which) to the next node in the flow.  In this case, that'll be our LDDS75 Function node.

#### 6. InfluxDB out

Add an **InfluxDB out** node to the Function node to store the data in InfluxDB.
    - Double-click the node to configure it.
    - Name the node `Local InfluxDB`

Click the `+` icon next to the "Server" field to create a new InfluxDB server configuration
    - Fill in the InfluxDB server properties:
   ```
   Name: [your org name, copy this from your credentials file]
   Version: 2.0
   URL: http://localhost:8086
   Token: [paste in your InfluxDB token from your credentials file]
   Leave other settings as is
   ```
    - `Add` to save the server configuration
   
   Now, in the InfluxDB Out node configuration:
    ```
   Name: Local InfluxDB
   Server: [should be the server you just set up]
   Organization: [your org name, copy this from your credentials file]
   Bucket: sensors [also in the credentials file]
   Measurement: [leave blank]
   Time precision: `Nanoseconds` 
     ```

![Configuring the InfluxDB out node](/images/tutorial-extras/004-images/node-red-influxdb-out-node-configure.png)
 
 Click `Done` to save the node, then click `Deploy` in the top-right.

![Connecting the nodes](/images/tutorial-extras/004-images/node-red-ldds-basic-flow-no-debug.png)

#### 7. Debug

Now, the pro move here is to add in Debug nodes.  It's not required, but it's what I've done.  Add a Debug node to every one our regular nodes. That way we'll see what's going through the whole flow the next time we have a packet come through.

For all of those:
```
- Set Output to `msg.payload`
- Name it something descriptive
```

#### 8. Deploy and test

With your flow set up, click `Deploy` in the top-right. 

![Deploying the flow](/images/tutorial-extras/004-images/node-red-flow-with-debug-deploy.png)

You should see a green bar and the word "Deployed" at the top of the screen.  

Now go back to your LDDS75 and power it back on.  Since you set it to fire on a one minute interval, you'll know quickly if everything is working or not as you'll see the data start flowing through in the debug panel on the right side.  

Remember, it might take a minute or two for the first join to complete and the data to start flowing.

![Connecting the nodes](/images/tutorial-extras/004-images/node-red-first-flow.png)

:::note
This modular structure makes it easy to add more sensors later. You can see I've added an AM319 sensor to the flow above in the image.  Each sensor follows the same basic pattern:
- HTTP In (receives data)
- JSON parser
- Switch (routes data to the correct sensor function)
    - Sensor Function (formats data for your needs)
- InfluxDB out (stores data)
:::

### B. InfluxDB Check

Let's check our InfluxDB to see if the data made it there.  Go to `http://your-pi:8086` and sign in with the credentials from your installation.  

Go to `Data Explorer` (the graphy icon on the left menu) and run a query for `ldds75` by pasting in the query below and hitting "Submit".  Hit the `View Raw Data` button (not circled in the image).  You should see your data there.

![InfluxDB query](/images/tutorial-extras/004-images/influxdb-data-explorer.png)

Here are two script queries you can run to see the data.  First, let's check distance readings from a specific device:

```sql
from(bucket: "sensors")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "ldds75_metsci")
  |> filter(fn: (r) => r["device"] == "LDDS 3 [your device name]")
  |> filter(fn: (r) => r["_field"] == "distance")
```

Here's a more complex query to see specific data from our device, including the gateway and region as well as the distance and RSSI fields.  Make sure to fill in the gateway and region with your own values.
```sql
from(bucket: "sensors")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "ldds75_metsci")
  |> filter(fn: (r) => r["gateway"] == "giant-swollen-rhino" [YOUR LOCAL GATEWAY NAME]")
  |> filter(fn: (r) => r["region"] == "US915" [YOUR REGION])
  |> filter(fn: (r) => r["_field"] == "distance" or r["_field"] == "rssi")
```
:::tip
This is a fairly simple setup, but you may still have problems.  We're nerds, usually don't work right the first time, and that's OK.  Check to make sure your queries in InfluxDB match your Device Names, Gateway, and Region.  If you just copy/paste exactly what I put, you're not going to see anything.By far the fastest way to debug on your own is to feed in messages from Node-RED debug and InfluxDB,  and drop screenshots into ChatGPT/Cursor/Grok etc.  
:::

### C. Grafana Dashboards

Now let's head over to Grafana and set up a dashboard, woohoo!

Go to the local Grafana at `http://your-pi:3000` and sign in with the credentials from your installation.  You'll see something like this after you sign in:

![Grafana dashboard](/images/tutorial-extras/004-images/grafana-home.png)

Now that we have data flowing into InfluxDB, let's visualize it in Grafana! First, we'll connect Grafana to our InfluxDB data source.

1. Click **Connections** in the left-side menu
2. Click **Add new connection**
3. Search for `InfluxDB` and select it

![Adding a new InfluxDB connection](/images/tutorial-extras/004-images/grafana-connections-influxdb.png)

4. Click **Add new data source**
5. Configure the settings:
   
   **Basic Settings:**
   - Name: `Local InfluxDB`
   - Default: ✓ (checked)

   **Query Language:**
   - Select: `Flux`
   (You'll see a note that Flux support is in beta - that's okay!)

   **HTTP Settings:**
   - URL: `http://<YOUR-PI-IP>:8086`

   **Auth:**
   - Basic auth: Toggle ON
   - With Credentials: Toggle ON
   - User: [your InfluxDB username]
   - Password: [your InfluxDB password]

   **InfluxDB Details:**
   - Organization: [your org name from credentials file]
   - Token: [paste your token from credentials file]
   - Default Bucket: `sensors`
   - Min time interval: `10s`
   - Max series: `1000`

6. Click **Save & test** at the bottom
   You should see "Data source is working" if everything is configured correctly

![Grafana InfluxDB connection setup](/images/tutorial-extras/004-images/grafana-influxdb-settings.png)

Now let's create a dashboard to visualize our LDDS75 data.

![Grafana add new dashboard](/images/tutorial-extras/004-images/grafana-build-new-dashboard.png)

1. Click the **+** icon up at the top right
2. Select **New Dashboard**
3. Click **Add visualization**
4. Select your `Local InfluxDB` data source
5. In the Flux Query editor, paste:

```flux
from(bucket: "sensors")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "ldds75_metsci")
  |> filter(fn: (r) => r["device"] == "LDDS 3 [YOUR-DEVICE-NAME]")
  |> filter(fn: (r) => r["_field"] == "distance")
``` 
Now, over on the right, we're going to configure the visualization settings.

The type of visualization we're going to use is a `Time Series` graph.  This is ideal for showing changes over time.

![Grafana Time Series](/images/tutorial-extras/004-images/grafana-initial-setup.png)

At the top right, select `Time series`.

6. `Panel Options`
   - Title: "Water Level"
   - Description: "Distance measurement from LDDS75 sensor"

7. `Graph Styles`
   - Style: Line (shows continuous changes)
   - Line width: 2
   - Fill opacity: 20 (adds a subtle fill below the line)
   - Connect null values: Always (smooths over any gaps in data)

8. `Standard Options`
   - Unit: Length → millimeter (mm)
   - Min: 0
   - Max: 8000 
   - Decimals: 0 (distance in mm doesn't need decimals)
   - Display Name: `${__field.name}`

9. `Thresholds`
   - Add threshold at 80% of your maximum expected water level
   - Base color: Green
   - Above 80%: Red (indicates barrel is getting full)

10. Save your dashboard, then leave the edit window and go `Back to dashboard`.

Now let's do a little admin work, then set up the sharing aspect.  Grafana makes this dead easy.

First, in your Pi Terminal:
```
sudo nano /etc/grafana/grafana.ini
```

You'll see the full file, modify/add the following, **replacing the domain and subdomain with your own as appropriate**:

```
[server]
domain = grafana.gristleking.dev 
root_url = https://grafana.gristleking.dev 

[security]
allow_embedding = true

```
Save & close with `Ctrl+X`, then `Y`, then `Enter`.

Now restart Grafana:
```
sudo systemctl restart grafana-server
```   

Back in Grafana, `Save` your dashboard, refresh the page, then `Exit Edit`

Click the Share button in the top right.  Go to the `Public Dashboard` tab

![Grafana Share Dashboard](/images/tutorial-extras/004-images/grafana-share-dashboard.png)

Check all the boxes, then click `Generate Public URL`.  It should generate a URL like `https://grafana.<YOUR-DOMAIN>>.dev/d/000000002/ldds75-metsci-dashboard?orgId=1&var-device=LDDS%202`.

Copy the URL and paste it into your browser, or share it with your Mom.  Now everybody can see how much water is in your tank.  Bam, you're public!

--- 

### D. AM319 Teaser

By now you'll have at least a couple of packets coming through the tunnel, so you should see the data in your dashboard.  If you don't, you can always check the debug panel in Node-RED to see what's gone wrong.

Liquid level sensing is simple, but generally not that exciting, so...

Using the steps above, I've added in a Milesight AM319, including a route, policy, and application in Cloudflare and a second dashboard.  This is what it looks like with some live data:

![Grafana AM319 Dashboard](/images/tutorial-extras/004-images/grafana-am319-burpees.png)

Just so you could see some real change,I closed up all the windows & doors in my office and did burpees until the CO2 went up.  You can also see where we dropped a couple of packets.  The AM319 fires a huge packet every minute, so it's easy to see where the packets are dropped.

:::tip Download My Node-RED Flow
Want to skip the manual setup? You can download the complete LDDS75 flow [here](/flows/MetSci-LDDS75-flow.json) and import it directly into Node-RED. Just remember to:
1. Configure your InfluxDB credentials
2. Update any device-specific information
3. Deploy the flow after importing
:::

---

## 6. Home Assistant Integration

Now, I'm assuming if you're reading this that you're already running [Home Assistant](https://www.home-assistant.io/) on another device.  If you're not, or "Home Assistant" is a foreign term to you, I'd skip this section for now and come back when you're tired of telling everyone to look at your rainwater tank levels. 

Installing and configuring HA is (WAY!) beyond the scope of this tutorial, but for those of you who already have it running and want to pipe in data from your shiny new MetSci dashboard, here are two options:

#### 1. Via Node-RED (Recommended)
This method provides real-time updates and more flexibility:

1. Install the Home Assistant nodes in Node-RED on your MetSci Pi:
   ```bash
   cd ~/.node-red
   npm install node-red-contrib-home-assistant-websocket
   ```

2. In Node-RED, add and configure the `home-assistant` config node:
   - Protocol: `http` or `https` (depending on your HA setup)
   - Base URL: `http://YOUR_HA_IP:8123` (or your external URL)
   - Access Token: Create a Long-Lived Access Token in HA
     (HA Profile → Long-Lived Access Tokens → Create Token)

3. Add a `call-service` node after your LDDS75 Function node:
   ```javascript
   Domain: sensor
   Service: set_state
   Entity ID: sensor.water_level
   Data: {
     state: msg.payload[0].distance,
     attributes: {
       unit_of_measurement: "mm",
       friendly_name: "Water Level",
       device_class: "distance",
       battery_level: msg.payload[0].battery
     }
   }
   ```

#### 2. Via InfluxDB
This method requires exposing InfluxDB securely to your network:

1. First, configure InfluxDB to accept remote connections. On your MetSci Pi:
   ```bash
   sudo nano /etc/influxdb/config.toml
   ```
   Add or modify:
   ```toml
   [http]
     bind-address = "0.0.0.0:8086"
   ```

2. Update your firewall to allow HA access:
   ```bash
   sudo ufw allow from YOUR_HA_IP to any port 8086
   ```

3. In Home Assistant's `configuration.yaml`, add:
   ```yaml
   influxdb:
     api_version: 2
     ssl: false
     host: YOUR_METSCI_PI_IP
     port: 8086
     token: YOUR_INFLUXDB_TOKEN
     organization: MeteoScientific
     bucket: sensors
     queries:
       - name: Water Level
         unit_of_measurement: "mm"
         measurement: "ldds75_metsci"
         field: "distance"
         where: 'device = ''LDDS 3'''
         device_class: "distance"
   ```

4. Restart Home Assistant to apply changes

:::warning Security Considerations
When connecting services across devices:
1. Use strong, unique passwords and tokens
2. Consider setting up a VPN if accessing over the internet
3. Use SSL/TLS when possible
4. Limit firewall rules to specific IPs
5. Monitor logs for unauthorized access attempts
:::

#### Example Lovelace Card
Add this to your Lovelace dashboard in Home Assistant:
```yaml
type: vertical-stack
cards:
  - type: gauge
    name: Water Level
    entity: sensor.water_level
    min: 0
    max: 8000
    severity:
      green: 0
      yellow: 6000
      red: 7000
  - type: history-graph
    title: Water Level History
    entities:
      - entity: sensor.water_level
        name: Level
```

:::tip
The Node-RED method is recommended because:
- Only requires one port forwarded (HA's port)
- Keeps InfluxDB secure behind your firewall
- Provides real-time updates
- Allows for data transformation before sending
:::


## 7. System Maintenance & Troubleshooting

### A. Credentials Management
Your credentials are stored in several locations:
1. Node-RED: `~/.node-red/settings.js`
2. InfluxDB: `/var/lib/influxdb/influxd.bolt` (and `/var/lib/influxdb/engine/`)
3. Grafana: `/etc/grafana/grafana.ini`
4. Installation credentials: Generated in `~/metsci-credentials.txt`

:::warning
After setting up your services, securely store the contents of `~/metsci-credentials.txt` somewhere safe, then delete it from your Pi:
```bash
rm ~/metsci-credentials.txt
```
:::

### B. Backing Up Configurations
Create a backup script for your configurations:
```bash
#!/bin/bash
BACKUP_DIR="/mnt/ssd/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup Node-RED flows and settings
cp -r ~/.node-red/* $BACKUP_DIR/node-red/

# Backup service configs
sudo cp -r /var/lib/influxdb $BACKUP_DIR/influxdb/
sudo cp /etc/grafana/grafana.ini $BACKUP_DIR/

# Set permissions
sudo chown -R $USER:$USER $BACKUP_DIR
```

### C. System Updates
Regular maintenance tasks:
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Restart services after updates
sudo systemctl restart nodered influxdb grafana-server
```

### D. Troubleshooting Guide

#### 1. Service Not Starting
Check service status:
```bash
sudo systemctl status [service-name]  # nodered, influxdb, or grafana-server
```

View logs:
```bash
sudo journalctl -u [service-name] -n 50 --no-pager
```

#### 2. Lost Connection to Pi
1. Check if Pi is powered on
2. Verify network connection
3. Try direct connection via ethernet
4. Check Cloudflare tunnel status:
```bash
sudo systemctl status cloudflared
```

#### 3. Data Not Flowing
Check each step:
1. MetSci LNS → View device events in console
2. Cloudflare → Check tunnel logs
3. Node-RED → Check debug tab
4. InfluxDB → Test token and query recent data:
   ```bash
   # Test token
   curl -v "http://localhost:8086/api/v2/write?org=YOUR_ORG&bucket=sensors" \
     -H "Authorization: Token YOUR_TOKEN" \
     -d "test,host=test value=1"
   ```
5. Grafana → Check data source connection

#### 4. Disk Space Issues
Monitor disk usage:
```bash
df -h
```

Check service logs taking up space:
```bash
sudo du -h /var/log | sort -rh | head -n 10
```

:::tip Recovery Steps
If something goes wrong:
1. Check the relevant service status
2. Review the logs
3. Restore from backup if needed
4. If all else fails, you can always reinstall the affected service
:::


## 8. La Ultima

Last step?  Tell your friends what you did!  Please tag us on X [MeteoScientific](https://x.com/meteoscientific) and [Gristleking](https://x.com/thegristleking) we'd love to see what you've done!

