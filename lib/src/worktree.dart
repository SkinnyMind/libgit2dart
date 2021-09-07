import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/worktree.dart' as bindings;
import 'reference.dart';
import 'repository.dart';

class Worktree {
  /// Initializes a new instance of [Worktree] class by creating new worktree
  /// with provided [Repository] object worktree [name], [path] and optional [ref]
  /// [Reference] object.
  ///
  /// If [ref] is provided, no new branch will be created but specified [ref] will
  /// be used instead.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree.create({
    required Repository repo,
    required String name,
    required String path,
    Reference? ref,
  }) {
    _worktreePointer = bindings.create(repo.pointer, name, path, ref?.pointer);
  }

  /// Initializes a new instance of [Worktree] class by looking up existing worktree
  /// with provided [Repository] object and worktree [name].
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree.lookup(Repository repo, String name) {
    _worktreePointer = bindings.lookup(repo.pointer, name);
  }

  /// Pointer to memory address for allocated branch object.
  late final Pointer<git_worktree> _worktreePointer;

  /// Returns list of names of linked working trees.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> list(Repository repo) => bindings.list(repo.pointer);

  /// Returns the name of the worktree.
  String get name => bindings.name(_worktreePointer);

  /// Returns the filesystem path for the worktree.
  String get path => bindings.path(_worktreePointer);

  /// Prunes working tree.
  ///
  /// Prune the working tree, that is remove the git data structures on disk.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void prune() => bindings.prune(_worktreePointer);

  /// Releases memory allocated for worktree object.
  void free() => bindings.free(_worktreePointer);
}
