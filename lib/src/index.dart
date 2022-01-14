import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/diff.dart' as diff_bindings;
import 'package:libgit2dart/src/bindings/index.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';

class Index with IterableMixin<IndexEntry> {
  /// Initializes a new instance of [Index] class from provided
  /// pointer to index object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  const Index(this._indexPointer);

  /// Creates an in-memory index object.
  ///
  /// This index object cannot be read/written to the filesystem, but may be
  /// used to perform in-memory index operations.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Index.newInMemory() : _indexPointer = bindings.newInMemory();

  final Pointer<git_index> _indexPointer;

  /// Pointer to memory address for allocated index object.
  Pointer<git_index> get pointer => _indexPointer;

  /// Full path to the index file on disk.
  String get path => bindings.path(_indexPointer);

  /// Index capabilities flags.
  Set<GitIndexCapability> get capabilities {
    final capInt = bindings.capabilities(_indexPointer);
    return GitIndexCapability.values
        .where((e) => capInt & e.value == e.value)
        .toSet();
  }

  set capabilities(Set<GitIndexCapability> flags) {
    bindings.setCapabilities(
      indexPointer: _indexPointer,
      caps: flags.fold(0, (acc, e) => acc | e.value),
    );
  }

  /// Returns index entry located at provided 0-based position or string path.
  ///
  /// Throws [RangeError] when provided [value] is outside of valid range or
  /// [ArgumentError] if nothing found for provided path.
  IndexEntry operator [](Object value) {
    if (value is int) {
      return IndexEntry(
        bindings.getByIndex(
          indexPointer: _indexPointer,
          position: value,
        ),
      );
    } else {
      return IndexEntry(
        bindings.getByPath(
          indexPointer: _indexPointer,
          path: value as String,
          stage: 0,
        ),
      );
    }
  }

  /// Whether entry at provided [path] is in the git index or not.
  bool find(String path) {
    return bindings.find(
      indexPointer: _indexPointer,
      path: path,
    );
  }

  /// Whether index contains entries representing file conflicts.
  bool get hasConflicts => bindings.hasConflicts(_indexPointer);

  /// Returns map of conflicts in the index with key as conflicted file path and
  /// value as [ConflictEntry] object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Map<String, ConflictEntry> get conflicts {
    final conflicts = bindings.conflictList(_indexPointer);
    final result = <String, ConflictEntry>{};

    for (final entry in conflicts) {
      IndexEntry? ancestor, our, their;
      String path;

      entry['ancestor'] == nullptr
          ? ancestor = null
          : ancestor = IndexEntry(entry['ancestor']!);
      entry['our'] == nullptr ? our = null : our = IndexEntry(entry['our']!);
      entry['their'] == nullptr
          ? their = null
          : their = IndexEntry(entry['their']!);

      if (our != null) {
        path = our.path;
      } else {
        path = their!.path;
      }

      result[path] = ConflictEntry(_indexPointer, path, ancestor, our, their);
    }

    return result;
  }

  /// Adds or updates index entries to represent a conflict. Any staged entries
  /// that exist at the given paths will be removed.
  ///
  /// The entries are the entries from the tree included in the merge. Any entry
  /// may be null to indicate that that file was not present in the trees during
  /// the merge. For example, [ancestorEntry] may be null to indicate
  /// that a file was added in both branches and must be resolved.
  ///
  /// [ancestorEntry] is the entry data for the ancestor of the conflict.
  ///
  /// [ourEntry] is the entry data for our side of the merge conflict.
  ///
  /// [theirEntry] is the entry data for their side of the merge conflict.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addConflict({
    IndexEntry? ancestorEntry,
    IndexEntry? ourEntry,
    IndexEntry? theirEntry,
  }) {
    bindings.conflictAdd(
      indexPointer: _indexPointer,
      ancestorEntryPointer: ancestorEntry?.pointer,
      ourEntryPointer: ourEntry?.pointer,
      theirEntryPointer: theirEntry?.pointer,
    );
  }

  /// Removes all conflicts in the index (entries with a stage greater than 0).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void cleanupConflict() => bindings.conflictCleanup(_indexPointer);

  /// Clears the contents (all the entries) of an index object.
  ///
  /// This clears the index object in memory; changes must be explicitly
  /// written to disk for them to take effect persistently.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void clear() => bindings.clear(_indexPointer);

  /// Adds or updates an index entry from an [IndexEntry] or from a file on
  /// disk.
  ///
  /// If a previous index entry exists that has the same path and stage as the
  /// given [entry], it will be replaced. Otherwise, the [entry] will be added.
  ///
  /// The file path must be relative to the repository's working folder and
  /// must be readable.
  ///
  /// This method will fail in bare index instances.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void add(Object entry) {
    if (entry is IndexEntry) {
      bindings.add(
        indexPointer: _indexPointer,
        sourceEntryPointer: entry._indexEntryPointer,
      );
    } else {
      bindings.addByPath(indexPointer: _indexPointer, path: entry as String);
    }
  }

  /// Adds or updates an index [entry] from a [buffer] in memory.
  ///
  /// This method will create a blob in the repository that owns the index and
  /// then add the index entry to the index. The path of the entry represents
  /// the position of the blob relative to the repository's root folder.
  ///
  /// If a previous index entry exists that has the same path as the given
  /// 'entry', it will be replaced. Otherwise, the 'entry' will be added.
  ///
  /// This forces the file to be added to the index, not looking at gitignore
  /// rules.
  ///
  /// If this file currently is the result of a merge conflict, this file will
  /// no longer be marked as conflicting. The data about the conflict will be
  /// moved to the "resolve undo" (REUC) section.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addFromBuffer({required IndexEntry entry, required String buffer}) {
    bindings.addFromBuffer(
      indexPointer: _indexPointer,
      entryPointer: entry.pointer,
      buffer: buffer,
    );
  }

  /// Adds or updates index entries matching files in the working directory.
  ///
  /// This method will fail in bare index instances.
  ///
  /// The [pathspec] is a list of file names or shell glob patterns that will
  /// be matched against files in the repository's working directory. Each file
  /// that matches will be added to the index (either updating an existing
  /// entry or adding a new entry).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addAll(List<String> pathspec) {
    bindings.addAll(indexPointer: _indexPointer, pathspec: pathspec);
  }

  /// Updates all index entries to match the working directory.
  ///
  /// This method will fail in bare index instances.
  ///
  /// This scans the existing index entries and synchronizes them with the
  /// working directory, deleting them if the corresponding working directory
  /// file no longer exists otherwise updating the information (including adding
  /// the latest version of file to the ODB if needed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void updateAll(List<String> pathspec) {
    bindings.updateAll(indexPointer: _indexPointer, pathspec: pathspec);
  }

  /// Updates the contents of an existing index object in memory by reading
  /// from the hard disk.
  ///
  /// If [force] is true (default), this performs a "hard" read that discards
  /// in-memory changes and always reloads the on-disk index data. If there is
  /// no on-disk version, the index will be cleared.
  ///
  /// If [force] is false, this does a "soft" read that reloads the index data
  /// from disk only if it has changed since the last time it was loaded.
  /// Purely in-memory index data will be untouched. Be aware: if there are
  /// changes on disk, unwritten in-memory changes are discarded.
  void read({bool force = true}) =>
      bindings.read(indexPointer: _indexPointer, force: force);

  /// Updates the contents of an existing index object in memory by reading
  /// from the specified [tree].
  void readTree(Tree tree) {
    bindings.readTree(indexPointer: _indexPointer, treePointer: tree.pointer);
  }

  /// Writes an existing index object from memory back to disk using an atomic
  /// file lock.
  void write() => bindings.write(_indexPointer);

  /// Writes the index as a tree.
  ///
  /// This method will scan the index and write a representation of its current
  /// state back to disk; it recursively creates tree objects for each of the
  /// subtrees stored in the index, but only returns the [Oid] of the root
  /// tree. This is the oid that can be used e.g. to create a commit.
  ///
  /// The index must not contain any file in conflict.
  ///
  /// Throws a [LibGit2Error] if error occured or there is no associated
  /// repository and no [repo] passed.
  Oid writeTree([Repository? repo]) {
    if (repo == null) {
      return Oid(bindings.writeTree(_indexPointer));
    } else {
      return Oid(
        bindings.writeTreeTo(
          indexPointer: _indexPointer,
          repoPointer: repo.pointer,
        ),
      );
    }
  }

  /// Removes an entry from the index at provided [path] relative to repository
  /// working directory with optional [stage].
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove(String path, [int stage = 0]) =>
      bindings.remove(indexPointer: _indexPointer, path: path, stage: stage);

  /// Removes all entries from the index under a given [directory] with
  /// optional [stage].
  void removeDirectory(String directory, [int stage = 0]) {
    bindings.removeDirectory(
      indexPointer: _indexPointer,
      dir: directory,
      stage: stage,
    );
  }

  /// Removes all matching index entries at provided list of [path]s relative
  /// to repository working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void removeAll(List<String> path) =>
      bindings.removeAll(indexPointer: _indexPointer, pathspec: path);

  /// Creates a diff with the difference between two index objects.
  ///
  /// [index] is the [Index] object to diff to.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff diffToIndex({
    required Index index,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(
      diff_bindings.indexToIndex(
        repoPointer: bindings.owner(_indexPointer),
        oldIndexPointer: _indexPointer,
        newIndexPointer: index.pointer,
        flags: flags.fold(0, (acc, e) => acc | e.value),
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ),
    );
  }

  /// Creates a diff between the repository index and the workdir directory.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  Diff diffToWorkdir({
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(
      diff_bindings.indexToWorkdir(
        repoPointer: bindings.owner(_indexPointer),
        indexPointer: _indexPointer,
        flags: flags.fold(0, (acc, e) => acc | e.value),
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ),
    );
  }

  /// Creates a diff between a tree and repository index.
  ///
  /// [tree] is the [Tree] object to diff from.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  Diff diffToTree({
    required Tree tree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(
      diff_bindings.treeToIndex(
        repoPointer: bindings.owner(_indexPointer),
        treePointer: tree.pointer,
        indexPointer: _indexPointer,
        flags: flags.fold(0, (acc, e) => acc | e.value),
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ),
    );
  }

  /// Releases memory allocated for index object.
  void free() => bindings.free(_indexPointer);

  @override
  String toString() => 'Index{hasConflicts: $hasConflicts}';

  @override
  Iterator<IndexEntry> get iterator => _IndexIterator(_indexPointer);
}

class IndexEntry {
  /// Initializes a new instance of [IndexEntry] class.
  const IndexEntry(this._indexEntryPointer);

  final Pointer<git_index_entry> _indexEntryPointer;

  /// Pointer to memory address for allocated index entry object.
  Pointer<git_index_entry> get pointer => _indexEntryPointer;

  /// [Oid] of the index entry.
  Oid get oid => Oid.fromRaw(_indexEntryPointer.ref.id);

  set oid(Oid oid) => _indexEntryPointer.ref.id = oid.pointer.ref;

  /// Path of the index entry.
  String get path => _indexEntryPointer.ref.path.cast<Utf8>().toDartString();

  set path(String path) =>
      _indexEntryPointer.ref.path = path.toNativeUtf8().cast<Int8>();

  /// UNIX file attributes of a index entry.
  GitFilemode get mode {
    return GitFilemode.values.singleWhere(
      (mode) => _indexEntryPointer.ref.mode == mode.value,
    );
  }

  /// Sets the UNIX file attributes of a index entry.
  set mode(GitFilemode mode) => _indexEntryPointer.ref.mode = mode.value;

  /// Stage number.
  int get stage => bindings.entryStage(_indexEntryPointer);

  /// Whether the given index entry is a conflict (has a high stage entry).
  bool get isConflict => bindings.entryIsConflict(_indexEntryPointer);

  @override
  String toString() {
    return 'IndexEntry{oid: $oid, path: $path, mode: $mode, stage: $stage}';
  }
}

class ConflictEntry {
  /// Initializes a new instance of [ConflictEntry] class.
  const ConflictEntry(
    this._indexPointer,
    this._path,
    this.ancestor,
    this.our,
    this.their,
  );

  /// Common ancestor.
  final IndexEntry? ancestor;

  /// "Our" side of the conflict.
  final IndexEntry? our;

  /// "Their" side of the conflict.
  final IndexEntry? their;

  /// Pointer to memory address for allocated index object.
  final Pointer<git_index> _indexPointer;

  /// Path to conflicted file.
  final String _path;

  /// Removes the index entry that represent a conflict of a single file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove() =>
      bindings.conflictRemove(indexPointer: _indexPointer, path: _path);

  @override
  String toString() =>
      'ConflictEntry{ancestor: $ancestor, our: $our, their: $their, '
      'path: $_path}';
}

class _IndexIterator implements Iterator<IndexEntry> {
  _IndexIterator(this._indexPointer) {
    count = bindings.entryCount(_indexPointer);
  }

  final Pointer<git_index> _indexPointer;
  IndexEntry? _currentEntry;
  int _index = 0;
  late final int count;

  @override
  IndexEntry get current => _currentEntry!;

  @override
  bool moveNext() {
    if (_index == count) {
      return false;
    } else {
      _currentEntry = IndexEntry(
        bindings.getByIndex(
          indexPointer: _indexPointer,
          position: _index,
        ),
      );
      _index++;
      return true;
    }
  }
}
