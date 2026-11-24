TAX_RATE = 0.2


def total(subtotal, discount=0.0):
    """Return the amount to charge. `discount` is a fraction of the subtotal."""
    taxed = subtotal * (1 + TAX_RATE)
    return round(taxed - subtotal * discount, 2)
