import unittest

from invoice import total


class TotalTest(unittest.TestCase):
    def test_no_discount(self):
        self.assertEqual(total(100), 120.0)


if __name__ == "__main__":
    unittest.main()
