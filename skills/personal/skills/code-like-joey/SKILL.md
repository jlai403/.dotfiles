---
name: code-like-joey
description: Apply Joey's coding preferences when writing new code
---

# code-like-joey

Coding style for all new code regardless of language.

## Formatting

- 2-space indent
- Function parameters on single line
- Trailing commas in multi-line objects/arrays
- Explicit return types on exported functions

## Control Flow

Guard clauses and early returns over nested conditionals. `continue` as loop guard.

## Naming

Types/classes/schemas: `PascalCase`. Functions/variables/modules: `camelCase`. Constants: `UPPER_CASE`. Use camelCase even in Python.

## Imports (TypeScript)

Order: External → workspace packages → local relatives. Prefer `import type` for type-only imports.

## Types

Derive from Zod via `z.infer` — never handwritten. Use `.nullable().optional().default(null)` for optional fields. Prefer `unknown` with type guards over `any`.

## Functions & Classes

Target 10–30 lines per function. Classes only when state/lifecycle warrants it.

## Comments

Self-documenting names first. JSDoc only on public API. Comments explain non-obvious *why*, not what.

## Tests

Nested: Suite > Group > Case. Guard integration tests with env var. Use concrete fixture values, not just `toBeDefined()`.
