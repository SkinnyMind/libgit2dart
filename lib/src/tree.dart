import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/tree.dart' as bindings;
import 'util.dart';

class Tree {
  /// Initializes a new instance of [Tree] class from provided
  /// pointers to repository object and oid object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Tree(Pointer<git_repository> repo, Pointer<git_oid> id) {
    libgit2.git_libgit2_init();
    _treePointer = bindings.lookup(repo, id);
  }

  late final Pointer<git_tree> _treePointer;

  /// Pointer to memory address for allocated tree object.
  Pointer<git_tree> get pointer => _treePointer;

  /// Releases memory allocated for tree object.
  void free() {
    bindings.free(_treePointer);
    libgit2.git_libgit2_shutdown();
  }
}
