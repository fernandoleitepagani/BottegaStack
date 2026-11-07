---
Expect: CHANGES
Keyword: injection
Split: test
---

# 007: SQL injection

## Spec excerpt

Search must accept a user-supplied term and return matching rows.

## Diff

```diff
- const rows = await db.query("SELECT * FROM posts WHERE title = ?", [term]);
+ const rows = await db.query(`SELECT * FROM posts WHERE title = '${term}'`);
```
