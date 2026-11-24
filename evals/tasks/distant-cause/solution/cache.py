"""Tiny memoize decorator."""
import functools


def memoize(fn):
    store = {}

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        key = (args, tuple(sorted(kwargs.items())))
        if key not in store:
            store[key] = fn(*args, **kwargs)
        return store[key]

    wrapper.cache = store
    return wrapper
