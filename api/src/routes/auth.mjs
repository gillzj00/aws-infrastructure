/**
 * Auth routes — GitHub OAuth flow + session management.
 *
 * Routes:
 *   GET  /auth/login    → Redirect to GitHub's OAuth authorize page
 *   GET  /auth/callback → Exchange code for token, create JWT, redirect to frontend
 *   GET  /auth/me       → Return current user from JWT cookie (or 401)
 *   POST /auth/logout   → Clear the session cookie
 *
 * Cookie strategy:
 *   - Name: "session"
 *   - Domain: .forfun.gillzhub.com (works across subdomains — site + API)
 *   - httpOnly: true (JavaScript can't read it → XSS-safe)
 *   - Secure: true (HTTPS only)
 *   - SameSite: Lax (sent on top-level navigations like the OAuth redirect,
 *     but not on cross-origin XHR/fetch — we use credentials:'include' for that)
 */
import { getSecrets } from "../lib/ssm.mjs";
import { exchangeCodeForToken, getUser } from "../lib/github.mjs";
import { createToken, verifyToken } from "../lib/jwt.mjs";
import { json, redirect, error } from "../lib/response.mjs";

const COOKIE_NAME = "session";

function buildCookie(value, maxAge) {
  const domain = process.env.API_DOMAIN.replace(/^api\./, ".");
  return [
    `${COOKIE_NAME}=${value}`,
    `Domain=${domain}`,
    `Path=/`,
    `Max-Age=${maxAge}`,
    `HttpOnly`,
    `Secure`,
    `SameSite=Lax`,
  ].join("; ");
}

/**
 * Parse the session cookie from the API Gateway event.
 * API Gateway v2 puts cookies in event.cookies as an array of "key=value" strings.
 */
function getSessionCookie(event) {
  if (!event.cookies) return null;
  for (const c of event.cookies) {
    const [name, ...rest] = c.split("=");
    if (name.trim() === COOKIE_NAME) return rest.join("=");
  }
  return null;
}

// ────────────────────────────────────────────
// GET /auth/login
// ────────────────────────────────────────────
export async function login() {
  const { githubClientId } = await getSecrets();

  const params = new URLSearchParams({
    client_id: githubClientId,
    redirect_uri: `https://${process.env.API_DOMAIN}/auth/callback`,
    scope: "read:user", // Only need basic profile info
  });

  return redirect(`https://github.com/login/oauth/authorize?${params}`);
}

// ────────────────────────────────────────────
// GET /auth/callback
// ────────────────────────────────────────────
export async function callback(event) {
  const code = event.queryStringParameters?.code;
  if (!code) {
    return error(400, "Missing code parameter");
  }

  try {
    const { githubClientId, githubClientSecret, jwtSigningKey } =
      await getSecrets();

    // Step 1: Exchange the authorization code for an access token
    const accessToken = await exchangeCodeForToken(
      code,
      githubClientId,
      githubClientSecret
    );

    // Step 2: Fetch the GitHub user profile
    const ghUser = await getUser(accessToken);

    // Step 3: Create a JWT containing the user's GitHub identity
    const token = createToken(ghUser, jwtSigningKey);

    // Step 4: Set the JWT as an httpOnly cookie and redirect to the frontend
    const cookie = buildCookie(token, 7 * 24 * 60 * 60); // 7 days
    return redirect(process.env.FRONTEND_URL, [cookie]);
  } catch (err) {
    console.error("OAuth callback error:", err);
    // Redirect to frontend with error flag rather than showing a raw error page
    return redirect(`${process.env.FRONTEND_URL}?auth_error=1`);
  }
}

// ────────────────────────────────────────────
// GET /auth/me
// ────────────────────────────────────────────
export async function me(event) {
  const token = getSessionCookie(event);
  if (!token) {
    return error(401, "Not authenticated");
  }

  const { jwtSigningKey } = await getSecrets();
  const payload = verifyToken(token, jwtSigningKey);

  if (!payload) {
    return error(401, "Invalid or expired session");
  }

  return json(200, {
    id: payload.sub,
    login: payload.login,
    avatar_url: payload.avatar_url,
  });
}

// ────────────────────────────────────────────
// POST /auth/logout
// ────────────────────────────────────────────
export async function logout() {
  // Setting Max-Age=0 tells the browser to delete the cookie immediately
  const cookie = buildCookie("", 0);
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": process.env.FRONTEND_URL,
      "Access-Control-Allow-Credentials": "true",
    },
    cookies: [cookie],
    body: JSON.stringify({ ok: true }),
  };
}
