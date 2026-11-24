"""Read expense rows from CSV text: category,description,amount."""
import csv
import io
from decimal import Decimal


def parse_amount(text):
    """Parse '12.50', '$12.50' or '(12.00)' (negative) into a Decimal.

    Amounts may carry a thousands separator, as in '1,234.50'.
    """
    s = text.strip().lstrip("$")
    negative = s.startswith("(") and s.endswith(")")
    if negative:
        s = s[1:-1].lstrip("$")
    s = s.replace(",", "")
    value = Decimal(s)
    return -value if negative else value


def read_rows(text):
    rows = []
    for rec in csv.reader(io.StringIO(text)):
        if len(rec) == 3:
            rows.append((rec[0].strip(), rec[1].strip(), parse_amount(rec[2])))
    return rows
