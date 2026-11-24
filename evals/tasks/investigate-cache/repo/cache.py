import time


class TTLCache:
    def __init__(self, ttl_seconds):
        self.ttl = ttl_seconds
        self.store = {}

    def set(self, key, value):
        self.store[key] = (value, time.time())

    def get(self, key):
        if key not in self.store:
            return None
        value, written = self.store[key]
        if time.time() - written > self.ttl * 60:
            del self.store[key]
            return None
        return value
