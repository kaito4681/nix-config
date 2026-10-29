set shell := ["bash", "-euo", "pipefail", "-c"]
set working-directory := ".."

# 自分用の非公開設定を取得（取得できない場合はスキップ）
private:
  #!/usr/bin/env bash
  set -euo pipefail

  if [[ -e private ]]; then
    echo "private/ already exists."
  elif ! GH_PROMPT_DISABLED=1 GIT_TERMINAL_PROMPT=0 gh repo clone kaito4681/nix-config-private private; then
    echo "Skipping private setup: nix-config-private is unavailable."
  fi

