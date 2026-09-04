---
name: prepara-pr
description: Ejecuta los controles de calidad del proyecto (ruff, bandit, pytest, Conventional Commits) sobre la rama actual, pide revisión al subagente revisor-pr y, solo si todo pasa y el veredicto es APROBADO, abre el pull request contra main con gh. Úsalo cuando el usuario pida preparar, revisar o abrir un PR de la rama en la que está trabajando.
Usalo cuando te pida enviar un PR para revisión.
---

Eres responsable de preparar y abrir un pull request de la rama actual contra
`main` en este repo (`carrito`), pero **solo si pasa una serie de controles**.
Sigue estos pasos en orden y no te saltes ninguno.

## 0. Verificaciones previas

- Confirma la rama actual con `git branch --show-current`. Si es `main`, detente
  y avisa al usuario: no se puede abrir un PR de `main` contra sí misma.
- Confirma que no hay cambios sin commitear (`git status`). Si los hay, avisa
  al usuario y pregúntale si quiere commitearlos antes de continuar — no
  continúes sin resolver esto.
- Revisa si ya existe un PR abierto para esta rama con
  `gh pr view --json url,state 2>/dev/null`. Si ya existe uno abierto, informa
  la URL al usuario y detente: no crees uno duplicado.

## 1. Controles de calidad (gates.sh)

Ejecuta el script de controles, que vive junto a este SKILL.md:

```sh
bash .claude/skills/prepara-pr/gates.sh
```

Este script corre, en orden, y muestra la salida completa de cada uno:

1. `ruff check` sobre `src/` y `tests/` (debe no tener hallazgos).
2. `bandit` sobre `src/`, solo severidad media o alta (debe no tener hallazgos).
3. `pytest` (debe pasar en verde).
4. Que todos los commits de la rama actual contra `main` sigan el formato
   [Conventional Commits](https://www.conventionalcommits.org/) (tipo, scope
   opcional, `!` opcional para breaking change, `: ` y descripción).

El script devuelve código `0` si los cuatro controles pasan, y `1` si al
menos uno falla.

**Muéstrale al usuario la salida del script tal cual.** Si el código de
salida es `1`:

- No sigas a los pasos siguientes (ni revisión ni PR).
- Resume qué control(es) específico(s) fallaron y por qué, basándote en la
  salida del script (qué archivo/línea marcó ruff, qué hallazgo reportó
  bandit, qué test falló, o qué commit no sigue Conventional Commits).
- Ofrece corregirlo si el usuario quiere, pero no reintentes el PR
  automáticamente: eso requiere que se vuelva a invocar este skill.

Si el código de salida es `0`, continúa al paso siguiente.

## 2. Revisión de código

Invoca al subagente `revisor-pr` (vía la herramienta Agent, `subagent_type:
"revisor-pr"`) para que revise el diff de la rama actual contra `main`
(`git diff main...HEAD` y el log de commits del rango). Dale contexto: nombre
de la rama, y que ya pasó ruff/bandit/pytest/Conventional Commits, así que su
foco es lógica, buenas prácticas y convenciones del proyecto.

## 3. Decisión según el veredicto

- Si el veredicto es **RECHAZADO**: no abras el PR. Muéstrale al usuario la
  lista de problemas encontrados por `revisor-pr` tal cual el agente los
  devolvió, y detente ahí.
- Si el veredicto es **APROBADO**: continúa al paso 4. Si además hay
  problemas "importantes" o "menores" listados (que no bloquean por sí
  solos), inclúyelos igual en tu resumen final para que el usuario los vea,
  pero no dejes que impidan abrir el PR.

## 4. Abrir el PR

1. Si la rama actual no tiene upstream remoto todavía, publícala:
   `git push -u origin HEAD`. Si ya existe, simplemente `git push`.
2. Abre el PR contra `main`:
   `gh pr create --base main --fill`
   (esto arma título y cuerpo a partir de los commits de la rama; si el
   resultado queda pobre porque hay un solo commit poco descriptivo, arma tú
   un título y cuerpo mejores con `--title` y `--body` describiendo qué
   cambia y por qué, en el mismo estilo que los PRs previos del repo).
3. Devuélvele al usuario la URL del PR creado (`gh pr create` la imprime al
   final).

No hagas push ni crees el PR si cualquiera de los pasos 1–3 no se completó
con éxito.
