import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/commit.dart' as bindings;
import 'package:libgit2dart/src/bindings/graph.dart' as graph_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:meta/meta.dart';

@immutable
class Commit extends Equatable {
  /// Initializes a new instance of [Commit] class from provided pointer to
  /// commit object in memory.
  ///
  /// Note: For internal use. Use [Commit.lookup] instead.
  @internal
  Commit(this._commitPointer) {
    _finalizer.attach(this, _commitPointer, detach: this);
  }

  /// Lookups commit object for provided [oid] in the [repo]sitory.
  Commit.lookup({required Repository repo, required Oid oid}) {
    _commitPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
    _finalizer.attach(this, _commitPointer, detach: this);
  }

  late final Pointer<git_commit> _commitPointer;

  /// Pointer to memory address for allocated commit object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_commit> get pointer => _commitPointer;

  /// Creates new commit in the [repo]sitory.
  ///
  /// [repo] is the repository where to store the commit.
  ///
  /// [updateRef] is the name of the reference that will be updated to point to
  /// this commit. If the reference is not direct, it will be resolved to a
  /// direct reference. Use "HEAD" to update the HEAD of the current branch and
  /// make it point to this commit. If the reference doesn't exist yet, it will
  /// be created. If it does exist, the first parent must be the tip of this
  /// branch.
  ///
  /// [author] is the signature with author and author time of commit.
  ///
  /// [committer] is the signature with committer and commit time of commit.
  ///
  /// [messageEncoding] is the encoding for the message in the commit,
  /// represented with a standard encoding name. E.g. "UTF-8". If null, no
  /// encoding header is written and UTF-8 is assumed.
  ///
  /// [message] is the full message for this commit. It will not be cleaned up
  /// automatically. I.e. excess whitespace will not be removed and no trailing
  /// newline will be added.
  ///
  /// [tree] is an instance of a [Tree] object that will be used as the tree
  /// for the commit. This tree object must also be owned by the given [repo].
  ///
  /// [parents] is a list of [Commit] objects that will be used as the parents
  /// for this commit. This array may be empty if parent count is 0
  /// (root commit). All the given commits must be owned by the [repo].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required String updateRef,
    required Signature author,
    required Signature committer,
    String? messageEncoding,
    required String message,
    required Tree tree,
    required List<Commit> parents,
  }) {
    return Oid(
      bindings.create(
        repoPointer: repo.pointer,
        updateRef: updateRef,
        authorPointer: author.pointer,
        committerPointer: committer.pointer,
        messageEncoding: messageEncoding,
        message: message,
        treePointer: tree.pointer,
        parentCount: parents.length,
        parents: parents.map((e) => e.pointer).toList(),
      ),
    );
  }

  /// Creates a commit and writes it into a buffer.
  ///
  /// Creates a commit as with [create] but instead of writing it to the
  /// objectdb, writes the contents of the object into a buffer.
  ///
  /// [repo] is the repository where to store the commit.
  ///
  /// [updateRef] is the name of the reference that will be updated to point to
  /// this commit. If the reference is not direct, it will be resolved to a
  /// direct reference. Use "HEAD" to update the HEAD of the current branch and
  /// make it point to this commit. If the reference doesn't exist yet, it will
  /// be created. If it does exist, the first parent must be the tip of this
  /// branch.
  ///
  /// [author] is the signature with author and author time of commit.
  ///
  /// [committer] is the signature with committer and commit time of commit.
  ///
  /// [messageEncoding] is the encoding for the message in the commit,
  /// represented with a standard encoding name. E.g. "UTF-8". If null, no
  /// encoding header is written and UTF-8 is assumed.
  ///
  /// [message] is the full message for this commit.
  ///
  /// [tree] is an instance of a [Tree] object that will be used as the tree
  /// for the commit. This tree object must also be owned by the given [repo].
  ///
  /// [parents] is a list of [Commit] objects that will be used as the parents
  /// for this commit. This array may be empty if parent count is 0
  /// (root commit). All the given commits must be owned by the [repo].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static String createBuffer({
    required Repository repo,
    required String updateRef,
    required Signature author,
    required Signature committer,
    String? messageEncoding,
    required String message,
    required Tree tree,
    required List<Commit> parents,
  }) {
    return bindings.createBuffer(
      repoPointer: repo.pointer,
      updateRef: updateRef,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      messageEncoding: messageEncoding,
      message: message,
      treePointer: tree.pointer,
      parentCount: parents.length,
      parents: parents.map((e) => e.pointer).toList(),
    );
  }

  /// Amends an existing commit by replacing only non-null values.
  ///
  /// This creates a new commit that is exactly the same as the old commit,
  /// except that any non-null values will be updated. The new commit has the
  /// same parents as the old commit.
  ///
  /// The [updateRef] value works as in the regular [create], updating the ref
  /// to point to the newly rewritten commit. If you want to amend a commit
  /// that is not currently the tip of the branch and then rewrite the
  /// following commits to reach a ref, pass this as null and update the rest
  /// of the commit chain and ref separately.
  ///
  /// Unlike [create], the [author], [committer], [message], [messageEncoding],
  /// and [tree] arguments can be null in which case this will use the values
  /// from the original [commit].
  ///
  /// All arguments have the same meanings as in [create].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid amend({
    required Repository repo,
    required Commit commit,
    required String? updateRef,
    Signature? author,
    Signature? committer,
    Tree? tree,
    String? message,
    String? messageEncoding,
  }) {
    return Oid(
      bindings.amend(
        repoPointer: repo.pointer,
        commitPointer: commit.pointer,
        authorPointer: author?.pointer,
        committerPointer: committer?.pointer,
        treePointer: tree?.pointer,
        updateRef: updateRef,
        message: message,
        messageEncoding: messageEncoding,
      ),
    );
  }

  /// Reverts commit, producing changes in the index and working directory.
  ///
  /// [mainline] is parent of the commit if it is a merge (i.e. 1, 2, etc.).
  ///
  /// [mergeFavor] is one of the optional [GitMergeFileFavor] flags for
  /// handling conflicting content.
  ///
  /// [mergeFlags] is optional combination of [GitMergeFlag] flags.
  ///
  /// [mergeFileFlags] is optional combination of [GitMergeFileFlag] flags.
  ///
  /// [checkoutStrategy] is optional combination of [GitCheckout] flags.
  ///
  /// [checkoutDirectory] is optional alternative checkout path to workdir.
  ///
  /// [checkoutPaths] is optional list of files to checkout (by default all
  /// paths are processed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void revert({
    int mainline = 0,
    GitMergeFileFavor? mergeFavor,
    Set<GitMergeFlag>? mergeFlags,
    Set<GitMergeFileFlag>? mergeFileFlags,
    Set<GitCheckout>? checkoutStrategy,
    String? checkoutDirectory,
    List<String>? checkoutPaths,
  }) {
    bindings.revert(
      repoPointer: bindings.owner(_commitPointer),
      commitPointer: _commitPointer,
      mainline: mainline,
      mergeFavor: mergeFavor?.value,
      mergeFlags: mergeFlags?.fold(0, (acc, e) => acc! | e.value),
      mergeFileFlags: mergeFileFlags?.fold(0, (acc, e) => acc! | e.value),
      checkoutStrategy: checkoutStrategy?.fold(0, (acc, e) => acc! | e.value),
      checkoutDirectory: checkoutDirectory,
      checkoutPaths: checkoutPaths,
    );
  }

  /// Reverts commit against provided [commit], producing an index that
  /// reflects the result of the revert.
  ///
  /// [mainline] is parent of the commit if it is a merge (i.e. 1, 2, etc.).
  ///
  /// [mergeFavor] is one of the optional [GitMergeFileFavor] flags for
  /// handling conflicting content.
  ///
  /// [mergeFlags] is optional combination of [GitMergeFlag] flags.
  ///
  /// [mergeFileFlags] is optional combination of [GitMergeFileFlag] flags.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index revertTo({
    required Commit commit,
    int mainline = 0,
    GitMergeFileFavor? mergeFavor,
    Set<GitMergeFlag>? mergeFlags,
    Set<GitMergeFileFlag>? mergeFileFlags,
  }) {
    return Index(
      bindings.revertCommit(
        repoPointer: bindings.owner(_commitPointer),
        revertCommitPointer: _commitPointer,
        ourCommitPointer: commit.pointer,
        mainline: mainline,
        mergeFavor: mergeFavor?.value,
        mergeFlags: mergeFlags?.fold(0, (acc, e) => acc! | e.value),
        mergeFileFlags: mergeFileFlags?.fold(0, (acc, e) => acc! | e.value),
      ),
    );
  }

  /// Encoding for the message of a commit, as a string representing a standard
  /// encoding name.
  ///
  /// If the encoding header in the commit is missing UTF-8 is assumed.
  String get messageEncoding => bindings.messageEncoding(_commitPointer);

  /// Full message of a commit.
  ///
  /// The returned message will be slightly prettified by removing any potential
  /// leading newlines.
  String get message => bindings.message(_commitPointer);

  /// Short "summary" of the git commit message.
  ///
  /// The returned message is the summary of the commit, comprising the first
  /// paragraph of the message with whitespace trimmed and squashed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get summary => bindings.summary(_commitPointer);

  /// Long "body" of the commit message.
  ///
  /// The returned message is the body of the commit, comprising everything but
  /// the first paragraph of the message. Leading and trailing whitespaces are
  /// trimmed.
  ///
  /// Returns empty string if message only consists of a summary.
  String get body => bindings.body(_commitPointer);

  /// [Oid] of a commit.
  Oid get oid => Oid(bindings.id(_commitPointer));

  /// Commit time (i.e. committer time) of a commit.
  int get time => bindings.time(_commitPointer);

  /// Commit timezone offset in minutes (i.e. committer's preferred timezone)
  /// of a commit.
  int get timeOffset => bindings.timeOffset(_commitPointer);

  /// Committer of a commit.
  Signature get committer => Signature(bindings.committer(_commitPointer));

  /// Author of a commit.
  Signature get author => Signature(bindings.author(_commitPointer));

  /// List of parent commits [Oid]s.
  List<Oid> get parents {
    final parentCount = bindings.parentCount(_commitPointer);
    return <Oid>[
      for (var i = 0; i < parentCount; i++)
        Oid(bindings.parentId(commitPointer: _commitPointer, position: i))
    ];
  }

  /// Returns the specified parent of the commit at provided 0-based [position].
  ///
  /// Throws a [LibGit2Error] if error occured.
  Commit parent(int position) {
    return Commit(
      bindings.parent(
        commitPointer: _commitPointer,
        position: position,
      ),
    );
  }

  /// Tree pointed to by a commit.
  Tree get tree => Tree(bindings.tree(_commitPointer));

  /// Oid of the tree pointed to by a commit.
  Oid get treeOid => Oid(bindings.treeOid(_commitPointer));

  /// Returns an arbitrary header field.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String headerField(String field) {
    return bindings.headerField(commitPointer: _commitPointer, field: field);
  }

  /// Returns commit object that is the [n]th generation ancestor of the
  /// commit, following only the first parents.
  ///
  /// Passing 0 as the generation number returns another instance of the base
  /// commit itself.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Commit nthGenAncestor(int n) {
    return Commit(bindings.nthGenAncestor(commitPointer: _commitPointer, n: n));
  }

  /// Checks if commit is the descendant of another [ancestor] commit.
  ///
  /// Note that a commit is not considered a descendant of itself, in contrast
  /// to `git merge-base --is-ancestor`.
  bool descendantOf(Oid ancestor) {
    return graph_bindings.descendantOf(
      repoPointer: bindings.owner(_commitPointer),
      commitPointer: bindings.id(_commitPointer),
      ancestorPointer: ancestor.pointer,
    );
  }

  /// Creates an in-memory copy of a commit.
  Commit duplicate() => Commit(bindings.duplicate(_commitPointer));

  /// Releases memory allocated for commit object.
  void free() {
    bindings.free(_commitPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Commit{oid: $oid, message: $message, '
        'messageEncoding: $messageEncoding, time: $time, committer: $committer,'
        ' author: $author}';
  }

  @override
  List<Object?> get props => [oid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_commit>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
