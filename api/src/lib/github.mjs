/**
 * GitHub OAuth helpers.
 *
 * OAuth flow recap:
 * 1. User clicks "Login" → we redirect to GitHub's authorize URL
 * 2. User approves → GitHub redirects back to /auth/callback?code=xxx
 * 3. We exchange the code for an access token (server-to-server POST)
 * 4. We use the access token to fetch the user's GitHub profile
 * 5. We create a JWT from the profile and set it as a cookie
 *
 * This module handles steps 3 and 4. Steps 1, 2, 5 happen in auth.mjs.
 */

/**
 * Exchange an OAuth authorization code for an access token.
 * This is a server-to-server call — the client secret never reaches the browser.
 */
export async function exchangeCodeForToken(code, clientId, clientSecret) {
  const res = await fetch("https://github.com/login/oauth/access_token", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json", // GitHub returns form-encoded by default without this
    },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      code,
    }),
  });

  const data = await res.json();

  if (data.error) {
    throw new Error(`GitHub OAuth error: ${data.error_description || data.error}`);
  }

  return data.access_token;
}

/**
 * Fetch the authenticated user's GitHub profile.
 * Returns { id, login, avatar_url, name } — we only store id, login, avatar_url in the JWT.
 */
export async function getUser(accessToken) {
  const res = await fetch("https://api.github.com/user", {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/vnd.github+json",
    },
  });

  if (!res.ok) {
    throw new Error(`GitHub API error: ${res.status} ${res.statusText}`);
  }

  return res.json();
}
