export interface Structured {
  title: string; cleaned_text: string; summary: string; kind: string;
  tags: string[]; action_items: string[]; open_questions: string[]; uncertain: boolean;
}
const KINDS = new Set(["idea", "task", "question", "reminder", "quote", "journal"]);
export const MAX_TRANSCRIPT_CHARS = 20_000;

export function extractJSON(text: string): string | null {
  let s = text;
  const end = s.indexOf("</think>");
  if (end >= 0) s = s.slice(end + 8);
  const start = s.indexOf("{");
  if (start < 0) return null;
  let depth = 0, inStr = false, esc = false;
  for (let i = start; i < s.length; i++) {
    const c = s[i];
    if (inStr) { if (esc) esc = false; else if (c === "\\") esc = true; else if (c === '"') inStr = false; }
    else if (c === '"') inStr = true;
    else if (c === "{") depth++;
    else if (c === "}" && --depth === 0) return s.slice(start, i + 1);
  }
  return null;
}

export function validateStructured(raw: string): Structured | null {
  const json = extractJSON(raw);
  if (!json) return null;
  let v: any;
  try { v = JSON.parse(json); } catch { return null; }
  const strs = (a: unknown) => Array.isArray(a) && a.every((x) => typeof x === "string");
  if (typeof v.title !== "string" || !v.title.trim() || typeof v.cleaned_text !== "string" || !v.cleaned_text.trim()) return null;
  if (typeof v.summary !== "string" || !KINDS.has(v.kind) || !strs(v.tags) || !strs(v.action_items)) return null;
  return {
    title: v.title, cleaned_text: v.cleaned_text, summary: v.summary, kind: v.kind,
    tags: v.tags.slice(0, 3), action_items: v.action_items,
    open_questions: strs(v.open_questions) ? v.open_questions : [], uncertain: v.uncertain === true,
  };
}

export function parseRequest(body: unknown): { transcript: string; script: "simplified" | "traditional" } | null {
  if (typeof body !== "object" || body === null) return null;
  const b = body as Record<string, unknown>;
  if (typeof b.transcript !== "string" || !b.transcript.trim() || b.transcript.length > MAX_TRANSCRIPT_CHARS) return null;
  const script = b.script === "traditional" ? "traditional" : "simplified";
  return { transcript: b.transcript, script };
}
