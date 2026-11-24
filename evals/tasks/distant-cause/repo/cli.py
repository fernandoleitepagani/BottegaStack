"""Usage: python3 cli.py EMAIL NAME [LANG]"""
import sys

import notify
import store


def main(argv):
    email, name = argv[0], argv[1]
    lang = argv[2] if len(argv) > 2 else "en"
    store.add_user(email, name, lang)
    print(notify.send_welcome(email)["body"])


if __name__ == "__main__":
    main(sys.argv[1:])
