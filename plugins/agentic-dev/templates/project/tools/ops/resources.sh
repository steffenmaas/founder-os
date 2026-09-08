#!/usr/bin/env bash
# Ressourcen-Wache vor jedem Agenten-Dispatch (Gründer 2026-09-08, 18:05 UTC — nach dem Container-Neustart
# unter Last 15 auf 4 Kernen). Liest Last, Speicher und die schweren Prozesse (Chromium, Blender, node-Builds)
# und sagt GO oder WAIT. Die VM einer Cloud-Session hat 4 vCPUs, 16 GB RAM, 30 GB Disk
# (code.claude.com/docs/en/cloud-environments → Resource limits); „the VM may stop tasks that need
# significantly more memory". Grenzen unten sind Erfahrungswerte dieser Session, keine Anthropic-Zahlen.
#
#   bash tools/ops/resources.sh            → Tabelle + Urteil, Exit 0 = GO, 1 = WAIT
#   bash tools/ops/resources.sh --json     → eine JSON-Zeile (fürs Brett / Check-in)
#   MAX_LOAD=6 MAX_CHROME=24 bash …        → Grenzen überschreiben
set -u
MAX_LOAD="${MAX_LOAD:-6}"          # 1-Minuten-Last; 4 Kerne → ab 6 stauen sich Headless-Läufe, ab 12 gab es den Neustart
MAX_CHROME="${MAX_CHROME:-24}"     # Chromium-Prozesse (jede Headless-Instanz ≈ 6–10 Prozesse)
MAX_BLENDER="${MAX_BLENDER:-1}"    # Blender rechnet allein
MIN_AVAIL_GB="${MIN_AVAIL_GB:-4}"  # verfügbarer Speicher
MIN_DISK_GB="${MIN_DISK_GB:-3}"    # freier Platz auf dem Arbeitsbaum

read -r l1 l5 l15 _ < /proc/loadavg
cores=$(nproc)
avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo); avail_gb=$(( avail_kb / 1024 / 1024 ))
total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo); total_gb=$(( total_kb / 1024 / 1024 ))
disk_gb=$(df -BG --output=avail "${PWD}" | tail -1 | tr -dc '0-9')
chrome=$(ps -eo comm | grep -ci "chrom" || true)
blender=$(ps -eo comm | grep -ci "blender" || true)
nodes=$(ps -eo comm | grep -cx "node" || true)
claude=$(ps -eo comm | grep -cx "claude" || true)
l1i=${l1%.*}

verdict=GO; reasons=()
[ "$l1i" -ge "$MAX_LOAD" ] && { verdict=WAIT; reasons+=("Last $l1 ≥ $MAX_LOAD"); }
[ "$chrome" -ge "$MAX_CHROME" ] && { verdict=WAIT; reasons+=("$chrome Chromium-Prozesse ≥ $MAX_CHROME"); }
[ "$blender" -gt "$MAX_BLENDER" ] && { verdict=WAIT; reasons+=("$blender Blender-Prozesse > $MAX_BLENDER"); }
[ "$avail_gb" -lt "$MIN_AVAIL_GB" ] && { verdict=WAIT; reasons+=("nur $avail_gb GB frei < $MIN_AVAIL_GB"); }
[ "$disk_gb" -lt "$MIN_DISK_GB" ] && { verdict=WAIT; reasons+=("nur $disk_gb GB Platte < $MIN_DISK_GB"); }

if [ "${1:-}" = "--json" ]; then
  printf '{"at":"%s","verdict":"%s","load1":%s,"load5":%s,"cores":%s,"memAvailGb":%s,"memTotalGb":%s,"diskFreeGb":%s,"chrome":%s,"blender":%s,"node":%s,"claude":%s,"reasons":"%s"}\n' \
    "$(date -u +%FT%TZ)" "$verdict" "$l1" "$l5" "$cores" "$avail_gb" "$total_gb" "$disk_gb" "$chrome" "$blender" "$nodes" "$claude" "${reasons[*]:-}"
else
  printf 'Last        %s (5 min %s) auf %s Kernen — Grenze %s\n' "$l1" "$l5" "$cores" "$MAX_LOAD"
  printf 'Speicher    %s GB frei von %s GB — Grenze %s\n' "$avail_gb" "$total_gb" "$MIN_AVAIL_GB"
  printf 'Platte      %s GB frei — Grenze %s\n' "$disk_gb" "$MIN_DISK_GB"
  printf 'Prozesse    chromium %s (Grenze %s) · blender %s (Grenze %s) · node %s · claude-Agenten %s\n' "$chrome" "$MAX_CHROME" "$blender" "$MAX_BLENDER" "$nodes" "$claude"
  if [ "$verdict" = GO ]; then echo "GO — Dispatch möglich"; else echo "WAIT — ${reasons[*]}"; fi
fi
[ "$verdict" = GO ]
