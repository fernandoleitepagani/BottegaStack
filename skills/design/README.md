# Design skills

UI/UX skills used when a PaganiStack job is design-heavy. They are loaded on
demand. The review lenses stay under `product-verification/` and
`code-quality/`.

## What is here

| Skill | Source | Why |
|---|---|---|
| `design-taste-frontend` | [leonxlnx/taste-skill](https://github.com/leonxlnx/taste-skill) | Anti-generic page skill. Deals researched directions and measures the result in a real browser. |
| `frontend-design` | [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Anthropic's design-lead skill: distinctive identity, typography, palette, copy. |
| `mobile-app-ui-design` | [ceorkm/mobile-app-ui-design](https://github.com/ceorkm/mobile-app-ui-design) | MIT mobile UI/UX principles: thumb zones, 8-point spacing, 60/30/10 colour, peak-end rule. |
| `openui` | [thesysdev/openui](https://github.com/thesysdev/openui) | Generative UI and agent-rendered interfaces. |
| `emil-design-eng` | [emilkowalski/skills](https://github.com/emilkowalski/skills) | Design engineering taste: polish, component behaviour, animation decisions. |

`web-design-guidelines` lives under `product-verification/` because it is a
compliance pass, not a design generator.

## Removed

- `design-mobile-apps` and `sleek-design-mobile-apps` are the paid Sleek API
  skill. They require `SLEEK_API_KEY` and a paid plan. They are not included.
- `ui.sh` is paid and invite-only. Not included.
- `typeui.sh` and `ui-skills.com` are registries, not single skills.

## How to use them

- Landing page or marketing site: `design-taste-frontend`, then
  `frontend-design` for a stronger point of view.
- App screen or dashboard: `design-taste-frontend` app-screen reference, then
  `emil-design-eng` for interaction polish.
- Mobile app: `mobile-app-ui-design`.
- Compliance pass: `web-design-guidelines`.
- Generative interface: `openui`.
- Motion and micro-interactions: `emil-design-eng`.

## Requirements

- `design-taste-frontend` needs Node 22+ and Chrome, Edge, or Chromium for its
  inspector. Its `assets.mjs` needs network access.
- `web-design-guidelines` fetches the current rules from Vercel at review time.

## Attribution

Each skill keeps its upstream `SKILL.md` and, where present, its license and
README. If you edit a skill, rename it so it does not masquerade as the upstream
version.
