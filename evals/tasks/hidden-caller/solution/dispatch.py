"""Run an action by name, using the routes listed in routes.json."""
import json
import os

import handlers

RENAMED = {"export-csv": "export-report"}
ROUTES_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "routes.json")


def load_routes():
    with open(ROUTES_PATH) as f:
        return json.load(f)["actions"]


def run(action, *args):
    if action not in load_routes():
        raise KeyError(f"unknown action: {action}")
    # An action can keep its public name while its handler is renamed.
    name = RENAMED.get(action, action)
    fn = getattr(handlers, "handle_" + name.replace("-", "_"))
    return fn(*args)
