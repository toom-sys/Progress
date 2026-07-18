const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

const OPENAI_CHAT_COMPLETIONS_URL = "https://api.openai.com/v1/chat/completions";
const ALLOWED_MODELS = new Set(["gpt-5.4-nano"]);
const MAX_COMPLETION_TOKENS_CAP = 4000;
const DAILY_REQUEST_LIMIT_PER_USER = 150;

/**
 * Authenticated proxy for OpenAI chat completions.
 *
 * The app sends its normal chat-completions body here with a Firebase ID
 * token (anonymous auth is fine) instead of an OpenAI key. The OpenAI key
 * lives only in Secret Manager. Requests are validated against a model
 * allowlist, capped on token spend, and rate-limited per user per day.
 */
exports.aiProxy = onRequest(
  {
    region: "europe-west2",
    secrets: [openaiApiKey],
    timeoutSeconds: 120,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: { message: "POST only" } });
      return;
    }

    // --- Authentication ---------------------------------------------------
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!idToken) {
      res.status(401).json({ error: { message: "Missing bearer token" } });
      return;
    }

    let uid;
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      uid = decoded.uid;
    } catch (error) {
      console.warn("Rejected invalid ID token:", error.message);
      res.status(401).json({ error: { message: "Invalid or expired token" } });
      return;
    }

    // --- Request validation -----------------------------------------------
    const body = req.body;
    if (!body || typeof body !== "object") {
      res.status(400).json({ error: { message: "Invalid JSON body" } });
      return;
    }
    if (!ALLOWED_MODELS.has(body.model)) {
      res.status(400).json({ error: { message: `Model not allowed: ${body.model}` } });
      return;
    }
    if (!Array.isArray(body.messages) || body.messages.length === 0) {
      res.status(400).json({ error: { message: "messages must be a non-empty array" } });
      return;
    }
    if (body.stream) {
      res.status(400).json({ error: { message: "Streaming is not supported" } });
      return;
    }

    const requestedTokens = Number(body.max_completion_tokens) || MAX_COMPLETION_TOKENS_CAP;
    body.max_completion_tokens = Math.min(requestedTokens, MAX_COMPLETION_TOKENS_CAP);

    // --- Per-user daily rate limit ------------------------------------------
    // Fails open if Firestore is unavailable so a config problem can't take
    // AI features down; auth above is the primary gate.
    try {
      const day = new Date().toISOString().slice(0, 10);
      const usageRef = admin.firestore().collection("aiUsage").doc(`${uid}_${day}`);
      const allowed = await admin.firestore().runTransaction(async (tx) => {
        const snapshot = await tx.get(usageRef);
        const count = snapshot.exists ? snapshot.data().count : 0;
        if (count >= DAILY_REQUEST_LIMIT_PER_USER) {
          return false;
        }
        tx.set(usageRef, { count: count + 1, updatedAt: new Date() }, { merge: true });
        return true;
      });
      if (!allowed) {
        res.status(429).json({ error: { message: "Daily AI request limit reached" } });
        return;
      }
    } catch (error) {
      console.warn("Rate limit check skipped:", error.message);
    }

    // --- Forward to OpenAI --------------------------------------------------
    try {
      const openaiResponse = await fetch(OPENAI_CHAT_COMPLETIONS_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openaiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      });

      const responseBody = await openaiResponse.text();
      res
        .status(openaiResponse.status)
        .set("Content-Type", "application/json")
        .send(responseBody);
    } catch (error) {
      console.error("OpenAI request failed:", error);
      res.status(502).json({ error: { message: "Upstream request failed" } });
    }
  }
);
