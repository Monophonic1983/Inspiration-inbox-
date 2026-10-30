import { systemPrompt } from "./prompt";
import { verifierFor, type AttestVerifier } from "./attest";
import { parseRequest, validateStructured } from "./validate";

export interface Env {
  ANTHROPIC_API_KEY: string;
  ANTHROPIC_MODEL: string;
  ATTEST_MODE?: string;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

export async function handle(request: Request, env: Env, verifier: AttestVerifier = verifierFor(env),
                             fetcher: typeof fetch = fetch): Promise<Response> {
  const url = new URL(request.url);
  if (request.method !== "POST" || url.pathname !== "/structure") return json({ error: "not_found" }, 404);

  const bodyText = await request.text();
  const keyId = request.headers.get("x-app-attest-key-id") ?? "";
  const assertion = request.headers.get("x-app-attest-assertion") ?? "";
  if (!(await verifier.verify(keyId, assertion, bodyText))) return json({ error: "attestation_failed" }, 401);

  let parsed;
  try { parsed = parseRequest(JSON.parse(bodyText)); } catch { parsed = null; }
  if (!parsed) return json({ error: "bad_request" }, 400);

  // The transcript is forwarded and never stored or logged.
  const upstream = await fetcher("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": env.ANTHROPIC_API_KEY, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: env.ANTHROPIC_MODEL,
      max_tokens: 1024,
      temperature: 0,
      system: systemPrompt(parsed.script),
      messages: [{ role: "user", content: `Transcript:\n${parsed.transcript}` }],
    }),
  });
  if (!upstream.ok) return json({ error: "upstream_failed" }, 502);
  const data = (await upstream.json()) as { content?: { type: string; text?: string }[] };
  const text = data.content?.filter((c) => c.type === "text").map((c) => c.text ?? "").join("") ?? "";
  const structured = validateStructured(text);
  return structured ? json(structured) : json({ error: "invalid_model_output" }, 502);
}

export default { fetch: (request: Request, env: Env) => handle(request, env) };
