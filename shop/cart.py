"""Order totals for a small online shop. Prices are integer cents."""
from shop.pricing import percent_off


def order_total(unit_price_cents: int, quantity: int) -> int:
    """Total in cents for `quantity` items at `unit_price_cents` each, after the volume discount."""
    if quantity < 0:
        raise ValueError("quantity must not be negative")
    if unit_price_cents < 0:
        raise ValueError("unit price must not be negative")
    subtotal = unit_price_cents * quantity
    return subtotal - subtotal * percent_off(quantity) // 100
