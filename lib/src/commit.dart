import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/commit.dart' as bindings;
import 'bindings/tree.dart' as tree_bindings;

class Commit {
  /// Initializes a new instance of [Commit] class from provided pointer to
  /// commit object in memory.
  ///
  /// Should be freed to release allocated memory.
  Commit(this._commitPointer);

  /// Lookups commit object for provided [id] in a [repo]sitory.
  ///
  /// Should be freed to release allocated memory.
  Commit.lookup({required Repository repo, required Oid id}) {
    _commitPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: id.pointer,
    );
  }

  late final Pointer<git_commit> _commitPointer;

  /// Pointer to memory address for allocated commit object.
  Pointer<git_commit> get pointer => _commitPointer;

  /// Creates new commit in the repository.
  ///
  /// [updateRef] is name of the reference that will be updated to point to this commit.
  /// If the reference is not direct, it will be resolved to a direct reference. Use "HEAD"
  /// to update the HEAD of the current branch and make it point to this commit. If the
  /// reference doesn't exist yet, it will be created. If it does exist, the first parent
  /// must be the tip of this branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required String message,
    required Signature author,
    required Signature commiter,
    required Tree tree,
    required List<Commit> parents,
    String? updateRef,
    String? messageEncoding,
  }) {
    final parentsPointers = parents.map((parent) => parent.pointer).toList();

    return Oid(bindings.create(
      repoPointer: repo.pointer,
      updateRef: updateRef,
      authorPointer: author.pointer,
      committerPointer: commiter.pointer,
      messageEncoding: messageEncoding,
      message: message,
      treePointer: tree.pointer,
      parentCount: parents.length,
      parents: parentsPointers,
    ));
  }

  /// Returns the encoding for the message of a commit, as a string
  /// representing a standard encoding name.
  String get messageEncoding => bindings.messageEncoding(_commitPointer);

  /// Returns the full message of a commit.
  ///
  /// The returned message will be slightly prettified by removing any potential leading newlines.
  String get message => bindings.message(_commitPointer);

  /// Returns the id of a commit.
  Oid get id => Oid(bindings.id(_commitPointer));

  /// Returns the commit time (i.e. committer time) of a commit.
  int get time => bindings.time(_commitPointer);

  /// Returns the committer of a commit.
  Signature get committer => Signature(bindings.committer(_commitPointer));

  /// Returns the author of a commit.
  Signature get author => Signature(bindings.author(_commitPointer));

  /// Returns list of parent commits.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Oid> get parents {
    var parents = <Oid>[];
    final parentCount = bindings.parentCount(_commitPointer);

    for (var i = 0; i < parentCount; i++) {
      final parentOid = bindings.parentId(
        commitPointer: _commitPointer,
        position: i,
      );
      parents.add(Oid(parentOid));
    }

    return parents;
  }

  /// Get the tree pointed to by a commit.
  Tree get tree {
    final repo = bindings.owner(_commitPointer);
    final oid = bindings.tree(_commitPointer);
    return Tree(tree_bindings.lookup(repoPointer: repo, oidPointer: oid));
  }

  /// Releases memory allocated for commit object.
  void free() => bindings.free(_commitPointer);

  @override
  String toString() => 'Commit{id: $id}';
}
