# libgit2dart

**Dart bindings to libgit2**

libgit2dart package provides ability to use [libgit2](https://github.com/libgit2/libgit2) in Dart/Flutter.

Currently supported platforms are 64-bit Linux, MacOS and Windows on both Flutter and Dart VM.

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

After compiling the application you should run:

```shell
dart run libgit2dart:setup
```

That'll copy the prebuilt libgit2 library for your platform into `.dart_tool/libgit2/<platform>/` which you'll need to add to the same folder as your executable.

If you upgrade the version of libgit2dart package in your dependencies you should run the following commands to have the latest libgit2 library for your platform to provide with your application:

```shell
dart run libgit2dart:setup clean
dart run libgit2dart:setup
```

## Usage

libgit2dart provides you ability to manage Git repository. You can read and write objects (commit, tag, tree and blob), walk a tree, access the staging area, manage config and lots more.

**Important**: Most of the instantiated objects require to call `free()` method on them, when they are no longer needed, in order to release allocated memory and prevent memory leak.

Let's look at some of the classes and methods.

### Repository

#### Instantiation

You can instantiate a `Repository` class with a path to open an existing repository:

```dart
final repo = Repository.open('path/to/repository');
```

You can create new repository with provided path and optional `bare` argument if you want it to be bare:

```dart
final repo = Repository.init(path: 'path/to/folder', bare: true);
```

You can clone the existing repository at provided url into local path:

```dart
final repo = Repository.clone(
  url: 'https://some.url/',
  localPath: 'path/to/clone/into',
);
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
// Release memory allocated for Reference object when it's no longer needed
ref.free();

// Looking up object with oid
final oid = repo['821ed6e80627b8769d170a293862f9fc60825226']; // Oid
final commit = repo.lookupCommit(oid); // Commit
commit.message; // => 'initial commit'
// Release memory allocated for Commit object when it's no longer needed
commit.free();

// Release memory allocated for Repository object when it's no longer needed
repo.free();
```

#### Writing to repository

There is two ways to write to repository. Using methods from different classes (e.g., `Commit.create(...)`) or using aliases of those methods on repository object:

```dart
// Suppose you created a new file named 'new.txt' in your freshly initialized
// repository and you want to commit it.

final index = repo.index;
index.add('new.txt');
index.write();
final tree = repo.lookupTree(index.writeTree());

repo.createCommit(
  updateRef: 'refs/heads/master',
  message: 'initial commit\n',
  author: repo.defaultSignature,
  commiter: repo.defaultSignature,
  tree: tree,
  parents: [],
);

tree.free();
index.free();
repo.free();
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
// Lookup using alias on repository object
final commit = repo.lookupCommit(repo['821ed6e']); // => Commit

// Lookup using named constructor from Commit class
final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']); // => Commit

commit.message; // => 'initial commit\n'
commit.time; // => 1635869993 (seconds since epoch)
commit.author; // => Signature
commit.tree; // => Tree

// Release memory allocated for Commit object when it's no longer needed
commit.free();
```

### Tree and TreeEntry

Tree and TreeEntry lookup and some of their getters and methods:

```dart
// Lookup using alias on repository object
final tree = tree.lookupTree(repo['a8ae3dd']); // => Tree

// Lookup using named constructor from Tree class
final tree = Tree.lookup(repo: repo, oid: repo['a8ae3dd']); // => Tree

tree.entries; // => [TreeEntry, TreeEntry, ...]
tree.length; // => 3
tree.oid; // => Oid
tree.diffToWorkdir(); // => Diff

// You can lookup single tree entry in the tree with index
final entry = tree[0]; // => TreeEntry

// You can lookup single tree entry in the tree with path to file
final entry = tree['some/file.txt']; // => TreeEntry

// Or you can lookup single tree entry in the tree with filename
final entry = tree['file.txt']; // => TreeEntry

entry.oid; // => Oid
entry.name // => 'file.txt'
entry.filemode // => GitFilemode.blob

// Release memory allocated for Tree object when it's no longer needed
tree.free();
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

// Release memory allocated for TreeBuilder object and all the entries when
// they are no longer needed
builder.free();

// Perform commit using that tree in arguments
...
```

### Tag

Tag create and lookup methods and some of the object getters:

```dart
// Create using alias on repository object
final oid = repo.createTag(
  tagName: 'v0.1',
  target: repo['821ed6e'],
  targetType: GitObject.commit,
  tagger: repo.defaultSignature,
  message: 'tag message',
); // => Oid

// Create using named constructor from Tag class
final oid = Tag.create(repo: repo, ...); // => Oid

// Lookup using alias on repository object
final tag = repo.lookupTag(repo['f0fdbf5']); // => Tag

// Lookup using named constructor from Tag class
final tag = Tag.lookup(repo: repo, oid: repo['f0fdbf5']); // => Tag

// Get list of all the tags names in repository
repo.tags; // => ['v0.1', 'v0.2']

tag.oid; // => Oid
tag.name; // => 'v0.1'

// Release memory allocated for Tag object when it's no longer needed
tag.free();
```

### Blob

Blob create and lookup methods and some of the object getters:

```dart
// Create a new blob from the file at provided path using alias on repository
// object
final oid = repo.createBlobFromDisk('path/to/file.txt'); // => Oid

// Create a new blob from the file at provided path using static method from
// Blob class
final oid = Blob.createFromDisk(repo: repo, path: 'path/to/file.txt'); // => Oid

// Lookup using alias on repository object
final blob = repo.lookupBlob(repo['e69de29']); // => Blob

// Lookup using named constructor from Blob class
final blob = Blob.lookup(repo: repo, oid: repo['e69de29']); // => Blob

blob.oid; // => Oid
blob.content; // => 'content of the file'
blob.size; // => 19

// Release memory allocated for Blob object when it's no longer needed
blob.free();
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

// Release memory allocated for Walker object when it's no longer needed
walker.free();
```

---

### Index ("staging") area and IndexEntry

Some methods and getters to inspect and manipulate the Git index:

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

// Release memory allocated for Index object when it's no longer needed
index.free();
```

---

### References and RefLog

```dart
// Get names of all of the references that can be found in repository
final refs = repo.references; // => ['refs/heads/master', 'refs/tags/v0.1', ...]

// Lookup reference using alias on repository object
final ref = repo.lookupReference('refs/heads/master'); // => Reference

// Lookup using named constructor from Reference class
final ref = Reference.lookup(repo: repo, name: 'refs/heads/master'); // => Reference

ref.type; // => ReferenceType.direct
ref.target; // => Oid
ref.name; // => 'refs/heads/master'

// Create reference using alias on repository object
final ref = repo.createReference(
  name: 'refs/heads/feature',
  target: repo['821ed6e'],
); // => Reference

// Update reference
ref.setTarget(repo['c68ff54']);

// Rename reference
repo.renameReference(oldName: 'refs/heads/feature', newName: 'refs/heads/feature2');

// Delete reference
repo.deleteReference('refs/heads/feature2');

// Access the reflog
final reflog = ref.log; // => RefLog
final entry = reflog.first; // RefLogEntry

entry.message; // => 'commit (initial): init'
entry.committer; // => Signature

// Release memory allocated for RefLog object when it's no longer needed
reflog.free();

// Release memory allocated for Reference object when it's no longer needed
ref.free();
```

---

### Branches

```dart
// Get all the branches that can be found in repository
final branches = repo.branches; // => [Branch, Branch, ...]

// Get only local/remote branches
final local = repo.branchesLocal; // => [Branch, Branch, ...]
final remote = repo.branchesRemote; // => [Branch, Branch, ...]

// Lookup branch using alias on repository object (lookups in local branches
// if no value for argument `type` is provided)
final branch = repo.lookupBranch(name: 'master'); // => Branch

// Lookup branch using named constructor from Branch class (lookups in local
// branches if no value for argument `type` is provided)
final branch = Branch.lookup(repo: repo, name: 'master'); // => Branch

branch.target; // => Oid
branch.isHead; // => true
branch.name; // => 'master'

// Create branch using alias on repository object
final branch = repo.createBranch(name: 'feature', target: commit); // => Branch

// Rename branch
repo.renameBranch(oldName: 'feature', newName: 'feature2');

// Delete branch
repo.deleteBranch('feature2');

// Release memory allocated for Branch object when it's no longer needed
branch.free();
```

---

### Diff

There is multiple ways to get the diff:

```dart
// Diff between two tree objects
final diff = repo.diff(a: tree1, b: tree2); // => Diff

// Diff between tree and current working directory
final diff = repo.diff(a: tree); // => Diff

// Diff between index (staging area) and current working directory
final diff = repo.diff(); // => Diff

// Diff between index (staging area) and tree
final diff = repo.diff(a: tree, cached: true); // => Diff

// Release memory allocated for Diff object when it's no longer needed
diff.free();
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
// Release memory allocated for DiffStats object when it's no longer needed
stats.free();

// Get the list of DiffDelta's containing file pairs with and old and new revisions
final deltas = diff.deltas; // => [DiffDelta, DiffDelta, ...]
final delta = deltas.first; // => DiffDelta
delta.status; // => GitDelta.modified
delta.oldFile; // => DiffFile
delta.newFile; // => DiffFile
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

// Release memory allocated for Config object when it's no longer needed
config.free();
```

---

## Contributing

Fork libgit2dart, improve libgit2dart, send a pull request.

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

## Running Tests

To run all tests and generate coverage report use the following commands:

```sh
$ dart pub global activate coverage
$ dart test --coverage="coverage"
$ format_coverage --lcov --check-ignore --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov):

```sh
$ genhtml coverage/lcov.info -o coverage/
$ open coverage/index.html
```

## Licence

MIT. See LICENSE file for more information.
