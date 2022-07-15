## 1.2.0

- feat: upgrade libgit2 to 1.5.0

- feat: add ability to pass checkout options to `reset(...)` API method

- feat: add ability to pass options to `prune(...)` Worktree API method

- feat: add ability to pass options to `Merge.fileFromIndex(...)` API method

- feat: add ability to pass options to `addAll(...)` Index API method

- feat: add ability to pass options to `revert(...)` and `revertTo(...)` Commit API methods:

  - select parent to revert to for merge commits
  - merge options
  - checkout options

- chore: upgrade dependencies

## 1.1.2

- fix: lookup library in Flutter's .pub_cache folder

- feat: add ability to limit number of commits to walk in revision walk

## 1.1.1

- fix: lookup library in correct locations

- feat: add ability to pass optional notes location to `Note.list(...)` method

## 1.1.0

- feat: add ability to get and set libgit2 global options

- feat: upgrade Flutter version constraints to `>=3.0.0`

- feat: add ability to remove entries in index with `resetDefault(...)` method

- feat: add ability to compare objects (value based equality)

  Note: comparison of Repository objects have naive implementation. Comparison is based on repository path, and previously loaded into memory index, odb, etc. might be different. Use with caution.

## 1.0.0

- Initial release.
