---
date: 2026-09-08
scope: upstream
area: process
severity: high
submitted: https://github.com/steffenmaas/founder-os/pull/34
---

# Container-Neustart unter Last — vier Builder, 48 Chromium-Prozesse, Last 15 auf 4 Kernen

**Was passiert ist.** Um ~17:45 UTC wurde der Session-Prozess in der Cloud-VM neu gestartet, während vier Builder
liefen (Club G, Begehen-Fix, Blender Stufe 3b, Studio 1c). Alle vier waren tot, ihre Denkarbeit (je 20–60 Minuten,
je ~0,5–1,5 M frische Eingabe-Tokens) verloren; nur die Dateien im Arbeitsbaum überlebten. `uptime` zeigte 13 h — die
VM selbst blieb, nur der Prozess starb. Kein Leerlauf-Ablauf (der Gründer hatte Minuten vorher geschrieben, und ein
Ablauf bringt eine frische VM ohne uncommittete Dateien).

**Warum.** Die VM hat 4 vCPUs, 16 GB RAM, 30 GB Disk (code.claude.com/docs/en/cloud-environments, „Resource
limits"; „the VM may stop tasks that need significantly more memory"). Drei Builder fuhren Headless-Chromium (je 6–10
Prozesse), einer Blender; Last 15 auf 4 Kernen.

**Was wir jetzt tun.**
1. `bash tools/ops/resources.sh` **vor jedem Dispatch** — GO/WAIT aus Last (< 6), Chromium-Prozessen (< 24), Blender
   (≤ 1), Speicher (≥ 4 GB), Platte (≥ 3 GB). Bei WAIT wartet der Orchestrator, statt zu starten.
2. **Höchstens drei Builder gleichzeitig**, davon höchstens einer mit Blender und höchstens zwei mit Headless-Browser.
3. Builder committen **Zwischenstände** (ein Commit je Schritt, wie der T029-Builder: Bug-Fix, 1b, 1c einzeln) — ein
   Neustart kostet dann höchstens den laufenden Schritt.
4. `node tools/ops/token-report.mjs` zeigt je Agent Ausgabe, frische Eingabe, Cache-Lesen, Minuten. Die Zahl je Paket
   wandert in die Release-Notiz (`Kosten:`-Zeile) — Roadmap-Zeilen tragen sie ab jetzt beim Abschluss.

**Was die Zahlen sagen (Sitzung 2026-09-08 bis 18:05 UTC).** Roh 3,4 Mrd. Tokens, davon 3,37 Mrd. Cache-Lesen, 50 M
frische Eingabe, 4,2 M Ausgabe. **Der Orchestrator selbst ist der größte Posten:** 2,7 M Ausgabe und 927 M Cache-Lesen
in 2.232 Modellaufrufen — sein Kontext liegt bei ~350 k Tokens, und jeder Aufruf liest ihn neu. Jede Stop-Hook-Meldung
(„uncommitted changes") und jede Deploy-Prüfung ist so ein Aufruf. Sub-Agenten kosten je 0,9–3,8 M frische Eingabe
und 25–95 k Ausgabe; die teuersten waren Blender Stufe 0–2 (3,8 M) und B001 (3,8 M, 605 Aufrufe).

**Hebel gegen die Kosten.** (a) Orchestrator-Turns sparen: Stop-Hook `~/.claude/stop-hook-git-check.sh` für die
Orchestrator-Sitzung abschalten oder auf eigene Dateien beschränken — jede Meldung kostet einen 350-k-Aufruf;
(b) Benachrichtigungen bündeln (Deploy-Prüfung nur einmal je Merge-Welle); (c) Orchestrator-Kontext klein halten —
Sitzung nach jedem Versionsschnitt neu beginnen (Übergabeblatt statt Gedächtnis), wie `CLAUDE.md` es vorsieht;
(d) Builder mit engem Auftrag und klarer Prüfung brauchen 150–400 k, offene Aufträge (B001) das Zehnfache.

**Umgesetzt (Gründer 2026-09-08, 18:40 UTC: „alle Token-Empfehlungen umsetzen"):**
- Stop-Hook `~/.claude/stop-hook-git-check.sh` in dieser Sitzung abgeschaltet (Original als `.orig`); er ist
  Harness-seitig (Cloud-Session), nicht im Repo — die dauerhafte Fassung ist die Regel upstream (unten).
- `CLAUDE.md` → Arbeitsweise: Merge-Wellen (ein PR, eine Deploy-Prüfung je Welle fertiger Builder), enge Aufträge
  (ein Inkrement, benannte Prüfung, Richtwert ≤ 400 k frische Eingabe — größer wird geteilt), Builder in eigenem
  Worktree ab dem nächsten Dispatch (kein geteilter Index, kein Hook-Lärm), neue Orchestrator-Sitzung nach jedem
  Versionsschnitt aus dem Übergabeblatt.

## Generalisable?

**Ja — jedes Projekt, das mehrere Agenten in einer Cloud-VM orchestriert, läuft in dieselben drei Fallen:** (1) die
VM stoppt den Session-Prozess unter Last, und alle laufenden Sub-Agenten sind weg; (2) der Orchestrator ist der
teuerste Prozess, weil sein Kontext bei jedem Aufruf neu gelesen wird und Hooks/Benachrichtigungen Aufrufe erzeugen;
(3) niemand misst Tokens je Agent, also kann niemand Aufträge nach Kosten schneiden.

**Regel 1 — Blueprint § 3.4 BUILD (Abschnitt „Geteilter Arbeitsraum", Ergänzung):**

> **Ressourcen vor dem Dispatch.** Ein Orchestrator startet einen Agenten erst, wenn eine Ressourcen-Wache GO
> sagt (Last, Speicher, Platte, schwere Prozesse wie Headless-Browser und Renderer). Richtwerte für eine 4-Kern-VM:
> Last < 1,5 × Kerne, höchstens drei Builder, höchstens einer davon mit Renderer, höchstens zwei mit Headless-Browser.
> Jeder Builder committet **jeden Schritt einzeln** — ein Neustart der Sitzung kostet dann nur den laufenden Schritt,
> nicht die Denkarbeit einer halben Stunde. Ein Agent, der gestorben ist, wird mit „weitermachen aus dem Arbeitsbaum"
> neu gestartet, nie von vorn.

**Regel 2 — Blueprint § 7 (Kosten) und § 10 (Kontexthygiene):**

> **Der Orchestrator ist der teuerste Prozess.** Sein Kontext wird bei jedem Aufruf neu gelesen; jeder Hook, jede
> Benachrichtigung, jede Deploy-Prüfung ist ein Aufruf. Darum: Hooks, die auf fremde uncommittete Dateien reagieren,
> sind in Orchestrator-Sitzungen aus (Builder halten ihre Arbeit im Baum); Merges laufen in **Wellen** (ein PR,
> eine Deploy-Prüfung je Welle fertiger Agenten, nicht je Agent); nach jedem Versionsschnitt beginnt eine **neue
> Orchestrator-Sitzung** aus dem Übergabeblatt statt der mitgewachsenen. Sub-Agenten laufen in eigenen Worktrees,
> damit der Hauptbaum sauber bleibt und kein Index geteilt wird.

**Regel 3 — Workflow `version-cut.md` und Contract `orchestrator-agent.md`:**

> **Tokens werden gemessen, nicht geschätzt.** Die Transkripte tragen je Modellantwort `usage` (Eingabe,
> Cache-Anlage, Cache-Lesen, Ausgabe). Ein Bericht je Agent und Lauf (`tools/ops/token-report.mjs` als Vorlage)
> gehört zum Versionsschnitt; jede Release-Notiz trägt je Paket eine `Kosten:`-Zeile (frische Eingabe + Ausgabe).
> Aufträge sind so geschnitten, dass ein Builder mit einem Inkrement und einer benannten Prüfung auskommt —
> Richtwert 150–400 k frische Eingabe; ein Auftrag, der das Zehnfache braucht, war zu offen.

**Ebene:** Blueprint (Regeln 1–2, Verletzung kostet Arbeit und Geld, aber zerstört nichts Fremdes), Workflow +
Contract (Regel 3), Vorlage `templates/project/tools/ops/` für Wache und Bericht. Kein Hook: die Wache ist ein
Werkzeug, das der Orchestrator aufruft, kein Verbot.

**Kosten der Regeln:** weniger Parallelität (drei statt vier bis fünf Builder), also längere Wanduhrzeit je Welle;
ein Worktree je Builder kostet Platz und Setup (node_modules verlinken); Merge-Wellen verzögern das Live-Gehen
einzelner Ergebnisse um Minuten.
