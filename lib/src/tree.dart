import 'dart:ffi';
import 'package:libgit2dart/src/repository.dart';

import 'bindings/libgit2_bindings.dart';
import 'bindings/tree.dart' as bindings;
import 'oid.dart';
import 'util.dart';

class Tree {
  /// Initializes a new instance of [Tree] class from provided
  /// pointer to tree object in memory.
  Tree(this._treePointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Tree] class from provided
  /// [Repository] and [Oid] objects.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Tree.lookup(Repository repo, Oid id) {
    _treePointer = bindings.lookup(repo.pointer, id.pointer);
  }

  late final Pointer<git_tree> _treePointer;

  /// Pointer to memory address for allocated tree object.
  Pointer<git_tree> get pointer => _treePointer;

  /// Releases memory allocated for tree object.
  void free() {
    bindings.free(_treePointer);
  }
}
