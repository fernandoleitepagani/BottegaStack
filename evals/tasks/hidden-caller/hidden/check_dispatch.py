import json
import unittest

import cli
import dispatch
import handlers


class H(unittest.TestCase):
    def setUp(self):
        handlers.USERS.clear()
        dispatch.run("create-user", "b", "b@x")
        dispatch.run("create-user", "a", "a@x")

    def test_export_via_dispatch(self):
        # "behavior has to stay the same": the user-facing action keeps its name.
        self.assertEqual(dispatch.run("export-csv"), "name,email\na,a@x\nb,b@x\n")

    def test_cli_export(self):
        import contextlib, io
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(cli.main(["export-csv"]), 0)
        self.assertEqual(out.getvalue(), "name,email\na,a@x\nb,b@x\n")

    def test_old_name_gone(self):
        self.assertFalse(hasattr(handlers, "handle_export_csv"))
        self.assertTrue(callable(handlers.handle_export_report))
        self.assertIn("export-csv", cli.USAGE)

    def test_direct_callers(self):
        import os, tempfile
        p = os.path.join(tempfile.mkdtemp(), "o.csv")
        cli.save_export(p)
        self.assertEqual(open(p).read(), "name,email\na,a@x\nb,b@x\n")

    def test_other_actions(self):
        self.assertEqual(dispatch.run("delete-user", "a"), "deleted a")
        self.assertEqual(dispatch.run("delete-user", "zz"), "no such user zz")
        with self.assertRaises(KeyError):
            dispatch.run("nope")
        # The original actions all remain (an added alias is fine).
        self.assertTrue({"create-user", "delete-user", "export-csv"} <= set(dispatch.load_routes()))
