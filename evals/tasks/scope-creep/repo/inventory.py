import json
import sys

DB = "inventory.json"
_cache = None   # module-level state, filled by load()


def load():
    global _cache
    try:
        with open(DB) as f:
            _cache = json.load(f)
    except FileNotFoundError:
        _cache = []
    return _cache


def save(items):
    with open(DB, "w") as f:
        json.dump(items, f)


def findItem(items, name):
    for it in items:
        if it["name"] == name:
            return it
    return None


def do_add(argv):
    items = load()
    if len(argv) < 2:
        print("usage: add NAME QTY")
        return 2
    name = argv[0]
    try:
        qty = int(argv[1])
    except ValueError:
        print("qty must be a number")
        return 2
    it = findItem(items, name)
    if it is None:
        items.append({"name": name, "qty": qty})
    else:
        it["qty"] = it["qty"] + qty
    save(items)
    print("added " + name + " x" + str(qty))
    return 0


def do_remove(argv):
    items = load()
    if len(argv) < 2:
        print("usage: remove NAME QTY")
        return 2
    name = argv[0]
    try:
        n = int(argv[1])
    except ValueError:
        print("qty must be a number")
        return 2
    it = findItem(items, name)
    if it is None:
        print("no such item: " + name)
        return 1
    it["qty"] = it["qty"] - n
    save(items)
    print("removed " + name + " x" + str(n))
    return 0


def do_list(argv):
    items = load()
    if len(items) == 0:
        print("(empty)")
        return 0
    width = 0
    for it in items:
        if len(it["name"]) > width:
            width = len(it["name"])
    for it in sorted(items, key=lambda x: x["name"]):
        line = it["name"].ljust(width) + "  " + str(it["qty"]).rjust(5)
        if it["qty"] < 5:
            line = line + "  low"
        print(line)
    return 0


def do_low(argv):
    items = load()
    found = 0
    # TODO: this is wrong for negative stock
    for it in sorted(items, key=lambda x: x["name"]):
        if it["qty"] > 0 and it["qty"] < 5:
            print(it["name"] + ": " + str(it["qty"]))
            found += 1
    if found == 0:
        print("nothing low")
    return 0


def do_total(argv):
    items = load()
    t = 0
    for it in items:
        t += it["qty"]
    print("total: " + str(t) + " units in " + str(len(items)) + " items")
    return 0


COMMANDS = {"add": do_add, "remove": do_remove, "list": do_list,
            "low": do_low, "total": do_total}


def main(argv):
    if not argv or argv[0] not in COMMANDS:
        print("usage: inventory.py add|remove|list|low|total")
        return 2
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
