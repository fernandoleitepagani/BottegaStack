import unittest

import cli
import handlers


class T(unittest.TestCase):
    def setUp(self):
        handlers.USERS.clear()

    def test_create_delete(self):
        self.assertEqual(handlers.handle_create_user("a", "a@x"), "created a")
        self.assertEqual(handlers.handle_delete_user("a"), "deleted a")

    def test_export_direct(self):
        handlers.handle_create_user("b", "b@x")
        self.assertEqual(handlers.handle_export_csv(), "name,email\nb,b@x\n")

    def test_save_export(self):
        import os, tempfile
        handlers.handle_create_user("c", "c@x")
        p = os.path.join(tempfile.mkdtemp(), "o.csv")
        cli.save_export(p)
        self.assertEqual(open(p).read(), "name,email\nc,c@x\n")


if __name__ == "__main__":
    unittest.main()
