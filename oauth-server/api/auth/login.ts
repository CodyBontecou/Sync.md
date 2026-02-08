import type { VercelRequest, VercelResponse } from "@vercel/node";

export default function handler(req: VercelRequest, res: VercelResponse) {
  const clientId = process.env.GITHUB_CLIENT_ID;
  if (!clientId) {
    return res.status(500).json({ error: "GITHUB_CLIENT_ID not configured" });
  }

  const state =
    (req.query?.state as string) ||
    Math.random().toString(36).slice(2) + Date.now().toString(36);

  const proto = req.headers["x-forwarded-proto"] || "https";
  const host = req.headers["x-forwarded-host"] || req.headers.host;
  const baseURL = `${proto}://${host}`;

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: `${baseURL}/api/auth/callback`,
    scope: "repo",
    state,
  });

  res.redirect(302, `https://github.com/login/oauth/authorize?${params}`);
}
