/**
 * Sync.md — Legacy Purchase Verifier
 *
 * POST /verify-legacy
 *   Body:    { "receipt": "<base64-encoded App Store receipt>" }
 *   Returns: { "isLegacy": true | false, "originalPurchaseDate": "ISO-8601",
 *              "originalVersion": "..." }
 *   Verifies via Apple's verifyReceipt endpoint (requires on-disk receipt file).
 *
 * POST /verify-legacy-jws
 *   Body:    { "jws": "<AppTransaction JWS from StoreKit 2>" }
 *   Returns: { "isLegacy": true | false, "originalPurchaseDate": "ISO-8601",
 *              "originalVersion": "..." }
 *   Decodes the Apple-signed AppTransaction JWS and classifies legacy by
 *   `originalPurchaseDate` against `FREEMIUM_CUTOFF_MS`. Works on TestFlight +
 *   App Store (no receipt file needed).
 *
 * The iOS app caches a successful `isLegacy: true` response in the Keychain
 * so either endpoint is only ever called once per device.
 */

interface Env {
  /** Shared secret from App Store Connect → In-App Purchases → App-Specific Shared Secret.
   *  Required for subscription receipt verification; optional for paid-app receipts,
   *  but should always be set so the worker is ready if subscriptions are added later. */
  APPLE_SHARED_SECRET?: string;
  /** Set to "true" in wrangler.toml temporarily to force isLegacy: true for any valid
   *  receipt. Used to test the full iOS unlock flow without a real legacy receipt.
   *  NEVER ship with this enabled. */
  DEBUG_FORCE_LEGACY?: string;
}

interface AppleVerifyReceiptResponse {
  /** 0 = success. See Apple docs for other status codes. */
  status: number;
  receipt?: {
    bundle_id: string;
    /** CFBundleVersion (build number) on iOS, CFBundleShortVersionString on macOS.
     *  Retained in the response shape for diagnostics; legacy classification uses
     *  `original_purchase_date_ms` instead — see comment on FREEMIUM_CUTOFF_MS. */
    original_application_version: string;
    /** Original purchase date as a string of milliseconds since 1970-01-01T00:00:00Z. */
    original_purchase_date_ms?: string;
  };
  /** Returned when status === 21007 — receipt is from the sandbox environment. */
  environment?: string;
}

const BUNDLE_ID = "bontecou.Sync-md";

/** Cutoff just past the App Store release of v1.7 (the first free build).
 *
 *  An `originalPurchaseDate` strictly before this milestone means the user first
 *  installed v1.5 or v1.6 — both paid releases — and qualifies for a legacy unlock.
 *
 *  We use the purchase date instead of the build-number string because the latter
 *  is `CFBundleVersion`, which can be reset (e.g. back to "1") in a future release.
 *  That would silently classify every fresh install as legacy. The purchase date is
 *  Apple-signed and immutable.
 *
 *  2026-04-01 00:00 UTC is biased toward generosity for paid customers: the v1.7
 *  build was created 2026-03-29 10:00 UTC and went live a day or two later, so
 *  this cutoff captures every v1.6 buyer (last paid build was 2026-03-26 09:33 UTC).
 *  Trade-off: anyone who installed free v1.7 in the window between Apple approval
 *  and 2026-04-01 also gets unlocked. */
const FREEMIUM_CUTOFF_MS = Date.UTC(2026, 3, 1, 0, 0, 0); // April = month 3 (0-indexed)

const APPLE_PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_SANDBOX_URL    = "https://sandbox.itunes.apple.com/verifyReceipt";

// ---------------------------------------------------------------------------
// JWS / JWT helpers
// ---------------------------------------------------------------------------

/** Decodes a base64url string (no padding) to a UTF-8 string. */
function base64urlDecode(input: string): string {
  let b64 = input.replace(/-/g, "+").replace(/_/g, "/");
  while (b64.length % 4 !== 0) b64 += "=";
  return atob(b64);
}

/**
 * Decodes an Apple AppTransaction JWS (compact serialization: header.payload.signature).
 * Returns the parsed payload or null if the structure is invalid.
 */
function decodeAppTransactionJWS(jws: string): AppTransactionPayload | null {
  const parts = jws.split(".");
  if (parts.length !== 3) return null;
  try {
    const payload = JSON.parse(base64urlDecode(parts[1])) as AppTransactionPayload;
    if (!payload.bundleId || typeof payload.originalPurchaseDate !== "number") return null;
    return payload;
  } catch {
    return null;
  }
}

interface AppTransactionPayload {
  bundleId: string;
  /** Apple uses "originalApplicationVersion" in the JWS payload, even though
   *  StoreKit 2's Swift API exposes it as `originalAppVersion`. Retained for
   *  diagnostics; legacy classification uses `originalPurchaseDate` instead. */
  originalApplicationVersion?: string;
  /** Milliseconds since 1970-01-01T00:00:00Z. Apple-signed and immutable. */
  originalPurchaseDate: number;
  applicationVersion?: string;
  environment?: string;
  [key: string]: unknown;
}

async function verifyWithApple(
  receiptData: string,
  sharedSecret: string | undefined,
  url: string
): Promise<AppleVerifyReceiptResponse> {
  const body: Record<string, string | boolean> = {
    "receipt-data": receiptData,
    "exclude-old-transactions": false,
  };
  if (sharedSecret) {
    body.password = sharedSecret;
  }

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  return response.json() as Promise<AppleVerifyReceiptResponse>;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const { method, url } = request;
    const { pathname } = new URL(url);

    if (pathname === "/health" && method === "GET") {
      return jsonResponse({ ok: true });
    }

    if (method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    // -----------------------------------------------------------------------
    // POST /verify-legacy-jws — StoreKit 2 AppTransaction JWS
    // -----------------------------------------------------------------------
    if (pathname === "/verify-legacy-jws") {
      let body: { jws?: string };
      try {
        body = await request.json() as { jws?: string };
      } catch {
        return jsonResponse({ error: "Invalid JSON body" }, 400);
      }

      if (!body.jws || typeof body.jws !== "string") {
        return jsonResponse({ error: "Missing or invalid 'jws' field" }, 400);
      }

      const payload = decodeAppTransactionJWS(body.jws);
      if (!payload) {
        return jsonResponse({ error: "Invalid JWS structure" }, 400);
      }

      if (payload.bundleId !== BUNDLE_ID) {
        return jsonResponse({ error: "Bundle ID mismatch" }, 400);
      }

      const originalPurchaseDateMs = payload.originalPurchaseDate;
      const isLegacy = env.DEBUG_FORCE_LEGACY === "true"
        ? true
        : originalPurchaseDateMs < FREEMIUM_CUTOFF_MS;

      return jsonResponse({
        isLegacy,
        originalPurchaseDate: new Date(originalPurchaseDateMs).toISOString(),
        originalVersion: payload.originalApplicationVersion,
      });
    }

    // -----------------------------------------------------------------------
    // POST /verify-legacy — Legacy receipt file → Apple verifyReceipt
    // -----------------------------------------------------------------------
    if (pathname !== "/verify-legacy") {
      return jsonResponse({ error: "Not found" }, 404);
    }

    let body: { receipt?: string };
    try {
      body = await request.json() as { receipt?: string };
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    if (!body.receipt || typeof body.receipt !== "string") {
      return jsonResponse({ error: "Missing or invalid 'receipt' field" }, 400);
    }

    let result = await verifyWithApple(body.receipt, env.APPLE_SHARED_SECRET, APPLE_PRODUCTION_URL);

    if (result.status === 21007) {
      result = await verifyWithApple(body.receipt, env.APPLE_SHARED_SECRET, APPLE_SANDBOX_URL);
    }

    if (result.status !== 0) {
      return jsonResponse(
        { error: "Apple receipt verification failed", appleStatus: result.status },
        400
      );
    }

    if (!result.receipt) {
      return jsonResponse({ error: "No receipt data in Apple response" }, 400);
    }

    if (result.receipt.bundle_id !== BUNDLE_ID) {
      return jsonResponse({ error: "Bundle ID mismatch" }, 400);
    }

    if (!result.receipt.original_purchase_date_ms) {
      return jsonResponse({ error: "Missing original_purchase_date_ms in receipt" }, 400);
    }

    const originalPurchaseDateMs = parseInt(result.receipt.original_purchase_date_ms, 10);
    if (!Number.isFinite(originalPurchaseDateMs)) {
      return jsonResponse({ error: "Malformed original_purchase_date_ms" }, 400);
    }

    const isLegacy = env.DEBUG_FORCE_LEGACY === "true"
      ? true
      : originalPurchaseDateMs < FREEMIUM_CUTOFF_MS;

    return jsonResponse({
      isLegacy,
      originalPurchaseDate: new Date(originalPurchaseDateMs).toISOString(),
      originalVersion: result.receipt.original_application_version,
    });
  },
};
