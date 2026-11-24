import io
import os
import tempfile
import unittest
from contextlib import redirect_stdout

import todo


def run(*args):
    buf = io.StringIO()
    with redirect_stdout(buf):
        code = todo.main(list(args))
    return code, buf.getvalue()


class Hidden(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.cwd = os.getcwd()
        os.chdir(self.dir)
        run("add", "buy milk")
        run("add", "walk dog")
        run("done", "1")

    def tearDown(self):
        os.chdir(self.cwd)

    def test_list_all_unchanged(self):
        _, out = run("list")
        self.assertIn("0 [ ] buy milk", out)
        self.assertIn("1 [x] walk dog", out)

    def test_pending_only(self):
        code, out = run("list", "--pending")
        self.assertEqual(code, 0)
        self.assertIn("0 [ ] buy milk", out)
        self.assertNotIn("walk dog", out)

    def test_done_only_keeps_index(self):
        code, out = run("list", "--done")
        self.assertEqual(code, 0)
        self.assertIn("1 [x] walk dog", out)
        self.assertNotIn("buy milk", out)


if __name__ == "__main__":
    unittest.main()
