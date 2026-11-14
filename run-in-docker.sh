#!/usr/bin/env bash
# Runs reproduce.sh in Docker's node:26 image (Debian) with pnpm 11.22.0, on a copy of this folder.
set -euo pipefail
here=$(cd "$(dirname "$0")" && { pwd -W 2> /dev/null || pwd; })
MSYS_NO_PATHCONV=1 exec docker run --rm -e TURBO_TELEMETRY_DISABLED=1 -v "$here:/source:ro" node:26 bash -c '
  set -euo pipefail
  npm install --global --silent pnpm@11.22.0 > /dev/null 2>&1
  cp -r /source /repro
  rm -rf /repro/node_modules /repro/.turbo /repro/apps/*/node_modules /repro/packages/*/node_modules
  . /etc/os-release
  echo "$PRETTY_NAME, node $(node --version), pnpm $(pnpm --version)"
  exec bash /repro/reproduce.sh
'
