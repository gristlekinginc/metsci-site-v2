---
sidebar_position: 3
title: "MCP for MetSci Console"
description: "What MCP is, why we built a Helium ChirpStack MCP, and how agents can use it safely with bring-your-own credentials."
slug: mcp-for-metsci-console
keywords: [mcp, model context protocol, chirpstack mcp, helium lns mcp, meteoscientific mcp, agent tools]
---

# MCP for MetSci Console

If you've been hearing "`we need an MCP for that`" and thinking _what does that even mean?_, this guide is for you.

This project adds an MCP endpoint for the MeteoScientific Console flavor of Helium-compatible ChirpStack. The goal is simple: make it easier for agents to work with the console without writing brittle, one-off scripts every time.

## What Is MCP?

MCP (Model Context Protocol) is a standard way for AI agents to discover and call tools.

Think of it as:

- an API contract that agents understand out of the box,
- plus tool schemas,
- plus structured responses,
- plus consistent error handling.

Instead of every agent writing custom glue code for every console endpoint, MCP gives them one interface to call.

## Why We Built This MCP

The MetSci Console runs a Helium-compatible ChirpStack stack. The APIs are powerful, but in practice agents run into friction:

- Different auth/header behavior across surfaces
- Repetitive boilerplate for common tasks
- Weak consistency in retry and error handling across custom scripts
- Security risk when people over-share powerful credentials

This MCP solves those problems by offering a structured tool layer for common operations like application creation, device profile creation, device registration, webhook setup, and telemetry lookup.

## The MCP Library Pattern

We publish MCPs as a library host:

- Root index: `https://mcp.nik.bot/`
- This MCP endpoint: `https://mcp.nik.bot/metsci-console`
- Bootstrap metadata: `https://mcp.nik.bot/metsci-console/info`

This lets us add more MCPs later under different paths (for different products/workflows) without spinning up a new hostname every time.

## Security Model (Important)

This MCP is intentionally designed to reduce blast radius:

- **Bring your own credentials**: callers provide their own LNS tokens.
- **No platform admin password in the MCP**.
- **Privileged tools disabled by default**.
- **Host policy fail-closed by default**.

In plain English: this does **not** give random callers your MetSci admin credentials. It uses caller-provided credentials and applies policy checks.

## How To Use It

### 1) Get your own LNS tokens

If you are using MetSci Console, default to:

`https://console.meteoscientific.com`

If you are using another Helium-ChirpStack console, replace with that console base URL.

Using an env var keeps the command reusable:

```bash
export LNS_CONSOLE="https://console.meteoscientific.com"
curl -X POST "$LNS_CONSOLE/console/1.0/sign/in" \
  -H "Content-Type: application/json" \
  -H "Origin: $LNS_CONSOLE" \
  -H "Referer: $LNS_CONSOLE/front/login" \
  -d '{"username":"YOUR_USERNAME","password":"YOUR_PASSWORD"}'
```

Use `chirpstackBearer` and `consoleBearer` from the response.

:::warning Credential Safety
It is okay to show this `curl` as a quickstart, but do not paste real credentials into shared terminals, docs, or screenshots. Commands with inline passwords can appear in shell history.

Safer options:
- run from a private shell session,
- clear or disable shell history for the session,
- or prompt for password interactively before constructing the request body.
:::

### 2) Point your MCP client to the endpoint

Use:

`https://mcp.nik.bot/metsci-console`

For discovery / bootstrapping details:

`https://mcp.nik.bot/metsci-console/info`

### 3) Authenticate with one of two patterns

- Raw bearer token (+ optional `x-lns-base-url` header), or
- Packed bearer token:
  - `mcpv1.<base64url(json)>`
  - fields include `lnsBaseUrl`, `chirpstackToken`, `consoleToken`, optional `tenantScopes`

### 4) Start with safe reads

Recommended first tool calls:

- `listStreams`
- `getLatestTelemetry`

Then add writes as needed (with idempotency keys and policy controls).

## What This Makes Easier for Agents

- Faster onboarding to Helium-ChirpStack workflows
- Safer automation defaults
- Fewer custom wrappers per framework
- Better reliability via strict schema + structured JSON responses

For most agent teams, this turns "weeks of integration glue" into "connect, authenticate, and call tools."

## A Note on Compatibility

This MCP targets the Helium-compatible ChirpStack console model currently used by MeteoScientific and related stacks. If your deployment differs, adjust host policy and token acquisition flow accordingly.

If you are operating your own instance, you can run the same MCP pattern under your own domain and keep the same path structure (`/your-mcp-name`).

## Final Thought

MCP is not magic by itself. It is a clean interface layer.

But for agent workflows, that layer matters a lot: it standardizes how tools are exposed, lowers integration friction, and makes it practical to build reusable skills around real-world sensing systems.
