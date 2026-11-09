#!/usr/bin/env bash
set -euo pipefail
./result/bin/t3 --version
nix eval --impure --json --expr 'import ./modules/t3code-policy.nix' > "$RUNNER_TEMP/t3code-policy.json"
./result/bin/t3 policy check "$RUNNER_TEMP/t3code-policy.json"
if [[ "$RUNNER_OS" == macOS ]]; then
  codesign --verify --deep --strict 'result/Applications/T3 Code (Beta).app'
fi
