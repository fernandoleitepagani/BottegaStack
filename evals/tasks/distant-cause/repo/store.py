"""In-memory user store."""

USERS = {}


def add_user(email, name, lang="en"):
    USERS[email] = {"email": email, "name": name, "lang": lang}
    return USERS[email]


def get_user(email):
    return USERS[email]
