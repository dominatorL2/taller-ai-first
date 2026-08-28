"""Verifica el cálculo del IVA según la documentación del proyecto.

`carrito.impuestos` aplica el 19% (`IVA`) sobre el monto. El redondeo de
montos con decimales está documentado en `carrito.dinero`: se redondea al
peso más cercano, y el medio peso va hacia arriba.
"""

import pytest

from carrito.impuestos import iva


@pytest.mark.parametrize(
    "monto, esperado",
    [
        (100, 19),  # 19.00 -> exacto, sin redondeo.
        (50, 10),  # 9.50 -> medio peso, redondea hacia arriba.
        (108, 21),  # 20.52 -> redondea hacia arriba.
        (145, 28),  # 27.55 -> redondea hacia arriba.
    ],
)
def test_iva_redondea_al_peso_mas_cercano(monto, esperado):
    assert iva(monto) == esperado
