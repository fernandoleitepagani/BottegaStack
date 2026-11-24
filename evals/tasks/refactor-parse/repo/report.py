def parse_sales(lines):
    rows = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, amount = line.split(",")
        rows.append((name.strip(), float(amount)))
    return rows


def parse_refunds(lines):
    rows = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, amount = line.split(",")
        rows.append((name.strip(), -float(amount)))
    return rows


def net(sales_lines, refund_lines):
    totals = {}
    for name, amount in parse_sales(sales_lines) + parse_refunds(refund_lines):
        totals[name] = totals.get(name, 0.0) + amount
    return totals
