"use strict";(self.webpackChunkmeteoscientific=self.webpackChunkmeteoscientific||[]).push([[9585],{7478:(e,s,n)=>{n.r(s),n.d(s,{assets:()=>l,contentTitle:()=>a,default:()=>h,frontMatter:()=>r,metadata:()=>i,toc:()=>c});const i=JSON.parse('{"id":"tutorial-basics/intro-to-console","title":"How to Use the LoRaWAN Console","description":"This lesson will walk you through the process of using the MeteoScientific (MetSci) Console. You can follow along by visiting console.meteoscientific.com. This guide will give you an overview of the console and how data flows within the LoRaWAN network.","source":"@site/docs/tutorial-basics/002-intro-to-console.md","sourceDirName":"tutorial-basics","slug":"/tutorial-basics/intro-to-console","permalink":"/docs/tutorial-basics/intro-to-console","draft":false,"unlisted":false,"editUrl":"https://github.com/meteoscientific/website/tree/main/docs/tutorial-basics/002-intro-to-console.md","tags":[],"version":"current","sidebarPosition":2,"frontMatter":{"sidebar_position":2},"sidebar":"tutorialSidebar","previous":{"title":"LoRaWAN - The Big Picture","permalink":"/docs/tutorial-basics/LoRaWAN-Big-Picture"},"next":{"title":"Device Profiles","permalink":"/docs/tutorial-basics/device-profiles"}}');var t=n(4848),o=n(8453);const r={sidebar_position:2},a="How to Use the LoRaWAN Console",l={},c=[{value:"Want to Watch?",id:"want-to-watch",level:2},{value:"Understanding Data Flow",id:"understanding-data-flow",level:2},{value:"Getting Started with the MetSci Console",id:"getting-started-with-the-metsci-console",level:2},{value:"Tenant Details",id:"tenant-details",level:2},{value:"Adding Users and API Keys",id:"adding-users-and-api-keys",level:2},{value:"Device Profiles and Applications",id:"device-profiles-and-applications",level:2},{value:"Additional Features",id:"additional-features",level:2},{value:"Conclusion",id:"conclusion",level:2}];function d(e){const s={a:"a",h1:"h1",h2:"h2",header:"header",li:"li",ol:"ol",p:"p",strong:"strong",ul:"ul",...(0,o.R)(),...e.components};return(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(s.header,{children:(0,t.jsx)(s.h1,{id:"how-to-use-the-lorawan-console",children:"How to Use the LoRaWAN Console"})}),"\n",(0,t.jsxs)(s.p,{children:["This lesson will walk you through the process of using the ",(0,t.jsx)(s.strong,{children:"MeteoScientific (MetSci) Console"}),". You can follow along by visiting ",(0,t.jsx)(s.a,{href:"https://console.meteoscientific.com",children:"console.meteoscientific.com"}),". This guide will give you an overview of the console and how data flows within the LoRaWAN network."]}),"\n",(0,t.jsx)(s.h2,{id:"want-to-watch",children:"Want to Watch?"}),"\n",(0,t.jsx)(s.p,{children:"If you'd rather do this via video, check that out here:"}),"\n",(0,t.jsx)("iframe",{width:"560",height:"315",src:"https://www.youtube.com/embed/pLJh061R_9w?si=-VJDDDX79X5D2Xfk",title:"YouTube video player",frameborder:"0",allow:"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",referrerpolicy:"strict-origin-when-cross-origin",allowfullscreen:!0}),"\n",(0,t.jsx)(s.h2,{id:"understanding-data-flow",children:"Understanding Data Flow"}),"\n",(0,t.jsx)(s.p,{children:"Before diving into the console, let's break down the flow of data in the system:"}),"\n",(0,t.jsxs)(s.ol,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Sensors"}),": It all starts with a sensor. For example, a sensor detects a leaky pipe and sends a coded packet through the airwaves."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Hotspots"}),": The packet is received by a hotspot, which then forwards it to the MetSci console through the Internet."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"LoRaWAN Network Server"}),": The packet passes through a LoRaWAN Network Server (LNS), which decodes the data."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Console Decoding"}),": The MetSci console interprets the decoded data, determining if a pipe is leaking, the current temperature, wind speed, etc."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Applications"}),": Finally, the decoded data is sent to an application (e.g., the MetSci app), or it can be integrated with other systems."]}),"\n"]}),"\n",(0,t.jsxs)(s.p,{children:["Today, we'll be focusing on the ",(0,t.jsx)(s.strong,{children:"MetSci Console"}),"."]}),"\n",(0,t.jsx)(s.h2,{id:"getting-started-with-the-metsci-console",children:"Getting Started with the MetSci Console"}),"\n",(0,t.jsxs)(s.ol,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Sign In"}),": Head over to ",(0,t.jsx)(s.a,{href:"https://console.meteoscientific.com",children:"console.meteoscientific.com"})," and sign up for an account."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Dashboard Overview"}),": After signing in, you'll land on the dashboard, where you'll see four cards:","\n",(0,t.jsxs)(s.ul,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Active Devices"}),": This is the most important card. Here, you can view devices you\u2019ve set up."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Active Gateways"}),": You can safely ignore this for now; all Helium's gateways are your active gateways."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Device Data Rate Usage"}),": This is more technical, and we'll cover it in a separate video."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Gateway Map"}),": This doesn't show in Console.  You'll need to use the ",(0,t.jsx)(s.a,{href:"https://explorer.helium.com",children:"Helium Explorer"})," to view all gateways."]}),"\n"]}),"\n"]}),"\n"]}),"\n",(0,t.jsx)(s.h2,{id:"tenant-details",children:"Tenant Details"}),"\n",(0,t.jsxs)(s.p,{children:["Every console account starts with ",(0,t.jsx)(s.strong,{children:"400 free data credits"}),". Here are a few things to know about data credits:"]}),"\n",(0,t.jsxs)(s.ul,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Cost of Data Credits"}),": Each data credit (DC) costs $0.0001. The minimum purchase amount is ",(0,t.jsx)(s.strong,{children:"50,000 DC"}),", which costs $5."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Usage"}),": For a minimal sensor, you could run a device sending 1 DC every hour for a year using just under 9,000 DC."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Managing Duplicates"}),": If you want redunancy, you can get duplicate packets from multiple hotspots. For now, iff you see a setting called ",(0,t.jsx)(s.strong,{children:"Current Value"}),", set it to 1 to avoid unnecessary duplicates."]}),"\n"]}),"\n",(0,t.jsx)(s.h2,{id:"adding-users-and-api-keys",children:"Adding Users and API Keys"}),"\n",(0,t.jsxs)(s.p,{children:["The console allows you to add Users, such as a business partner or admin, by navigating to ",(0,t.jsx)(s.strong,{children:"Users"})," and entering their email information."]}),"\n",(0,t.jsxs)(s.p,{children:["Additionally, you can generate ",(0,t.jsx)(s.strong,{children:"API Keys"})," to connect your console to other software systems.  We'll cover that more in depth later."]}),"\n",(0,t.jsx)(s.h2,{id:"device-profiles-and-applications",children:"Device Profiles and Applications"}),"\n",(0,t.jsxs)(s.p,{children:["One key area where new users get tripped up is understanding ",(0,t.jsx)(s.strong,{children:"Device Profiles"})," and ",(0,t.jsx)(s.strong,{children:"Applications"}),"."]}),"\n",(0,t.jsx)(s.p,{children:"Here's a quick breakdown:"}),"\n",(0,t.jsxs)(s.ul,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Device Profiles"}),": Think of this as an application template. It holds settings that apply to a group of devices."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Applications"}),": An application is a collection of devices, such as parking sensors or trash can level sensors."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Tags"}),": You can use tags to organize devices, such as grouping parking sensors by levels in a parking structure."]}),"\n"]}),"\n",(0,t.jsx)(s.h2,{id:"additional-features",children:"Additional Features"}),"\n",(0,t.jsxs)(s.ul,{children:["\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Purchase Data Credits"}),": You can purchase additional data credits directly through the console."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Service Requests"}),": If you encounter any issues, you can submit a service request here, although it's far more helpful to the public if you submit over on the ",(0,t.jsx)(s.a,{href:"https://github.com/meteoscientific/website/issues",children:"Github Issues"})," page."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"Migrating from Legacy"}),": If you're transitioning from the original Helium Console (almost no one is as of August 2024), there's an option to migrate your data."]}),"\n",(0,t.jsxs)(s.li,{children:[(0,t.jsx)(s.strong,{children:"User Profile"}),": You can update your profile details at any time, including your name, address, and company info."]}),"\n"]}),"\n",(0,t.jsx)(s.h2,{id:"conclusion",children:"Conclusion"}),"\n",(0,t.jsxs)(s.p,{children:["That wraps up this overview of the MetSci Console! We\u2019ll dive deeper into specific features in the following lessons. If you haven't signed up for a console account yet, head over to ",(0,t.jsx)(s.a,{href:"https://console.meteoscientific.com",children:"console.meteoscientific.com"}),", sign up, and poke around."]})]})}function h(e={}){const{wrapper:s}={...(0,o.R)(),...e.components};return s?(0,t.jsx)(s,{...e,children:(0,t.jsx)(d,{...e})}):d(e)}},8453:(e,s,n)=>{n.d(s,{R:()=>r,x:()=>a});var i=n(6540);const t={},o=i.createContext(t);function r(e){const s=i.useContext(o);return i.useMemo((function(){return"function"==typeof e?e(s):{...s,...e}}),[s,e])}function a(e){let s;return s=e.disableParentContext?"function"==typeof e.components?e.components(t):e.components||t:r(e.components),i.createElement(o.Provider,{value:s},e.children)}}}]);