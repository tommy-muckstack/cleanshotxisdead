#!/usr/bin/env bash
# Retries publishing every listed app until each repo is pushed (GitHub rate-limits repo creation).
apps="$*"; for round in $(seq 1 60); do pending=""; for a in $apps; do
  if gh repo view tommy-muckstack/$a >/dev/null 2>&1 && (cd /workspace/$a && git fetch -q origin 2>/dev/null; [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main 2>/dev/null)" ]); then echo "$(date +%T) $a published"; else
    out=$(/workspace/isdead-scaffold/publish.sh $a "Update" "Free, open-source $(echo $a | sed 's/isdead//') alternative. Part of the IsDead series." 2>&1 | tail -2); echo "$(date +%T) $a: $out"; if ! echo "$out" | grep -q "^https"; then pending="$pending $a"; fi; fi; done
  [ -z "$pending" ] && { echo ALLDONE; exit 0; }; sleep 600; done
