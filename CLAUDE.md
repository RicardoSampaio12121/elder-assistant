# elder-assistant

## Code conventions

### One type per file
Each class, record, interface, or enum gets its own file. Never put multiple types in the same file.

### English only
All code must be in English: variable names, method names, comments, exception messages, validation error messages, log messages, string constants. No Portuguese anywhere in the codebase.

### Folder organisation
Group related files into subfolders when a concept has multiple files. For example, request/response contracts live in a `Contracts/` subfolder alongside the service interface and validators that use them.
