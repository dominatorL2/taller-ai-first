"""IVA del pedido."""

from carrito.dinero import porcentaje

IVA = 19


def iva(monto: int) -> int:
    """El IVA que corresponde a `monto`."""
    return porcentaje(monto, IVA)


def con_iva(monto: int) -> int:
    return monto + iva(monto)
