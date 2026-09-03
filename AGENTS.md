# AGENTS.md

Este archivo le da contexto a Claude Code (claude.ai/code) para trabajar en este repositorio.

## Qué es esto

`carrito` es un CLI en Python que calcula el total de un pedido: subtotal,
descuentos (cupones y promociones), IVA y envío. No tiene servidor, base de
datos ni API; los pedidos y productos de ejemplo viven en `datos/ejemplo.json`.

## Comandos

```sh
uv sync                                          # instalar dependencias
uv run python -m carrito total --pedido 42       # correr el CLI
uv run python -m carrito total --pedido 42 --detalle   # con desglose de líneas
uv run python -m carrito total --pedido 44 --sin volumen  # excluir una promoción

uv run pytest                                    # correr todos los tests
uv run pytest tests/test_impuestos.py            # un archivo de tests
uv run pytest -k redondea                        # un test por nombre/expresión
```

Versiones fijadas en `.tool-versions`: Python 3.13.5, uv 0.9.5. CI
(`.github/workflows/tests.yml`) corre `uv sync --locked && uv run pytest` en
cada push/PR.

## Arquitectura

El flujo de cálculo atraviesa varios módulos pequeños en `src/carrito/`, cada
uno con una sola responsabilidad; `resumen.py` es el que los orquesta:

- `modelo.py` — dataclasses del dominio: `Producto`, `Linea`, `Cupon`, `Pedido`.
- `datos.py` — `pedido(numero)` carga y parsea `datos/ejemplo.json` en cada
  llamada (sin caché) y arma los objetos del modelo.
- `precios.py` — `subtotal(pedido)`, suma de `precio_linea` por cada línea.
- `descuentos.py` — dos mecanismos de descuento con **orden de aplicación
  fijo y significativo**:
  1. **Promociones** (`PROMOCIONES`: `2x1`, `volumen`, `primera-compra`), cada
     una calculada sobre el subtotal original y sumadas entre sí.
  2. **Cupones** del pedido, aplicados en secuencia sobre el monto que va
     quedando: primero los porcentuales, después los de monto fijo.
  `detalle_descuentos()` devuelve el desglose línea por línea en ese orden;
  `total_con_descuentos()` da el monto final. El CLI puede excluir
  promociones puntuales con `--sin <nombre>`.
- `dinero.py` — toda la plata se maneja en pesos enteros; `redondear()`
  redondea al peso más cercano y el medio peso siempre sube (incluso en
  negativos). `porcentaje()` se apoya en esto para cualquier cálculo con
  decimales.
- `impuestos.py` — IVA fijo de 19% (`IVA`), aplicado sobre el monto ya
  descontado.
- `envio.py` — costo por región (`TRAMOS`), gratis sobre `UMBRAL_ENVIO_GRATIS`
  ($50.000) y gratis siempre para clientes nuevos (`cliente_nuevo`),
  independiente del monto. Se calcula sobre el monto **después** de
  descuentos, no sobre el subtotal.
- `resumen.py` — arma el dict ordenado que se muestra/exporta: Subtotal →
  detalle de descuentos → Descuentos → IVA → Envío → Total.
- `cli.py` / `__main__.py` — parseo de argumentos y formato de salida por
  consola (alineación de columnas, modo `--detalle`).

No hay abstracción de "reportes" ni exportación a otros formatos: eso se
descartó en favor de un sistema externo.

## Convenciones

- **Nombres en inglés.** El código actual mezcla nombres de funciones en
  inglés y español (p. ej. `promo_2x1` junto a `volume_discount` en
  `descuentos.py`, o `costo_envio` junto a `free_shipping_for_new_customer`
  en `envio.py`). De ahora en adelante, todo nombre nuevo (funciones,
  variables, clases, módulos) se escribe en inglés. No hace falta traducir
  el código existente de oficio, pero al tocar una función que esté en
  español conviene renombrarla de paso.
- **Documentación vs. código: gana la documentación.** Si un cambio deja la
  documentación (README, docstrings) contradiciendo el código, o al revés,
  trata la documentación como la fuente de verdad y ajusta el código para
  que calce con lo documentado — pero antes de hacerlo, avisa explícitamente
  de la contradicción encontrada (archivo y línea de cada lado) para que se
  confirme el arbitraje.
