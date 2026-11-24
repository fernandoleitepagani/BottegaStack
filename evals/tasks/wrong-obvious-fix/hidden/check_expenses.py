import unittest
from decimal import Decimal

from fmt import money
from parse import parse_amount
from report import render, totals


class Hidden(unittest.TestCase):
    def test_thousands(self):
        self.assertEqual(parse_amount("1,234.50"), Decimal("1234.50"))
        self.assertEqual(parse_amount("12,000"), Decimal("12000"))
        self.assertEqual(parse_amount("$1,234,567.89"), Decimal("1234567.89"))
        self.assertEqual(parse_amount("999.99"), Decimal("999.99"))

    def test_parens(self):
        self.assertEqual(parse_amount("(12.00)"), Decimal("-12.00"))
        self.assertEqual(parse_amount("($1,200.00)"), Decimal("-1200.00"))

    def test_totals(self):
        csv_text = 'travel,flight,"1,234.50"\ntravel,bus,40.00\nfood,lunch,12.50\ntravel,refund,"(34.50)"\n'
        t = totals(csv_text)
        self.assertEqual(t["travel"], Decimal("1240.00"))
        self.assertIn("1240.00", render(csv_text))

    def test_fmt_unchanged(self):
        self.assertEqual(money(Decimal("1234.5")), "1234.50")
        self.assertEqual(money(Decimal("0.005")), "0.01")
        self.assertEqual(money(Decimal("-3")), "-3.00")
        self.assertEqual(money(Decimal("2.675")), "2.68")
        self.assertEqual(money(Decimal("1234.567")), "1234.57")


if __name__ == "__main__":
    unittest.main()
