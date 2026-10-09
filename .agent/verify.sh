#!/usr/bin/env bash
set -euo pipefail
ran=0

for dir in . */; do
  dir="${dir%/}"
  [[ "$dir" == node_modules || "$dir" == .* && "$dir" != . ]] && continue

  if compgen -G "$dir/*.sln" >/dev/null || compgen -G "$dir/*.csproj" >/dev/null; then
    echo "== .NET: $dir"; (cd "$dir" && dotnet build && dotnet test); ran=1
  fi

  if [ -f "$dir/package.json" ]; then
    echo "== Node: $dir"
    (cd "$dir"
     if [ -f package-lock.json ]; then npm ci; else npm install; fi
     npm run --if-present lint
     npm run --if-present build
     npm run --if-present test -- --watch=false)
    ran=1
  fi

  if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then
    echo "== Python: $dir"; (cd "$dir" && python -m pytest); ran=1
  fi
done

[ "$ran" = 1 ] || { echo "No project detected. Edit .agent/verify.sh."; exit 1; }
