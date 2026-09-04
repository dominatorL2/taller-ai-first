#!/usr/bin/env bash
# Controles de calidad que deben pasar antes de abrir un PR desde la rama actual.
# Ejecuta cada control mostrando su salida completa. Devuelve 0 si todos pasan,
# 1 si al menos uno falla.

set -uo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root" || exit 1

overall=0

run_gate() {
    local name="$1"
    shift
    echo "=================================================="
    echo "GATE: $name"
    echo "=================================================="
    "$@"
    local status=$?
    if [ "$status" -ne 0 ]; then
        echo "--> FALLÓ: $name (código $status)"
        overall=1
    else
        echo "--> OK: $name"
    fi
    echo
}

# 1. ruff check sobre src/ y tests/, sin hallazgos.
run_gate "ruff check (src/ tests/)" uvx ruff check src/ tests/

# 2. bandit sobre src/, sin hallazgos de severidad media o alta.
run_gate "bandit (src/, severidad media/alta)" uvx bandit -r src/ --severity-level medium

# 3. pytest en verde.
run_gate "pytest" uv run pytest

# 4. Todos los commits de la rama contra main en formato Conventional Commits.
echo "=================================================="
echo "GATE: Conventional Commits (rama actual vs main)"
echo "=================================================="

conventional_pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_./-]+\))?!?: .+'

if ! git rev-parse --verify main >/dev/null 2>&1; then
    echo "--> FALLÓ: no existe una rama local 'main' contra la cual comparar"
    overall=1
else
    base="$(git merge-base main HEAD)"
    commits="$(git log --reverse --format='%H %s' "$base"..HEAD)"

    if [ -z "$commits" ]; then
        echo "(no hay commits nuevos respecto a main)"
        echo "--> OK: Conventional Commits"
    else
        bad=0
        while IFS= read -r line; do
            sha="${line%% *}"
            subject="${line#* }"
            short="${sha:0:7}"
            if [[ "$subject" =~ $conventional_pattern ]]; then
                echo "  OK    $short  $subject"
            else
                echo "  FALLA $short  $subject"
                bad=1
            fi
        done <<<"$commits"

        if [ "$bad" -ne 0 ]; then
            echo "--> FALLÓ: Conventional Commits"
            overall=1
        else
            echo "--> OK: Conventional Commits"
        fi
    fi
fi
echo

if [ "$overall" -ne 0 ]; then
    echo "❌ Uno o más controles fallaron."
    exit 1
fi

echo "✅ Todos los controles pasaron."
exit 0
