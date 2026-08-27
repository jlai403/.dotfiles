---
name: code-like-joey
description: Apply coding preferences before any coding implementation. Must always load when writing code.
---

# code-like-joey

Coding style for all new code in any language. Defaults target TypeScript; adapt to the language (e.g. PEP 8 snake_case in Python).

## Formatting

- A repo's formatter/linter (eslint, prettier) wins; this skill fills gaps it doesn't cover
- 2-space indent
- Function parameters on single line
- Trailing commas in multi-line objects/arrays where the language supports it
- Explicit return types on exported functions

## Control Flow

Guard clauses and early returns over nested conditionals. `continue` as loop guard.

## Naming

Types/classes/schemas: `PascalCase`. Functions/variables/modules: `camelCase`. Constants: `UPPER_CASE`. Follow the language's conventions otherwise (e.g. snake_case in Python).

## Imports (TypeScript)

Order: External → workspace packages → local relatives. Prefer `import type` for type-only imports.

## Types

Prefer `unknown` with type guards over `any`. Where Zod defines a data schema, derive its type via `z.infer` — never handwritten; use `.nullable().optional().default(null)` for optional fields.

## Functions

Extract a fragment when its intent hides behind its implementation: if you must read a body to know what it does, name a function after that "what". Aim for small, intention-revealing functions — no line-count target. Classes only when state/lifecycle warrants it.

## Errors

Fail fast with descriptive messages at boundaries. Tolerate and skip non-critical per-item failures (e.g. `continue` past a bad entry, skip a corrupted record). Don't swallow critical errors; rethrow with context across service boundaries.

## Comments

Self-documenting names first. JSDoc only on public API. Comments explain non-obvious *why*, not what. Keep them tight — one or two sentences; a header comment is a paragraph, not an essay. Don't narrate incident history, alternatives considered, or restate what the code already shows.

## Tests

Nested: Suite > Group > Case. Guard integration tests with env var. Use concrete fixture values, not just `toBeDefined()`.
