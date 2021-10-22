import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/worktree.dart' as bindings;

class Worktree {
  /// Creates new worktree.
  ///
  /// If [ref] is provided, no new branch will be created but specified [ref] will
  /// be used instead.
  ///
  /// [repo] is the repository to create working tree for.
  ///
  /// [name] is the name of the working tree.
  ///
  /// [path] is the path to create working tree at.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree.create({
    required Repository repo,
    required String name,
    required String path,
    Reference? ref,
  }) {
    _worktreePointer = bindings.create(
      repoPointer: repo.pointer,
      name: name,
      path: path,
      refPointer: ref?.pointer,
    );
  }

  /// Lookups existing worktree in [repo] with provided [name].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree.lookup({required Repository repo, required String name}) {
    _worktreePointer = bindings.lookup(repoPointer: repo.pointer, name: name);
  }

  /// Pointer to memory address for allocated branch object.
  late final Pointer<git_worktree> _worktreePointer;

  /// Returns list of names of linked working trees.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repo) => bindings.list(repo.pointer);

  /// Name of the worktree.
  String get name => bindings.name(_worktreePointer);

  /// Filesystem path for the worktree.
  String get path => bindings.path(_worktreePointer);

  /// Whether worktree is locked.
  ///
  /// A worktree may be locked if the linked working tree is stored on a portable
  /// device which is not available.
  bool get isLocked => bindings.isLocked(_worktreePointer);

  /// Locks worktree if not already locked.
  void lock() => bindings.lock(_worktreePointer);

  /// Unlocks a locked worktree.
  void unlock() => bindings.unlock(_worktreePointer);

  /// Whether worktree is prunable.
  ///
  /// A worktree is not prunable in the following scenarios:
  /// - the worktree is linking to a valid on-disk worktree.
  /// - the worktree is locked.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isPrunable => bindings.isPrunable(_worktreePointer);

  /// Prunes working tree.
  ///
  /// Prune the working tree, that is remove the git data structures on disk.
  void prune() => bindings.prune(_worktreePointer);

  /// Whether worktree is valid.
  ///
  /// A valid worktree requires both the git data structures inside the linked parent
  /// repository and the linked working copy to be present.
  bool get isValid => bindings.isValid(_worktreePointer);

  /// Releases memory allocated for worktree object.
  void free() => bindings.free(_worktreePointer);

  @override
  String toString() {
    return 'Worktree{name: $name, path: $path}';
  }
}
