#!/usr/bin/env bash
# Hook PreToolUse (matcher: Bash). Bloquea cualquier `git commit` cuyo mensaje
# no siga Conventional Commits. Recibe el payload del hook (JSON) por stdin.
set -uo pipefail

input="$(cat)"

python3 - "$input" <<'PYEOF'
import json
import re
import sys

raw = sys.argv[1] if len(sys.argv) > 1 else ""

try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

command = (data.get("tool_input") or {}).get("command") or ""

# ¿El comando incluye un `git commit`? (permite comandos encadenados, p. ej.
# `git add -A && git commit -m "..."`).
if not re.search(r"(?<![\w-])git\s+commit(?=\s|$)", command):
    sys.exit(0)

subject = None

# 1) Mensaje vía heredoc, sea `-F - <<EOF ...` o el patrón habitual
#    `-m "$(cat <<'EOF' ... EOF)"`. Se busca primero porque un heredoc suele
#    quedar embebido dentro de las comillas de un -m y confundiría el punto 2.
heredoc_open = re.search(r"<<-?\s*(['\"]?)(\w+)\1", command)
if heredoc_open:
    quote, delim = heredoc_open.group(1), heredoc_open.group(2)
    rest = command[heredoc_open.end():]
    end_match = re.search(r"^[ \t]*" + re.escape(delim) + r"[ \t]*$", rest, re.MULTILINE)
    body = rest[: end_match.start()] if end_match else rest
    body = body.lstrip("\n")
    first_line = body.splitlines()[0].strip() if body.strip() else ""
    if first_line:
        subject = first_line

# 2) `-m "mensaje"` / `-m 'mensaje'` / `-m mensaje` / `--message=mensaje`
#    (una sola línea, sin heredoc).
if subject is None:
    m = re.search(
        r"(?:-m|--message)(?:=|\s+)(\"([^\"\n]*)\"|'([^'\n]*)'|(\S+))",
        command,
    )
    if m:
        subject = next(g for g in m.groups()[1:] if g is not None)

# 3) `-F <archivo>` / `--file <archivo>` apuntando a un archivo real en disco.
if subject is None:
    fmatch = re.search(r"(?:-F|--file)\s+([^\s<>|&;]+)", command)
    if fmatch and fmatch.group(1) != "-":
        path = fmatch.group(1).strip("'\"")
        try:
            with open(path, "r") as fh:
                subject = fh.readline().strip()
        except OSError:
            subject = None

if not subject:
    # No se pudo extraer el mensaje (p. ej. editor interactivo sin -m/-F):
    # no hay nada que validar acá, se deja pasar.
    sys.exit(0)

pattern = re.compile(
    r"^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)"
    r"(\([a-zA-Z0-9_./-]+\))?!?: .+"
)

if pattern.match(subject):
    sys.exit(0)

reason = (
    "Commit rechazado: el mensaje no sigue Conventional Commits.\n"
    f"Asunto detectado: {subject!r}\n"
    "Formato esperado: <tipo>(<scope opcional>)!: <descripcion>, con tipo en "
    "feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert "
    "(el '!' es opcional, para breaking changes)."
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    },
    "systemMessage": reason,
}))
sys.exit(0)
PYEOF
