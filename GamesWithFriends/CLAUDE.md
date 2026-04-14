# CLAUDE.md

> **Source of truth: [`AGENTS.md`](./AGENTS.md).**
>
> This project uses `AGENTS.md` as the single cross-tool specification for any AI coding assistant (Claude Code, Cursor, Aider, etc.). `CLAUDE.md` deliberately contains no project rules of its own — everything lives in `AGENTS.md` so the two files cannot drift apart.

## How to use this repo as Claude Code

1. **Always read `AGENTS.md` first** — it has the stack, architecture, folder layout, coding rules, build commands, and workflows.
2. **Before any UI work, read `DESIGN_GUIDE.md`** — it is the authoritative UI / theme / component bible and is already written for a Claude Code audience.
3. **Check `DECISIONS.md`** — running log of architectural decisions and gotchas. Read when debugging. Append to it when you make a non-obvious choice the next session should inherit.
4. **When adding a new game**, follow the "Add a new game" workflow in `AGENTS.md` §7.1 — the single most-forgotten step is registering the game in `Features/GameHub/GameRegistry.swift`.

## Quick links

- Stack & architecture → `AGENTS.md` §1–3
- Coding rules (the non-negotiables) → `AGENTS.md` §5
- Build commands → `AGENTS.md` §6
- UI bible → `DESIGN_GUIDE.md`
- Running decision log → `DECISIONS.md`
- Game-specific specs → `LICENSE_PLATE_GAME_README.md`, `BorderHop_PRD.docx` (+ handoff + plan)

## When in doubt

Ask before:

- adding any external dependency,
- changing the `GameDefinition` protocol or `GameRegistry` shape,
- breaking a SwiftData `@Model` schema,
- touching `GamesWithFriendsApp.swift` app-level configuration.

See `AGENTS.md` §8 for the full list.
