export default {
  async fetch(request, env) {
    // 1. Only accept POST + validate token
    if (request.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405 });
    }
    const auth = request.headers.get("Authorization");
    if (auth !== env.TRACKER_AUTH_TOKEN) {
      return new Response("Unauthorized", { status: 401 });
    }

    // 2. Parse JSON
    if (!request.headers.get("Content-Type")?.includes("application/json")) {
      return new Response("Unsupported Media Type", { status: 415 });
    }
    let body;
    try {
      body = await request.json();
    } catch {
      return new Response("Bad JSON", { status: 400 });
    }

    // 3. Extract fields
    const id            = body.deduplicationId;
    const time          = body.time;
    const dev_eui       = body.deviceInfo?.devEui;
    const batV          = body.object?.batV            ?? null;
    const fixFailed     = body.object?.fixFailed        ?? false;
    const latitude      = body.object?.latitudeDeg      ?? null;
    const longitude     = body.object?.longitudeDeg     ?? null;
    const speedKmph     = body.object?.speedKmph        ?? null;
    const headingDeg    = body.object?.headingDeg       ?? null;

    // 4. Single INSERT into oyster_tracks
    try {
      await env.DB.prepare(`
        INSERT INTO oyster_tracks (
          id, time, dev_eui,
          battery_voltage, fix_failed,
          latitude, longitude,
          speed_kmph, heading_deg
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `)
      .bind(
        id, time, dev_eui,
        batV, fixFailed,
        latitude, longitude,
        speedKmph, headingDeg
      )
      .run();

      return new Response("OK", { status: 200 });
    } catch (err) {
      return new Response(
        `Error writing to DB: ${err.message}`,
        { status: 500 }
      );
    }
  }
}
