import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/branch.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/reference.dart' as reference_bindings;
import 'package:meta/meta.dart';

@immutable
class Branch extends Equatable {
  /// Initializes a new instance of [Branch] class from provided pointer to
  /// branch object in memory.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Branch.create]
  /// - [Branch.lookup]
  @internal
  Branch(this._branchPointer) {
    _finalizer.attach(this, _branchPointer, detach: this);
  }

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
    _finalizer.attach(this, _branchPointer, detach: this);
  }

  /// Lookups a branch by its [name] and [type] in a [repo]sitory. Lookups in
  /// local branches by default.
  ///
  /// The branch name will be checked for validity.
  ///
  /// If branch [type] is [GitBranch.remote] you must include the remote name
  /// in the [name] (e.g. "origin/master").
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
    _finalizer.attach(this, _branchPointer, detach: this);
  }

  late final Pointer<git_reference> _branchPointer;

  /// Pointer to memory address for allocated branch object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_reference> get pointer => _branchPointer;

  /// Returns a list of branches that can be found in a [repo]sitory for
  /// provided [type]. Default is all branches (local and remote).
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

  /// Remote name of a remote-tracking branch.
  ///
  /// This will return the name of the remote whose fetch refspec is matching
  /// the given branch. E.g. given a branch "refs/remotes/test/master", it
  /// will extract the "test" part.
  ///
  /// Throws a [LibGit2Error] if refspecs from multiple remotes match or if
  /// error occured.
  String get remoteName {
    final owner = reference_bindings.owner(_branchPointer);
    final branchName = reference_bindings.name(_branchPointer);
    return bindings.remoteName(repoPointer: owner, branchName: branchName);
  }

  /// Upstream [Reference] of a local branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference get upstream => Reference(bindings.getUpstream(_branchPointer));

  /// Sets a branch's upstream branch.
  ///
  /// This will update the configuration to set the branch named [branchName] as
  /// the upstream of branch. Pass a null name to unset the upstream
  /// information.
  ///
  /// **Note**: The actual tracking reference must have been already created for
  /// the operation to succeed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setUpstream(String? branchName) => bindings.setUpstream(
        branchPointer: _branchPointer,
        branchName: branchName,
      );

  /// Upstream name of a branch.
  ///
  /// Given a local branch, this will return its remote-tracking branch
  /// information, as a full reference name, ie. "feature/nice" would become
  /// "refs/remotes/origin/feature/nice", depending on that branch's configuration.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get upstreamName {
    final owner = reference_bindings.owner(_branchPointer);
    final branchName = reference_bindings.name(_branchPointer);
    return bindings.upstreamName(repoPointer: owner, branchName: branchName);
  }

  /// Upstream remote of a local branch.
  ///
  /// This will return the currently configured "branch.*.remote" for a branch.
  /// Branch must be local.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get upstreamRemote {
    final owner = reference_bindings.owner(_branchPointer);
    final branchName = reference_bindings.name(_branchPointer);
    return bindings.upstreamRemote(repoPointer: owner, branchName: branchName);
  }

  /// Upstream merge of a local branch.
  ///
  /// This will return the currently configured "branch.*.merge" for a branch.
  /// Branch must be local.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get upstreamMerge {
    final owner = reference_bindings.owner(_branchPointer);
    final branchName = reference_bindings.name(_branchPointer);
    return bindings.upstreamMerge(repoPointer: owner, branchName: branchName);
  }

  /// Releases memory allocated for branch object.
  void free() {
    bindings.free(_branchPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Branch{name: $name, target: $target, isHead: $isHead, '
        'isCheckedOut: $isCheckedOut}';
  }

  @override
  List<Object?> get props => [target, name];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_reference>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
