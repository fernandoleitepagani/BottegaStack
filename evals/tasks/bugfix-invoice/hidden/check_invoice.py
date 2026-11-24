import unittest

from invoice import total


class Hidden(unittest.TestCase):
    def test_no_discount(self):
        self.assertEqual(total(100), 120.0)

    def test_discount_is_taxed_too(self):
        self.assertEqual(total(100, 0.1), 108.0)

    def test_full_discount(self):
        self.assertEqual(total(50, 1.0), 0.0)


if __name__ == "__main__":
    unittest.main()
