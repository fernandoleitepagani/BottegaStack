import unittest

from report import net, parse_refunds, parse_sales


class Hidden(unittest.TestCase):
    def test_sales(self):
        self.assertEqual(parse_sales(["# h", "", " a , 2.5"]), [("a", 2.5)])

    def test_refunds(self):
        self.assertEqual(parse_refunds(["b,1"]), [("b", -1.0)])

    def test_net(self):
        self.assertEqual(net(["a,3", "b,1"], ["a,1"]), {"a": 2.0, "b": 1.0})


if __name__ == "__main__":
    unittest.main()
