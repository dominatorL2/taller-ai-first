"""Verifica el orden de aplicación de los descuentos.

La política, documentada en el README y en el docstring de
`carrito.descuentos`, es: primero el cupón porcentual y, sobre el monto que
queda, el vale de monto fijo.
"""

from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_cupon_porcentual_se_aplica_antes_que_el_vale_de_monto_fijo():
    producto = Producto(sku="X", nombre="Producto", precio=10_000)
    pedido = Pedido(
        numero=1,
        lineas=[Linea(producto=producto, cantidad=1)],
        cupones=[
            Cupon(codigo="VALE1000", tipo="monto", valor=1_000),
            Cupon(codigo="DESC10", tipo="porcentaje", valor=10),
        ],
    )

    # Subtotal: 10_000.
    # 1) Cupón porcentual (10%): 10_000 - 1_000 = 9_000.
    # 2) Vale de monto fijo ($1_000) sobre lo que queda: 9_000 - 1_000 = 8_000.
    assert total_con_descuentos(pedido) == 8_000
