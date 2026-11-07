---
Expect: PASS
Keyword: none
Split: test
---

# 006: Clean test-only change

## Spec excerpt

Add a test for an existing behavior. No production code changes.

## Diff

```diff
+ test("rejects an empty name", () => {
+   expect(validateName("")).toBe(false);
+ });
```
