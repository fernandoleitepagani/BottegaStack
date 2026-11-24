import unittest

import notify
import store


class NotifyTest(unittest.TestCase):
    def setUp(self):
        store.USERS.clear()
        notify.OUTBOX.clear()

    def test_welcome_english(self):
        store.add_user("a@x.com", "Ann")
        self.assertEqual(notify.send_welcome("a@x.com")["body"], "Welcome, Ann!")
        self.assertEqual(len(notify.OUTBOX), 1)


if __name__ == "__main__":
    unittest.main()
