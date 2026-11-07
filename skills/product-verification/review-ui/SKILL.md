---
name: review-ui
description: Review a PaganiStack change for visual consistency, responsive layout, spacing, contrast, and design-system fit. Use by the UI reviewer subagent.
---

# PaganiStack UI Review

You review the visual result of one job. Your prompt gives the job folder, the
spec, the build reports, `checks.md`, and the diff. You write exactly one file,
`pagani/jobs/<id>/round-<N>/review-ui.md`. You never edit code.

## Read

1. `AGENTS.md`, `GLOSSARY.md`, and `docs/ui-guidelines.md` if it exists.
2. `spec.md` and the build reports.
3. The styling the change should match: theme or design-token config, global
   stylesheets, and neighbouring components.
4. The diff.
5. On round 2+, your own previous review. Check whether each finding was fixed.

## Look at it

Use the `verification` skill. If the change appears on a page, start the dev
server on a free port and screenshot at desktop and phone widths. Do not sign in
or submit forms unless the spec says so. Close the browser session and stop the
dev server when done. If no browser tool is available, say so and review the
code and styles instead.

## What to look for

- It looks like it belongs in the app: the same colours, type scale, spacing,
  radii, backgrounds, and shadows as the components around it.
- It uses the existing styling system and classes. Flag new one-off CSS or
  hard-coded colours where a theme value exists.
- Alignment, spacing rhythm, and hierarchy hold up. Nothing overflows at phone
  width.
- Text contrast is readable.
- Interactive states look right: hover, focus, disabled, loading.

Matters of taste go under **Notes**, not **Findings**.

## Write `round-<N>/review-ui.md`

```markdown
VERDICT: PASS | CHANGES

## Summary
Three to five bullets.

## Findings
1. <path:line or page> — what looks wrong — the fix you want — evidence.

## Verified
The pages, widths, and screenshots you checked.

## Risks

## Notes
Optional.
```

- The first line must be exactly `VERDICT: PASS` or `VERDICT: CHANGES`.
- Use `CHANGES` only for visible inconsistencies or breakage.
- Under Findings, write "None." when there are none.

## Report

```
VERDICT: PASS | CHANGES
FINDINGS: <count>
WORST: <one line, or "none">
```

## Gotchas

- Reviewing the code instead of the rendered page.
- Only checking desktop width. Check phone width too.
- Missing empty, loading, error, hover, focus, and disabled states.
- Calling a contrast or overflow issue a matter of taste.
- Screenshotting before the page has hydrated.
