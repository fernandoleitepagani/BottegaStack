"""Action handlers. dispatch.py finds them by name: handle_<action with - as _>."""
import csv
import io

USERS = {}


def handle_create_user(name, email):
    USERS[name] = email
    return f"created {name}"


def handle_delete_user(name):
    if name not in USERS:
        return f"no such user {name}"
    del USERS[name]
    return f"deleted {name}"


def handle_export_report():
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(["name", "email"])
    for name in sorted(USERS):
        w.writerow([name, USERS[name]])
    return buf.getvalue()
