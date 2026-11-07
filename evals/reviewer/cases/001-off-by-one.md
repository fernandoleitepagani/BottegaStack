---
Expect: CHANGES
Keyword: bounds
Split: train
---

# 001: Off-by-one

## Spec excerpt

The list must render every item exactly once.

## Diff

```diff
- for (let i = 0; i < items.length; i++) {
+ for (let i = 0; i <= items.length; i++) {
    render(items[i]);
  }
```
