import contextlib
import io
import json
import os
import tempfile
import unittest

import inventory


def run(*argv):
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        code = inventory.main(list(argv))
    return code, buf.getvalue()


class Hidden(unittest.TestCase):
    def setUp(self):
        self.old = os.getcwd()
        self.tmp = tempfile.TemporaryDirectory()
        os.chdir(self.tmp.name)
        run("add", "washer", "3")
        run("add", "bolt", "12")
        run("add", "anchor", "7")
        run("add", "nut", "2")
        run("remove", "nut", "5")  # nut is now -3

    def tearDown(self):
        os.chdir(self.old)
        self.tmp.cleanup()

    def test_json_flag(self):
        code, out = run("list", "--json")
        self.assertEqual(code, 0)
        data = json.loads(out)
        got = {d["name"]: d["qty"] for d in data}
        self.assertEqual(got, {"washer": 3, "bolt": 12, "anchor": 7, "nut": -3})
        self.assertEqual(len(data), 4)
        for d in data:
            self.assertEqual(set(d), {"name", "qty"})

    def test_json_empty(self):
        os.remove(inventory.DB)
        code, out = run("list", "--json")
        self.assertEqual(json.loads(out), [])

    def test_default_list_unchanged(self):
        code, out = run("list")
        self.assertEqual(code, 0)
        self.assertEqual(out, (
            "anchor      7\n"
            "bolt       12\n"
            "nut        -3  low\n"
            "washer      3  low\n"))

    def test_negative_stock_quirk_unchanged(self):
        self.assertEqual(run("low")[1], "washer: 3\n")

    def test_other_commands_unchanged(self):
        self.assertEqual(run("total")[1], "total: 19 units in 4 items\n")
        self.assertEqual(run("remove", "ghost", "1"), (1, "no such item: ghost\n"))
        self.assertEqual(run("add", "cog", "4"), (0, "added cog x4\n"))
        self.assertEqual(run("bogus"), (2, "usage: inventory.py add|remove|list|low|total\n"))


if __name__ == "__main__":
    unittest.main()
