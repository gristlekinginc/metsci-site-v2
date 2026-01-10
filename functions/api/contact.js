// Cloudflare Pages Function for contact form
// This file automatically becomes available at /api/contact

export async function onRequestPost(context) {
  const { request, env } = context;

  // --- Parse and validate JSON body ---
  let data;
  try {
    data = await request.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { name, email, message, website } = data;
  if (!name || !email || !message) {
    return new Response(JSON.stringify({ error: "Missing fields" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // --- Honeypot spam check ---
  if (website && website.trim() !== "") {
    return new Response(JSON.stringify({ error: "Spam detected" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // --- Turnstile Verification ---
  const token = data["cf-turnstile-response"];
  const secretKey = env.TURNSTILE_SECRET_KEY;

  if (!token) {
    return new Response(JSON.stringify({ error: "Turnstile token missing" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const turnstileFormData = new FormData();
  turnstileFormData.append("secret", secretKey);
  turnstileFormData.append("response", token);
  turnstileFormData.append("remoteip", request.headers.get("CF-Connecting-IP"));

  const turnstileResult = await fetch(
    "https://challenges.cloudflare.com/turnstile/v0/siteverify",
    {
      body: turnstileFormData,
      method: "POST",
    }
  );

  const turnstileOutcome = await turnstileResult.json();
  if (!turnstileOutcome.success) {
    return new Response(
      JSON.stringify({ error: "Turnstile verification failed" }),
      {
        status: 403,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  // --- Store submission in D1 ---
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  
  try {
    await env.METSCI_D1.prepare(
      `INSERT INTO contact_submissions (name, email, message, ip_address, user_agent, created_at) 
       VALUES (?, ?, ?, ?, ?, datetime('now'))`
    ).bind(name, email, message, clientIP, userAgent).run();
  } catch (dbError) {
    console.error("D1 insert error:", dbError);
    // Continue even if D1 fails - email is more important
  }

  // --- Send email via Mailgun ---
  const mailgunDomain = "mg.meteoscientific.com";
  const mailgunApiKey = env.MAILGUN_CONTACT_API;
  const mailgunUrl = `https://api.mailgun.net/v3/${mailgunDomain}/messages`;

  const params = new URLSearchParams();
  params.append("from", `Contact Form <contact@${mailgunDomain}>`);
  params.append("to", env.CONTACT_TO_EMAIL);
  params.append("subject", `New Contact Form Submission from ${name}`);
  params.append("text", `Name: ${name}\nEmail: ${email}\nMessage:\n${message}`);

  const auth = "Basic " + btoa(`api:${mailgunApiKey}`);

  const mgResponse = await fetch(mailgunUrl, {
    method: "POST",
    headers: {
      Authorization: auth,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
  });

  if (!mgResponse.ok) {
    const errorText = await mgResponse.text();
    return new Response(
      JSON.stringify({ error: "Failed to send email: " + errorText }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  // --- Success! ---
  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

// Handle OPTIONS for CORS preflight (not typically needed for same-origin, but good to have)
export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}
