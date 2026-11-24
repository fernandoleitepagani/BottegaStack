import unittest

import cache
import notify
import store
import templates


class Hidden(unittest.TestCase):
    def setUp(self):
        store.USERS.clear()
        notify.OUTBOX.clear()

    def test_language_per_user_en_first(self):
        store.add_user("e@x.com", "Eve", "en")
        store.add_user("p@x.com", "Paulo", "pt")
        self.assertEqual(notify.send_welcome("e@x.com")["body"], "Welcome, Eve!")
        self.assertEqual(notify.send_welcome("p@x.com")["body"], "Bem-vindo, Paulo!")

    def test_language_per_user_pt_first(self):
        store.add_user("p@x.com", "Paulo", "pt")
        store.add_user("e@x.com", "Eve", "en")
        self.assertEqual(notify.send_welcome("p@x.com")["body"], "Bem-vindo, Paulo!")
        self.assertEqual(notify.send_welcome("e@x.com")["body"], "Welcome, Eve!")

    def test_goodbye_language(self):
        store.add_user("p@x.com", "Paulo", "pt")
        store.add_user("e@x.com", "Eve", "en")
        self.assertEqual(notify.send("e@x.com", "goodbye")["body"], "Goodbye, Eve.")
        self.assertEqual(notify.send("p@x.com", "goodbye")["body"], "Adeus, Paulo.")

    def test_memoize_distinguishes_kwargs(self):
        @cache.memoize
        def f(a, b=1):
            return (a, b)
        self.assertEqual(f(1, b=2), (1, 2))
        self.assertEqual(f(1, b=3), (1, 3))
        self.assertEqual(f(1), (1, 1))

    def test_memoize_still_caches(self):
        calls = []

        @cache.memoize
        def f(a, b=1):
            calls.append(1)
            return a + b
        f(1, b=2)
        f(1, b=2)
        f(1)
        f(1)
        self.assertEqual(len(calls), 2)

    def test_render_cached_for_identical_requests(self):
        before = templates.RENDER_CALLS
        templates.render("welcome", lang="pt")
        templates.render("welcome", lang="pt")
        templates.render("welcome", lang="en")
        templates.render("welcome", lang="en")
        self.assertLessEqual(templates.RENDER_CALLS - before, 2)

    def test_send_behavior_unchanged(self):
        store.add_user("a@x.com", "Ann", "pt")
        msg = notify.send_welcome("a@x.com")
        self.assertEqual(msg, {"to": "a@x.com", "subject": "welcome", "body": "Bem-vindo, Ann!"})
        self.assertEqual(notify.OUTBOX, [msg])
        with self.assertRaises(KeyError):
            notify.send_welcome("nobody@x.com")


if __name__ == "__main__":
    unittest.main()
