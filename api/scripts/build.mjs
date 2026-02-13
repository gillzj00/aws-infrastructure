/**
 * Package the Lambda function as a ZIP for deployment.
 *
 * What it does:
 * 1. Copies src/ and node_modules/ into a temp staging directory
 * 2. ZIPs the staging directory into api/dist/guestbook-api.zip
 *
 * Why a custom script instead of `zip -r`?
 *   Cross-platform (Windows/macOS/Linux) and we can control exactly
 *   what goes into the archive — no accidental .env or test files.
 */
import { execSync } from "node:child_process";
import { mkdirSync, cpSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const dist = join(root, "dist");
const stage = join(dist, "stage");

// Clean previous build
rmSync(dist, { recursive: true, force: true });
mkdirSync(stage, { recursive: true });

// Copy source and production dependencies
cpSync(join(root, "src"), join(stage, "src"), { recursive: true });
cpSync(join(root, "node_modules"), join(stage, "node_modules"), {
  recursive: true,
});

// Create ZIP — cd into stage so paths inside the ZIP are relative
execSync(`cd "${stage}" && zip -qr "${join(dist, "guestbook-api.zip")}" .`);

// Clean up staging directory
rmSync(stage, { recursive: true, force: true });

console.log("Built dist/guestbook-api.zip");
