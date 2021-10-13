import 'dart:collection';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/index.dart' as bindings;
import 'bindings/diff.dart' as diff_bindings;

class Index with IterableMixin<IndexEntry> {
  /// Initializes a new instance of [Index] class from provided
  /// pointer to index object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  const Index(this._indexPointer);

  final Pointer<git_index> _indexPointer;

  /// Pointer to memory address for allocated index object.
  Pointer<git_index> get pointer => _indexPointer;

  /// Returns index entry located at provided 0-based position or string path.
  ///
  /// Throws error if position is out of bounds or entry isn't found at path.
  IndexEntry operator [](Object value) {
    if (value is int) {
      return IndexEntry(bindings.getByIndex(
        indexPointer: _indexPointer,
        position: value,
      ));
    } else {
      return IndexEntry(bindings.getByPath(
        indexPointer: _indexPointer,
        path: value as String,
        stage: 0,
      ));
    }
  }

  /// Checks whether entry at provided [path] is in the git index or not.
  bool find(String path) {
    return bindings.find(
      indexPointer: _indexPointer,
      path: path,
    );
  }

  /// Checks if the index contains entries representing file conflicts.
  bool get hasConflicts => bindings.hasConflicts(_indexPointer);

  /// Returns map of conflicts in the index with key as conflicted file path and
  /// value as [ConflictEntry] object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Map<String, ConflictEntry> get conflicts {
    final conflicts = bindings.conflictList(_indexPointer);
    var result = <String, ConflictEntry>{};

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

      if (ancestor != null) {
        path = ancestor.path;
      } else if (our != null) {
        path = our.path;
      } else {
        path = their!.path;
      }

      result[path] = ConflictEntry(_indexPointer, path, ancestor, our, their);
    }

    return result;
  }

  /// Clears the contents (all the entries) of an index object.
  ///
  /// This clears the index object in memory; changes must be explicitly written to
  /// disk for them to take effect persistently.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void clear() => bindings.clear(_indexPointer);

  /// Adds or updates an index entry from an [IndexEntry] or from a file on disk.
  ///
  /// If a previous index entry exists that has the same path and stage as the given `entry`,
  /// it will be replaced. Otherwise, the `entry` will be added.
  ///
  /// The file path must be relative to the repository's working folder and must be readable.
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

  /// Adds or updates index entries matching files in the working directory.
  ///
  /// This method will fail in bare index instances.
  ///
  /// The `pathspec` is a list of file names or shell glob patterns that will be matched
  /// against files in the repository's working directory. Each file that matches will be
  /// added to the index (either updating an existing entry or adding a new entry).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addAll(List<String> pathspec) {
    bindings.addAll(indexPointer: _indexPointer, pathspec: pathspec);
  }

  /// Updates the contents of an existing index object in memory by reading from the hard disk.
  ///
  /// If force is true (default), this performs a "hard" read that discards in-memory changes and
  /// always reloads the on-disk index data. If there is no on-disk version,
  /// the index will be cleared.
  ///
  /// If force is false, this does a "soft" read that reloads the index data from disk only
  /// if it has changed since the last time it was loaded. Purely in-memory index data
  /// will be untouched. Be aware: if there are changes on disk, unwritten in-memory changes
  /// are discarded.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void read({bool force = true}) =>
      bindings.read(indexPointer: _indexPointer, force: force);

  /// Updates the contents of an existing index object in memory by reading from the
  /// specified [tree].
  void readTree(Tree tree) {
    bindings.readTree(indexPointer: _indexPointer, treePointer: tree.pointer);
  }

  /// Writes an existing index object from memory back to disk using an atomic file lock.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void write() => bindings.write(_indexPointer);

  /// Writes the index as a tree.
  ///
  /// This method will scan the index and write a representation of its current state back to disk;
  /// it recursively creates tree objects for each of the subtrees stored in the index, but only
  /// returns the [Oid] of the root tree. This is the OID that can be used e.g. to create a commit.
  ///
  /// The index must not contain any file in conflict.
  ///
  /// Throws a [LibGit2Error] if error occured or there is no associated repository and no [repo] passed.
  Oid writeTree([Repository? repo]) {
    if (repo == null) {
      return Oid(bindings.writeTree(_indexPointer));
    } else {
      return Oid(bindings.writeTreeTo(
        indexPointer: _indexPointer,
        repoPointer: repo.pointer,
      ));
    }
  }

  /// Removes an entry from the index.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove(String path, [int stage = 0]) =>
      bindings.remove(indexPointer: _indexPointer, path: path, stage: stage);

  /// Removes all matching index entries.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void removeAll(List<String> path) =>
      bindings.removeAll(indexPointer: _indexPointer, pathspec: path);

  /// Creates a diff between the repository index and the workdir directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff diffToWorkdir({
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(diff_bindings.indexToWorkdir(
      repoPointer: bindings.owner(_indexPointer),
      indexPointer: _indexPointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    ));
  }

  /// Creates a diff between a tree and repository index.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff diffToTree({
    required Tree tree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(diff_bindings.treeToIndex(
      repoPointer: bindings.owner(_indexPointer),
      treePointer: tree.pointer,
      indexPointer: _indexPointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    ));
  }

  /// Releases memory allocated for index object.
  void free() => bindings.free(_indexPointer);

  @override
  Iterator<IndexEntry> get iterator => _IndexIterator(_indexPointer);
}

class IndexEntry {
  /// Initializes a new instance of [IndexEntry] class.
  const IndexEntry(this._indexEntryPointer);

  final Pointer<git_index_entry> _indexEntryPointer;

  /// Pointer to memory address for allocated index entry object.
  Pointer<git_index_entry> get pointer => _indexEntryPointer;

  /// Returns inique identity of the index entry.
  Oid get oid => Oid.fromRaw(_indexEntryPointer.ref.id);

  /// Sets inique identity of the index entry.
  set oid(Oid oid) => _indexEntryPointer.ref.id = oid.pointer.ref;

  /// Returns path of the index entry.
  String get path => _indexEntryPointer.ref.path.cast<Utf8>().toDartString();

  /// Sets path of the index entry.
  set path(String path) =>
      _indexEntryPointer.ref.path = path.toNativeUtf8().cast<Int8>();

  /// Returns id of the index entry as sha hex.
  String get sha => _oidToHex(_indexEntryPointer.ref.id);

  /// Returns the UNIX file attributes of a index entry.
  GitFilemode get mode {
    return GitFilemode.values.singleWhere(
      (mode) => _indexEntryPointer.ref.mode == mode.value,
    );
  }

  /// Sets the UNIX file attributes of a index entry.
  set mode(GitFilemode mode) => _indexEntryPointer.ref.mode = mode.value;

  @override
  String toString() {
    return 'IndexEntry{path: $path, sha: $sha}';
  }

  String _oidToHex(git_oid oid) {
    var hex = StringBuffer();
    for (var i = 0; i < 20; i++) {
      hex.write(oid.id[i].toRadixString(16));
    }
    return hex.toString();
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
      'ConflictEntry{ancestor: $ancestor, our: $our, their: $their}';
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
      _currentEntry = IndexEntry(bindings.getByIndex(
        indexPointer: _indexPointer,
        position: _index,
      ));
      _index++;
      return true;
    }
  }
}
