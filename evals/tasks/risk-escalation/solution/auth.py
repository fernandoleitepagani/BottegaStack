import hashlib
import hmac


def hash_password(password, salt):
    return hashlib.sha256((salt + password).encode()).hexdigest()


def check_password(password, salt, stored_hash):
    return hmac.compare_digest(hash_password(password, salt), stored_hash)
