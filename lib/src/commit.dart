import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/commit.dart' as bindings;
import 'bindings/tree.dart' as tree_bindings;

class Commit {
  /// Initializes a new instance of [Commit] class from provided pointer to
  /// commit object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Commit(this._commitPointer);

  /// Lookups commit object for provided [oid] in the [repo]sitory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Commit.lookup({required Repository repo, required Oid oid}) {
    _commitPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
  }

  late final Pointer<git_commit> _commitPointer;

  /// Pointer to memory address for allocated commit object.
  Pointer<git_commit> get pointer => _commitPointer;

  /// Creates new commit in the [repo]sitory.
  ///
  /// [repo] is the repository where to store the commit.
  ///
  /// [updateRef] is the name of the reference that will be updated to point to this commit.
  /// If the reference is not direct, it will be resolved to a direct reference. Use "HEAD"
  /// to update the HEAD of the current branch and make it point to this commit. If the
  /// reference doesn't exist yet, it will be created. If it does exist, the first parent
  /// must be the tip of this branch.
  ///
  /// [author] is the signature with author and author time of commit.
  ///
  /// [committer] is the signature with committer and commit time of commit.
  ///
  /// [messageEncoding] is the encoding for the message in the commit, represented with
  /// a standard encoding name. E.g. "UTF-8". If null, no encoding header is written and
  /// UTF-8 is assumed.
  ///
  /// [message] is the full message for this commit.
  ///
  /// [tree] is an instance of a [Tree] object that will be used as the tree for the commit.
  /// This tree object must also be owned by the given [repo].
  ///
  /// [parents] is a list of [Commit] objects that will be used as the parents for this commit.
  /// This array may be empty if parent count is 0 (root commit). All the given commits must
  /// be owned by the [repo].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    String? updateRef,
    required Signature author,
    required Signature committer,
    String? messageEncoding,
    required String message,
    required Tree tree,
    required List<Commit> parents,
  }) {
    return Oid(bindings.create(
      repoPointer: repo.pointer,
      updateRef: updateRef,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      messageEncoding: messageEncoding,
      message: message,
      treePointer: tree.pointer,
      parentCount: parents.length,
      parents: parents.map((e) => e.pointer).toList(),
    ));
  }

  /// Amends an existing commit by replacing only non-null values.
  ///
  /// This creates a new commit that is exactly the same as the old commit, except that
  /// any non-null values will be updated. The new commit has the same parents as the old commit.
  ///
  /// The [updateRef] value works as in the regular [create], updating the ref to point to
  /// the newly rewritten commit. If you want to amend a commit that is not currently
  /// the tip of the branch and then rewrite the following commits to reach a ref, pass
  /// this as null and update the rest of the commit chain and ref separately.
  ///
  /// Unlike [create], the [author], [committer], [message], [messageEncoding], and
  /// [tree] arguments can be null in which case this will use the values from the original
  /// [commit].
  ///
  /// All arguments have the same meanings as in [create].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid amend({
    required Repository repo,
    required Commit commit,
    Signature? author,
    Signature? committer,
    Tree? tree,
    String? updateRef,
    String? message,
    String? messageEncoding,
  }) {
    return Oid(bindings.amend(
      repoPointer: repo.pointer,
      commitPointer: commit.pointer,
      authorPointer: author?.pointer,
      committerPointer: committer?.pointer,
      treePointer: tree?.pointer,
      updateRef: updateRef,
      message: message,
      messageEncoding: messageEncoding,
    ));
  }

  /// Wncoding for the message of a commit, as a string representing a standard
  /// encoding name.
  String get messageEncoding => bindings.messageEncoding(_commitPointer);

  /// Full message of a commit.
  ///
  /// The returned message will be slightly prettified by removing any potential
  /// leading newlines.
  String get message => bindings.message(_commitPointer);

  /// [Oid] of a commit.
  Oid get oid => Oid(bindings.id(_commitPointer));

  /// Commit time (i.e. committer time) of a commit.
  int get time => bindings.time(_commitPointer);

  /// Committer of a commit.
  Signature get committer => Signature(bindings.committer(_commitPointer));

  /// Author of a commit.
  Signature get author => Signature(bindings.author(_commitPointer));

  /// List of parent commits [Oid]s.
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

  /// Tree pointed to by a commit.
  Tree get tree {
    return Tree(tree_bindings.lookup(
      repoPointer: bindings.owner(_commitPointer),
      oidPointer: bindings.tree(_commitPointer),
    ));
  }

  /// Releases memory allocated for commit object.
  void free() => bindings.free(_commitPointer);

  @override
  String toString() {
    return 'Commit{oid: $oid, message: $message, messageEncoding: $messageEncoding, '
        'time: $time, committer: $committer, author: $author}';
  }
}

/// An annotated commit contains information about how it was looked up, which may be useful
/// for functions like merge or rebase to provide context to the operation. For example, conflict
/// files will include the name of the source or target branches being merged.
///
/// Note: for internal use.
class AnnotatedCommit {
  /// Lookups an annotated commit from the given commit [oid].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  AnnotatedCommit.lookup({required Repository repo, required Oid oid}) {
    _annotatedCommitPointer = bindings.annotatedLookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
  }

  late final Pointer<Pointer<git_annotated_commit>> _annotatedCommitPointer;

  /// Pointer to pointer to memory address for allocated commit object.
  Pointer<Pointer<git_annotated_commit>> get pointer => _annotatedCommitPointer;

  /// Releases memory allocated for commit object.
  void free() => bindings.annotatedFree(_annotatedCommitPointer.value);
}
