# elder-assistant

## Code conventions

### One type per file
Each class, record, interface, or enum gets its own file. Never put multiple types in the same file.

### English only
All code must be in English: variable names, method names, comments, exception messages, validation error messages, log messages, string constants. No Portuguese anywhere in the codebase.

### Folder organisation
Group related files into subfolders when a concept has multiple files. For example, request/response contracts live in a `Contracts/` subfolder alongside the service interface and validators that use them.

### Use constructors, not object initialisers
Initialise entities and value objects through constructors, not object initialisers. Add a `protected` parameterless constructor alongside the public one to keep EF Core happy.

### Never use DbContext directly in services
Services must not depend on `DbContext`. Wrap all database operations in a manager class (e.g. `RefreshTokenManager`) and inject that instead.

### Try to use managers related to their services
If, for example, on User service and need the Car manager, call Car service instead.

# Design rules

## Who uses this
Adult children (30–55) coordinating a parent's care, often stressed, on their phone,
in short moments. The elder is NOT a user. Optimize for: "what needs my attention
right now?" in under 5 seconds.

## Feel
Calm, warm, trustworthy. Closer to a good health/banking app than a startup dashboard.
Reassuring, never alarming. No playful gimmicks, no stock-illustration cheeriness.

## Visual language
- Palette: warm off-white background, one deep primary (muted teal or blue-green),
  one soft accent. Semantic colors only for status: green = done, amber = due soon,
  red = overdue/urgent. Never rely on color alone (add icon + label).
- Type: one humanist sans (e.g. Inter/Source Sans) with a clear scale
  (12/14/16/20/28). Body min 16px. Strong weight contrast for hierarchy.
- Spacing: 8px grid. Generous padding. Cards with 12–16px radius, soft shadow.
- Touch targets ≥ 48px. Contrast WCAG AA minimum.

## UX principles
- Home = "today": next medication, next appointment, anything overdue, latest sibling update.
- Every screen has one primary action.
- Medication taken/missed must be 1 tap to log, with undo.
- Empty, loading, error and offline states designed for every screen.
- Plain language, no jargon. Portuguese-first copy (pt-PT), not translated-feeling.
- Sensitive data (health): show privacy cues, confirm destructive actions.
- Multi-carer: always show who did/changed what and when.

## Process
After building a screen: run it, screenshot it, critique against these rules, fix, repeat.