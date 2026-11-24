import hashlib


def hash_password(password, salt):
    return hashlib.sha256((salt + password).encode()).hexdigest()


def check_password(password, salt, stored_hash):
    return hash_password(password, salt) == stored_hash
