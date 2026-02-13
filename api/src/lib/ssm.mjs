/**
 * Batch-load SSM parameters with in-memory caching.
 *
 * Why cache? Lambda containers are reused across invocations (warm starts).
 * Secrets rarely change, so we cache for 5 minutes to avoid hitting SSM
 * on every request. This saves latency (~50ms per SSM call) and cost
 * (SSM GetParameters is free but has a 40 TPS limit per account/region).
 */
import { SSMClient, GetParametersCommand } from "@aws-sdk/client-ssm";

const ssm = new SSMClient();

let cache = null;
let cacheExpiry = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Loads all guestbook secrets from SSM Parameter Store.
 * Returns { githubClientId, githubClientSecret, jwtSigningKey }.
 */
export async function getSecrets() {
  if (cache && Date.now() < cacheExpiry) {
    return cache;
  }

  const { Parameters } = await ssm.send(
    new GetParametersCommand({
      Names: [
        process.env.SSM_GITHUB_CLIENT_ID,
        process.env.SSM_GITHUB_CLIENT_SECRET,
        process.env.SSM_JWT_SIGNING_KEY,
      ],
      WithDecryption: true, // Required for SecureString parameters
    })
  );

  // Build a name→value map so we don't depend on response ordering
  const byName = Object.fromEntries(Parameters.map((p) => [p.Name, p.Value]));

  cache = {
    githubClientId: byName[process.env.SSM_GITHUB_CLIENT_ID],
    githubClientSecret: byName[process.env.SSM_GITHUB_CLIENT_SECRET],
    jwtSigningKey: byName[process.env.SSM_JWT_SIGNING_KEY],
  };
  cacheExpiry = Date.now() + CACHE_TTL_MS;

  return cache;
}
