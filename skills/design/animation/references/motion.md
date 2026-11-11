# Motion (formerly Framer Motion)

Install with the project's package manager: `motion` (import from
`motion/react`). Older projects use `framer-motion` with the same API.

## Basics

Any HTML or SVG element has a `motion.*` twin.

| Prop | Purpose |
|---|---|
| `initial` | starting values (`false` skips the mount animation) |
| `animate` | target values; changes animate automatically |
| `exit` | values while leaving (needs `AnimatePresence`) |
| `transition` | duration, ease, delay, or spring settings |
| `whileHover` / `whileTap` / `whileFocus` / `whileInView` | gesture states |
| `variants` | named states shared with children |
| `layout` / `layoutId` | animate layout changes and shared elements |

## AnimatePresence

Keeps a removed child mounted until its `exit` finishes.

- The direct child needs a stable, unique `key`.
- `mode="wait"` finishes the exit before the next enter (step flows).
- `mode="popLayout"` lets surrounding layout move immediately.
- `initial={false}` stops the first child animating in on page load.
- `custom` passes data (for example a direction) to exit variants that are
  functions, so "back" and "next" slide opposite ways.

```tsx
<AnimatePresence mode="wait" custom={dir} initial={false}>
  <motion.div key={step} custom={dir}
    variants={{ enter: (d) => ({ x: d * 40, opacity: 0 }), center: { x: 0, opacity: 1 }, exit: (d) => ({ x: d * -40, opacity: 0 }) }}
    initial="enter" animate="center" exit="exit" />
</AnimatePresence>
```

## Variants

Named states propagate to children, which lets a parent orchestrate them:
`staggerChildren`, `delayChildren`, `when: "beforeChildren"`.

## Layout

- `layout` animates size and position changes caused by re-render, using
  transforms (cheap). Add `layout` to children too, or text stretches.
- `layoutId` links two elements across renders; Motion morphs one into the other
  (tab pills, card -> detail view).
- Wrap independent groups in `LayoutGroup` so sibling components coordinate.
- Animating to `height: auto`: measure the content (ResizeObserver or a
  `useMeasure` hook) and animate the measured number.

## Gestures

`whileHover`, `whileTap`, and `drag` (`drag="x"`, `dragConstraints`,
`dragElastic`, `onDragEnd` with `info.offset` and `info.velocity` to decide
dismissals by distance or speed).

## Hooks

| Hook | Use |
|---|---|
| `useMotionValue` | a value that updates without re-rendering React |
| `useTransform` | map one motion value into another (x -> rotate) |
| `useSpring` | smooth a motion value with a spring |
| `useScroll` | scroll progress for scroll-linked effects |
| `useInView` | true once an element enters the viewport |
| `useReducedMotion` | the user's reduced-motion preference |
| `useAnimate` | imperative sequences |

## Transitions

```ts
{ duration: 0.25, ease: [0.23, 1, 0.32, 1] }
{ type: "spring", stiffness: 400, damping: 30 }
{ type: "spring", duration: 0.3, bounce: 0 }
{ opacity: { duration: 0.15 }, default: { type: "spring", bounce: 0 } } // per property
```

Arrays animate through keyframes: `animate={{ x: [0, -6, 6, 0] }}` with `times`.
