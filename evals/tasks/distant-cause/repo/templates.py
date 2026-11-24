"""Email templates."""
from cache import memoize

TEMPLATES = {
    "welcome": {
        "en": "Welcome, {name}!",
        "pt": "Bem-vindo, {name}!",
    },
    "goodbye": {
        "en": "Goodbye, {name}.",
        "pt": "Adeus, {name}.",
    },
}

RENDER_CALLS = 0  # real (uncached) renders, for monitoring


@memoize
def render(name, lang="en"):
    global RENDER_CALLS
    RENDER_CALLS += 1
    return TEMPLATES[name].get(lang, TEMPLATES[name]["en"])
