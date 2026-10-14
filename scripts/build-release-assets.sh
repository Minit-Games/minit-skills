#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <out-dir>" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$repo_root/plugins/minit/skills"
skill_url="https://github.com/Minit-Games/minit-skills/blob/main/plugins/minit/skills/minit"
setup_url="https://github.com/Minit-Games/minit-skills#cursor-and-vs-code"

mkdir -p "$1"
out_dir="$(cd "$1" && pwd)"

rm -f "$out_dir/minit-skill.zip"
(cd "$skills_dir" && zip -r -X -q "$out_dir/minit-skill.zip" minit -x '*.DS_Store')

{
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { in_fm = 0; after_fm = 1; next }
    in_fm { next }
    after_fm && $0 == "" { after_fm = 0; next }
    { after_fm = 0; print }
  ' "$skills_dir/minit/SKILL.md" | sed "s#](references/#](${skill_url}/references/#g"
  echo
  echo "Set up the Minit MCP server in Cursor or VS Code: ${setup_url}"
} > "$out_dir/AGENTS.md"

echo "Built $out_dir/minit-skill.zip and $out_dir/AGENTS.md"
