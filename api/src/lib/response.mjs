/**
 * Response helpers for API Gateway HTTP API (payload format 2.0).
 *
 * API Gateway v2 expects { statusCode, headers, body } responses.
 * These helpers ensure consistent JSON formatting and CORS headers.
 */

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": process.env.FRONTEND_URL,
  "Access-Control-Allow-Credentials": "true",
};

export function json(statusCode, data) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    body: JSON.stringify(data),
  };
}

export function redirect(url, cookies = []) {
  return {
    statusCode: 302,
    headers: { Location: url, ...CORS_HEADERS },
    // API Gateway v2 uses the top-level "cookies" array (not Set-Cookie header)
    ...(cookies.length > 0 && { cookies }),
  };
}

export function error(statusCode, message) {
  return json(statusCode, { error: message });
}
