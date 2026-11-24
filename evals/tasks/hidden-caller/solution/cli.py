"""Tiny command line front end."""
import sys

import dispatch
import handlers

USAGE = "usage: cli.py <action> [args]   actions: " + ", ".join(dispatch.load_routes())


def save_export(path):
    """Write the user export to a file; used by the nightly job."""
    with open(path, "w") as f:
        f.write(handlers.handle_export_report())
    return path


def main(argv):
    if not argv:
        print(USAGE)
        return 1
    try:
        print(dispatch.run(argv[0], *argv[1:]), end="")
    except KeyError as e:
        print(e)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
