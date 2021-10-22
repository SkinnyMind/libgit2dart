import 'dart:ffi';

import 'package:libgit2dart/libgit2dart.dart';

import 'bindings/branch.dart' as bindings;
import 'bindings/libgit2_bindings.dart';
import 'bindings/reference.dart' as reference_bindings;

class Branch {
  /// Initializes a new instance of [Branch] class from provided pointer to
  /// branch object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Branch(this._branchPointer);

  /// Creates a new branch pointing at a [target] commit.
  ///
  /// A new direct reference will be created pointing to this target commit.
  /// If [force] is true and a reference already exists with the given name,
  /// it'll be replaced.
  ///
  /// [name] is the name for the branch, this name is validated for consistency.
  /// It should also not conflict with an already existing branch name.
  ///
  /// [target] is the commit to which this branch should point. This object must
  /// belong to the given [repo].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch.create({
    required Repository repo,
    required String name,
    required Commit target,
    bool force = false,
  }) {
    _branchPointer = bindings.create(
      repoPointer: repo.pointer,
      branchName: name,
      targetPointer: target.pointer,
      force: force,
    );
  }

  /// Lookups a branch by its [name] and [type] in a [repo]sitory.
  ///
  /// The branch name will be checked for validity.
  ///
  /// If branch [type] is [GitBranch.remote] you must include the remote name
  /// in the [name] (e.g. "origin/master").
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch.lookup({
    required Repository repo,
    required String name,
    GitBranch type = GitBranch.local,
  }) {
    _branchPointer = bindings.lookup(
      repoPointer: repo.pointer,
      branchName: name,
      branchType: type.value,
    );
  }

  late final Pointer<git_reference> _branchPointer;

  /// Pointer to memory address for allocated branch object.
  Pointer<git_reference> get pointer => _branchPointer;

  /// Returns a list of branches that can be found in a [repo]sitory for
  /// provided [type]. Default is all branches (local and remote).
  ///
  /// **IMPORTANT**: Branches must be freed manually when no longer needed to
  /// prevent memory leak.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<Branch> list({
    required Repository repo,
    GitBranch type = GitBranch.all,
  }) {
    final pointers = bindings.list(
      repoPointer: repo.pointer,
      flags: type.value,
    );

    return pointers.map((e) => Branch(e)).toList();
  }

  /// Deletes an existing branch reference with provided [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({required Repository repo, required String name}) {
    final branch = Branch.lookup(repo: repo, name: name);
    bindings.delete(branch.pointer);
    branch.free();
  }

  /// Renames an existing local branch reference with provided [oldName].
  ///
  /// The new branch name [newName] will be checked for validity.
  ///
  /// If [force] is true, existing branch will be overwritten.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void rename({
    required Repository repo,
    required String oldName,
    required String newName,
    bool force = false,
  }) {
    final branch = Branch.lookup(repo: repo, name: oldName);

    bindings.rename(
      branchPointer: branch.pointer,
      newBranchName: newName,
      force: force,
    );

    branch.free();
  }

  /// [Oid] pointed to by a branch.
  ///
  /// Throws an [Exception] if error occured.
  Oid get target => Oid(reference_bindings.target(_branchPointer));

  /// Whether HEAD points to the given branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isHead => bindings.isHead(_branchPointer);

  /// Whether any HEAD points to the current branch.
  ///
  /// This will iterate over all known linked repositories (usually in the form
  /// of worktrees) and report whether any HEAD is pointing at the current
  /// branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isCheckedOut => bindings.isCheckedOut(_branchPointer);

  /// Branch name.
  ///
  /// Given a reference object, this will check that it really is a branch
  /// (i.e. it lives under "refs/heads/" or "refs/remotes/"), and return the branch part of it.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get name => bindings.name(_branchPointer);

  /// Releases memory allocated for branch object.
  void free() => bindings.free(_branchPointer);

  @override
  String toString() {
    return 'Branch{name: $name, target: $target, isHead: $isHead, '
        'isCheckedOut: $isCheckedOut}';
  }
}
