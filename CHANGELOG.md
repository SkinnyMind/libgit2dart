## 1.1.0

- feat: add ability to get and set libgit2 global options

- feat: upgrade Flutter version constraints to `>=3.0.0`

- feat: add ability to remove entries in index with `resetDefault(...)` method

- feat: add ability to compare objects (value based equality).

  Note: comparison of Repository objects have naive implementation. Comparison is based on repository path, and previously loaded into memory index, odb, etc. might be different. Use with caution.

## 1.0.0

- Initial release.
