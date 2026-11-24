import unittest

from fmt import money
from parse import parse_amount
from report import render, totals

CSV = "food,lunch,12.50\nfood,coffee,3.25\ntravel,bus,40.00\n"


class Visible(unittest.TestCase):
    def test_parse(self):
        self.assertEqual(str(parse_amount("$12.50")), "12.50")

    def test_totals(self):
        self.assertEqual(str(totals(CSV)["food"]), "15.75")

    def test_money(self):
        self.assertEqual(money(3), "3.00")

    def test_render(self):
        self.assertIn("15.75", render(CSV))


if __name__ == "__main__":
    unittest.main()
