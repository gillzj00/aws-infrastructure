/**
 * Lambda handler — single entry point with a route map.
 *
 * Why a single Lambda with a router instead of one Lambda per route?
 * 1. Shared cold start: once this Lambda is warm, ALL routes are fast
 * 2. Shared code: auth helpers, DB client, SSM cache are initialized once
 * 3. Simpler deployment: one ZIP, one function, one set of env vars
 * 4. At this scale (personal site), the trade-off is overwhelmingly in favor
 *    of simplicity. You'd split into separate Lambdas when individual routes
 *    need different memory/timeout settings or independent scaling.
 *
 * API Gateway HTTP API (v2) sends events with:
 *   event.routeKey    → "GET /auth/login" (matches our route map keys)
 *   event.rawPath     → "/auth/login"
 *   event.cookies     → ["session=eyJ..."] (parsed from Cookie header)
 *   event.body        → request body as string (for POST)
 */
import { login, callback, me, logout } from "./routes/auth.mjs";
import { list, sign } from "./routes/guestbook.mjs";

// Route map — keys match the routeKey values configured in api_gateway.tf
const routes = {
  "GET /auth/login": login,
  "GET /auth/callback": callback,
  "GET /auth/me": me,
  "POST /auth/logout": logout,
  "GET /guestbook": list,
  "POST /guestbook": sign,
};

export async function handler(event) {
  const routeHandler = routes[event.routeKey];

  if (!routeHandler) {
    return {
      statusCode: 404,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Not found" }),
    };
  }

  try {
    return await routeHandler(event);
  } catch (err) {
    console.error(`Error in ${event.routeKey}:`, err);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
}
