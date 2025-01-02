---
sidebar_position: 3
title: DRAFT -- Build A Dashboard
---

# Build a Custom Dashboard

Ok nerds, let's do something rad with [Helium](https://www.helium.com/) and build a dashboard for a sensor!  I know, I know, you can use a ready-made service like [Datacake](https://datacake.de), but...we're nerds, and wherever possible we build our own things.

My goal here is to enable you to build your own "no-subscription" public or private dashboards for under US$150 not including the sensors.    

You'll need hardware for this, make sure you have the following on hand:
### Hardware
 - [Rasbperry Pi 4](https://amzn.to/3DAVCnO), about $60.  You can use a 3, or a 5 and it should work, but this tutorial was built with a 4
 - Dragino LDDS 75 sensor.  You can buy one at [RobotShop](https://www.robotshop.com/products/dragino-ldds75-lorawan-distance-detection-sensor-915-mhz) for $60-80.
 - External SSD for the Pi, about $30.  IoT data sets can get pretty big and you'll want plenty of space beyond the SD card on the Pi.  SD cards can also wear out if you write to 'em a bunch. Something like [this](https://amzn.to/3PbhbNY) is fine.
 - Some kind of USB-TTL adapter (the thing that allows you to communicate directly over-the-wire with the sensor)
    - [BusPirate](https://buspirate.com/) I used the v5 for this, but the v6 is already out!  $40-80
    - Cheapie [Amazon Kit](https://www.amazon.com/dp/B07VNVVXW6?ref=ppx_pop_mob_ap_share) (thanks to GreyHat for the rec) $14
    - [Segger J-Link EDU Mini](https://www.sparkfun.com/products/24078) - $60 on Sparkfun

### Not-Hardware
    - Custom domain.  For this tutorial I'll be using mine, `gristleking.dev`.  If you don't already have a domain, I'd **strongly** recommend buying one at [Cloudflare](https://cloudflare.com).  They're about $12/year and buying it there makes everything else a little bit easier.
    - If you have a domain already, you'll need to set up your domain's name servers to point to Cloudflare.

### Notes on what you "Need"
You don't actually NEED a USB-TTL adapter if you're not going to make any changes to the sensor (like how often it reports), but it's generally good practice to have one hanging around the work bench if you're any kind of aspiring nerd.

You *could* do this without a custom domain by hosting in the cloud and managing tunnels with Cloudflare, but then you're on the hook for cloud hosting, which is probably $6/month at the cheapest.  A domain is something like $70/year for an expensive AI one and $12/year for a cheap one. Trust me, just buy a domain 

Having your own domain makes part of this workflow way simpler, plus it's just cool to have your own domain.  Ask Larry at Google or Steve at Apple.  Having a custom domain is cool. 

## Set Up Overview

**1. Set Up Your Raspberry Pi** - Connect it to your network, integrate the external SSD.

**2. Configure the Sensor** - Get the LDDS75 sending data.

**3. Set Up Node-RED** - This will route the data once it hits the Pi, so you can integrate with Home Assistant AND have a public dashboard.

**4. Install & Configure InfluxDB** - This is where your data will be stored on the SSD attached to the Pi.

**5. Set Up Grafana** - This is what runs the public dashboard.

**6. Test MetSci LNS** - Make sure you can get data from MetSci first before we batten down the hatches.

**7. Set Up Cloudflare Tunnel** - This is the secure route we'll use between MetSci, your Pi, and back to a public dashboard.

**8. Add Security** - This keeps all the dirty rotten Internet hackers out.


---
## 1. **Setting Up Your Rasbperry Pi**
### Load an OS, then connect
Rather than re-writing (and constantly updating) this part, I'm going to suggest you [follow the official docs](https://www.raspberrypi.com/software/) for the first part of this.  The basic flow is that you load an OS onto an SD card using your computer, then plug the SD card into your Pi.  Connect your Pi (Ethernet/LAN cable strongly preferred over WiFi) and search for the Pi on your local network.  SSH in, then update/upgrade whatever you need to.  

### Connect and integrate the external SSD
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

5. Confirm it's mounted properly with `lsblk`.  You should now see something like this, confirming the ssd is mounted:
```bash
   core@myrmytron:~ $ lsblk
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sda           8:0    0 111.8G  0 disk 
    └─sda1        8:1    0 111.8G  0 part /mnt/ssd
    mmcblk0     179:0    0 116.2G  0 disk 
    ├─mmcblk0p1 179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2 179:2    0 115.7G  0 part /
```

Nice work, we'll use this SSD later when we get to setting up InfluxDB!

---
## 1. **Setting Up Your LDDS 75 Sensor**

Whether this is your first device ever or your 100th, now is a good time to think about how you're going to structure your data.  I've written a [separate tutorial just on structuring data](/docs/tutorial-basics/009-good-housekeeping-for-LoRaWAN-sensor-fleets.md). I STRONGLY recommend you read that tutorial if you haven't already and think long & hard about how you're going to structure your data.  Seriously.

### Provision that sucker!
Use the [Add A Device](/docs/tutorial-basics/adding-a-device) tutorial on this site to walk you through it.  A working codec for the device is in MetSci already. When you're done, it should look like this:

![LDDS 75 reporting in the MetSci Chirpstack](/images/tutorial-extras/004-images/LDDS75-working-on-MetSci.png)

Ok, assuming you've got your data structure set up, after a while (for me this is about 3 weeks) your Link Metrics for the device will be pretty boring flat lines, like this:

![LDDS 75 Link Metrics](/images/tutorial-extras/004-images/link-metrics-ldds75.png)

Quick note:  You *can't* see the **Device Metrics** properly in Chirpstack, which is what we're using for an LNS, as both the Battery Voltage and the Distance will be off the chart, which is 0 - 1.0.  Don't worry about this; we'll be setting up a dashboard to see this.

![LDDS 75 Link Metrics](/images/tutorial-extras/004-images/device-metrics-dont-worry.png)

Now that we can see the metrics coming off the sensor and into the LNS, we're going to set up a test, to make sure we can get them into our Pi.  This part is just a test, so if you're a total cowboy you can skip, but...I wouldn't.  Plus, we'll be setting up something you'll use later anyway (the Cloudflare tunnel to our Pi).S

---
## 2. **Cloudflare Setup, Part 1**
To start this off, login to Cloudflare. 

You'll need to set up your Zero Trust account in Cloudflare (yes, you can use the free option.)  

If you haven't set up Zero Trust yet, you may not see "Zero Trust" in your menu.  If that's the case, navigate to your domain name, look for `Access` in the left menu, then hit the `Launch Zero Trust` blue button on the right, then click it and set up ZT.

![Cloudflare Zero Trust](/images/tutorial-extras/004-images/set-up-zero-trust.png)

Once you have it, you'll see it in your **main** (not your domain) Cloudflare menu, like this.

![Cloudflare Zero Trust](/images/tutorial-extras/004-images/go-to-zero-trust.png)

With Zero Trust on and ready to go, let's set up the Pi.

### Prepare Your Raspberry Pi for Cloudflare

In the Pi terminal, install Cloudflare Tunnel. As always, kick things off with a system update:
```bash
    sudo apt update && sudo apt upgrade -y
```
Next, download the Cloudflare binary to the Pi.  I'm running a Pi 4B with 64-bit ARM architecture (use `uname -m` to check yours if you're unsure)
```bash
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared
```
Then let's do a few nerdy things (making the binary executable, moving it a system pass, then verifying the installation).
Make it executable:
```bash
    chmod +x cloudflared
```
Move it:
```bash
    sudo mv cloudflared /usr/local/bin/cloudflared
```
Verify the installation:
```bash
    cloudflared --version
```

That should get you here on your Pi:

![Cloudflare tunnel installed and ready to set up](/images/tutorial-extras/004-images/set-up-cloudflare-tunnel.png)

### Create a Tunnel In Cloudflare Zero Trust
With Cloudflare's Zero Trust on and our Pi set up, we're going to set up the actual tunnel.  

In Zero Trust, go to `Networks --> Tunnels --> Add a tunnel`.

![Zero Trust Network Tunnels](/images/tutorial-extras/004-images/zero-trust-networks-tunnels.png)

On the next page (not shown here), select `Cloudflared`, **NOT** `WARP Connector`, then choose a tunnel name.

![Name your Cloudflare tunnel](/images/tutorial-extras/004-images/choose-tunnel-name.png)

Save it and you'll be taken to the Configure page.  Go down to `Install and Run Connector` and copy the one on the right.

![Install and run connector](/images/tutorial-extras/004-images/install-and-run-connector.png)

### Add The Tunnel To Your Raspberry Pi
We've already installed Cloudflare on our Pi, so on your Pi just run the command they gave us:

`sudo cloudflared service install super-duper-alpha-numeric-string`

You should see a success message, like this. 

![Tunnel successfully installed](/images/tutorial-extras/004-images/tunnel-success.png)

Double check that on your Pi with a status request: 

`sudo systemctl status cloudflared`

That should give you something like this:

![Cloudflare tunnel running on Pi](/images/tutorial-extras/004-images/cloudflare-tunnel-running.png)

Back on your Cloudflare page you'll see confirmation under Connectors; look for `Status`.  

Cool, now you've got a secure tunnel between Cloudflare and your Pi. Hit `Next` down at the bottom right in Cloudflare, then you'll see this:

![Setting up a test route in our tunnel](/images/tutorial-extras/004-images/test-route.png)

As you can see, I've filled in a "route" for `test` using `HTTP` and `localhost:1881`because we're going to test this first.  A tunnel can have multiple routes in it.  Later we'll create separate routes for each service, so traffic to `node-red.yourdomain.com` will route to Node-RED and traffic to `grafana.yourdomain.com` will route to Grafana.  For now, we just want to make sure of our http connection from the MetSci LNS to our Pi.  Hit `Save hostname`.

Now let's test the connection from MetSci LNS to our Pi.  We'll do that by setting up a temporary lightweight Python test server on the Pi.

On your Pi, 
```bash
   nano test_server.py
```
Then paste the following code:
```bash
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class RequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        print(f"Received data: {post_data.decode('utf-8')}")
        
        # Send a response back to the LNS
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"status": "success"}).encode("utf-8"))

def run(server_class=HTTPServer, handler_class=RequestHandler, port=1881):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting test server on port {port}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run()
```
Save and exit, I use Ctrl-X on my Mac, then choose Y for yes.

Now run the server:
```bash
   python3 test_server.py
```

Ok, head over to your MetSci Console at `console.meteoscientific.com`.  For testing, you'll want to use a device that sends data frequently.  In my case it's an AM319 which sends data every minute.  Choose `Applications --> Your Application --> Integrations --> HTTP` and hit the `+` sign.

![Choosing an http integration](/images/tutorial-extras/004-images/AM319-http-integration-test.png)

Fill in your new tunnel name, mine is `test.gristleking.dev` and hit `Submit`.

![Fill in your new tunnel name and submit the http integration](/images/tutorial-extras/004-images/fill-in-your-new-tunnel.png)

If it works, the next time your device sends data, you should see it come in on your Pi, like this:

![Integration test working](/images/tutorial-extras/004-images/integration-test-works.png)

I know, I know, most of my top secret payload is obscured.  Copy yours down and keep it somewhere, we'll use it later when we're setting up Node-RED.

Now you know your tunnel works, which is cool. Let's kill all the test stuff for now.

- Delete the HTTP integration in the LNS (MetSci) to stop sending data to the test route.
- Remove the test route (`test.gristleking.dev`) from your Cloudflare tunnel configuration.
- Stop the test server running on your Raspberry Pi by pressing `Ctrl-C` in the terminal where it's active.
- Document your success to ensure you have a record of this working step for future troubleshooting or reference.


*Gotta be honest here; if you've gotten this far, you're way further than most people get, and while it may not raise many eyebrows at the next cocktail party to tell 'em you used a ZeroTrust Cloudflare tunnel for a successful HTTP integration from the Helium LNS to a local Pi, it'll raise the **right** eyebrows.*

---

## 3. **Setup Node-RED**
### Installation
1. Update your Raspberry Pi:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. Install Node-RED using the [Node-RED installation script](https://nodered.org/docs/getting-started/raspberrypi):
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
   ```
   It'll ask you a couple of questions, threatening to wipe your life clean if you get anything wrong.  Because you're installing this on a Raspberry Pi and can just start over if you get something wrong, I live a carefree life and just say "yes" to everything.

   You should see something like this (I'm using VS Code here, very fancy)

   ![node-red-installed](/images/tutorial-extras/004-images/node-red-installed.png)

   Hit `Enter` to go through set up.  I set up security, adding a username and a password, giving that user full access, like this:

![node-red-set-up](/images/tutorial-extras/004-images/bog-standard-setup.png)

3. Improve security

Start by opening up your new node-red/setting.js file with:

```sudo nano ~/.node-red/settings.js```

Look for the `adminAuth` section, around line 78.  It'll look like this:
```bash
adminAuth: {
    type: "credentials",
    users: [{
        username: "your-username",
        password: "$29uxnsSKUY9...", // Your hashed password
        permissions: "*"
    }]
},
```

Copy the entire hashed password string and save it somewhere secure; you'll need it for the next step.

Now save and exit with `CTRL-X` and `Y` and `Enter`.

4. Create the `.env` file

Next we'll create a Node-RED Environment file (`.env`) to make things a little more secure.

Start by creating the file:
```bash
sudo mkdir -p /etc/node-red
sudo nano /etc/node-red/.env
```

Add the following lines, **replacing the placeholders** with your actual hashed password and credential secret.

```bash
NODE_RED_ADMIN_PASSWORD=your-hashed-password-goes-here
NODE_RED_CREDENTIAL_SECRET=your-secret-phrase-goes-here
```

Secure the `.env` file, making sure that only your user (in my case, `core`), can read it.

```bash
sudo chmod 600 /etc/node-red/.env
sudo chown core:core /etc/node-red/.env
```

5. Configure the Node-RED Service

We'll put all the configurations into one service file and source the `.env` for the variables.

```sudo nano /etc/systemd/system/nodered.service```

Then paste in the following content:
```bash
[Unit]
Description=Node-RED
After=network.target

[Service]
Type=simple
User=core
EnvironmentFile=/etc/node-red/.env
ExecStart=/usr/bin/env node-red
Restart=on-failure
SyslogIdentifier=Node-RED

[Install]
WantedBy=multi-user.target
```

Reload systemd and start Node-RED:
```bash
sudo systemctl daemon-reload
sudo systemctl enable nodered
sudo systemctl start nodered
```

6. Now we'll add our user (again, in my case `core`) to access various required groups for Node-RED:
```bash
sudo usermod -a -G gpio,i2c,spi core
```

Reboot the Pi:

```sudo reboot```

7. Update `settings.js` to use the .env variables you set up earlier.

Open the `settings.js` file:
```bash
sudo nano ~/.node-red/settings.js
```

Find the `credentialSecret`, typically around line 44, and update it to reference the env variable:
```bash
credentialSecret: process.env.NODE_RED_CREDENTIAL_SECRET,
```

Cruise down and look for the `adminAuth` section and updat it to use the `.env` as well:
```bash
adminAuth: {
    type: "credentials",
    users: [{
        username: "your-username",
        password: process.env.NODE_RED_ADMIN_PASSWORD,
        permissions: "*"
    }]
},
```
Keep scrolling down and and disable https enforcement. 

Look for this:
```bash
//requireHttps: true,
```
and "uncomment" it by deleting the first `//`, like this:
```bash
requireHttps: false,
```
Save it with `CTRL-X`, then `Y`, and `Enter` to save.

8. Restart Node-RED to apply changes:
```bash
sudo systemctl daemon-reload
sudo systemctl restart nodered
```

9. Make sure it's running:
```bash
sudo systemctl status nodered
```

You'll see something like this:
```bash
● nodered.service - Node-RED
     Loaded: loaded (/etc/systemd/system/nodered.service; enabled; preset: enabled)
     Active: active (running) since Sat 2024-12-28 14:01:52 PST; 2s ago
   Main PID: 10632 (node)
      Tasks: 11 (limit: 8738)
        CPU: 3.198s
     CGroup: /system.slice/nodered.service
             └─10632 node /usr/bin/node-red
```


10. Access the Dashboard

Now check it to make sure you see it on your local network (which is a fancy way of saying you can see what your Pi is displaying from your computer.  Sheesh.)  My Pi is at `192.168.60.6` on my local network, so I'll just put `192.168.60.6:1880` in the URL bar, and I should see this:

![Node-RED is running on my Pi](/images/tutorial-extras/004-images/node-red-is-running-on-pi.png)

Wildly exciting, I know.  Login and you'll see something like this, which can seem bloody intimidating:

![Node-RED front page](/images/tutorial-extras/004-images/node-red-homepage.png)

Relax, I'll walk ya through it when we get there.

Now that we've got Node-RED working with a tested pipe, let's set up our database (InfluxDB) and Grafana to visualize the data.  Once those are up we'll give some test data to Node-RED and make sure the local flow works, then we'll connect the MetSci LNS to Node-RED on our Pi through "real" tunnels and let 'er rip!

Next up?  Setting up the database!

## 4. **Set Up InfluxDB**
### Installation
You can always check the [InfluxDB v2 docs](https://docs.influxdata.com/influxdb/v2/install/), but if you just want to copy/pasta and put this thing on blast, open up a terminal window to your Pi and LFG:

Install the required dependencies
```bash
sudo apt install -y wget gpg
```
Download the InfluxData GPG key:
```bash
wget -qO- https://repos.influxdata.com/influxdata-archive_compat.key | sudo gpg --dearmor -o /usr/share/keyrings/influxdata-keyring.gpg
```
Add the repository to your package list:
```bash
echo "deb [signed-by=/usr/share/keyrings/influxdata-keyring.gpg] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list
```
Update your package list to include the new repo
```bash
sudo apt update
```
Install InfluxDB
```bash
sudo apt install influxdb2
```
Remember when we set up the SSD earlier?  Now we're going to use it.  First, create the required structure on the SSD.  I know all three of these commands are together, but I usually run them one at a time.  
```bash
sudo mkdir -p /mnt/ssd/influxdb/{meta,data,wal}
sudo chown -R influxdb:influxdb /mnt/ssd/influxdb
sudo chmod -R 775 /mnt/ssd/influxdb
```
Next, create a symbolic link:
```bash
sudo ln -s /mnt/ssd/influxdb /var/lib/influxdb
```
Start & Enable InfluxDB
```bash
sudo systemctl start influxdb
```
Make sure it can start automagically on boot:
``` bash
sudo systemctl enable influxdb
```
Now make sure the thing is running:
```bash
sudo systemctl status influxdb
```
You can get out of that with `CTRL-C`, then add some whizbang magic just in case ya need it later:
```bash
sudo apt install -y telegraf
```

This setup will allow you to process sensor data in Node-RED, store it in InfluxDB on your SSD, and visualize it with Grafana, all leveraging the SSD for improved storage capacity and performance.

By default InfluxDB will be on 8086 locally, `http://<Your-RPi-address>:8086`

In my case, that'll be `http://192.168.60.6:8086/`.

Now cruise over to yours:
```bash
http://<RaspberryPi-IP>:8086
   ```

It should look like this:

![InfluxDB Starting page](/images/tutorial-extras/004-images/influx-db-gui.png)

Go through the steps to set up your account:

![InfluxDB setup for GK](/images/tutorial-extras/004-images/influx-db-setup.png)

On the next page it'll give you your `Operator API Token`; store that somewhere safe, you'll need it.

Now, my advanced IoT friend, hit that `Advanced` button!

![InfluxDB copy your API token and choose Advance](/images/tutorial-extras/004-images/choose-advance.png)

That's it, InfluxDB is all setup.  Poke around the Advanced dash, check out your shiny new bucket, and bask in the glor.  For now you don't have to sweat any more details, but...


I know this is kind of boring and nerdy, but planning ahead is pretty important here.  

A critical element is making sure you pick one canonical unit for each measurement type—e.g., all “distance” in millimeters, “temperature” in Celsius, etc. This means you'll have to make sure your decoders are putting out payloads in those units.

You can always add in things later, but if you build as you go it'll probably get messy later.  We're aiming for a well-structured dataset for querying and visualization.

---

## 5. **Set Up Grafana**
### Installation
1. Install the prerequisite packages:
```bash
sudo apt install -y software-properties-common curl
```

2. Add the Grafana GPG key:
```bash
curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana-archive-keyring.gpg

```
3. Add the Grafana Repository with a direct link to the GPG key you just added.  Fancy.
```bash
echo "deb [signed-by=/usr/share/keyrings/grafana-archive-keyring.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
```
4. Update, always update.
```bash
sudo apt update
```
5. Now you can install Grafana.  Now Silent Bob!
```bash
sudo apt install -y grafana
```
6. Start and enable the service:
```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

### Access Grafana
- Open a browser and go to `http://<RaspberryPi_IP>:3000`.  For me, that'd be `http://192.168.60.6/`

Use user `admin` and password `admin` to log in.  You'll be prompted to set up a new password after logging in.  Follow the prompts.

Once you've set up your new password, we'll do one more thing, which is to get rid of the user `admin` and replace it with something a little harder to guess.  This won't make your Grafana into Fort Knox, but it'll make it slightly harder for those goofy jackwagons who rattle every doorknob they can find.

Head over to the hamburger `Home` menu in the top left, then dig down through `Administration-->Users and access-->Users` 

![Admin then profile](/images/tutorial-extras/004-images/home-administration-users.png)

then follow the prompts to create a new user. 

Save, then change the Admin permissions to `Yes`.

![Change admin perms to yes](/images/tutorial-extras/004-images/change-admin-to-yes.png)

Add your new login, your email, a display name, and a strong password. 

Set the role to `Admin`, then save.

Log out of the `admin` user, log in as the new user, find the old `admin` account, and delete it.  Nice work, the doorknob jigglers now have to work that much harder to get in.

### 7. Integration
Ok, so we've now got Node-RED, InfluxDB, and Grafana all running, and we've got our sensor on MetSci sending us payloads.  

![Tabs set up for integration, running all apps](/images/tutorial-extras/004-images/tabs-set-up-for-integration.png)

We'll start with installing an InfluxDB Node in Node-RED:
```bash
cd ~/.node-red
npm install node-red-contrib-influxdb
```

Restart Node-RED.
```bash
node-red-restart
```

Refresh your page. `CMD-R` on Mac.

### Building a Node_RED Flow
Before we do anything, lemme make your life easier in Node-RED by walking you through setting a `credentialSecret`.  This makes it so if someone accesses your `flows_cred.json` file, they can't read sensitive information.

In Terminal on the Pi:
```bash
nano ~/.node-red/settings.js
```

Add or update the `credentialSecret`.  Use any password you want for the `secret-key`; I just used a password generator. 

Find the section, or, if it doesn't exist, create it.  It'll look like this:
```bash
module.exports = {
    credentialSecret: "your-secret-key",
    // other settings...
}
```
![Set your credential secret](/images/tutorial-extras/004-images/set-your-cred-secret.png)


A "flow" in Node-RED is what it sounds like; the flow of signals from where it comes in (it'll be coming from the MetSci LNS eventually, but we'll "inject" some fake data first just test it) all the way to where it'll go, which is eventually Grafana.

It'll look like this for the test:

```Inject node-->Function Node-->Debug Node-->InfluxDB Out Node```

And it'll look like this when we do it for real:

```MetSci Ingest node-->Function Node-->Debug Node-->InfluxDB Out Node```


Let's start with a simple `Inject Node` for testing, that'll inject fake data from the LDDS75. 

**1. Add an Inject Node**
![Find an inject node](/images/tutorial-extras/004-images/drag-an-inject-node.png)
On the top left, where you see the search bar, start typing `inject` to find it,then drag an `Inject` node from the palette onto the workspace.  It may change to `timestamp`, don't worry about it.

Double click the node to configure it:

**Name:** Simulated LDDS 75

Look for the field labeled `msg.payload`.

To the right of this, there's a dropdown menu. Click it and select `JSON`.

![Change it to a JSON inject node](/images/tutorial-extras/004-images/change-type-to-JSON.png)

**Payload:** Change type to **JSON** and paste in the following:
```bash
{
    "time": "2024-12-27T19:00:14.338+00:00",
    "deviceInfo": {
        "deviceName": "LDDS75 Sensor",
        "devEui": "1111111111111111",
        "applicationName": "LDDS - Liquid Level Sensor"
    },
    "object": {
        "TempC_DS18B20": "0.00",
        "Bat": "3.348",
        "Distance": "1250 mm",
        "log": {
            "sensor_flag": 1.0,
            "interrupt_flag": 0.0,
            "distance": "1250 mm",
            "batV": "3.348",
            "tempValue": 0.0,
            "temp": 0.0
        }
    },
    "rxInfo": [
        {
            "rssi": -70,
            "snr": 12.5,
            "metadata": {
                "gateway_name": "anonymized-gateway",
                "gateway_lat": "0.0",
                "gateway_long": "0.0"
            }
        }
    ],
    "txInfo": {
        "frequency": 904300000,
        "modulation": {
            "lora": {
                "bandwidth": 125000,
                "spreadingFactor": 7,
                "codeRate": "CR_4_5"
            }
        }
    }
}
```

Delete any other properties (in my case `msg.topic`)

Click **Done**.

**2. Add a Function Node**

Drag a  **Function** node onto the workspace.

Connect the output of the **Inject** node to the input of this node.

Double click the Function node to configure:

**Name:** Dynamic Payload Processor

**Function Code:**
```bash
const payload = msg.payload;

// Flatten the payload for the InfluxDB Output node
msg.measurement = "sensor_data";
msg.tags = {
    deviceName: payload.deviceInfo.deviceName,
    devEui: payload.deviceInfo.devEui,
    applicationName: payload.deviceInfo.applicationName,
    gateway_name: payload.rxInfo[0]?.metadata?.gateway_name,
};
msg.fields = {
    temperature: parseFloat(payload.object.TempC_DS18B20 || 0),
    battery: parseFloat(payload.object.Bat || 0),
    distance: parseFloat(payload.object.Distance.replace(" mm", "") || 0),
    rssi: payload.rxInfo[0]?.rssi || 0,
    snr: payload.rxInfo[0]?.snr || 0,
};
msg.timestamp = new Date(payload.time).getTime() * 1000000; // Convert to nanoseconds

// Ensure msg.payload is empty to avoid additional data being sent to InfluxDB
delete msg.payload;

return msg;


```
Click **Done**.

![Set up the function node](/images/tutorial-extras/004-images/function-node.png)

**3. Add a Debug Node**

Drag a **Debug** node onto the workspace.

Connect the output of the **Function** node to the input of this node.

Double click the Debug node to configure:

**Name:** Processed Payload

**Output:** Entire message (`msg.payload`)

Click **Done**.

**4. Add an InfluxDB Out Node**

Drag an **InfluxDB Out** node onto the workspace.

Connect the output of the **Function** node to the input of this node.

Double click the InfluxDB node:

**Name: InfluxDB Output**

**Server:** Click the `+` to add a new connection.

    **- Name: `MetSci Demo` (something descriptive)

    **- Version:** `2.0`

    **- URL:** `http://localhost:8086`

    **- Token:** Paste in the API token you saved when we set InfluxDB.

    Leave connection timeout at `10` seconds and the `Verify server certificate` checked.

    - Click **Add** and **Done**.

![Set up the new db](/images/tutorial-extras/004-images/part-1-set-up-influxdb.png)

Now that you've added the db, let's configure the node (I know, confusing, right?)

    **- Name:** `InfluxDB Output`

    **- Server:** This'll be filled in with the server you just set up.

    **- Organization:** Your organization that you set up in InfluxDB.  
    Mine is `Gristle King Inc`.

    **- Bucket:** Use the bucket name from InfluxDB, mine is `metsci-demo`

    **- Measurement:** Leave empty

    **- Time Precision:** `nanoseconds`

    - Click **Add** and **Done**.

![Set up the new node for your db](/images/tutorial-extras/004-images/part-2-set-up-influxdb-out-node.png)

**Measurement:** `sensor_data` (or whatever you want to call it)

Click **Done**.

Your screen will look something like this, with the exception that I've added in a simulated AM319 `inject node` just to double check things for ya.  You don't need this.

![Flow deployed with 2 simulated injectors](/images/tutorial-extras/004-images/ready-to-test.png)

**5. Deploy the Flow**
Click the **Deploy** button to activate the flow. 

Now, to test it, click the button on the **Inject** node to simulate a payload.
Check the **Debug** sidebar to verify the processed payload.  It should look like this:

![Flow deployed with 2 simulated injectors](/images/tutorial-extras/004-images/node-red-success.png)

Now, there's a distinct possibility this won't work the first time.  The very first troubleshooting step I'd take is to generate a new token over in InfluxDB, give it all access, and update the InfluxDB node we just set up.  


Query your InfluxDB database to ensure data is being written correctly:
 - Example CLI Command: `influx -database 'sensor_data' -execute 'SELECT * FROM sensor_data'`

Or you can visualize it directly in Grafana.





### Hard Mode
For this first one, we'll use the simplest payload I have, from the LDDS75.

In the MetSci LNS, go to ```Applications-->Your Sensor Application Name-->Devices-->Your Device Name```, then click on the `Events` tab, then click on the `Up` blue button:

![Find a sample payload from an Event in the LNS](/images/tutorial-extras/004-images/find-event-in-LNS.png)

That'll bring up the Event.  In there, look for the payload, which should be the object & log.  It'll look like this:

![Look for the object and log in the Event](/images/tutorial-extras/004-images/find-object-log-in-event.png)

Now, the LNS displays the payload in "hierarchical format" with "nested keys".  We'll need to get that into JSON format, which takes a few steps.  

First, expand the `object` field in the Event viewer.  I've already done this above.

Now highlight the nested fields, e.g., `TempC_DS18B20`, `Bat` etc, and copy them.  You won't be able to highlight `object`:

![Highlight what you can](/images/tutorial-extras/004-images/highlight-what-you-can.png)

Paste them into a JSON editor or a text editor like Sublime or VS Code, and manually add the `object` key, like this:

```bash
{
  "object": {
    "TempC_DS18B20": "0.00",
    "Bat": "3.345",
    "Distance": "1280 mm",
    "log": {
      "interrupt_flag": 0,
      "distance": "1280 mm",
      "temp": 0,
      "batV": "3.345",
      "sensor_flag": 1,
      "tempValue": 0
    }
  }
}
```

If you want, you can use my formatted example above to make the copy/pasting a bit easier, though you'll have to customize it to your sensor data fields. As an aside, I don't have the optional temperature sensor attached here, so the temp is showing as 0.




---
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW
# EVERYTHING BELOW THIS IS JUST NOTES FOR THE FUTURE PART OF THE TUTORIAL - IGNORE FOR NOW

### Create Dashboards
- Build panels using the stored sensor data, such as distance readings and battery voltage.


## 10.  **Cloudflare Setup, Part 2**  The Real Routes

![Add a new public hostname](/images/tutorial-extras/004-images/add-new-public-hostname.png)

Add the hostname for grafana (keep it simple, yo), then `Save tunnel`.
![Add the hostname and post for Grafana](/images/tutorial-extras/004-images/add-hostname-for-grafana.png)

You can now see both your public hostnames for your tunnel.  Cool, right?

![Confirm both your public hostnames](/images/tutorial-extras/004-images/public-hostnames-are-set-up.png)


### Check Your Subdomain in Cloudflare
Back in Cloudflare, choose your domain, then `DNS` then look for the subdomains you just set up.  I usually add a note to mine, something like `this is for Node-RED for the MetSci Demo Dash project`, just so future me has a clue as to what's going on. 

![Add notes to your DNS records](/images/tutorial-extras/004-images/add-note-to-dns-records.png)

### Secure Your Node-RED Dashboard
Ok, that's rad to see, but...your Raspberry Pi is now facing the internet, which is an ocean of mostly nice people but a few real jackwagons.  Let's make access to your Pi a little harder to access for them.

In Zero Trust, go to `Access-->Service Auth` and click `Create Service Token`.  Name your token something descriptive (this will end up applying to your MetSci Application) and set the duration to Non-Expiring.

![Add a Service Token in Zero Trust](/images/tutorial-extras/004-images/add-service-token.png)

That will give you a `Header and client ID` and a `Header and client secret`.  Save the secret in a secure place.

With our Service Token set up, go to `Access-->Applications` and add a new Application.

![Add a Zero Trust Application](/images/tutorial-extras/004-images/zero-trust-applications.png)

Select `Self Hosted`

Next you'll define the Application details, giving it a descriptive name like `Node-RED Dashboard`, and enter the subdomain for where it'll "live"; this should match the subdomain you set up earlier.  

![Configure Zero Trust Appication](/images/tutorial-extras/004-images/node-red-application-setup.png)

Click `Next` to proceed to the `Policies` section.  

I'll create two Policy rules, one for my email (nik@metsci) and one to allow the use of the Service Token we just set up.

In `Access-->Applications-->Your App Name-->Policies`, select "Add a Policy" setting the Action to `Allow` and the Session Duration to `6 hours`.

Scroll down to `Configure rules`.  We'll set up one for our email and one for the API.  For the first Selector choose `Add include` then `Emails` then put in your email for the Value.  On the second Selector choose `Service Token`, then select the Service Token you just created. 

![Add Selectors to your Zero Trust policy](/images/tutorial-extras/004-images/set-service-token-api.png)

Super, now head over to MetSci and set up the HTTP integration for your Application.  In this case this is for my LDDS - Liquid Level Sensor, so once I'm in that Application I look for Integrations and add an HTTP integration going to `https://node-red.gristleking.dev/metsci-lns-data/` then add two headers using the info from when we set up the Service Token in Cloudflare.  One is the Client ID, one is the secret.

![Set up your http integration in MetSci Chirpstack](/images/tutorial-extras/004-images/metsci-chirpstack-http-integration.png)

Now you've set it up so the MetSci LNS can securely send data through a Zero Trust Cloudflare tunnel to Node-RED on your Raspberry Pi.  Cool, right?

Want to see something cool?  Remember that Cloudflare tunnel you set up?  It's working!  Go to `node-red.yourdomain.com` and you'll see the same login screen.  Now you can access your Node-RED from anywhere, woohoo!

Nice work!  The NSA can prolly still get in, but the rest of the screaming hordes should be kept at bay for now.


## 8. **Full Integration** Set Up & Test Integrations from the MetSci LNS

Visit Node-RED at your new subdomain or your local Pi address in a browser.

Open the Node-RED editor:

![Select Edit from the menu](/images/tutorial-extras/004-images/node-red-editor.png)

Then, up in the top left, search for `http`, then drag in an `HTTP In` node:

![Find an http in node](/images/tutorial-extras/004-images/find-http-in-node.png)

Double-click it and configure:
Method: `POST`
URL: `/metsci-lns-data` *(we set this up when we set up permissions, remember?)

Add a JSON node to parse incoming payloads
Configure the JSON Node

Double-click the JSON node to open its settings.
Set the mode to "Convert to Object" (this is typically the default mode).
Click Done to save the settings.

Connect it to the HTTP In node.

Add a Debug node to inspect the parsed data:
Drag the Debug node into the workspace and connect it to the output of the JSON node.
Configure the Debug node to display msg.payload (default setting).

Deploy the flow.

![With nodes set up, deploy the flow](/images/tutorial-extras/004-images/nodes-set-up-now-deploy.png)

### FUTURE post - Using a Payload to construct a JSON
You'll also need a sample payload from your device, which you can find in Chirpstack.  