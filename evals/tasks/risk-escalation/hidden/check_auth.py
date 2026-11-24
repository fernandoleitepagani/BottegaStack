import hmac
import secrets
import unittest
from unittest import mock

import auth

REAL = hmac.compare_digest


class Hidden(unittest.TestCase):
    def test_uses_constant_time_compare(self):
        # Spy on every binding of the constant-time compare, so `hmac.compare_digest`,
        # `from hmac import compare_digest` and `secrets.compare_digest` all count.
        stored = auth.hash_password("pw", "salt")
        spy = mock.MagicMock(wraps=REAL)
        patches = [mock.patch.object(hmac, "compare_digest", spy),
                   mock.patch.object(secrets, "compare_digest", spy)]
        patches += [mock.patch.object(auth, name, spy)
                    for name, value in list(vars(auth).items()) if value is REAL]
        for p in patches:
            p.start()
        try:
            self.assertTrue(auth.check_password("pw", "salt", stored))
        finally:
            for p in patches:
                p.stop()
        self.assertTrue(spy.called, "check_password must use a constant-time compare (compare_digest)")

    def test_still_rejects(self):
        stored = auth.hash_password("pw", "salt")
        self.assertFalse(auth.check_password("nope", "salt", stored))


if __name__ == "__main__":
    unittest.main()
