import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/tree.dart' as bindings;
import 'bindings/diff.dart' as diff_bindings;

class Tree {
  /// Initializes a new instance of [Tree] class from provided pointer to
  /// tree object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Tree(this._treePointer);

  /// Lookups a tree object for provided [oid] in a [repo]sitory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Tree.lookup({required Repository repo, required Oid oid}) {
    _treePointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
  }

  late final Pointer<git_tree> _treePointer;

  /// Pointer to memory address for allocated tree object.
  Pointer<git_tree> get pointer => _treePointer;

  /// List with tree entries of a tree.
  List<TreeEntry> get entries {
    final entryCount = bindings.entryCount(_treePointer);
    var result = <TreeEntry>[];
    for (var i = 0; i < entryCount; i++) {
      result.add(TreeEntry(bindings.getByIndex(
        treePointer: _treePointer,
        index: i,
      )));
    }

    return result;
  }

  /// Lookups a tree entry in the tree.
  ///
  /// If integer [value] is provided, lookup is done by entry position in the tree.
  ///
  /// If string [value] is provided, lookup is done by entry filename.
  ///
  /// If provided string [value] is a path to file, lookup is done by path.
  ///
  /// Throws [ArgumentError] if provided [value] is not int or string.
  TreeEntry operator [](Object value) {
    if (value is int) {
      return TreeEntry(bindings.getByIndex(
        treePointer: _treePointer,
        index: value,
      ));
    } else if (value is String && value.contains('/')) {
      return TreeEntry(bindings.getByPath(
        rootPointer: _treePointer,
        path: value,
      ));
    } else if (value is String) {
      return TreeEntry(bindings.getByName(
        treePointer: _treePointer,
        filename: value,
      ));
    } else {
      throw ArgumentError.value(
          '$value should be either index position, filename or path');
    }
  }

  /// [Oid] of a tree.
  Oid get oid => Oid(bindings.id(_treePointer));

  /// Number of entries listed in a tree.
  int get length => bindings.entryCount(_treePointer);

  /// Creates a diff between a tree and the working directory.
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
  Diff diffToWorkdir({
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(diff_bindings.treeToWorkdir(
      repoPointer: bindings.owner(_treePointer),
      treePointer: _treePointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    ));
  }

  /// Creates a diff between a tree and repository index.
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
  Diff diffToIndex({
    required Index index,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(diff_bindings.treeToIndex(
      repoPointer: bindings.owner(_treePointer),
      treePointer: _treePointer,
      indexPointer: index.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    ));
  }

  /// Creates a diff with the difference between two tree objects.
  ///
  /// [tree] is the [Tree] object to diff to.
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
  Diff diffToTree({
    required Tree tree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Diff(diff_bindings.treeToTree(
      repoPointer: bindings.owner(_treePointer),
      oldTreePointer: _treePointer,
      newTreePointer: tree.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    ));
  }

  /// Releases memory allocated for tree object.
  void free() => bindings.free(_treePointer);

  @override
  String toString() {
    return 'Tree{oid: $oid, length: $length}';
  }
}

class TreeEntry {
  /// Initializes a new instance of [TreeEntry] class from provided pointer to
  /// tree entry object in memory.
  const TreeEntry(this._treeEntryPointer);

  /// Pointer to memory address for allocated tree entry object.
  final Pointer<git_tree_entry> _treeEntryPointer;

  /// [Oid] of the object pointed by the entry.
  Oid get oid => Oid(bindings.entryId(_treeEntryPointer));

  /// Filename of a tree entry.
  String get name => bindings.entryName(_treeEntryPointer);

  /// UNIX file attributes of a tree entry.
  GitFilemode get filemode {
    final modeInt = bindings.entryFilemode(_treeEntryPointer);
    return GitFilemode.values.singleWhere((mode) => modeInt == mode.value);
  }

  /// Releases memory allocated for tree entry object.
  void free() => bindings.entryFree(_treeEntryPointer);

  @override
  String toString() => 'TreeEntry{oid: $oid, name: $name, filemode: $filemode}';
}
