import 'dart:ffi';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/merge.dart' as bindings;
import 'package:libgit2dart/src/util.dart';

class Merge {
  const Merge._(); // coverage:ignore-line

  /// Finds a merge base between [commits].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid base({required Repository repo, required List<Oid> commits}) {
    return commits.length == 2
        ? Oid(
            bindings.mergeBase(
              repoPointer: repo.pointer,
              aPointer: commits[0].pointer,
              bPointer: commits[1].pointer,
            ),
          )
        : Oid(
            bindings.mergeBaseMany(
              repoPointer: repo.pointer,
              commits: commits.map((e) => e.pointer.ref).toList(),
            ),
          );
  }

  /// Finds a merge base in preparation for an octopus merge.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid octopusBase({
    required Repository repo,
    required List<Oid> commits,
  }) {
    return Oid(
      bindings.mergeBaseOctopus(
        repoPointer: repo.pointer,
        commits: commits.map((e) => e.pointer.ref).toList(),
      ),
    );
  }

  /// Analyzes the given branch's [theirHead] oid and determines the
  /// opportunities for merging them into [ourRef] reference (default is
  /// 'HEAD').
  ///
  /// Returns analysis result and preference for fast forward merge.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static MergeAnalysis analysis({
    required Repository repo,
    required Oid theirHead,
    String ourRef = 'HEAD',
  }) {
    final ref = Reference.lookup(repo: repo, name: ourRef);
    final head = AnnotatedCommit.lookup(
      repo: repo,
      oid: theirHead,
    );
    final analysisInt = bindings.analysis(
      repoPointer: repo.pointer,
      ourRefPointer: ref.pointer,
      theirHeadPointer: head.pointer,
      theirHeadsLen: 1,
    );

    final result = GitMergeAnalysis.values
        .where((e) => analysisInt[0] & e.value == e.value)
        .toSet();
    final preference = GitMergePreference.values.firstWhere(
      (e) => analysisInt[1] == e.value,
    );

    return MergeAnalysis._(result: result, mergePreference: preference);
  }

  /// Merges the given [commit] into HEAD, writing the results into the
  /// working directory. Any changes are staged for commit and any conflicts
  /// are written to the index. Callers should inspect the repository's index
  /// after this completes, resolve any conflicts and prepare a commit.
  ///
  /// For compatibility with git, the repository is put into a merging state.
  /// Once the commit is done (or if the user wishes to abort), that state
  /// should be cleared by calling [stateCleanup] method of [Repository] object.
  ///
  /// [repo] is the repository to merge.
  ///
  /// [commit] is the commit to merge.
  ///
  /// [favor] is one of the [GitMergeFileFavor] flags for handling conflicting
  /// content. Defaults to [GitMergeFileFavor.normal], recording conflict to t
  /// he index.
  ///
  /// [mergeFlags] is a combination of [GitMergeFlag] flags. Defaults to
  /// [GitMergeFlag.findRenames] enabling the ability to merge between a
  /// modified and renamed file.
  ///
  /// [fileFlags] is a combination of [GitMergeFileFlag] flags. Defaults to
  /// [GitMergeFileFlag.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void commit({
    required Repository repo,
    required AnnotatedCommit commit,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFlag> mergeFlags = const {GitMergeFlag.findRenames},
    Set<GitMergeFileFlag> fileFlags = const {GitMergeFileFlag.defaults},
  }) {
    bindings.merge(
      repoPointer: repo.pointer,
      theirHeadPointer: commit.pointer,
      theirHeadsLen: 1,
      favor: favor.value,
      mergeFlags: mergeFlags.fold(0, (acc, e) => acc | e.value),
      fileFlags: fileFlags.fold(0, (acc, e) => acc | e.value),
    );
  }

  /// Merges two commits, producing an index that reflects the result of the
  /// merge. The index may be written as-is to the working directory or checked
  /// out. If the index is to be converted to a tree, the caller should resolve
  /// any conflicts that arose as part of the merge.
  ///
  /// [repo] is the repository that contains the given commits.
  ///
  /// [ourCommit] is the commit that reflects the destination tree.
  ///
  /// [theirCommit] is the commit to merge into [ourCommit].
  ///
  /// [favor] is one of the [GitMergeFileFavor] flags for handling conflicting
  /// content. Defaults to [GitMergeFileFavor.normal], recording conflict to t
  /// he index.
  ///
  /// [mergeFlags] is a combination of [GitMergeFlag] flags. Defaults to
  /// [GitMergeFlag.findRenames] enabling the ability to merge between a
  /// modified and renamed file.
  ///
  /// [fileFlags] is a combination of [GitMergeFileFlag] flags. Defaults to
  /// [GitMergeFileFlag.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Index commits({
    required Repository repo,
    required Commit ourCommit,
    required Commit theirCommit,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFlag> mergeFlags = const {GitMergeFlag.findRenames},
    Set<GitMergeFileFlag> fileFlags = const {GitMergeFileFlag.defaults},
  }) {
    return Index(
      bindings.mergeCommits(
        repoPointer: repo.pointer,
        ourCommitPointer: ourCommit.pointer,
        theirCommitPointer: theirCommit.pointer,
        favor: favor.value,
        mergeFlags: mergeFlags.fold(0, (acc, e) => acc | e.value),
        fileFlags: fileFlags.fold(0, (acc, e) => acc | e.value),
      ),
    );
  }

  /// Merges two trees, producing an index that reflects the result of the
  /// merge. The index may be written as-is to the working directory or checked
  /// out. If the index is to be converted to a tree, the caller should resolve
  /// any conflicts that arose as part of the merge.
  ///
  /// [repo] is the repository that contains the given trees.
  ///
  /// [ancestorTree] is the common ancestor between the trees, or null if none
  /// (default).
  ///
  /// [ourTree] is the tree that reflects the destination tree.
  ///
  /// [theirTree] is the tree to merge into [ourTree].
  ///
  /// [favor] is one of the [GitMergeFileFavor] flags for handling conflicting
  /// content. Defaults to [GitMergeFileFavor.normal], recording conflict to
  /// the index.
  ///
  /// [mergeFlags] is a combination of [GitMergeFlag] flags. Defaults to
  /// [GitMergeFlag.findRenames] enabling the ability to merge between a
  /// modified and renamed file.
  ///
  /// [fileFlags] is a combination of [GitMergeFileFlag] flags. Defaults to
  /// [GitMergeFileFlag.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Index trees({
    required Repository repo,
    Tree? ancestorTree,
    required Tree ourTree,
    required Tree theirTree,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    List<GitMergeFlag> mergeFlags = const [GitMergeFlag.findRenames],
    List<GitMergeFileFlag> fileFlags = const [GitMergeFileFlag.defaults],
  }) {
    return Index(
      bindings.mergeTrees(
        repoPointer: repo.pointer,
        ancestorTreePointer: ancestorTree?.pointer ?? nullptr,
        ourTreePointer: ourTree.pointer,
        theirTreePointer: theirTree.pointer,
        favor: favor.value,
        mergeFlags: mergeFlags.fold(0, (acc, element) => acc | element.value),
        fileFlags: fileFlags.fold(0, (acc, element) => acc | element.value),
      ),
    );
  }

  /// Merges two files as they exist in the in-memory data structures, using the
  /// given common ancestor as the baseline, producing a string that reflects
  /// the merge result.
  ///
  /// Note that this function does not reference a repository and configuration
  /// must be passed as [favor] and [flags].
  ///
  /// [ancestor] is the contents of the ancestor file.
  ///
  /// [ancestorLabel] is optional label for the ancestor file side of the
  /// conflict which will be prepended to labels in diff3-format merge files.
  /// Defaults to "file.txt".
  ///
  /// [ours] is the contents of the file in "our" side.
  ///
  /// [oursLabel] is optional label for our file side of the conflict which
  /// will be prepended to labels in merge files. Defaults to "file.txt".
  ///
  /// [theirs] is the contents of the file in "their" side.
  ///
  /// [theirsLabel] is optional label for their file side of the conflict which
  /// will be prepended to labels in merge files.  Defaults to "file.txt".
  ///
  /// [favor] is one of the [GitMergeFileFavor] flags for handling conflicting
  /// content. Defaults to [GitMergeFileFavor.normal].
  ///
  /// [flags] is a combination of [GitMergeFileFlag] flags. Defaults to
  /// [GitMergeFileFlag.defaults].
  static String file({
    required String ancestor,
    String ancestorLabel = '',
    required String ours,
    String oursLabel = '',
    required String theirs,
    String theirsLabel = '',
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFileFlag> flags = const {GitMergeFileFlag.defaults},
  }) {
    libgit2.git_libgit2_init();

    return bindings.mergeFile(
      ancestor: ancestor,
      ancestorLabel: ancestorLabel,
      ours: ours,
      oursLabel: oursLabel,
      theirs: theirs,
      theirsLabel: theirsLabel,
      favor: favor.value,
      flags: flags.fold(0, (acc, e) => acc | e.value),
    );
  }

  /// Merges two files [ours] and [theirs] as they exist in the index, using the
  /// given common [ancestor] as the baseline, producing a string that reflects
  /// the merge result containing possible conflicts.
  ///
  /// [ancestorLabel] is optional label for the ancestor file side of the
  /// conflict which will be prepended to labels in diff3-format merge files.
  ///
  /// [oursLabel] is optional label for our file side of the conflict which
  /// will be prepended to labels in merge files.
  ///
  /// [theirsLabel] is optional label for their file side of the conflict which
  /// will be prepended to labels in merge files.
  ///
  /// [favor] is one of the [GitMergeFileFavor] flags for handling conflicting
  /// content. Defaults to [GitMergeFileFavor.normal].
  ///
  /// [flags] is a combination of [GitMergeFileFlag] flags. Defaults to
  /// [GitMergeFileFlag.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static String fileFromIndex({
    required Repository repo,
    required IndexEntry? ancestor,
    String ancestorLabel = '',
    required IndexEntry ours,
    String oursLabel = '',
    required IndexEntry theirs,
    String theirsLabel = '',
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFileFlag> flags = const {GitMergeFileFlag.defaults},
  }) {
    return bindings.mergeFileFromIndex(
      repoPointer: repo.pointer,
      ancestorPointer: ancestor?.pointer,
      ancestorLabel: ancestorLabel,
      oursPointer: ours.pointer,
      oursLabel: oursLabel,
      theirsPointer: theirs.pointer,
      theirsLabel: theirsLabel,
      favor: favor.value,
      flags: flags.fold(0, (acc, e) => acc | e.value),
    );
  }

  /// Cherry-picks the provided [commit], producing changes in the index and
  /// working directory.
  ///
  /// Any changes are staged for commit and any conflicts are written to the
  /// index. Callers should inspect the repository's index after this
  /// completes, resolve any conflicts and prepare a commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void cherryPick({required Repository repo, required Commit commit}) {
    bindings.cherryPick(
      repoPointer: repo.pointer,
      commitPointer: commit.pointer,
    );
  }
}

class MergeAnalysis {
  const MergeAnalysis._({required this.result, required this.mergePreference});

  /// Merge opportunities.
  final Set<GitMergeAnalysis> result;

  /// The user's stated preference for merges.
  final GitMergePreference mergePreference;
}
