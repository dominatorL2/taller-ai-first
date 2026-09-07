# language: es
#
# Reglas de negocio del envío gratis (decisiones fijadas, no se reabren en este archivo):
#   1. El umbral de $50.000 se evalúa ANTES de aplicar cupones y promociones: se compara
#      contra el subtotal (más el IVA, ver punto 2), nunca contra el monto ya descontado.
#   2. El IVA SÍ cuenta para el umbral: el monto que se compara contra $50.000 es
#      subtotal + IVA(subtotal), con el IVA calculado sobre el subtotal, sin descuentos.
#   3. Las promociones descuentan igual que los cupones: ninguno de los dos mecanismos de
#      descuento cambia si el envío es gratis, porque el umbral ya se evaluó antes de aplicarlos.
#   4. Con $50.000 justos (en el monto sujeto al umbral) el envío es gratis: la comparación
#      es "mayor o igual", no "estrictamente mayor".
#
# Fórmulas usadas en los montos de los escenarios:
#   - IVA: carrito.impuestos.iva(monto) = redondear(monto * 19 / 100), con
#     carrito.dinero.redondear: al peso más cercano, medio peso hacia arriba.
#   - Costo de envío cuando se cobra (carrito.envio.TRAMOS): metropolitana $3.990,
#     regiones $5.990, extremo $12.990.

Característica: Envío gratis del carrito
  Como cliente de la tienda
  Quiero que el envío sea gratis cuando mi compra supera cierto monto
  Para no pagar de más por pedidos grandes

  Esquema del escenario: Los cuatro bordes del umbral de $50.000 (subtotal + IVA, sin descuentos)
    Dado un pedido de la región "metropolitana" sin cupones, sin promociones y sin ser cliente nuevo
    Y el pedido tiene un producto de $<precio_unitario> por unidad y cantidad 1
    Cuando se calcula el envío del pedido
    Entonces el IVA calculado es $<iva>
    Y el monto sujeto al umbral (subtotal + IVA) es $<monto_umbral>
    Y el costo de envío es $<costo_envio>

    Ejemplos:
      | caso                                   | precio_unitario | iva  | monto_umbral | costo_envio |
      | Muy por debajo del umbral               | 10000           | 1900 | 11900        | 3990        |
      | Justo por debajo del umbral ($49.999)   | 42016           | 7983 | 49999        | 3990        |
      | Exactamente en el umbral ($50.000)      | 42017           | 7983 | 50000        | 0           |
      | Justo por encima del umbral ($50.001)   | 42018           | 7983 | 50001        | 0           |

      # Muy por debajo: subtotal 10.000. IVA = redondear(10.000 * 0,19) = 1.900.
      #   Monto sujeto al umbral: 10.000 + 1.900 = 11.900 (< 50.000) -> se cobra $3.990 (metropolitana).
      # Justo por debajo: subtotal 42.016. IVA = redondear(42.016 * 0,19) = redondear(7.983,04) = 7.983.
      #   Monto sujeto al umbral: 42.016 + 7.983 = 49.999 (< 50.000) -> se cobra $3.990.
      # Exactamente en el umbral: subtotal 42.017. IVA = redondear(42.017 * 0,19) = redondear(7.983,23) = 7.983.
      #   Monto sujeto al umbral: 42.017 + 7.983 = 50.000 (= 50.000) -> gratis, por la decisión 4.
      # Justo por encima: subtotal 42.018. IVA = redondear(42.018 * 0,19) = redondear(7.983,42) = 7.983.
      #   Monto sujeto al umbral: 42.018 + 7.983 = 50.001 (> 50.000) -> gratis.

  Escenario: Un cupón no cambia si el envío es gratis, porque el umbral se evalúa antes del descuento
    Dado un pedido de la región "metropolitana" sin promociones y sin ser cliente nuevo
    Y el pedido tiene un producto de $42.017 por unidad y cantidad 1
    Y el pedido tiene un cupón de monto fijo "AHORRA20" por $20.000
    Cuando se calcula el envío del pedido
    Entonces el envío es gratis
    Y el costo de envío es $0

    # Subtotal 42.017 + IVA 7.983 (mismo cálculo que "Exactamente en el umbral") = monto
    # sujeto al umbral de 50.000 -> justo en el umbral, gratis, antes de tocar el cupón.
    # Con el cupón aplicado el monto que paga el cliente queda en 42.017 - 20.000 = 22.017,
    # muy por debajo de $50.000 — pero eso no cambia el resultado: el umbral ya se evaluó
    # sobre el subtotal + IVA, antes de aplicar el cupón (decisión 1).

  Escenario: Una promoción tampoco cambia si el envío es gratis, porque descuenta igual que un cupón
    Dado un pedido de la región "metropolitana" sin cupones y sin ser cliente nuevo
    Y el pedido tiene un producto de $4.202 por unidad y cantidad 10
    Y el pedido tiene la promoción "volumen" (5% de descuento por llevar 10 unidades o más)
    Cuando se calcula el envío del pedido
    Entonces el envío es gratis
    Y el costo de envío es $0

    # Subtotal: 4.202 x 10 = 42.020. IVA = redondear(42.020 * 0,19) = redondear(7.983,8) = 7.984.
    # Monto sujeto al umbral: 42.020 + 7.984 = 50.004 (> 50.000) -> gratis, antes de tocar la promoción.
    # Descuento de la promoción "volumen": 5% de 42.020 = 2.101. Monto que paga el cliente:
    # 42.020 - 2.101 = 39.919, muy por debajo de $50.000 — pero no cambia el resultado: la
    # promoción descuenta igual que un cupón (decisión 3) y el umbral ya se evaluó antes (decisión 1).

  Escenario: El cliente nuevo no paga envío sin importar el monto de su pedido
    Dado un pedido de la región "extremo" sin cupones, sin promociones y de un cliente nuevo
    Y el pedido tiene un producto de $5.000 por unidad y cantidad 1
    Cuando se calcula el envío del pedido
    Entonces el envío es gratis
    Y el costo de envío es $0

    # Subtotal 5.000: muy por debajo del umbral, y en la región más cara ($12.990 si se
    # cobrara). Aun así el envío es gratis, porque el cliente nuevo no paga envío en su
    # primera compra sin importar el monto — esta regla es independiente de las decisiones
    # 1 a 4, que solo aplican al umbral por monto.
