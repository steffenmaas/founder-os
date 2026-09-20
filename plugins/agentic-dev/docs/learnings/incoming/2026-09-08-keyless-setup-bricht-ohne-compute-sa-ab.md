---
date: 2026-09-08
scope: upstream
area: deploy
severity: high
submitted: https://github.com/steffenmaas/founder-os/pull/34
---

# Das Cloud-Setup meldete „Fertig", ohne die WIF-Föderation je angelegt zu haben

## What happened

Der Gründer hat `scripts/setup-cloud.sh` (ruft `setup-keyless-deploy.sh`) für `<projekt>`
ausgeführt. Danach: Projektnummer im Workflow richtig (<projektnummer>), aber
`gcloud iam workload-identity-pools providers describe github-oidc --workload-identity-pool=github`
→ `NOT_FOUND`. Der Deploy-Workflow scheiterte seither bei jeder Anmeldung mit `invalid_target`
und übersprang den Deploy-Schritt — bei grünem Lauf.

## Why it happened

**Ursache belegt (zweiter Lauf, 2026-09-08 09:30 UTC, Log des Gründers):** `setup-cloud.sh` wurde
nicht aus dem Repo-Wurzelverzeichnis aufgerufen. Schritt 2 prüft `[ -x scripts/setup-keyless-deploy.sh ]`
relativ zum Arbeitsverzeichnis, findet nichts, schreibt **eine** Zeile („nicht gefunden — im
Repo-Wurzelverzeichnis ausführen") und läuft weiter bis „Fertig". Die Föderation entstand nie; der
Gründer sah ein fertiges Setup. Genau das war schon am 2026-09-06 passiert.

Zweite Falle im selben Lauf: Schritt 4 (Identity Platform) antwortete 403 „requires a quota project" —
Nutzer-Anmeldedaten in der Cloud Shell brauchen `x-goog-user-project`; der Fehlertext wurde nur
ausgegeben, nicht bewertet.

Die Vermutung der ersten Fassung dieses Blatts (Schritt 3 des Keyless-Skripts bricht ohne
Compute-Dienstkonto ab) bleibt eine mögliche Falle für reine Hosting-Projekte, war hier aber nicht
die Ursache — bis zu diesem Schritt kam das Skript gar nicht.

## What we do differently now

- `scripts/setup-cloud.sh` wechselt zuerst ins Repo-Wurzelverzeichnis (`cd "$(dirname "$0")/.."`),
  ein fehlendes Keyless-Skript ist **tödlich** (exit 1), und `api()` sendet `x-goog-user-project`
  und bewertet `"error"` in der Antwort als Fehler des Schritts.
- `scripts/setup-keyless-deploy.sh` (Projektkopie): Schritt 3 nicht mehr tödlich; am Ende prüft das
  Skript selbst, dass der Provider existiert — sonst rot. „Setup complete" ohne Provider gibt es nicht.
- Dritter Lauf (mit `REPO=`): Schritte 1–4 grün, Abbruch in Schritt 5 — `add-iam-policy-binding` eine
  Sekunde nach `service-accounts create`: „Service account … does not exist" (IAM eventual consistency).
  Jede Bindung läuft jetzt über `bind()` mit bis zu sechs Versuchen im Abstand von zehn Sekunden.
- **Regel:** ein Einrichtungsskript, das einen Schritt überspringt, endet nicht mit „Fertig". Jeder
  Schritt, ohne den das Ziel nicht erreicht ist, ist tödlich.
- Upstream (Founder OS `stacks/firebase-flutter/`): Keyless-Skript mit Provider-Prüfung am Ende; in
  `keyless-deploy.md` § Failure modes die Zeile *„Provider NOT_FOUND nach dem Setup → das
  Setup-Skript lief nicht aus dem Repo-Wurzelverzeichnis oder brach vor Schritt 4 ab."*
