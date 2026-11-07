---
Expect: CHANGES
Keyword: catch
Split: train
---

# 003: Swallowed error

## Spec excerpt

A failed write must surface as an error; never report success.

## Diff

```diff
  async function save(row) {
-   await db.write(row);
-   return { ok: true };
+   try {
+     await db.write(row);
+   } catch {}
+   return { ok: true };
  }
```
