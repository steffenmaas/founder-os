---
date: 2026-09-07
scope: upstream
area: process
severity: high
submitted: <vorbereitet in 2026-09-07-einreichung-founder-os.md — Einreichung braucht eine Sitzung mit Zugriff auf steffenmaas/founder-os>
---

# Parallele Agenten skalieren, wenn Dateien Eigentum haben — und die Lieferstrecke gehört zum Inkrement

> Rückschau auf eine durchgearbeitete Sitzung an **Neon City** (2026-09-06 bis 07), auf Wunsch des
> Gründers: *„Die parallelen Agenten haben uns richtig auf Tempo gebracht, ohne Konflikte. Und der
> schnelle Prototyp hat richtig Spaß gemacht."* Das stimmt — und beides hat Voraussetzungen, die im
> Modul bisher nicht stehen. Dieses Blatt hält fest, was getragen hat, was Zeit gekostet hat, und was
> davon in `.founder-os/` gehört. **Es ist ein Vorschlag nach oben, keine lokale Änderung** —
> `.founder-os/` bleibt unberührt (CLAUDE.md, harte Verletzung 11).

## Was in der Sitzung passiert ist

124 Commits an einem Tag; 88 protokollierte Entscheidungen; drei ADRs (0014 Engine, 0015 Plattform,
0016 Ausblende); vier Pakete abgeschlossen (F020, T022, T023, T023b), drei neu spezifiziert (T024,
T025, D009); zwei Merges nach `main`; 78 bezogene und 3 selbst gebaute Assets; ein Prototyp von 918
Zeilen, der elfmal veröffentlicht und vom Gründer viermal selbst getestet wurde.

Gleichzeitig liefen bis zu **sieben Sub-Agenten** in **einem** Container auf **einem** Arbeitsbaum:
Prototyp-Builder, F020-Builder, Konstrukt-Builder, drei Engine-Spike-Builder, Asset-Import,
Asset-Scout, Verifier, Reviewer. Es gab **null Merge-Konflikte auf Produktdateien** — aber drei
Vorfälle, die die ganze Werkstatt stilllegten, und alle drei kamen aus der **geteilten Umgebung**,
nicht aus dem Code.

## Was getragen hat, und warum

**1 · Dateieigentum, im Auftrag benannt.** Jeder Dispatch nannte genau die Dateien, die der Agent
besitzt, und verbot alle anderen namentlich. Sieben Agenten am selben Baum, kein einziger Konflikt in
einer Produktdatei. Das ist die eine Regel, die Parallelität trägt — nicht Absprache, nicht Sperren,
sondern **Eigentum**. Wo zwei Agenten dieselbe Datei brauchten (`prototype/city.html`), wurden sie
**nacheinander** gefahren, per Fortsetzung desselben Agenten statt Neu-Dispatch.

**2 · Ein Prototyp ohne Bauschritt.** Eine HTML-Datei, drei Sekunden zwischen Änderung und Bild. Der
Gründer testete selbst und meldete präzise: *„Straßen viel zu breit"*, *„Palmen entfernen"*, *„ich
kann nicht herumlaufen"*. Zum Vergleich: derselbe Umfang im Anwendungs-Stack braucht Lint,
Typprüfung, Build und Prüflauf je Inkrement. **Der Prototyp war nicht der Entwurf des Produkts, er
war das Messinstrument für Absicht.**

**3 · Dev-Haken als Prüffläche.** `window.__city`, `window.__construct`, `window.__spike` — jeweils
dieselbe kleine Oberfläche (`ready`, `state`, `settle(n)`, eine Bewegung, ein Bild). Damit wurde jede
Behauptung headless prüfbar und, was mehr zählt, **über vier verschiedene Engines hinweg
vergleichbar**.

**4 · Der Vertrag vor dem Spike.** Die Engine-Frage („Unity? Godot? PlayCanvas?") wurde nicht
diskutiert, sondern gebaut: eine Szene als Datei (`scene.json`), vier Umsetzungen, eine Messung von
außen. Ergebnis in einer Zahl — Godots Web-Export wiegt 49 MB gegen 14,7 MB — und die Entscheidung
war unstrittig. **Eine Meinungsfrage wurde zu einer Messung, weil zuerst der Vertrag geschrieben
wurde und dann der Code.**

**5 · Das Messinstrument statt der Einzelkorrektur.** Auf *„die Modelle sind teilweise nicht richtig
skaliert"* war die Antwort nicht, drei Modelle zu korrigieren, sondern **Das Konstrukt** zu bauen:
ein weißer Raum mit Schachbrett, in dem jedes Asset neben einer 1,72-m-Figur, einem 1-m-Würfel und
einem 4,5-m-Auto steht und gegen Erwartungsbereiche gemessen wird. Es fand sofort 83 Fehler — und
danach einen Fehler **in der eigenen Messung**, der zwei Bugs im Spiel erklärte. Ein Instrument, das
sich selbst prüft (die drei Maßstäbe), ist mehr wert als jede Einzelkorrektur.

**6 · Der Gründer testet selbst, jede Runde.** Jede seiner Testnachrichten erzeugte eine konkrete
Fehlerliste. Kein Reviewer hätte „die Straßen sind zu breit" gefunden — die Zahl stand seit Wochen
im Code und war formal korrekt.

## Was Zeit gekostet hat

**1 · Geteilte Umgebung ohne geteilte Disziplin.** Zwei Agenten räumten mit `pkill` vermeintliche
Zombie-Prozesse auf und töteten die Browser anderer Agenten mitten im Prüflauf. Ein kollidierter
`git pull --rebase --autostash` blieb im Baum stehen und blockierte **alle** Agenten, bis jemand von
Hand aufräumte. Beides sind keine Code-Fehler: es sind **Umgebungskonflikte**, für die das Modul
keine Regeln kennt.

**2 · Die Lieferstrecke zeigte den Stand nicht.** Der Gründer testete ausschließlich über ein
eigenständiges HTML-Artefakt mit 16 MB Grenze. Die importierten Assets (88 MB) passten nicht hinein,
also schaltete der Bau sie per Schalter ab. Ergebnis: er testete eine Fassung, in der **nichts** von
der Asset-Arbeit sichtbar war, meldete zu Recht „die Gebäude sind noch nicht da" — und bekam von mir
eine Erklärung statt einer Lösung. Erst zwei Runden später wurde das Budget so umgebaut, dass die
wichtigen Pakete hineinpassen. **Das war der teuerste Fehler der Sitzung, und er kostete Vertrauen,
nicht Zeit.**

**3 · Der Prüfstand lag außerhalb des Repos.** Sechs Skripte — Missionskette, Kameramodi, Größen im
Innenraum, Karte, CSP-Probe und **der Bau des Artefakts selbst** — existierten nur im Scratchpad der
Sitzung. Mit deren Ende wären sie weg gewesen, und mit ihnen die Fähigkeit, überhaupt eine neue
Fassung für den Gründer zu bauen. Aufgefallen ist es erst durch seine Abschlussfrage *„liegt noch
etwas lokal bei dir?"*.

**4 · Einkaufen statt bauen.** 79 Asset-Pakete von zwölf Autoren in sechs Stilen. Jedes für sich
ordentlich, zusammen ein Flohmarkt. Der eigene Scout hatte gewarnt (*„damit das gut aussieht und
nicht so zusammengewürfelt"*), und ich habe die Warnung als Stilfrage gelesen statt als Befund. Die
Korrektur (eigene Assets per Blender-Skript, `DESIGN.md` als Materialquelle) kam erst, als der
Gründer einen fremden Arbeitsstand zeigte und sagte: *„und wir dödeln hier rum"*.

**5 · Fehlendes Werkzeug mit Blockade verwechselt.** Nach einem Container-Neustart waren die
GitHub-Werkzeuge weg. Ich meldete den Merge als blockiert. Der Gründer fragte zurück, warum das nicht
gehen solle — und es ging: ein Merge ist eine Git-Operation, `checkout -B`, `merge --no-ff`, Gate auf
dem Merge-Commit, `push`. **Ich hatte das Werkzeug mit der Fähigkeit verwechselt.**

**6 · Ein Inkrement gegen eine Vierer-Liste.** Der Builder-Vertrag verlangt genau ein Inkrement je
Auftrag — richtig so. Gründerfeedback kommt aber als Liste von vier Punkten. Ein Builder lieferte
korrekt nur Punkt eins und begründete es mit seinem Vertrag; die drei übrigen brauchten einen zweiten
Anlauf. Die Übersetzung von Feedback in Inkremente ist Orchestrator-Arbeit, aber das Modul sagt
nirgends, dass sie es ist.

## Was wir jetzt anders machen

Sofort im Projekt umgesetzt (diese Sitzung):

- Jeder Dispatch trägt die Arbeitsbaum-Regeln (kein `stash`, kein `add -A`, kein `reset --hard`,
  kein `checkout -- .`, kein `clean`; erst committen, dann ziehen) **und** „nie Prozesse töten, die
  du nicht gestartet hast".
- Der Prüfstand liegt in `tools/city/` mit README, nicht im Scratchpad.
- `tools/blender/` baut eigene Assets aus `DESIGN.md` heraus; `prototype/assets/authored/` nennt je
  Datei das erzeugende Skript.
- **Das Konstrukt** ist Eingangsprüfung: kein Asset kommt ins Spiel ohne Lauf durch die Maßprüfung.

## Vorschlag an Founder OS (Modul 16)

Sieben Ergänzungen. Die ersten drei halte ich für die wichtigsten.

**A · Ein Abschnitt „Geteilter Arbeitsraum" im Blueprint.** Wenn N Agenten einen Container und einen
Arbeitsbaum teilen, gelten Regeln, die heute nirgends stehen:
*Dateieigentum wird im Dispatch benannt* (besitzt / darf nicht anfassen) · *nie Prozesse töten, die
man nicht gestartet hat* · *nie `stash`/`add -A`/`reset --hard`/`checkout -- .`/`clean`* · *erst die
eigene Datei committen, dann ziehen* · *zwei Agenten an derselben Datei werden nacheinander gefahren,
per Fortsetzung statt Neu-Dispatch* · *ein abgestürzter Lauf unter Last ist „nicht gelaufen", weder
grün noch rot.*

**B · „Die Lieferstrecke gehört zum Inkrement" in die Definition of Done.** Wenn der Gründer durch
Kanal X prüft und die Arbeit in X nicht sichtbar ist, ist das Inkrement **nicht fertig** — auch wenn
der Code stimmt und alle Prüfungen grün sind. Der Kanal ist Teil des Inkrements, nicht sein Umfeld.
Ein Agent, der erklärt, warum man die Arbeit nicht sieht, hat die Aufgabe nicht verstanden.

**C · „Ein Prüfstand im Scratchpad ist kein Prüfstand."** Der Blueprint sagt bereits: *existiert keine
ausführbare Prüfung, ist es dein erster Schritt, eine zu bauen.* Ihm fehlt der zweite Satz: **wo sie
liegt.** Alles, was eine Behauptung beweist — Prüfskripte, Fixturen, das Bauwerkzeug der Lieferung —
gehört ins Repo, mit einem README, das sagt, was jedes Stück beweist.

**D · Eine Eskalationsleiter für fehlende Werkzeuge.** *Werkzeug → gleichwertiges Werkzeug →
Grundmittel (`git`, `curl`, Shell) → erst dann fragen.* „Blockiert" ist erst wahr, wenn alle drei
Stufen leer sind. Ein Merge ist eine Git-Operation, kein API-Aufruf.

**E · Muster „Vertrag vor dem Spike".** Für Technologieentscheidungen: den Fall zuerst als **Daten**
schreiben (eine Szene, ein Datensatz, ein Ablauf), dann N-mal umsetzen, dann **von außen** messen,
mit vorab festgelegter Entscheidungsregel. Vier Umsetzungen in einer Sitzung, eine unstrittige
Entscheidung — die Regel vorher zu schreiben verhindert, dass man sie nachher an das Ergebnis
anpasst.

**F · Muster „Messinstrument statt Einzelkorrektur".** Wiederholt sich eine Qualitätsklage, ist die
nächste Handlung nicht die Korrektur, sondern das Instrument, das die Klasse von Fehlern sichtbar
macht — mit **eingebauter Selbstprüfung** (bekannte Referenzobjekte, deren Messwerte stimmen müssen).
Unser Konstrukt fand dadurch einen Fehler in seiner eigenen Messung.

**G · Feedback-Übersetzung als benannte Orchestrator-Pflicht.** Gründerfeedback kommt als Liste;
Builder liefern ein Inkrement. Dass die Zerlegung, Reihenfolge und Priorisierung Orchestrator-Arbeit
ist, sollte im Contract stehen — sonst liefert ein vertragstreuer Builder korrekt ein Viertel und
niemand ist zuständig für den Rest.

## Die Kostenstruktur — und warum sie der eigentliche Punkt ist

Die Modellwahl lag **nicht** beim Orchestrator: sie steht in den Rollendefinitionen
(`.claude/agents/*.md`, verwaltet). Für diese Sitzung hieß das:

| Rolle | Modell |
|---|---|
| `builder`, `verifier`, `reviewer`, `planner`, `security-auditor` | Sonnet |
| `orchestrator` | `inherit` — das Modell der Sitzung |
| `general-purpose` | ohne Eintrag, Voreinstellung der Laufzeit |

**Die gesamte Bauarbeit lief auf Sonnet**: Fassaden, Konstrukt, vier Engine-Varianten,
Asset-Import, alle Prüfläufe. Das größere Modell koordinierte — Specs, ADRs, Priorisierung, das
Gespräch mit dem Gründer. Das ist die eigentliche Beobachtung dieser Sitzung: **ein Sonnet-Builder
mit präzisem Auftrag, klarem Dateieigentum und einer ausführbaren Prüfung ist schnell und billig.**
Wo es teuer wurde, waren es nie Modellfragen, sondern Koordinationsfehler: abgeschossene Prozesse,
kollidierte Zwischenablage, eine Lieferstrecke, die den Stand nicht zeigte.

Daraus folgt für das Modul: **in Auftragsqualität investieren, nicht in die Modellgröße der
Builder.** Was ein Dispatch enthält — Dateieigentum, die Prüfung, die Abnahme, die Umgebungsregeln —
entscheidet mehr über das Ergebnis als das Modell, das ihn ausführt.

**Und daraus folgt eine Anforderung** (Gründer, 2026-09-07: *„Das sollte nicht fest verdrahtet
sein"*): Die Modellwahl steht heute in den **verwalteten** Rollendefinitionen, die ein Projekt nicht
ändern darf, und das Agent-Werkzeug nimmt beim Dispatch keinen Modellparameter. Ein Projekt kann eine
Rolle also weder hochstufen, wenn sie erkennbar an eine Grenze stößt, noch herunterstufen, wenn ein
Modell überdimensioniert ist — **und vor allem nicht messen, ob die Voreinstellung stimmt.** Das ist
die eigentliche Schwere: die Voreinstellung mag gut sein, aber sie ist unwiderlegbar. Der Vorschlag
(Gruppe 5 der Einreichung) macht sie zu einer **Voreinstellung mit Begründungspflicht bei
Abweichung** statt zu einer Verdrahtung — nicht, um hochzustufen, sondern **um die Frage entscheidbar
zu machen.**

## Was ich nicht belegen kann

Ob die Parallelität **schneller** war als eine serielle Kette, ist nicht sauber gemessen: es gibt
keinen Vergleichslauf. Der Gründer sagt es rückblickend deutlich — *„es war auf jeden Fall
schneller, wir haben einen lauffähigen Prototypen in wenigen Stunden erstellt, mit mehreren
Iterationen"* — und die Modellverteilung stützt es. Beides sind Beobachtungen, keine Messung.

Wer das Modul ändert, sollte beim nächsten Mal zwei Zahlen erheben: **Durchsatz und Kosten einer
seriellen Kette gegen N parallele Builder bei gleicher Aufgabenmenge**, und **wie viele Störungen aus
der geteilten Umgebung kamen statt aus dem Code** — hier waren es alle drei.
