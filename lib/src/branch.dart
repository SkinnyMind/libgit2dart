import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/branch.dart' as bindings;
import 'bindings/reference.dart' as reference_bindings;
import 'commit.dart';
import 'reference.dart';
import 'repository.dart';
import 'oid.dart';
import 'git_types.dart';

class Branches {
  /// Initializes a new instance of the [Branches] class
  /// from provided [Repository] object.
  Branches(Repository repo) {
    _repoPointer = repo.pointer;
  }

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Returns a list of all branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> list() => bindings.list(_repoPointer, GitBranch.all.value);

  /// Returns a list of local branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get local => bindings.list(_repoPointer, GitBranch.local.value);

  /// Returns a list of remote branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get remote =>
      bindings.list(_repoPointer, GitBranch.remote.value);

  /// Lookups a branch by its name in a repository.
  ///
  /// The generated reference must be freed. The branch name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch operator [](String branchName) {
    final ref = Reference(
      reference_bindings.lookupDWIM(_repoPointer, branchName),
    );
    late final GitBranch type;
    ref.isBranch ? type = GitBranch.local : GitBranch.remote;
    ref.free();

    return Branch(bindings.lookup(_repoPointer, branchName, type.value));
  }

  /// Creates a new branch pointing at a [target] commit.
  ///
  /// A new direct reference will be created pointing to this target commit.
  /// If [force] is true and a reference already exists with the given name, it'll be replaced.
  ///
  /// The returned reference must be freed.
  ///
  /// The branch name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference create({
    required String name,
    required Commit target,
    bool force = false,
  }) {
    return Reference(bindings.create(
      _repoPointer,
      name,
      target.pointer,
      force,
    ));
  }
}

class Branch {
  /// Initializes a new instance of [Branch] class from provided pointer to
  /// branch object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  const Branch(this._branchPointer);

  /// Pointer to memory address for allocated branch object.
  final Pointer<git_reference> _branchPointer;

  /// Returns the OID pointed to by a branch.
  ///
  /// Throws an exception if error occured.
  Oid get target => Oid(reference_bindings.target(_branchPointer));

  /// Deletes an existing branch reference.
  ///
  /// Note that if the deletion succeeds, the reference object will not be valid anymore,
  /// and will be freed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void delete() => bindings.delete(_branchPointer);

  /// Renames an existing local branch reference.
  ///
  /// The new branch name will be checked for validity.
  ///
  /// Note that if the move succeeds, the old reference object will not be valid anymore,
  /// and will be freed immediately.
  ///
  /// If [force] is true, existing branch will be overwritten.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch rename({required String newName, bool force = false}) {
    return Branch(bindings.rename(_branchPointer, newName, force));
  }

  /// Checks if HEAD points to the given branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isHead => bindings.isHead(_branchPointer);

  /// Checks if any HEAD points to the current branch.
  ///
  /// This will iterate over all known linked repositories (usually in the form of worktrees)
  /// and report whether any HEAD is pointing at the current branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isCheckedOut => bindings.isCheckedOut(_branchPointer);

  /// Returns the branch name.
  ///
  /// Given a reference object, this will check that it really is a branch
  /// (ie. it lives under "refs/heads/" or "refs/remotes/"), and return the branch part of it.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get name => bindings.name(_branchPointer);

  /// Releases memory allocated for branch object.
  void free() => bindings.free(_branchPointer);
}
