#!/usr/bin/env bash
# Boucle CI sans SDK Flutter local : attend le run GitHub Actions d'un commit, affiche les
# erreurs utiles et prépare les correctifs que la CI sait calculer.
#
# Usage :
#   tool/ci.sh wait [sha]       attend le run (défaut : HEAD), affiche jobs et erreurs
#   tool/ci.sh apply-format     applique le diff de format imprimé par la CI (dernier run lu)
#   tool/ci.sh apply-lock       remplace pubspec.lock par celui imprimé par la CI
#
# Le dépôt est public : l'API GitHub se lit sans authentification. Les fichiers de travail
# vont dans $STARMINE_CI_DIR (défaut : ${TMPDIR:-/tmp}/starmine-ci).
set -u
REPO=paul-pch/starmine
API=https://api.github.com/repos/$REPO
DIR=${STARMINE_CI_DIR:-${TMPDIR:-/tmp}/starmine-ci}
mkdir -p "$DIR"
ROOT=$(git rev-parse --show-toplevel)

# Retire l'horodatage en tête de chaque ligne des logs Actions.
strip() { sed 's/^[0-9TZ:.-]* //' "$DIR/log.txt"; }

wait_run() {
  local sha=${1:-$(git -C "$ROOT" rev-parse HEAD)} run="" st=""
  for _ in $(seq 1 40); do
    run=$(curl -sS --max-time 20 "$API/actions/runs?head_sha=$sha" |
      python3 -c 'import sys,json;r=json.load(sys.stdin)["workflow_runs"];print(r[0]["id"] if r else "")' 2>/dev/null)
    [ -n "$run" ] && break
    sleep 10
  done
  [ -z "$run" ] && { echo "Aucun run pour $sha"; return 1; }
  for _ in $(seq 1 90); do
    st=$(curl -sS --max-time 20 "$API/actions/runs/$run" |
      python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["status"],d["conclusion"])' 2>/dev/null)
    case "$st" in completed*) break ;; esac
    sleep 20
  done
  echo "run $run ($sha) : $st"
  curl -sS --max-time 20 "$API/actions/runs/$run/jobs" | python3 -c '
import sys, json
for j in json.load(sys.stdin)["jobs"]:
    print(j["id"], j["name"], j["conclusion"])
    for s in j["steps"]:
        if s["conclusion"] not in ("success", "skipped", None):
            print("   FAIL", s["name"])' >"$DIR/jobs.txt"
  cat "$DIR/jobs.txt"
  local job
  job=$(head -1 "$DIR/jobs.txt" | cut -d' ' -f1)
  curl -sSL --max-time 30 -o "$DIR/log.txt" "$API/actions/jobs/$job/logs"
  # Erreurs d'analyse, de compilation et de tests (le diff de format est à part).
  strip | grep -E "(error|warning|info) •|issues found|Error: |\[E\]|Expected:|Actual:|Which:|tests passed|failed\.|EXCEPTION CAUGHT" | head -80
  strip | awk '/^diff --git/{p=1} /##\[error\]|^::error/{if(p)exit} p{print}' >"$DIR/format.patch"
  strip | awk '/^----- END pubspec.lock -----$/{p=0} p{print} /^----- BEGIN pubspec.lock -----$/{p=1}' >"$DIR/pubspec.lock"
  [ -s "$DIR/format.patch" ] && echo "Format : diff disponible (tool/ci.sh apply-format)"
  [ -s "$DIR/pubspec.lock" ] && echo "Lock : nouveau pubspec.lock disponible (tool/ci.sh apply-lock)"
  case "$st" in "completed success") return 0 ;; *) return 1 ;; esac
}

case "${1:-}" in
  wait) wait_run "${2:-}" ;;
  apply-format) git -C "$ROOT" apply "$DIR/format.patch" && echo "Format appliqué" ;;
  apply-lock) cp "$DIR/pubspec.lock" "$ROOT/pubspec.lock" && echo "pubspec.lock remplacé" ;;
  *) sed -n '2,12p' "$0"; exit 2 ;;
esac
