import json
import sys

DB = "todos.json"


def load():
    try:
        with open(DB) as f:
            return json.load(f)
    except FileNotFoundError:
        return []


def save(items):
    with open(DB, "w") as f:
        json.dump(items, f)


def main(argv):
    items = load()
    if argv[:1] == ["add"]:
        items.append({"title": " ".join(argv[1:]), "done": False})
        save(items)
    elif argv[:1] == ["done"]:
        items[int(argv[1])]["done"] = True
        save(items)
    elif argv[:1] == ["list"]:
        only = {"--pending": False, "--done": True}.get(argv[1] if len(argv) > 1 else "")
        for i, item in enumerate(items):
            if only is not None and item["done"] != only:
                continue
            print(f"{i} [{'x' if item['done'] else ' '}] {item['title']}")
    else:
        print("usage: todo.py add <title> | done <n> | list")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
