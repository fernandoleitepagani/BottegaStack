TAX_RATE = 0.2


def total(subtotal, discount=0.0):
    """Return the amount to charge. `discount` is a fraction of the subtotal."""
    return round(subtotal * (1 - discount) * (1 + TAX_RATE), 2)
