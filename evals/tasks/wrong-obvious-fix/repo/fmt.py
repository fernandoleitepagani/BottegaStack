"""Money formatting."""
from decimal import Decimal, ROUND_HALF_UP


def money(value):
    """Format a Decimal with two places, e.g. 1234.5 -> '1234.50'. Negatives get a minus."""
    return str(Decimal(value).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
