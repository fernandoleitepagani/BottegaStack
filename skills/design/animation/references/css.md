# CSS animation

## Transforms

```css
transform: translate(10px, 20px);   /* or translateX / translateY */
transform: scale(1.05);
transform: rotate(45deg);
transform: translateY(-4px) scale(1.02);  /* order matters: right to left */
```

Modern browsers also accept the individual properties `translate`, `scale`, and
`rotate`, which can transition independently.

`transform-origin` sets the pivot. A popover should scale from the edge nearest
its trigger (`transform-origin: top left`), not from its centre. Radix and
similar libraries expose that origin as a CSS variable.

3D needs `perspective` on the parent (or `perspective()` in the transform) and
`backface-visibility: hidden` for card flips.

## Transitions

```css
.el {
  transition-property: opacity, transform;
  transition-duration: 200ms;
  transition-timing-function: var(--ease-out);
}
/* shorthand: property duration easing delay */
.el { transition: opacity 200ms var(--ease-out), transform 200ms var(--ease-out); }
```

Transitions run between two states and reverse cleanly if the state flips
mid-way. Use them for anything interactive.

Common shapes:

```css
.fade   { opacity: 0; transition: opacity 200ms; }   .fade.show   { opacity: 1; }
.slide  { transform: translateY(8px); opacity: 0; transition: transform 250ms var(--ease-out), opacity 250ms; }
.slide.show { transform: none; opacity: 1; }
```

For entry from `display: none`, use `@starting-style` plus
`transition-behavior: allow-discrete` where supported, or a presence library.

## Keyframes

```css
@keyframes rise {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: none; }
}
.title { animation: rise 400ms var(--ease-out) both; }
```

| Property | Note |
|---|---|
| `animation-delay` | stagger with `calc(var(--i) * 40ms)` |
| `animation-iteration-count` | `infinite` for loaders only |
| `animation-fill-mode` | `both` keeps the `from` state before start and `to` after end |
| `animation-play-state` | pause on hover or offscreen |

Put the hidden state in the `from` keyframe with `fill-mode: both`, not in the
base rule; otherwise the element stays hidden if the animation never runs.

Keyframes cannot be interrupted and reversed. Use them for one-shot sequences:
loaders, text reveals, attention pulses.

## clip-path

`clip-path` animates on the compositor in modern browsers and makes reveals
without layout shifts.

```css
.reveal { clip-path: inset(0 100% 0 0); transition: clip-path 400ms var(--ease-out); }
.reveal.show { clip-path: inset(0 0 0 0); }
.circle { clip-path: circle(0% at 50% 50%); }  /* -> circle(75% at 50% 50%) */
```

Uses: before/after image sliders (`inset(0 0 0 var(--pos))`), a tab highlight
that clips a duplicated "active" label row, and wipe transitions.
