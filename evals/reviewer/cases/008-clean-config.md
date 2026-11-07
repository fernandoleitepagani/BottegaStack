---
Expect: PASS
Keyword: none
Split: test
---

# 008: Clean config change

## Spec excerpt

Add the new environment variable to the example file. No code changes.

## Diff

```diff
  DATABASE_URL=
+ CACHE_TTL_SECONDS=300
```
