---
name: code-like-joey
description: Use when writing any new code, before implementing any feature, function, or class
---

# code-like-joey

Joey's personal coding style. Apply these preferences to all new code regardless of language.

## Formatting

- 2-space indent
- Function parameters on a single line — no line-wrapping
- Trailing commas in multi-line objects/arrays
- Return types always explicit on exported functions

## Control Flow

Guard clauses and early returns over nested conditionals:

```ts
// ❌
function process(data) {
  if (data) {
    if (data.items.length > 0) {
      doWork(data);
    }
  }
}

// ✅
function process(data) {
  if (!data) return;
  if (data.items.length === 0) return;
  doWork(data);
}
```

Use `continue` in loops as the guard equivalent.

## Naming

| Context | Convention |
|---|---|
| Types, classes, schemas | `PascalCase` |
| Functions, variables, module namespaces | `camelCase` |
| Constants | `UPPER_CASE` |

Apply camelCase even in Python (matches JS convention).

## Imports (TypeScript)

Order: **External libs → workspace packages → local relatives**

```ts
import { format } from 'date-fns';                     // external
import { log } from '@my-org/core/logger';             // workspace
import { helper } from './utils.ts';                   // local
```

- Use `import * as X` for modules that export multiple things
- Use `import type` for type-only imports

## Types

- Derive types from Zod schemas via `z.infer` — never write separately:
  ```ts
  export const UserSchema = z.object({ id: z.number(), name: z.string() });
  export type User = z.infer<typeof UserSchema>;  // ✅ derived, not handwritten
  ```
- Use `.nullable().optional().default(null)` for optional API fields
- Use assertion functions as flow guards, not `try/catch` for control flow
- Avoid `any`; use `unknown` with type guards

## Functions & Classes

- Short functions — 10–30 lines target
- Classes only when state/lifecycle warrants it (not for grouping static methods)
- `readonly` on all immutable class fields
- If a function needs a comment to explain what it does, it's doing too much

## Comments

- Self-documenting names over comments — clear names first
- JSDoc only on public API functions (`@param`, `@returns`)
- `// TODO:` for known debt
- Explanatory comments only for non-obvious *why* (e.g. timezone semantics, retry logic)
- No narrative comments restating what the code does

## Tests

- Nested hierarchy: `Suite > Group > Case`
- Integration tests guarded by env var — skip in CI
- Use concrete fixture values as ground truth, not just `toBeDefined()`

## Usage with Subagent-Driven Development

When dispatching implementer subagents via `subagent-driven-development`, add this
line to the implementer prompt under `## Code Organization`:

> Load and follow the `code-like-joey` skill before writing any code.
