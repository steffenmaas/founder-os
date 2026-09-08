#!/usr/bin/env node
// Token-Bericht je Agent und Lauf aus den Sitzungs-Transkripten (Gründer 2026-09-08, 18:05 UTC:
// „hast du Zugriff auf die Token Usage? wie viel hat ein Agent und ein Lauf gebraucht?").
// Quelle: ~/.claude/projects/<repo>/<session>.jsonl (Orchestrator) und …/<session>/subagents/agent-*.jsonl
// (jeder Sub-Agent). Jede Assistenten-Nachricht trägt `usage` mit input_tokens, cache_creation_input_tokens,
// cache_read_input_tokens, output_tokens. Was das Konto belastet, ist bei Anthropic gewichtet (Cache-Lesen
// billiger als frische Eingabe); hier stehen die Rohzahlen, damit man Läufe vergleichen kann. Das Restguthaben
// des Kontos ist aus der Session nicht lesbar — das steht nur unter claude.ai → Settings → Usage.
//
//   node tools/ops/token-report.mjs                → Tabelle je Agent (Label = Anfang des Auftrags), Summe
//   node tools/ops/token-report.mjs --session <id> → andere Sitzung; --json → maschinenlesbar
//   node tools/ops/token-report.mjs --top 15       → nur die teuersten 15
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const json = args.includes('--json');
const top = Number(opt('--top', 0)) || 0;
const projDir = path.join(os.homedir(), '.claude', 'projects', '-' + process.cwd().replace(/\//g, '-').replace(/^-/, ''));
let session = opt('--session', null);
if (!session) {
  const files = fs.existsSync(projDir) ? fs.readdirSync(projDir).filter((f) => f.endsWith('.jsonl')) : [];
  files.sort((a, b) => fs.statSync(path.join(projDir, b)).mtimeMs - fs.statSync(path.join(projDir, a)).mtimeMs);
  session = files[0]?.replace(/\.jsonl$/, '');
}
if (!session) { console.error('kein Transkript gefunden unter ' + projDir); process.exit(2); }

function sumFile(file) {
  const t = { turns: 0, input: 0, cacheCreate: 0, cacheRead: 0, output: 0, thinking: 0, first: null, last: null, label: '' };
  const text = fs.readFileSync(file, 'utf8');
  for (const line of text.split('\n')) {
    if (!line) continue;
    let o; try { o = JSON.parse(line); } catch { continue; }
    const ts = o.timestamp ? Date.parse(o.timestamp) : null;
    if (ts) { t.first = t.first ?? ts; t.last = ts; }
    if (!t.label && o.type === 'user' && typeof o.message?.content === 'string') t.label = o.message.content.slice(0, 90).replace(/\s+/g, ' ');
    if (!t.label && o.type === 'user' && Array.isArray(o.message?.content)) { const c = o.message.content.find((x) => x.type === 'text'); if (c) t.label = c.text.slice(0, 90).replace(/\s+/g, ' '); }
    const u = o.message?.usage; if (!u) continue;
    t.turns++; t.input += u.input_tokens || 0; t.cacheCreate += u.cache_creation_input_tokens || 0;
    t.cacheRead += u.cache_read_input_tokens || 0; t.output += u.output_tokens || 0; t.thinking += u.output_tokens_details?.thinking_tokens || 0;
  }
  t.fresh = t.input + t.cacheCreate; t.total = t.fresh + t.cacheRead + t.output; t.minutes = t.first && t.last ? Math.round((t.last - t.first) / 60000) : 0;
  return t;
}
const rows = [];
const main = path.join(projDir, session + '.jsonl');
if (fs.existsSync(main)) rows.push({ id: 'orchestrator', ...sumFile(main), label: 'Orchestrator (Hauptsitzung)' });
const subDir = path.join(projDir, session, 'subagents');
if (fs.existsSync(subDir)) for (const f of fs.readdirSync(subDir).filter((f) => f.endsWith('.jsonl'))) rows.push({ id: f.replace(/^agent-|\.jsonl$/g, ''), ...sumFile(path.join(subDir, f)) });
rows.sort((a, b) => b.output + b.fresh - (a.output + a.fresh));
const shown = top ? rows.slice(0, top) : rows;
const sum = rows.reduce((s, r) => { for (const k of ['turns', 'input', 'cacheCreate', 'cacheRead', 'output', 'thinking', 'fresh', 'total']) s[k] = (s[k] || 0) + r[k]; return s; }, {});
if (json) { console.log(JSON.stringify({ session, agents: rows, sum })); process.exit(0); }
const k = (n) => (n >= 1e6 ? (n / 1e6).toFixed(2) + ' M' : n >= 1e3 ? Math.round(n / 1e3) + ' k' : String(n));
console.log(`Sitzung ${session} — ${rows.length} Transkripte (Orchestrator + Sub-Agenten)\n`);
console.log('Agent              Min  Turns   Ausgabe   frisch    Cache-Lesen  Label');
for (const r of shown) console.log(`${r.id.padEnd(18)} ${String(r.minutes).padStart(4)} ${String(r.turns).padStart(6)} ${k(r.output).padStart(9)} ${k(r.fresh).padStart(8)} ${k(r.cacheRead).padStart(12)}  ${r.label.slice(0, 70)}`);
console.log(`\nSumme: Ausgabe ${k(sum.output)} (davon Denken ${k(sum.thinking)}) · frische Eingabe ${k(sum.fresh)} · Cache-Lesen ${k(sum.cacheRead)} · roh gesamt ${k(sum.total)} · ${sum.turns} Modellaufrufe`);
console.log('Gewichtung fürs Konto: Ausgabe > frische Eingabe > Cache-Lesen (siehe claude.ai → Usage); Restguthaben ist hier nicht lesbar.');
