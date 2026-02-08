import type { VercelRequest, VercelResponse } from "@vercel/node";

// GitHub redirects here after the user authorizes.
// We exchange the temporary code for an access token using the client_secret
// (which is safe here on the server), then redirect to the iOS app via
// custom URL scheme: syncmd://auth?token=XXX&state=YYY

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const code = req.query.code as string | undefined;
  const state = req.query.state as string | undefined;

  if (!code) {
    return res.status(400).json({ error: "Missing authorization code" });
  }

  const clientId = process.env.GITHUB_CLIENT_ID;
  const clientSecret = process.env.GITHUB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    return res
      .status(500)
      .json({ error: "GitHub OAuth credentials not configured" });
  }

  try {
    // Exchange code for access token
    const tokenResponse = await fetch(
      "https://github.com/login/oauth/access_token",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          client_id: clientId,
          client_secret: clientSecret,
          code,
        }),
      }
    );

    const tokenData = (await tokenResponse.json()) as {
      access_token?: string;
      error?: string;
      error_description?: string;
    };

    if (tokenData.error) {
      return res.status(400).json({
        error: tokenData.error,
        description: tokenData.error_description,
      });
    }

    const accessToken = tokenData.access_token;

    if (!accessToken) {
      return res.status(500).json({ error: "No access token in response" });
    }

    // Redirect to the iOS app via custom URL scheme
    // ASWebAuthenticationSession will intercept this
    const params = new URLSearchParams({
      token: accessToken,
      ...(state ? { state } : {}),
    });

    res.redirect(302, `syncmd://auth?${params}`);
  } catch (error: any) {
    return res.status(500).json({
      error: "Token exchange failed",
      message: error.message,
    });
  }
}
