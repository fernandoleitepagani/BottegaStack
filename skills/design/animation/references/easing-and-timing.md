# Easing and timing

## Why easing matters

Real objects speed up and slow down. Linear motion looks mechanical except for
opacity, colour, and things that spin forever (spinners).

| Curve | Feels like | Use for |
|---|---|---|
| ease-out | starts fast, settles | things arriving, responses to a click |
| ease-in | starts slow, leaves fast | things leaving for good |
| ease-in-out | slow, fast, slow | things moving from A to B on screen |
| ease | a softer ease-in-out | small hover changes |
| linear | constant | opacity fades, progress, rotation |

ease-in on an entrance feels laggy because the first frames barely move. Prefer
ease-out for anything the user triggered.

## Cubic bezier

`cubic-bezier(x1, y1, x2, y2)` sets two control points of a curve from (0,0) to
(1,1). x is time, y is progress. A large y1 early means a fast start.

```css
--ease-out-quad:   cubic-bezier(.25, .46, .45, .94);
--ease-out-cubic:  cubic-bezier(.33, 1, .68, 1);
--ease-out-quint:  cubic-bezier(.23, 1, .32, 1);
--ease-in-out-cubic: cubic-bezier(.645, .045, .355, 1);
--ease-in-cubic:   cubic-bezier(.32, 0, .67, 0);
```

The built-in keywords are weak; the stronger custom curves read as more deliberate.

## Durations

| Kind | Duration |
|---|---|
| Tooltips, hovers, small toggles | 100-150ms |
| Dropdowns, popovers, buttons | 150-250ms |
| Modals, drawers, sheets | 200-350ms |
| Page or route transitions | 300-500ms |

- Bigger distance or bigger element -> a little longer.
- Exits ~75% of the entrance.
- Mobile can run ~20% faster than desktop.
- Anything over 500ms needs a reason.

## Springs

A spring has no fixed duration; it settles based on physics and keeps velocity
when retargeted, so it handles interruptions well.

| Parameter | Effect |
|---|---|
| stiffness | higher = faster, snappier |
| damping | higher = less overshoot |
| mass | higher = heavier, slower |

```ts
const snappy = { type: "spring", stiffness: 500, damping: 30 };
const smooth = { type: "spring", stiffness: 300, damping: 30 };
const soft   = { type: "spring", stiffness: 150, damping: 20 };
// Duration-based: easier to reason about
const tidy   = { type: "spring", duration: 0.3, bounce: 0 };
```

Keep bounce at 0 for interface chrome; reserve bounce for playful moments.

## When not to animate

- Actions repeated constantly (typing, keyboard list navigation, command palettes).
- When it delays the user getting what they asked for.
- When the motion carries no information about what changed.
- When the user prefers reduced motion (fade or skip instead).
