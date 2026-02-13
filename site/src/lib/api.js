/**
 * Fetch wrapper for the guestbook API.
 *
 * credentials: "include" is critical — it tells the browser to send
 * the httpOnly cookie cross-origin (forfun.gillzhub.com → api.forfun.gillzhub.com).
 * Without it, the session cookie won't be included in requests.
 */
const API_BASE = import.meta.env.VITE_API_URL || "https://api.forfun.gillzhub.com";

export async function apiFetch(path, options = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    ...options,
  });

  // For non-JSON responses (redirects handled by browser automatically)
  const contentType = res.headers.get("content-type");
  if (!contentType || !contentType.includes("application/json")) {
    if (!res.ok) throw new Error(`API error: ${res.status}`);
    return null;
  }

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error || `API error: ${res.status}`);
  }
  return data;
}

export function getLoginUrl() {
  return `${API_BASE}/auth/login`;
}
