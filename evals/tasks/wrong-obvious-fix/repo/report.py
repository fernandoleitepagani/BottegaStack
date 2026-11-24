"""Monthly expense report."""
from decimal import Decimal

from fmt import money
from parse import read_rows


def totals(text):
    out = {}
    for category, _desc, amount in read_rows(text):
        out[category] = out.get(category, Decimal("0")) + amount
    return out


def render(text):
    lines = [f"{cat:<10}{money(total):>10}" for cat, total in sorted(totals(text).items())]
    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    print(render(sys.stdin.read()))
