# Feature map

One row per feature the agent may need to reach and verify. Keep it current.

| Feature | Route / URL | How to reach | Seed / login | Expected visible result | Flow |
|---|---|---|---|---|---|
| Home | `/` | open the root URL | none | hero and primary navigation | `main` |
| Sign in | `/login` | click Sign in | test user | signed-in state | `login` |
| <feature> | <route> | <steps> | <data> | <what to see> | `docs/verify/flows/<name>.sh` |

## Notes

- Start the app with `scripts/verify start`.
- Run a flow with `scripts/verify flow <name>`.
- Record the evidence path in the build report.
