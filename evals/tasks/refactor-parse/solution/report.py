def _parse(lines, sign):
    rows = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, amount = line.split(",")
        rows.append((name.strip(), sign * float(amount)))
    return rows


def parse_sales(lines):
    return _parse(lines, 1)


def parse_refunds(lines):
    return _parse(lines, -1)


def net(sales_lines, refund_lines):
    totals = {}
    for name, amount in parse_sales(sales_lines) + parse_refunds(refund_lines):
        totals[name] = totals.get(name, 0.0) + amount
    return totals
