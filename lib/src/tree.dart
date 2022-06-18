import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/tree.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Tree extends Equatable {
  /// Initializes a new instance of [Tree] class from provided pointer to
  /// tree object in memory.
  ///
  /// Note: For internal use. Use [Tree.lookup] instead.
  @internal
  Tree(this._treePointer) {
    _finalizer.attach(this, _treePointer, detach: this);
  }

  /// Lookups a tree object for provided [oid] in a [repo]sitory.
  Tree.lookup({required Repository repo, required Oid oid}) {
    _treePointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
    _finalizer.attach(this, _treePointer, detach: this);
  }

  late final Pointer<git_tree> _treePointer;

  /// Pointer to memory address for allocated tree object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_tree> get pointer => _treePointer;

  /// List with tree entries of a tree.
  List<TreeEntry> get entries {
    final entryCount = bindings.entryCount(_treePointer);
    return <TreeEntry>[
      for (var i = 0; i < entryCount; i++)
        TreeEntry(bindings.getByIndex(treePointer: _treePointer, index: i))
    ];
  }

  /// Lookups a tree entry in the tree.
  ///
  /// If integer [value] is provided, lookup is done by entry position in the
  /// tree.
  ///
  /// If string [value] is provided, lookup is done by entry filename.
  ///
  /// If provided string [value] is a path to file, lookup is done by path.
  ///
  /// Throws [ArgumentError] if provided [value] is not int or string.
  TreeEntry operator [](Object value) {
    if (value is int) {
      return TreeEntry(
        bindings.getByIndex(
          treePointer: _treePointer,
          index: value,
        ),
      );
    } else if (value is String && value.contains('/')) {
      return TreeEntry._byPath(
        bindings.getByPath(
          rootPointer: _treePointer,
          path: value,
        ),
      );
    } else if (value is String) {
      return TreeEntry(
        bindings.getByName(
          treePointer: _treePointer,
          filename: value,
        ),
      );
    } else {
      throw ArgumentError.value(
        '$value should be either index position, filename or path',
      );
    }
  }

  /// [Oid] of a tree.
  Oid get oid => Oid(bindings.id(_treePointer));

  /// Number of entries listed in a tree.
  int get length => bindings.entryCount(_treePointer);

  /// Releases memory allocated for tree object.
  void free() {
    bindings.free(_treePointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Tree{oid: $oid, length: $length}';
  }

  @override
  List<Object?> get props => [oid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_tree>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

@immutable
class TreeEntry extends Equatable {
  /// Initializes a new instance of [TreeEntry] class from provided pointer to
  /// tree entry object in memory.
  ///
  /// Note: For internal use.
  @internal
  const TreeEntry(this._treeEntryPointer);

  /// Initializes a new instance of [TreeEntry] class from provided pointer to
  /// tree entry object in memory.
  ///
  /// Unlike the other lookup methods, must be freed.
  TreeEntry._byPath(this._treeEntryPointer) {
    _entryFinalizer.attach(this, _treeEntryPointer, detach: this);
  }

  /// Pointer to memory address for allocated tree entry object.
  final Pointer<git_tree_entry> _treeEntryPointer;

  /// [Oid] of the object pointed by the entry.
  Oid get oid => Oid(bindings.entryId(_treeEntryPointer));

  /// Filename of a tree entry.
  String get name => bindings.entryName(_treeEntryPointer);

  /// UNIX file attributes of a tree entry.
  GitFilemode get filemode {
    final modeInt = bindings.entryFilemode(_treeEntryPointer);
    return GitFilemode.values.firstWhere((mode) => modeInt == mode.value);
  }

  /// Releases memory allocated for tree entry object.
  ///
  /// **IMPORTANT**: Only tree entries looked up by path should be freed.
  void free() {
    bindings.freeEntry(_treeEntryPointer);
    _entryFinalizer.detach(this);
  }

  @override
  String toString() => 'TreeEntry{oid: $oid, name: $name, filemode: $filemode}';

  @override
  List<Object?> get props => [oid, name, filemode];
}

// coverage:ignore-start
final _entryFinalizer = Finalizer<Pointer<git_tree_entry>>(
  (pointer) => bindings.freeEntry(pointer),
);
// coverage:ignore-end
