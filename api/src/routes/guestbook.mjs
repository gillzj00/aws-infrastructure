/**
 * Guestbook routes — list, sign, and delete.
 *
 * Routes:
 *   GET    /guestbook            → List all entries (public, no auth required)
 *   POST   /guestbook            → Sign the guestbook (requires valid session cookie)
 *   DELETE /guestbook/{entryId}  → Delete own entry (requires valid session cookie)
 *
 * Entry schema in DynamoDB:
 *   entryId   (S) — UUIDv4, hash key
 *   login     (S) — GitHub username
 *   avatarUrl (S) — GitHub avatar URL
 *   message   (S) — User's message (max 500 chars)
 *   createdAt (S) — ISO 8601 timestamp
 */
import { randomUUID } from "node:crypto";
import { getSecrets } from "../lib/ssm.mjs";
import { verifyToken } from "../lib/jwt.mjs";
import { putEntry, getEntry, deleteEntry, listEntries } from "../lib/dynamodb.mjs";
import { json, error } from "../lib/response.mjs";

const MAX_MESSAGE_LENGTH = 500;

/**
 * Parse the session cookie from the API Gateway event.
 */
function getSessionCookie(event) {
  if (!event.cookies) return null;
  for (const c of event.cookies) {
    const [name, ...rest] = c.split("=");
    if (name.trim() === "session") return rest.join("=");
  }
  return null;
}

// ────────────────────────────────────────────
// GET /guestbook — public
// ────────────────────────────────────────────
export async function list() {
  const entries = await listEntries();
  return json(200, { entries });
}

// ────────────────────────────────────────────
// POST /guestbook — auth required
// ────────────────────────────────────────────
export async function sign(event) {
  // Verify authentication
  const token = getSessionCookie(event);
  if (!token) {
    return error(401, "You must be logged in to sign the guestbook");
  }

  const { jwtSigningKey } = await getSecrets();
  const user = verifyToken(token, jwtSigningKey);
  if (!user) {
    return error(401, "Invalid or expired session");
  }

  // Parse and validate the request body
  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch {
    return error(400, "Invalid JSON body");
  }

  const message = (body.message || "").trim();
  if (!message) {
    return error(400, "Message is required");
  }
  if (message.length > MAX_MESSAGE_LENGTH) {
    return error(400, `Message must be ${MAX_MESSAGE_LENGTH} characters or fewer`);
  }

  // Write the entry
  const entry = {
    entryId: randomUUID(),
    login: user.login,
    avatarUrl: user.avatar_url,
    message,
    createdAt: new Date().toISOString(),
  };

  await putEntry(entry);

  return json(201, { entry });
}

// ────────────────────────────────────────────
// DELETE /guestbook/{entryId} — auth required, own entries only
// ────────────────────────────────────────────
export async function remove(event) {
  // Verify authentication
  const token = getSessionCookie(event);
  if (!token) {
    return error(401, "You must be logged in to delete an entry");
  }

  const { jwtSigningKey } = await getSecrets();
  const user = verifyToken(token, jwtSigningKey);
  if (!user) {
    return error(401, "Invalid or expired session");
  }

  // Extract entryId from path parameters
  const entryId = event.pathParameters?.entryId;
  if (!entryId) {
    return error(400, "Entry ID is required");
  }

  // Fetch the entry to verify ownership
  const entry = await getEntry(entryId);
  if (!entry) {
    return error(404, "Entry not found");
  }

  if (entry.login !== user.login) {
    return error(403, "You can only delete your own entries");
  }

  await deleteEntry(entryId);

  return json(200, { ok: true });
}
