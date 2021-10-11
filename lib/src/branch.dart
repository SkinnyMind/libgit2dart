import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/branch.dart' as bindings;
import 'bindings/reference.dart' as reference_bindings;

class Branch {
  /// Initializes a new instance of [Branch] class from provided pointer to
  /// branch object in memory.
  ///
  /// Should be freed with [free] to release allocated memory when no longer
  /// needed.
  Branch(this._branchPointer);

  /// Creates a new branch pointing at a [target] commit.
  ///
  /// A new direct reference will be created pointing to this target commit.
  /// If [force] is true and a reference already exists with the given name, it'll be replaced.
  ///
  /// Should be freed with [free] to release allocated memory when no longer
  /// needed.
  ///
  /// The branch name will be checked for validity.
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

  /// Lookups a branch by its [name] in a [repo]sitory.
  ///
  /// The branch name will be checked for validity.
  ///
  /// Should be freed with [free] to release allocated memory when no longer
  /// needed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch.lookup({required Repository repo, required String name}) {
    final ref = Reference(
      reference_bindings.lookupDWIM(
        repoPointer: repo.pointer,
        name: name,
      ),
    );
    late final GitBranch type;
    ref.isBranch ? type = GitBranch.local : GitBranch.remote;
    ref.free();

    _branchPointer = bindings.lookup(
      repoPointer: repo.pointer,
      branchName: name,
      branchType: type.value,
    );
  }

  late final Pointer<git_reference> _branchPointer;

  /// Pointer to memory address for allocated branch object.
  Pointer<git_reference> get pointer => _branchPointer;

  /// Returns a list of branches that can be found in a [repo]sitory for provided [type].
  /// Default is all branches (local and remote).
  ///
  /// IMPORTANT: Branches must be freed manually when no longer needed to prevent
  /// memory leak.
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

    final result = <Branch>[];
    for (var pointer in pointers) {
      result.add(Branch(pointer));
    }

    return result;
  }

  /// Deletes an existing branch reference.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({required Repository repo, required String name}) {
    final branch = Branch.lookup(repo: repo, name: name);
    bindings.delete(branch.pointer);
  }

  /// Renames an existing local branch reference.
  ///
  /// The new branch name will be checked for validity.
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

  /// Returns the OID pointed to by a branch.
  ///
  /// Throws an exception if error occured.
  Oid get target => Oid(reference_bindings.target(_branchPointer));

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

  @override
  String toString() {
    return 'Branch{name: $name, target: $target}';
  }
}
