#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
selection=all
for arg in "$@"; do
  case "$arg" in
    --strict) ;; # Every execution now fails for failed or empty suites.
    all|full|node|python|api|e2e|unit|integration|security|resilience|performance) selection="$arg" ;;
    *) echo "Unknown test selection: $arg" >&2; exit 2 ;;
  esac
done
exec python3 scripts/regression.py "$selection"
