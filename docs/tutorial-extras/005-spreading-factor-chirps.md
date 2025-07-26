---
sidebar_position: 5
title: Spreading Factor & Chirps
---

# Spreading Factor & Chirps

Like most amazing things in technology, LoRa was inspired by nature.

Standing for Long Range, LoRa is a radio protocol based on using Chirp Spread Spectrum to transmit information for long ranges at low power.

In the same way that dolphins and bats “chirp” for sonar, we humans have figured out how to use chirps for long range communication.

Knowing a bit more about chirps and spreading factor is helpful in LoRa, partly because this will save you battery life with your LoRa devices, and partly because it’s flat-out rad to know how the world works.

## The Chirp
A `chirp` is a piece of data, technically called a "symbol", though we'll stick with `chirp`. A LoRa packet will have lots of chirps in it. Think of these like bird chirps rising from low frequency to high frequency, or the other way around.

The frequency center is the middle sound of the chirp.  Chirps can go from low to high (an “up chirp”) or from high to low (a “down chirp”).

It’s best at this point to hear these: here’s what LoRa sounds like when you slow it down into the audio spectrum (*courtesy Jeremy Cooper aka "Jerm"*)

### Audio - Simple Chirps

<div className="custom-audio-player" style={{
  marginTop: '25px',
  marginBottom: '25px'
}}>
  <audio controls preload="metadata" style={{
    width: '100%',
    height: '50px',
    backgroundColor: '#000000',
    borderRadius: '8px',
    border: '2px solid #FA7F2A'
  }}>
    <source src="https://video.meteoscientific.com/actual-lora_mixdown.mp3" type="audio/mpeg" />
    Your browser does not support the audio element.
  </audio>
  <style jsx>{`
    .custom-audio-player audio::-webkit-media-controls-panel {
      background-color: #000000;
    }
    .custom-audio-player audio::-webkit-media-controls-play-button {
      background-color: #FA7F2A;
      border-radius: 50%;
    }
    .custom-audio-player audio::-webkit-media-controls-timeline {
      background-color: #18A7D9;
    }
    .custom-audio-player audio::-webkit-media-controls-volume-slider {
      background-color: #18A7D9;
    }
  `}</style>
</div>

Up chirps and down chirps are more or less **orthogonal**, which is a fancy way of saying that you can hear an up chirp and a down chirp at the same time and they don’t cancel each other out.  Orthogonality is useful when you’re sending a LOT of chirps, which is what LoRa radio waves are full of.   

How full?  The Helium LoRaWAN, which is more or less global and receives just about every LoRa signal out there (though it only routes the ones addressed to Helium devices) “hears” 5-7,000 packets per **second**.  If this were sound it would be a cacophony, but due to various factors of CSS, each one of these signals is intelligible.  That, by the way, is bloody amazing.

## Why We Use Chirps

Due to the physical properties of these chirps (which is beyond the scope of this article), they are resilient to interference and performant at low power.  They don’t get confused by multi-path (bouncing off buildings in a city), the Doppler effect doesn’t disrupt them, and they can be used to transmit data an incredibly long way for very little power expenditure.

For these reasons, chirps are used in military and marine radars as well as ionospheric and space weather assessments.

## Data Per Chirp

An inquisitive person might now say, “Ok, that’s cool.  How much data is in a chirp?”

The answer is that it depends on the Spreading Factor.  You see, all chirps are not equal.  Some are spread out longer, some are compacted shorter.  Some cross a wider section of bandwidth, some a narrower. This leads us directly into the concept of spreading factor.


## Spreading Factors

The difference in the length of those chirps is called the Spreading Factor (SF); the chirp is “spread” over time.  Spreading Factors range from 7 to 12, and those numbers correspond to the bits in a chirp.  A chirp at SF 7 has 7 bits, and takes less time to transmit than one at SF 12, which has 12 bits. 

Why would you use one or the other?  It’s a balance between how fast and how far you want to send data.  Lower spreading factors send data faster at a lower energy cost but with shorter range.  Higher spreading factors can send it further, but it will take longer to send that data and require more energy because you’re transmitting for more time.

To put some ballpark numbers on it, a higher SF, like SF 12 can have a data rate of 0.3 kbps versus SF 7 which might have a data rate of approximately 22 kbps.  This depends on bandwidth, which is beyond the scope of this article. 

The further you want it to go, the slower you should send it, but the more energy per chirp it’ll take to get there because you’re on the air longer.

The shorter distance you need to send it the faster you can send data and the lower the energy cost. 

A lower spreading factor (like 7) has fewer bits per chirp, which means less time on air, which gives you a higher data rate because you can send data more frequently.

A higher spreading factor (like 12) encodes more bits per chirp, and requires more time on air, giving a lower overall data rate.

That can seem backward for us non-engineers; shouldn’t more time on air per chirp give you more data?  No. 

Think of this in terms of bench pressing; it costs way less energy to bench 40 lbs than 400 lbs, and you can burn through reps at 40 lbs much faster, giving you more presses in any given time period.  This isn’t an exact analogy, it’s just helpful to visualize.

The upside of a lower data rate like 12 is that you’re putting space between the bits of data, which means the message is less jumbled and can be more clearly “heard” at the receiving end.  Instead of yelling at the top of your lungs as fast as you can speak, you’re articulating each word very clearly, pausing in between words.

## Using Spreading Factor In The Real World
With this new understanding of chirps and spreading factor, consider how you should set up your devices to optimize for efficiency, range, and power consumption.

In real-world applications like smart cities, agriculture, and environmental monitoring, where you have to roll trucks to change the batteries on devices, setting your spreading factor correctly can significantly decrease your costs. 

## Spreading Factor Rules of Thumb 

The one way I’ve found to guarantee RF engineer feedback is to publish rules of thumb that are off by more than a femtometer; this is one of the reasons I don’t have comments on these tutorials.  ;)

This table should give you a general idea of when to use what Spreading Factor.  It combines data from [NIH](https://pmc.ncbi.nlm.nih.gov/articles/PMC9921199/), [Semtech](https://www.semtech.com/uploads/technology/LoRa/lora-and-lorawan.pdf), and other [LoRaWAN practitioners](https://www.minew.com/lorawan-range-overview/) to give you a rough idea of where to start with your SF settings per device.

As always, you’ll be the most sure if you test your coverage, but if you’re in a rush or just daydreaming through your initial planning, you’ll find this spreading factor table helpful


<div className="spreading-factor-table">
  <table style={{
    width: 'fit-content',
    tableLayout: 'fixed',
    borderCollapse: 'collapse',
    backgroundColor: '#FCF5F0',
    border: '2px solid #FA7F2A',
    borderRadius: '8px',
    overflow: 'hidden',
    marginTop: '20px',
    marginBottom: '20px'
  }}>
    <thead>
      <tr style={{ backgroundColor: '#FA7F2A' }}>
        <th style={{
          padding: '12px 16px',
          textAlign: 'left',
          fontWeight: 'bold',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>Environment</th>
        <th style={{
          padding: '12px 16px',
          textAlign: 'center',
          fontWeight: 'bold',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>500m</th>
        <th style={{
          padding: '12px 16px',
          textAlign: 'center',
          fontWeight: 'bold',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>1km</th>
        <th style={{
          padding: '12px 16px',
          textAlign: 'center',
          fontWeight: 'bold',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>5km</th>
        <th style={{
          padding: '12px 16px',
          textAlign: 'center',
          fontWeight: 'bold',
          color: '#000000'
        }}>10km</th>
      </tr>
    </thead>
    <tbody>
      <tr style={{ backgroundColor: '#FCF5F0' }}>
        <td style={{
          padding: '12px 16px',
          color: '#000000',
          fontWeight: '500',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>Dense Cities (Urban)</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF7</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF7-SF8</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF10-SF12</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderBottom: '1px solid #18A7D9'
        }}>SF12 (marginal, often &lt;10km)</td>
      </tr>
      <tr style={{ backgroundColor: '#FCF5F0' }}>
        <td style={{
          padding: '12px 16px',
          color: '#000000',
          fontWeight: '500',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>Suburbs</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF7</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF7</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9',
          borderBottom: '1px solid #18A7D9'
        }}>SF8-SF10</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderBottom: '1px solid #18A7D9'
        }}>SF11-SF12</td>
      </tr>
      <tr style={{ backgroundColor: '#FCF5F0' }}>
        <td style={{
          padding: '12px 16px',
          color: '#000000',
          fontWeight: '500',
          borderRight: '2px solid #18A7D9'
        }}>Rural</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>SF7</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>SF7</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000',
          borderRight: '2px solid #18A7D9'
        }}>SF7-SF9</td>
        <td style={{
          padding: '12px 16px',
          textAlign: 'center',
          color: '#000000'
        }}>SF9-SF11</td>
      </tr>
    </tbody>
  </table>
</div>

That’s it, you now know enough about spreading factor to have a good idea of what to set it to, how it works, and how setting everything to SF12 is not the optimal way to run a network.

Get out there and crush!  

If you're ready to start chirping on Helium, please sign up for the [MeteoScientific Console](https://console.meteoscientific.com/front/); it's free to sign up, the first 400 DC (24 bytes each) are free and after that cost just $0.0001 each.  Have fun out there!

<ConsoleButton />
