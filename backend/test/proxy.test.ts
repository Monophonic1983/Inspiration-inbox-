import test from "node:test";
import assert from "node:assert/strict";
import { handle } from "../src/index";
import { validateStructured, parseRequest } from "../src/validate";

const env = { ANTHROPIC_API_KEY: "k", ANTHROPIC_MODEL: "m" };
const allow = { verify: async () => true };
const deny = { verify: async () => false };
const good = '{"title":"T","cleaned_text":"C","summary":"S","kind":"idea","tags":["a","b","c","d"],"action_items":[],"open_questions":[],"uncertain":false}';
const req = (body: unknown) => new Request("https://x/structure", { method: "POST", body: JSON.stringify(body) });

test("refuses without a valid attestation and never calls upstream", async () => {
  let calls = 0;
  const res = await handle(req({ transcript: "hi" }), env, deny, (async () => { calls++; return new Response("{}"); }) as any);
  assert.equal(res.status, 401);
  assert.equal(calls, 0);
});

test("rejects empty and oversized transcripts", async () => {
  assert.equal(parseRequest({ transcript: " " }), null);
  assert.equal(parseRequest({ transcript: "x".repeat(20_001) }), null);
  assert.equal((await handle(req({ transcript: "" }), env, allow)).status, 400);
});

test("returns validated, tag-trimmed JSON from the model", async () => {
  const fetcher = (async () => new Response(JSON.stringify({ content: [{ type: "text", text: "```json\n" + good + "\n```" }] }))) as any;
  const res = await handle(req({ transcript: "hi", script: "traditional" }), env, allow, fetcher);
  assert.equal(res.status, 200);
  assert.equal(((await res.json()) as any).tags.length, 3);
});

test("invalid model output is a 502, not passed through", async () => {
  const fetcher = (async () => new Response(JSON.stringify({ content: [{ type: "text", text: "sorry" }] }))) as any;
  assert.equal((await handle(req({ transcript: "hi" }), env, allow, fetcher)).status, 502);
  assert.equal(validateStructured('{"title":"","cleaned_text":"x"}'), null);
});

test("only POST /structure exists", async () => {
  assert.equal((await handle(new Request("https://x/other"), env, allow)).status, 404);
});
