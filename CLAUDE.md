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
