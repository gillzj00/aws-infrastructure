/**
 * Minimal JWT (HS256) implementation using Node.js built-in crypto.
 *
 * Why not use a library like jsonwebtoken?
 * - Zero dependencies = smaller Lambda ZIP = faster cold starts
 * - HS256 (HMAC-SHA256) is ~10 lines of code; we don't need RSA/EC/JWK
 * - Node 22 crypto module handles everything we need
 *
 * The JWT stores the GitHub user's id, login, and avatar_url as claims.
 * It's signed with the secret from SSM and set as an httpOnly cookie,
 * so the browser can't read or tamper with it.
 */
import { createHmac, timingSafeEqual } from "node:crypto";

const ALGORITHM = "HS256";
const TOKEN_EXPIRY_SECONDS = 7 * 24 * 60 * 60; // 7 days

function base64url(input) {
  const str = typeof input === "string" ? input : JSON.stringify(input);
  return Buffer.from(str).toString("base64url");
}

function sign(payload, secret) {
  const header = base64url({ alg: ALGORITHM, typ: "JWT" });
  const body = base64url(payload);
  const signature = createHmac("sha256", secret)
    .update(`${header}.${body}`)
    .digest("base64url");
  return `${header}.${body}.${signature}`;
}

function verify(token, secret) {
  const parts = token.split(".");
  if (parts.length !== 3) return null;

  const [header, body, sig] = parts;

  // Recompute the expected signature
  const expected = createHmac("sha256", secret)
    .update(`${header}.${body}`)
    .digest();

  const actual = Buffer.from(sig, "base64url");

  // Timing-safe comparison prevents timing attacks
  if (
    expected.length !== actual.length ||
    !timingSafeEqual(expected, actual)
  ) {
    return null;
  }

  const payload = JSON.parse(Buffer.from(body, "base64url").toString());

  // Check expiration
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
    return null;
  }

  return payload;
}

/**
 * Create a signed JWT for a GitHub user.
 */
export function createToken(user, secret) {
  const now = Math.floor(Date.now() / 1000);
  return sign(
    {
      sub: String(user.id),
      login: user.login,
      avatar_url: user.avatar_url,
      iat: now,
      exp: now + TOKEN_EXPIRY_SECONDS,
    },
    secret
  );
}

/**
 * Verify and decode a JWT. Returns the payload or null if invalid/expired.
 */
export function verifyToken(token, secret) {
  return verify(token, secret);
}
