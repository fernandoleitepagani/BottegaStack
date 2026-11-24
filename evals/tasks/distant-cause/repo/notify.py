"""Builds emails and 'sends' them into the outbox."""
import store
import templates

OUTBOX = []


def send(email, template):
    user = store.get_user(email)
    body = templates.render(template, lang=user["lang"]).format(name=user["name"])
    msg = {"to": email, "subject": template, "body": body}
    OUTBOX.append(msg)
    return msg


def send_welcome(email):
    return send(email, "welcome")
