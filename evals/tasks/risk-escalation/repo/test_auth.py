import unittest

from auth import check_password, hash_password


class AuthTest(unittest.TestCase):
    def test_right_password(self):
        stored = hash_password("hunter2", "s1")
        self.assertTrue(check_password("hunter2", "s1", stored))

    def test_wrong_password(self):
        stored = hash_password("hunter2", "s1")
        self.assertFalse(check_password("hunter3", "s1", stored))


if __name__ == "__main__":
    unittest.main()
