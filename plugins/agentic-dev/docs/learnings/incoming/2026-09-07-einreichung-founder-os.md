---
date: 2026-09-07
scope: upstream
area: process
severity: high
submitted: https://github.com/steffenmaas/founder-os/pull/34
---

# Einreichung an Founder OS Modul 16 — PR-fertig, nach `dev-learn` Modus B

> Der Befund steht in `2026-09-07-parallele-agenten-und-der-schnelle-prototyp.md`. Dieses Blatt ist
> die **Einreichung** nach dem Verfahren der Skill `dev-learn --upstream`: Einwilligung, Sammeln,
> Gruppieren, Scrubben, Regeländerung, PR-Text.

## 0 · Einwilligung (Schritt 0 der Skill)

`preferences/project-config.json` **existiert in diesem Projekt nicht**, also auch kein
`learnings.contribute_upstream`. Die Skill sagt: fehlt der Eintrag, gilt `ask`, und das Onboarding
hat die Wahl nie festgehalten — das ist selbst ein Befund (siehe Gruppe 5b).

**Einwilligung liegt vor** durch die ausdrückliche Anweisung des Gründers am 2026-09-07:
*„Nutze Founder OS learn und reiche es als PR ein."* Sie gilt für **diesen Stapel**, nicht dauerhaft.
Wer den Eintrag nachträgt, macht daraus eine bewusste Einstellung statt einer Einzelfallzustimmung.

## 1 · Gesammelt

Eine Datei mit `scope: upstream` ohne `submitted:`:
`docs/learnings/2026-09-07-parallele-agenten-und-der-schnelle-prototyp.md`.

## 2 · Gruppiert — fünf Regeländerungen aus einer Sitzung

| # | Regel | Ebene | Vorfälle |
|---|---|---|---|
| 1 | Geteilter Arbeitsraum | Blueprint **+ Hook** | 3 (zweimal `pkill`, einmal Autostash) |
| 2 | Lieferstrecke gehört zum Inkrement | Blueprint (Definition of Done) | 1, teuer |
| 3 | Prüfstand gehört ins Repo | Blueprint | 1, beinahe-Totalverlust |
| 4 | Eskalationsleiter für fehlende Werkzeuge | Harness | 1 |
| 5 | **Modellwahl je Rolle ist Projektsache, nicht fest verdrahtet** | Blueprint + Projektvorlage | 1 (Experiment nicht durchführbar) |

Die Muster *Vertrag vor dem Spike*, *Messinstrument statt Einzelkorrektur* und
*Feedback-Übersetzung* gehen als drei Absätze in die Harness, ohne eigene Gruppe.

## 2b · Gescrubbt (das Modul-Repo ist öffentlich)

Geprüft nach Blueprint § 9.3:

- **Keine offene Sicherheitslücke** in diesem Stapel — es geht um Prozess, nicht um Code.
- **Keine Projektinterna:** kein Projektname eines Cloud-Anbieters, keine Kennungen, keine Schlüssel,
  keine Umsatz- oder Nutzerzahlen, keine unveröffentlichten Produktpläne. **Zurückgehalten wurde
  bewusst:** der Inhalt des Spiels (P18-Thema, Inhaltsentscheidungen), die Zielgruppe, jede
  Geschäftszahl und die Namen der Asset-Quellen. Für die Regeln ist nichts davon nötig — die
  Mechanismen (geteilter Baum, Lieferkanal, Prüfstand, Werkzeugausfall, Modellwahl) stehen ohne
  Kontext.
- **Steht allein:** jede der fünf Regeln ist ohne Kenntnis dieses Projekts verständlich.

Eine Formulierung wurde entschärft: das Zitat des Gründers über einen fremden Arbeitsstand nennt in
der Einreichung keine Person und kein Produkt.

## 3 · Die Regeländerungen

### Gruppe 1 — Blueprint: Abschnitt „Geteilter Arbeitsraum" · plus Hook

Neuer Abschnitt, einzufügen dort, wo der Blueprint von parallelen Agenten spricht:

> **Geteilter Arbeitsraum.** Teilen mehrere Agenten einen Container und einen Arbeitsbaum, gilt
> zusätzlich:
> 1. **Dateieigentum steht im Dispatch.** Jeder Auftrag nennt die Dateien, die der Agent besitzt,
>    und die, die er nicht anfassen darf. Ohne diesen Satz ist der Auftrag unvollständig.
> 2. **Zwei Agenten an derselben Datei laufen nacheinander** — als Fortsetzung desselben Agenten,
>    nicht als zweiter Dispatch.
> 3. **Nie Prozesse töten, die man nicht gestartet hat.** Kein `pkill`, kein `killall`. Eigene
>    Prozesse per PID.
> 4. **Kein `stash`, `add -A`, `reset --hard`, `checkout -- .`, `clean`.** Erst die eigene Datei
>    committen, dann ziehen — ein kollidierter `--autostash` bleibt stehen und blockiert **alle**.
> 5. **Ein abgestürzter Lauf unter Last ist „nicht gelaufen"** — weder grün noch rot. Bis zu drei
>    Wiederholungen unter `nice`; danach wird der Lauf als nicht durchgeführt berichtet.

**Hook** (`hooks/scripts/guard-bash.sh`): `pkill`/`killall` ohne PID sowie `git stash`,
`git add -A`, `git reset --hard`, `git checkout -- .` und `git clean` in einem Agenten-Kontext
blockieren, mit Verweis auf den Abschnitt. **Dazu ein Testfall je Muster in `tools/test_hooks.sh`** —
ein Hook ohne Test ist unvollständig.

*Warum Hook und nicht nur Blueprint:* die Regel wurde verletzt, obwohl sie in jedem Dispatch stand.
Die Verletzung zerstört fremde Arbeit — nach der Faustregel der Skill damit Hook-würdig.

### Gruppe 2 — Blueprint: Definition of Done

> **Die Lieferstrecke gehört zum Inkrement.** Prüft der Gründer durch einen Kanal (Artefakt,
> Vorschau, Testumgebung) und ist die Arbeit in diesem Kanal **nicht sichtbar**, ist das Inkrement
> **nicht fertig** — auch wenn der Code stimmt und alle Prüfungen grün sind. Stößt der Kanal an eine
> Grenze (Größe, Rechte, Reichweite), ist deren Behebung Teil des Inkrements, nicht seine
> Voraussetzung. Ein Agent, der erklärt, warum man die Arbeit nicht sieht, hat die Aufgabe nicht
> verstanden.

*Kosten der Regel:* Inkremente werden größer, weil der Kanal mitgedacht werden muss. Das ist
gewollt — der Kanal ist die einzige Stelle, an der ein Gründer prüfen kann.

### Gruppe 3 — Blueprint: wo eine Prüfung liegt

Der Blueprint sagt bereits: *existiert keine ausführbare Prüfung, ist es dein erster Schritt, eine zu
bauen.* Ein Satz fehlt:

> **Und sie liegt im Repository.** Prüfskripte, Fixturen und das Werkzeug, das die Lieferung baut,
> gehören versioniert ins Projekt, mit einem README, das je Skript sagt, **was es beweist**. Ein
> Prüfstand in einem Scratchpad ist kein Prüfstand: er verschwindet mit der Sitzung, und mit ihm die
> Fähigkeit, die Behauptung zu wiederholen.

*Kosten:* etwas mehr Aufräumarbeit je Sitzung.

### Gruppe 4 — Harness: Eskalationsleiter für fehlende Werkzeuge

> **Fehlendes Werkzeug ist selten eine Blockade.** Bevor „blockiert" berichtet wird:
> 1. das vorgesehene Werkzeug,
> 2. ein gleichwertiges,
> 3. das Grundmittel darunter — `git` statt einer Git-Oberfläche, `curl` statt eines Konnektors,
>    die Shell statt eines Werkzeugs.
>
> „Blockiert" ist erst wahr, wenn alle drei Stufen leer sind. **Ausnahme, die keine ist:** eine
> Berechtigungsgrenze wird nicht umgangen, auch wenn der Transport darunter offen steht. Der
> Unterschied zwischen *fehlendem Werkzeug* und *fehlender Erlaubnis* ist die ganze Regel.

*Vorfall:* nach einem Neustart fehlten die Werkzeuge einer Weboberfläche; ein Merge wurde als
blockiert gemeldet. Er war es nicht — ein Merge ist eine Git-Operation. Im selben Zug wurde eine
Repository-Freigabe **nicht** umgangen, obwohl der Transport funktioniert hätte: beide Hälften der
Regel stammen aus derselben Sitzung.

### Gruppe 5 — Blueprint + Projektvorlage: Modellwahl ist Projektsache

**Anforderung des Gründers, 2026-09-07:** *„Nimm die Anforderung mit auf, dass du das Modell
festlegen kannst. Das sollte nicht fest verdrahtet sein."*

**Heutiger Zustand:** die Rollendefinitionen der Laufzeit (`.claude/agents/*.md`, verwaltet) setzen
`builder`, `verifier`, `reviewer`, `planner` und `security-auditor` fest auf ein Modell und
`orchestrator` auf `inherit`. Diese Dateien darf ein Projekt nicht ändern (harte Verletzung
„`.founder-os/` und die verwalteten `.claude/`-Pfade nie lokal editieren"), und das Agent-Werkzeug
nimmt beim Dispatch **keinen** Modellparameter.

**Folge:** ein Projekt kann weder eine Rolle hochstufen, wenn sie erkennbar an eine Grenze stößt,
noch herunterstufen, wenn ein Modell für die Aufgabe überdimensioniert ist — **noch überhaupt
messen, ob die Wahl stimmt.** Das ist die eigentliche Schwere: die Voreinstellung mag gut sein, aber
sie ist unwiderlegbar, und eine unwiderlegbare Voreinstellung ist im Modul ein Fremdkörper.

Vorgeschlagene Regel:

> **Modelle sind eine Voreinstellung, keine Verdrahtung.** Das Modul empfiehlt je Rolle ein Modell;
> das Projekt darf es überschreiben, ohne eine verwaltete Datei anzufassen. Wer überschreibt, hält
> in einer Zeile fest, warum — die Begründung, nicht die Erlaubnis, ist der Wert.

Mechanismus (Projektvorlage, `preferences/project-config.json`):

```jsonc
{
  "agents": {
    // Rolle → Modell. Fehlt ein Eintrag, gilt die Empfehlung des Moduls.
    // Eine Zeile Begründung je Abweichung, damit die Wahl überprüfbar bleibt.
    "models": {
      "reviewer": { "model": "opus", "why": "urteilt über große Diffs; ein übersehener Befund kostet eine Runde" },
      "builder":  { "model": "sonnet", "why": "mechanische Inkremente mit ausführbarer Prüfung" }
    }
  }
}
```

Die Laufzeit liest die Zuordnung beim Dispatch und wendet sie an; die verwalteten Rollendateien
bleiben unberührt und liefern weiter die Voreinstellung. Alternativ oder zusätzlich: ein optionaler
Modellparameter am Dispatch, damit ein A/B ohne Konfigurationsänderung möglich ist.

**Was diese Sitzung zur Sache selbst beitragen kann** — und was sie ausdrücklich *nicht* kann:
Die gesamte Bauarbeit lief auf der kleineren Voreinstellung und war gut (ein Reviewer blockierte ein
Paket mit einem echten Befund; ein Builder fand einen subtilen Messfehler und verfolgte ihn zur
Ursache; ein anderer schrieb einen reproduzierbaren Szenengenerator). **Es gibt keinen Beleg, dass
die Modellgröße der Engpass war** — alle messbaren Fehlschläge waren Koordinationsfehler. Die
Vermutung, die daraus folgt und geprüft gehört: **Auftragsqualität schlägt Modellgröße.** Genau
deshalb braucht es den Schalter: nicht um hochzustufen, sondern **um die Frage entscheidbar zu
machen.**

Vorgeschlagener Messaufbau für Projekte, die es probieren: zwei gleichartige Aufgaben je Modell,
gemessen an Werkzeugaufrufen bis „fertig", Wanduhrzeit, nötiger Nacharbeit und „Abnahme im ersten
Anlauf (ja/nein)".

### Gruppe 5b — Onboarding: die Einwilligung fehlte

`preferences/project-config.json` existierte in diesem Projekt nicht, obwohl
`learnings.contribute_upstream` laut Skill im Onboarding (Schritt 5b) gesetzt wird. Die Skill fängt
das ab (`ask`), aber der Zustand sollte gar nicht entstehen: **das Onboarding sollte die Datei
anlegen, auch wenn der Gründer die Frage überspringt** — mit `"ask"` als geschriebener Vorgabe statt
als angenommener.

### Harness — die drei Muster, ohne eigene Gruppe

> **Vertrag vor dem Spike.** Bei Technologieentscheidungen zuerst den Fall als **Daten** schreiben
> (eine Szene, ein Datensatz, ein Ablauf), dann N-mal umsetzen, dann **von außen** messen — und die
> **Entscheidungsregel vorher** festhalten, damit sie nicht ans Ergebnis angepasst wird.
>
> **Messinstrument statt Einzelkorrektur.** Wiederholt sich eine Qualitätsklage, ist die nächste
> Handlung nicht die Korrektur, sondern das Instrument, das die *Klasse* von Fehlern sichtbar macht
> — mit **eingebauter Selbstprüfung** (bekannte Referenzen, deren Messwerte stimmen müssen). Ein
> Instrument ohne Selbstprüfung misst auch seinen eigenen Fehler mit.
>
> **Feedback-Übersetzung ist Orchestrator-Arbeit.** Gründerfeedback kommt als Liste, Builder liefern
> ein Inkrement. Die Zerlegung in Inkremente, ihre Reihenfolge und die Zuständigkeit für den Rest
> gehören benannt in den Orchestrator-Contract — sonst liefert ein vertragstreuer Builder korrekt
> ein Viertel und niemand ist zuständig für den Rest.

## 4 · PR

```
Branch:  learning/process-geteilter-arbeitsraum-und-modellwahl
Titel:   learning(process): geteilter Arbeitsraum, Lieferstrecke in der DoD, Prüfstand ins Repo, Modellwahl konfigurierbar
Dateien: docs/learnings/incoming/2026-09-07-parallele-agenten-und-der-schnelle-prototyp.md
         docs/learnings/incoming/2026-09-07-einreichung-founder-os.md
         knowledge/blueprint.md            (Gruppen 1, 2, 3, 5)
         knowledge/harness.md              (Gruppe 4 + die drei Muster)
         knowledge/contracts/orchestrator-agent.md  (Feedback-Übersetzung)
         hooks/scripts/guard-bash.sh       (Gruppe 1)
         tools/test_hooks.sh               (ein Testfall je neuem Hook-Muster)
         templates/project/preferences/project-config.json  (Gruppen 5, 5b)
Vor dem Öffnen: python3 tools/validate.py && bash tools/test_hooks.sh
```

### PR-Text

**## Incident**

Eine durchgearbeitete Sitzung eines Projekts auf Modul 16 v0.9.4 (2026-09-06/07): 124 Commits,
3 ADRs, 4 Pakete abgeschlossen, 2 Merges nach `main`, bis zu **sieben Sub-Agenten gleichzeitig auf
einem Container und einem Arbeitsbaum**. **Null Merge-Konflikte auf Produktdateien** — und **drei
Vorfälle, die alle Agenten stilllegten, sämtlich aus der geteilten Umgebung statt aus dem Code**:
zweimal wurden mit `pkill` fremde Browser-Prozesse mitten im Prüflauf getötet, einmal blieb ein
kollidierter `git pull --rebase --autostash` im Baum stehen und blockierte jeden weiteren Commit.

Dazu drei weitere Befunde: der Prüfkanal des Gründers zeigte die geleistete Arbeit nicht (sie passte
nicht in sein Größenlimit und war abgeschaltet), sechs Prüfskripte samt dem Bauwerkzeug der
Lieferung lagen nur im Scratchpad und wären mit der Sitzung verloren gewesen, und ein fehlendes
Werkzeug wurde mit einer Blockade verwechselt.

Der fünfte Befund kam als Anforderung: **die Modellwahl je Rolle ist verdrahtet und für ein Projekt
weder änderbar noch messbar.**

Learnings: `docs/learnings/incoming/` in diesem PR.

**## Proposed rule**

Fünf Regeln, jede an mindestens einen Vorfall gebunden: geteilter Arbeitsraum (Dateieigentum im
Dispatch, keine fremden Prozesse, keine baumweiten Git-Kommandos), Lieferstrecke als Teil der
Definition of Done, Prüfstand gehört ins Repository, Eskalationsleiter vor „blockiert" mit
ausdrücklicher Ausnahme für Berechtigungsgrenzen, und Modellwahl als überschreibbare Voreinstellung
statt Verdrahtung. Volltext oben.

**## Level and why**

Blueprint für 1, 2, 3, 5 — es sind Phasenregeln und eine Ergänzung der Definition of Done.
**Zusätzlich Hook** für 1: die Regel stand in jedem Dispatch und wurde trotzdem zweimal verletzt, und
die Verletzung zerstört fremde Arbeit; nach der Faustregel der Skill damit Hook-würdig, mit Testfall.
Harness für 4 und die drei Muster (Abwägungen, keine Verbote). Orchestrator-Contract für die
Feedback-Übersetzung. Projektvorlage für 5 und 5b.

**## Cost of the rule**

Gruppe 1 macht Dispatches länger und verbietet bequeme Aufräum-Kommandos; der Hook wird gelegentlich
falsch anschlagen, wenn jemand legitim einen eigenen Prozess beendet — die PID-Form bleibt erlaubt.
Gruppe 2 macht Inkremente größer, weil der Lieferkanal mitgedacht wird. Gruppe 3 kostet Aufräumzeit
je Sitzung. Gruppe 4 verzögert ehrliche Blockademeldungen um zwei Prüfungen. Gruppe 5 fügt eine
Konfigurationsfläche hinzu, die falsch gesetzt werden kann — deshalb die Pflicht zur Begründung je
Abweichung; sie kostet eine Zeile und macht die Wahl überprüfbar.

**## Verification**

`python3 tools/validate.py` und `bash tools/test_hooks.sh` grün, mit **je einem neuen Testfall** für
jedes neue Hook-Muster (`pkill`/`killall` ohne PID, `git stash`, `git add -A`, `git reset --hard`,
`git checkout -- .`, `git clean`). Die Regeln selbst sind an Vorfällen belegt, nicht vorbeugend
formuliert: jede nennt ihren Vorfall.

## 5 · Als eingereicht markieren

Nach dem Öffnen des PR: `submitted: <PR-URL>` in den Kopf **beider** Blätter
(`2026-09-07-parallele-agenten-und-der-schnelle-prototyp.md` und dieses), damit nichts zweimal geht.

## 6 · Warum dieser PR noch nicht offen ist

Die Repository-Freigabe dieser Sitzung nennt ausschließlich `steffenmaas/red-empire`; das Werkzeug,
mit dem ein weiteres Repository hinzugefügt wird, war nach einem Container-Neustart nicht verfügbar,
und `gh` ist nicht installiert. Der Git-Transport zu `founder-os` funktioniert zwar — geprüft mit
einem `ls-remote` —, **aber eine Berechtigungsgrenze wird nicht umgangen, nur weil der Weg offen
steht.** Genau diese Unterscheidung steht als Regel in Gruppe 4.

**Der letzte Schritt ist ein Befehl:** `bash tools/upstream-pr.sh` klont das Modul-Repo, legt den
Zweig an, kopiert beide Blätter nach `docs/learnings/incoming/`, committet, pusht und druckt die
Adresse zum Öffnen des PR samt fertigem Titel und dem `gh`-Aufruf. `--dry-run` zeigt vorher, was
liefe. Die Regeltexte werden **bewusst nicht blind gepatcht** — diese Sitzung kannte die Zieldateien
des Moduls nicht und rät nicht; sie stehen ausformuliert in Abschnitt 3 und werden von dem
eingefügt, der die Dateien sieht.

Alternativ: eine Sitzung mit `steffenmaas/founder-os` in der Repository-Freigabe erledigt Schritt 4
und 5 selbst, inklusive der Regeltexte in den Zieldateien.
