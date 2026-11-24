import contextlib
import io
import os
import tempfile
import unittest

import inventory


def run(*argv):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = inventory.main(list(argv))
    return code, buf.getvalue()


class InventoryTest(unittest.TestCase):
    def setUp(self):
        self.old = os.getcwd()
        self.tmp = tempfile.TemporaryDirectory()
        os.chdir(self.tmp.name)

    def tearDown(self):
        os.chdir(self.old)
        self.tmp.cleanup()

    def test_add_and_total(self):
        run("add", "bolt", "10")
        run("add", "bolt", "5")
        self.assertEqual(run("total")[1], "total: 15 units in 1 items\n")

    def test_list_marks_low(self):
        run("add", "nut", "2")
        self.assertIn("low", run("list")[1])


if __name__ == "__main__":
    unittest.main()
