"""El resumen del pedido, desglosado."""

from carrito.descuentos import detalle_descuentos, total_con_descuentos
from carrito.envio import costo_envio
from carrito.impuestos import IVA, iva
from carrito.precios import subtotal


ETIQUETAS = {
    "2x1": "Promoción 2x1",
    "volumen": "Descuento por volumen",
    "primera-compra": "Primera compra",
}


def etiqueta_descuento(tipo: str, identificador: str) -> str:
    if tipo == "promocion":
        return ETIQUETAS.get(identificador, identificador)
    return f"Cupón {identificador}"


def resumen(pedido) -> dict[str, int]:
    """El desglose del pedido, en orden de presentación."""
    base = subtotal(pedido)
    descontado = total_con_descuentos(pedido)
    impuesto = iva(descontado)
    envio = costo_envio(pedido, descontado)

    lineas = {"Subtotal": base}
    if descontado != base:
        for tipo, identificador, importe in detalle_descuentos(pedido):
            lineas[etiqueta_descuento(tipo, identificador)] = -importe
        lineas["Descuentos"] = descontado - base
    lineas[f"IVA ({IVA}%)"] = impuesto
    lineas["Envío"] = envio
    lineas["Total"] = descontado + impuesto + envio
    return lineas
