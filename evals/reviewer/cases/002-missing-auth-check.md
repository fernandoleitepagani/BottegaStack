---
Expect: CHANGES
Keyword: ownership
Split: train
---

# 002: Missing auth check

## Spec excerpt

Only the owner of a post may delete it.

## Diff

```diff
+ app.delete("/api/posts/:id", async (req, res) => {
+   await db.posts.delete(req.params.id);
+   res.status(204).end();
+ });
```
