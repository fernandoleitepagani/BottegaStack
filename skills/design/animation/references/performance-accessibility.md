# Performance and accessibility

## Performance

The goal is 60fps: about 16ms per frame for everything.

**Cheap (compositor):** `transform`, `opacity`, and usually `filter` and
`clip-path`.

**Expensive:** `width`, `height`, `top`, `left`, `margin`, `padding` (layout),
and `box-shadow`, `background`, `border-radius` on large areas (paint). To
animate a shadow, fade the opacity of a pseudo-element that holds it.

**`will-change`:** add it only after you see stutter on the first frame, name
the exact property (`will-change: transform`), and remove it from elements that
never animate. Each one costs memory for a layer. The old
`translateZ(0)` trick does the same with less control.

**Check it:** DevTools Performance panel (long frames, layout shifts), Rendering
panel (paint flashing, layer borders), and the Animations panel to replay at
10% speed.

**Common issues:**

| Symptom | Likely cause |
|---|---|
| Jank on first frame | missing layer; try `will-change` on that property |
| Jank throughout | animating layout properties |
| Blurry text after scale | text rasterised on a scaled layer; end at `scale(1)` |
| Many items stutter | too many animated elements; animate the container |
| Everything flashes on theme change | colour transitions firing at once; disable transitions during the swap |

## Accessibility

**Reduced motion** is a requirement, not polish. Some people get dizzy or
nauseous from movement.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Prefer the reverse: write movement inside
`@media (prefers-reduced-motion: no-preference)` so it is opt-in, and keep an
opacity fade for the reduced case instead of a hard cut.

In React with Motion:

```tsx
<MotionConfig reducedMotion="user">{app}</MotionConfig>
// or per component
const reduce = useReducedMotion();
<motion.div animate={{ x: reduce ? 0 : 100, opacity: 1 }} />
```

`MotionConfig reducedMotion`: `"user"` follows the OS, `"always"` forces it,
`"never"` ignores it.

**Guidelines:**

- Motion is never the only signal; pair it with colour, icon, or text.
- Nothing flashes more than three times a second.
- Anything moving for more than five seconds needs pause or stop.
- Parallax, zoom, and large slides are the worst offenders; drop them under
  reduced motion.

**Focus:** after a modal opens, move focus into it once it is visible; on close,
return focus to the trigger. Do not let an exit animation trap focus on an
element that is leaving.

**Test it:** toggle "Reduce motion" in the OS, or emulate
`prefers-reduced-motion` in DevTools Rendering.
