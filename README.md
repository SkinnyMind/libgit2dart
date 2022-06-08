# libgit2dart

![Coverage](coverage_badge.svg)

**Dart bindings to libgit2**

libgit2dart package provides ability to use [libgit2](https://github.com/libgit2/libgit2) in Dart/Flutter.

Currently supported platforms are 64-bit Linux, MacOS and Windows on both Flutter and Dart VM.

- [Getting Started](#getting-started)
- [Usage](#usage)
  - [Repository](#repository)
  - [Commit](#commit)
  - [Tree and TreeEntry](#tree-and-treeentry)
  - [Tag](#tag)
  - [Blob](#blob)
  - [Commit Walker](#commit-walker)
  - [Index and IndexEntry](#index-and-indexentry)
  - [References and RefLog](#references-and-reflog)
  - [Branches](#branches)
  - [Diff](#diff)
  - [Patch](#patch)
  - [Config Files](#config-files)
  - [Checkout](#checkout)
  - [Merge](#merge)
  - [Stashes](#stashes)
  - [Worktrees](#worktrees)
  - [Submodules](#submodules)
- [Contributing](#contributing)
- [Development](#development)

## Getting Started

1. Add package as a dependency in your `pubspec.yaml`
2. Import:

```dart
import 'package:libgit2dart/libgit2dart.dart';
```

3. Verify installation (should return string with version of libgit2 shipped with package):

```dart
...
print(Libgit2.version);
...
```

**Note**: The following steps only required if you are using package in Dart application (Flutter application will have libgit2 library bundled automatically when you build for release).

After adding the package as dependency you should run:

```shell
dart run libgit2dart:setup
```

That'll copy the prebuilt libgit2 library for your platform into `.dart_tool/libgit2/<platform>/` which you'll need to add to the same folder as your executable after compilation.

If you upgrade the version of libgit2dart package in your dependencies you should run the following commands to have the latest libgit2 library for your platform to provide with your application:

```shell
dart run libgit2dart:setup clean
dart run libgit2dart:setup
```

## Usage

libgit2dart provides you ability to manage Git repository. You can read and write objects (commit, tag, tree and blob), walk a tree, access the staging area, manage config and lots more.

Let's look at some of the classes and methods (you can also check [example](example/example.dart)).

### Repository

#### Instantiation

You can instantiate a `Repository` class with a path to open an existing repository:

```dart
final repo = Repository.open('path/to/repository'); // => Repository
```

You can create new repository with provided path and optional `bare` argument if you want it to be bare:

```dart
final repo = Repository.init(path: 'path/to/folder', bare: true); // => Repository
```

You can clone the existing repository at provided url into local path:

```dart
final repo = Repository.clone(
  url: 'https://some.url/',
  localPath: 'path/to/clone/into',
); // => Repository
```

Also you can discover the path to the '.git' directory of repository if you provide a path to subdirectory:

```dart
Repository.discover(startPath: '/repository/lib/src'); // => '/repository/.git/'
```

Once the repository object is instantiated (`repo` in the following examples) you can perform various operations on it.

#### Accessing repository

```dart
// Boolean repository state values
repo.isBare; // => false
repo.isEmpty; // => true
repo.isHeadDetached; // => false
repo.isBranchUnborn; // => false
repo.isWorktree; // => false

// Path getters
repo.path; // => 'path/to/repository/.git/'
repo.workdir; // => 'path/to/repository/

// The HEAD of the repository
final ref = repo.head; // => Reference

// From returned ref you can get the 'name', 'target', target 'sha' and much more
ref.name; // => 'refs/heads/master'
ref.target; // => Oid
ref.target.sha; // => '821ed6e80627b8769d170a293862f9fc60825226'

// Looking up object with oid
final oid = repo['821ed6e80627b8769d170a293862f9fc60825226']; // => Oid
final commit = Commit.lookup(repo: repo, oid: oid); // => Commit
commit.message; // => 'initial commit'
```

#### Writing to repository

```dart
// Suppose you created a new file named 'new.txt' in your freshly initialized
// repository and you want to commit it.

final index = repo.index; // => Index
index.add('new.txt');
index.write();
final tree = Tree.lookup(repo: repo, oid: index.writeTree()); // => Tree

Commit.create(
  repo: repo,
  updateRef: 'refs/heads/master',
  message: 'initial commit\n',
  author: repo.defaultSignature,
  committer: repo.defaultSignature,
  tree: tree,
  parents: [], // empty list for initial commit, 1 parent for regular and 2+ for merge commits
); // => Oid
```

---

### Git Objects

There are four kinds of base object types in Git: **commits**, **trees**, **tags**, and **blobs**. libgit2dart have a corresponding class for each of these object types.

Lookups of these objects requires Oid object, which can be instantiated from provided SHA-1 string in two ways:

```dart
// Using alias on repository object with SHA-1 string that can be any length
// between 4 and 40 characters
final oid = repo['821ed6e'];

// Using named constructor from Oid class (rules for SHA-1 string length is
// the same)
final oid = Oid.fromSHA(repo: repo, sha: '821ed6e');
```

### Commit

Commit lookup and some of the getters of the object:

```dart
final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']); // => Commit

commit.message; // => 'initial commit\n'
commit.time; // => 1635869993 (seconds since epoch)
commit.author; // => Signature
commit.tree; // => Tree
```

### Tree and TreeEntry

Tree and TreeEntry lookup and some of their getters and methods:

```dart
final tree = Tree.lookup(repo: repo, oid: repo['a8ae3dd']); // => Tree

tree.entries; // => [TreeEntry, TreeEntry, ...]
tree.length; // => 3
tree.oid; // => Oid

// You can lookup single tree entry in the tree with index
final entry = tree[0]; // => TreeEntry

// You can lookup single tree entry in the tree with path to file
final entry = tree['some/file.txt']; // => TreeEntry

// Or you can lookup single tree entry in the tree with filename
final entry = tree['file.txt']; // => TreeEntry

entry.oid; // => Oid
entry.name // => 'file.txt'
entry.filemode // => GitFilemode.blob
```

You can also write trees with TreeBuilder:

```dart
final builder = TreeBuilder(repo: repo); // => TreeBuilder
builder.add(
  filename: 'file.txt',
  oid: index['file.txt'].oid,
  filemode: GitFilemode.blob,
);
final treeOid = builder.write(); // => Oid

// Perform commit using that tree in arguments
...
```

### Tag

Tag create and lookup methods and some of the object getters:

```dart
// Create annotated tag
final annotated = Tag.createAnnotated(
  repo: repo,
  tagName: 'v0.1',
  target: repo['821ed6e'],
  targetType: GitObject.commit,
  tagger: repo.defaultSignature,
  message: 'tag message',
); // => Oid

// Create lightweight tag
final lightweight = Tag.createLightweight(
  repo: repo,
  tagName: 'v0.1',
  target: repo['821ed6e'],
  targetType: GitObject.commit,
); // => Oid

// Lookup tag
final tag = Tag.lookup(repo: repo, oid: repo['f0fdbf5']); // => Tag

// Get list of all the tags names in repository
repo.tags; // => ['v0.1', 'v0.2']

tag.oid; // => Oid
tag.name; // => 'v0.1'
```

### Blob

Blob create and lookup methods and some of the object getters:

```dart
// Create a new blob from the file at provided path
final oid = Blob.createFromDisk(repo: repo, path: 'path/to/file.txt'); // => Oid

// Lookup blob
final blob = Blob.lookup(repo: repo, oid: repo['e69de29']); // => Blob

blob.oid; // => Oid
blob.content; // => 'content of the file'
blob.size; // => 19
```

---

### Commit Walker

There's two ways to traverse a set of commits. Through Repository object alias or by using RevWalk class for finer control:

```dart
// Traverse a set of commits starting at provided oid
final commits = repo.log(oid: repo['821ed6e']); // => [Commit, Commit, ...]

// Use RevWalk object to fine tune traversal
final walker = RevWalk(repo); // => RevWalk

// Set desired sorting (optional)
walker.sorting({GitSort.topological, GitSort.time});

// Push Oid for the starting point
walker.push(repo['821ed6e']);

// Hide commits if you are not interested in anything beneath them
walker.hide(repo['c68ff54']);

// Perform traversal
final commits = walker.walk(); // => [Commit, Commit, ...]
```

---

### Index and IndexEntry

Some methods and getters to inspect and manipulate the Git index ("staging area"):

```dart
// Initialize Index object
final index = repo.index; // => Index

// Get number of entries in index
index.length; // => 69

// Re-read the index from disk
index.read();

// Write an existing index object to disk
index.write();

// Iterate over index entries
for (final entry in index) {
  print(entry.path); // => 'path/to/file.txt'
}

// Get a specific entry
final entry = index['file.txt']; // => IndexEntry

// Stage using path to file or IndexEntry (updates existing entry if there is one)
index.add('new.txt');

// Unstage entry from index
index.remove('new.txt');
```

---

### References and RefLog

```dart
// Get names of all of the references that can be found in repository
final refs = repo.references; // => ['refs/heads/master', 'refs/tags/v0.1', ...]

// Lookup reference
final ref = Reference.lookup(repo: repo, name: 'refs/heads/master'); // => Reference

ref.type; // => ReferenceType.direct
ref.target; // => Oid
ref.name; // => 'refs/heads/master'

// Create reference
final ref = Reference.create(
  repo: repo,
  name: 'refs/heads/feature',
  target: repo['821ed6e'],
); // => Reference

// Update reference
ref.setTarget(repo['c68ff54']);

// Rename reference
Reference.rename(repo: repo, oldName: 'refs/heads/feature', newName: 'refs/heads/feature2');

// Delete reference
Reference.delete(repo: repo, name: 'refs/heads/feature2');

// Access the reflog
final reflog = ref.log; // => RefLog
final entry = reflog.first; // RefLogEntry

entry.message; // => 'commit (initial): init'
entry.committer; // => Signature
```

---

### Branches

```dart
// Get all the branches that can be found in repository
final branches = repo.branches; // => [Branch, Branch, ...]

// Get only local/remote branches
final local = repo.branchesLocal; // => [Branch, Branch, ...]
final remote = repo.branchesRemote; // => [Branch, Branch, ...]

// Lookup branch (lookups in local branches if no value for argument `type`
// is provided)
final branch = Branch.lookup(repo: repo, name: 'master'); // => Branch

branch.target; // => Oid
branch.isHead; // => true
branch.name; // => 'master'

// Create branch
Branch.create(repo: repo, name: 'feature', target: commit); // => Branch

// Rename branch
Branch.rename(repo: repo, oldName: 'feature', newName: 'feature2');

// Delete branch
Branch.delete(repo: repo, name: 'feature2');
```

---

### Diff

There is multiple ways to get the diff:

```dart
// Diff between index (staging area) and current working directory
final diff = Diff.indexToWorkdir(repo: repo, index: repo.index); // => Diff

// Diff between tree and index (staging area)
final diff = Diff.treeToIndex(repo: repo, tree: tree, index: repo.index); // => Diff

// Diff between tree and current working directory
final diff = Diff.treeToWorkdir(repo: repo, tree: tree); // => Diff

// Diff between tree and current working directory with index
final diff = Diff.treeToWorkdirWithIndex(repo: repo, tree: tree); // => Diff

// Diff between two tree objects
final diff = Diff.treeToTree(repo: repo, oldTree: tree1, newTree: tree2); // => Diff

// Diff between two index objects
final diff = Diff.indexToIndex(repo: repo, oldIndex: repo.index, newIndex: index); // => Diff

// Read the contents of a git patch file
final diff = Diff.parse(patch.text); // => Diff
```

Some methods for inspecting Diff object:

```dart
// Get the number of diff records
diff.length; // => 3

// Get the patch
diff.patch; // => 'diff --git a/modified_file b/modified_file ...'

// Get the DiffStats object of the diff
final stats = diff.stats; // => DiffStats
stats.insertions; // => 69
stats.deletions; // => 420
stats.filesChanged; // => 1

// Get the list of DiffDelta's containing file pairs with and old and new revisions
final deltas = diff.deltas; // => [DiffDelta, DiffDelta, ...]
final delta = deltas.first; // => DiffDelta
delta.status; // => GitDelta.modified
delta.oldFile; // => DiffFile
delta.newFile; // => DiffFile
```

---

### Patch

Some API methods to generate patch:

```dart
// Patch from difference between two blobs
final patch = Patch.fromBlobs(
  oldBlob: null, // empty blob
  newBlob: blob,
  newBlobPath: 'file.txt',
); // => Patch

// Patch from entry in the diff list at provided index position
final patch = Patch.fromDiff(diff: diff, index: 0); // => Patch
```

Some methods for inspecting Patch object:

```dart
// Get the content of a patch as a single diff text
patch.text; // => 'diff --git a/modified_file b/modified_file ...'

// Get the size of a patch diff data in bytes
patch.size(); // => 1337

// Get the list of hunks in a patch
patch.hunks; // => [DiffHunk, DiffHunk, ...]
```

---

### Config files

Some methods and getters of Config object:

```dart
// Open config file at provided path
final config = Config.open('path/to/config'); // => Config

// Open configuration file for repository
final config = repo.config; // => Config

// Get value of config variable
config['user.name'].value; // => 'Some Name'

// Set value of config variable
config['user.name'] = 'Another Name';

// Delete variable from the config
config.delete('user.name');
```

---

### Checkout

Perform different types of checkout:

```dart
// Update files in the index and the working directory to match the
// content of the commit pointed at by HEAD
Checkout.head(repo: repo);

// Update files in the working directory to match the content of the index
Checkout.index(repo: repo);

// Update files in the working directory to match the content of the tree
// pointed at by the reference target
Checkout.reference(repo: repo, name: 'refs/heads/master');

// Update files in the working directory to match the content of the tree
// pointed at by the commit
Checkout.commit(repo: repo, commit: commit);

// Perform checkout using various strategies
Checkout.head(repo: repo, strategy: {GitCheckout.force});

// Checkout only required files
Checkout.head(repo: repo, paths: ['some/file.txt']);
```

---

### Merge

Some API methods:

```dart
// Find a merge base between commits
final oid = Merge.base(
  repo: repo,
  commits: [commit1.oid, commit2.oid],
); // => Oid

// Merge commit into HEAD writing the results into the working directory
Merge.commit(repo: repo, commit: annotatedCommit);

// Cherry-pick the provided commit, producing changes in the index and
// working directory.
Merge.cherryPick(repo: repo, commit: commit);
```

---

### Stashes

```dart
// Get the list of all stashed states (first being the most recent)
repo.stashes; // => [Stash, Stash, ...]

// Save local modifications to a new stash
Stash.create(repo: repo, stasher: signature, message: 'WIP'); // => Oid

// Apply stash (defaults to last saved if index is not provided)
Stash.apply(repo: repo);

// Apply only specific paths from stash
Stash.apply(repo: repo, paths: ['file.txt']);

// Drop stash (defaults to last saved if index is not provided)
Stash.drop(repo: repo);

// Pop stash (apply and drop if successful, defaults to last saved
// if index is not provided)
Stash.pop(repo: repo);
```

---

### Worktrees

```dart
// Get list of names of linked worktrees
repo.worktrees; // => ['worktree1', 'worktree2'];

// Lookup existing worktree
Worktree.lookup(repo: repo, name: 'worktree1'); // => Worktree

// Create new worktree
final worktree = Worktree.create(
  repo: repo,
  name: 'worktree3',
  path: '/worktree3/path/',
); // => Worktree

// Get name of worktree
worktree.name; // => 'worktree3'

// Get path for the worktree
worktree.path; // => '/worktree3/path/';

// Lock and unlock worktree
worktree.lock();
worktree.unlock();

// Prune the worktree (remove the git data structures on disk)
worktree.prune();
```

---

### Submodules

Some API methods for submodule management:

```dart
// Get list with all tracked submodules paths
repo.submodules; // => ['Submodule1', 'Submodule2'];

// Lookup submodule
Submodule.lookup(repo: repo, name: 'Submodule'); // => Submodule

// Init and update
Submodule.init(repo: repo, name: 'Submodule');
Submodule.update(repo: repo, name: 'Submodule');

// Add submodule
Submodule.add(repo: repo, url: 'https://some.url', path: 'submodule'); // => Submodule
```

Some methods for inspecting Submodule object:

```dart
// Get name of the submodule
submodule.name; // => 'Submodule'

// Get path to the submodule
submodule.path; // => 'Submodule'

// Get URL for the submodule
submodule.url; // => 'https://some.url'

// Set URL for the submodule in the configuration
submodule.url = 'https://updated.url';
submodule.sync();
```

---

## Contributing

Fork libgit2dart, improve libgit2dart, send a pull request.

---

## Development

### Troubleshooting

If you are developing on Linux using non-Debian based distrib you might encounter these errors:

- Failed to load dynamic library: libpcre.so.3: cannot open shared object file: No such file or directory
- Failed to load dynamic library: libpcreposix.so.3: cannot open shared object file: No such file or directory

That happens because dynamic library is precompiled on Ubuntu and Arch/Fedora/RedHat names for those libraries are `libpcre.so` and `libpcreposix.so`.

To fix these errors create symlinks:

```shell
sudo ln -s /usr/lib64/libpcre.so /usr/lib64/libpcre.so.3
sudo ln -s /usr/lib64/libpcreposix.so /usr/lib64/libpcreposix.so.3
```

### Ffigen

To generate bindings with ffigen use (adjust paths to yours):

```bash
dart run ffigen --compiler-opts "-I/path/to/libgit2dart/libgit2/headers/ -I/lib64/clang/12.0.1/include"
```

### Running Tests

To run all tests and generate coverage report make sure to have activated packages and [lcov](https://github.com/linux-test-project/lcov) installed:

```sh
$ dart pub global activate coverage
$ dart pub global activate flutter_coverage_badge
```

And run:

```sh
$ ./coverage.sh
$ open coverage/index.html
```

---

## Licence

MIT. See [LICENSE](LICENSE) file for more information.
