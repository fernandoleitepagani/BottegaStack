---
Expect: PASS
Keyword: none
Split: train
---

# 004: Clean small refactor

## Spec excerpt

Rename `getUser` to `findUser` and update all call sites. Behavior unchanged.

## Diff

```diff
- export function getUser(id) { return db.users.find(id); }
+ export function findUser(id) { return db.users.find(id); }
```
```diff
- import { getUser } from "./users";
+ import { findUser } from "./users";
```
