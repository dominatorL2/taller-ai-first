"""Step definitions para tests/features/envio.feature.

Verifican la regla de envío gratis: el umbral de $50.000 se evalúa sobre
subtotal + IVA, calculados antes de aplicar cupones y promociones.
"""

from pytest_bdd import given, parsers, scenarios, then, when

from carrito.impuestos import iva as calcular_iva
from carrito.modelo import Cupon, Linea, Pedido, Producto
from carrito.precios import subtotal as calcular_subtotal
from carrito.resumen import resumen

scenarios("features/envio.feature")


def parse_monto(texto: str) -> int:
    """Convierte "42.017" o "42017" en el entero 42017."""
    return int(texto.replace(".", ""))


parse_monto.pattern = r"[\d.]+"

EXTRA_TYPES = {"Monto": parse_monto}


@given(
    parsers.parse(
        'un pedido de la región "{region}" sin cupones, sin promociones y sin ser cliente nuevo'
    ),
    target_fixture="pedido",
)
def pedido_sin_descuentos(region):
    return Pedido(numero=1, region=region, cliente_nuevo=False)


@given(
    parsers.parse(
        'un pedido de la región "{region}" sin promociones y sin ser cliente nuevo'
    ),
    target_fixture="pedido",
)
def pedido_sin_promociones(region):
    return Pedido(numero=1, region=region, cliente_nuevo=False)


@given(
    parsers.parse(
        'un pedido de la región "{region}" sin cupones y sin ser cliente nuevo'
    ),
    target_fixture="pedido",
)
def pedido_sin_cupones(region):
    return Pedido(numero=1, region=region, cliente_nuevo=False)


@given(
    parsers.parse(
        'un pedido de la región "{region}" sin cupones, sin promociones y de un cliente nuevo'
    ),
    target_fixture="pedido",
)
def pedido_cliente_nuevo(region):
    return Pedido(numero=1, region=region, cliente_nuevo=True)


@given(
    parsers.parse(
        "el pedido tiene un producto de ${precio:Monto} por unidad y cantidad {cantidad:d}",
        extra_types=EXTRA_TYPES,
    )
)
def agregar_producto(pedido, precio, cantidad):
    producto = Producto(sku="SKU-TEST", nombre="Producto de prueba", precio=precio)
    pedido.lineas.append(Linea(producto=producto, cantidad=cantidad))


@given(
    parsers.parse(
        'el pedido tiene un cupón de monto fijo "{codigo}" por ${monto:Monto}',
        extra_types=EXTRA_TYPES,
    )
)
def agregar_cupon(pedido, codigo, monto):
    pedido.cupones.append(Cupon(codigo=codigo, tipo="monto", valor=monto))


@given(
    parsers.parse(
        'el pedido tiene la promoción "{nombre}" (5% de descuento por llevar 10 unidades o más)'
    )
)
def agregar_promocion(pedido, nombre):
    pedido.promociones.append(nombre)


@when("se calcula el envío del pedido", target_fixture="resultado")
def calcular_envio(pedido):
    subtotal = calcular_subtotal(pedido)
    return {
        "subtotal": subtotal,
        "iva": calcular_iva(subtotal),
        "monto_umbral": subtotal + calcular_iva(subtotal),
        "costo_envio": resumen(pedido)["Envío"],
    }


@then(parsers.parse("el IVA calculado es ${iva:Monto}", extra_types=EXTRA_TYPES))
def verificar_iva(resultado, iva):
    assert resultado["iva"] == iva


@then(
    parsers.parse(
        "el monto sujeto al umbral (subtotal + IVA) es ${monto_umbral:Monto}",
        extra_types=EXTRA_TYPES,
    )
)
def verificar_monto_umbral(resultado, monto_umbral):
    assert resultado["monto_umbral"] == monto_umbral


@then(
    parsers.parse("el costo de envío es ${costo_envio:Monto}", extra_types=EXTRA_TYPES)
)
def verificar_costo_envio(resultado, costo_envio):
    assert resultado["costo_envio"] == costo_envio


@then("el envío es gratis")
def verificar_envio_gratis(resultado):
    assert resultado["costo_envio"] == 0
