import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/diff.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

@immutable
class Diff extends Equatable {
  /// Initializes a new instance of [Diff] class from provided
  /// pointer to diff object in memory.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Diff.indexToWorkdir]
  /// - [Diff.indexToIndex]
  /// - [Diff.treeToIndex]
  /// - [Diff.treeToWorkdir]
  /// - [Diff.treeToWorkdirWithIndex]
  /// - [Diff.treeToTree]
  /// - [Diff.parse]
  @internal
  Diff(this._diffPointer) {
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff between the [repo]sitory [index] and the workdir directory.
  ///
  /// This matches the `git diff` command.
  ///
  /// [repo] is the repository containing index.
  ///
  /// [index] is the index to diff from.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff.indexToWorkdir({
    required Repository repo,
    required Index index,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _diffPointer = bindings.indexToWorkdir(
      repoPointer: repo.pointer,
      indexPointer: index.pointer,
      flags: flags.fold(0, (int acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff between a [tree] and [repo]sitory [index].
  ///
  /// This is equivalent to `git diff --cached <treeish>` or if you pass the
  /// HEAD tree, then like `git diff --cached`.
  ///
  /// [repo] is the repository containing the tree and index.
  ///
  /// [tree] is the [Tree] object to diff from or null for empty tree.
  ///
  /// [index] is the index to diff with.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  Diff.treeToIndex({
    required Repository repo,
    required Tree? tree,
    required Index index,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _diffPointer = bindings.treeToIndex(
      repoPointer: repo.pointer,
      treePointer: tree?.pointer,
      indexPointer: index.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff between a [tree] and the working directory.
  ///
  /// This is not the same as `git diff <treeish>` or
  /// `git diff-index <treeish>`. Those commands use information from the
  /// index, whereas this method strictly returns the differences between the
  /// tree and the files in the working directory, regardless of the state of
  /// the index. Use [Diff.treeToWorkdirWithIndex] to emulate those commands.
  ///
  /// To see difference between this and [Diff.treeToWorkdirWithIndex],
  /// consider the example of a staged file deletion where the file has then
  /// been put back into the working directory and further modified. The
  /// tree-to-workdir diff for that file is 'modified', but `git diff` would
  /// show status 'deleted' since there is a staged delete.
  ///
  /// [repo] is the repository containing the tree.
  ///
  /// [tree] is the [Tree] object to diff from or null for empty tree.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  Diff.treeToWorkdir({
    required Repository repo,
    required Tree? tree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _diffPointer = bindings.treeToWorkdir(
      repoPointer: repo.pointer,
      treePointer: tree?.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff between a [tree] and the working directory using index
  /// data to account for staged deletes, tracked files, etc.
  ///
  /// This emulates `git diff <tree>` by diffing the tree to the index and the
  /// index to the working directory and blending the results into a single diff
  /// that includes staged deleted, etc.
  ///
  /// [repo] is the repository containing the tree.
  ///
  /// [tree] is a [Tree] object to diff from, or null for empty tree.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff.treeToWorkdirWithIndex({
    required Repository repo,
    required Tree? tree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _diffPointer = bindings.treeToWorkdirWithIndex(
      repoPointer: repo.pointer,
      treePointer: tree?.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff with the difference between two [Tree] objects.
  ///
  /// This is equivalent to `git diff <old-tree> <new-tree>`.
  ///
  /// [repo] is the repository containing the trees.
  ///
  /// [oldTree] is the [Tree] object to diff from, or null for empty tree.
  ///
  /// [newTree] is the [Tree] object to diff to, or null for empty tree.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if both trees
  /// are null.
  Diff.treeToTree({
    required Repository repo,
    required Tree? oldTree,
    required Tree? newTree,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    if (oldTree == null && newTree == null) {
      throw ArgumentError('Both trees cannot be null');
    }

    _diffPointer = bindings.treeToTree(
      repoPointer: repo.pointer,
      oldTreePointer: oldTree?.pointer,
      newTreePointer: newTree?.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Creates a diff with the difference between two [Index] objects.
  ///
  /// [repo] is the repository containing the indexes.
  ///
  /// [oldIndex] is the [Index] object to diff from.
  ///
  /// [newIndex] is the [Index] object to diff to.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff.indexToIndex({
    required Repository repo,
    required Index oldIndex,
    required Index newIndex,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _diffPointer = bindings.indexToIndex(
      repoPointer: repo.pointer,
      oldIndexPointer: oldIndex.pointer,
      newIndexPointer: newIndex.pointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  /// Reads the [content]s of a git patch file into a git diff object.
  ///
  /// The diff object produced is similar to the one that would be produced if
  /// you actually produced it computationally by comparing two trees, however
  /// there may be subtle differences. For example, a patch file likely
  /// contains abbreviated object IDs, so the object IDs in a diff delta
  /// produced by this function will also be abbreviated.
  ///
  /// This function will only read patch files created by a git implementation,
  /// it will not read unified diffs produced by the `diff` program, nor any
  /// other types of patch files.
  Diff.parse(String content) {
    libgit2.git_libgit2_init();
    _diffPointer = bindings.parse(content);
    _finalizer.attach(this, _diffPointer, detach: this);
  }

  late final Pointer<git_diff> _diffPointer;

  /// Pointer to memory address for allocated diff object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_diff> get pointer => _diffPointer;

  /// How many diff records are there in a diff.
  int get length => bindings.length(_diffPointer);

  /// Returns a list of [DiffDelta]s containing file pairs with and old and new
  /// revisions.
  List<DiffDelta> get deltas {
    final length = bindings.length(_diffPointer);
    return <DiffDelta>[
      for (var i = 0; i < length; i++)
        DiffDelta(bindings.getDeltaByIndex(diffPointer: _diffPointer, index: i))
    ];
  }

  /// A List of [Patch]es.
  List<Patch> get patches {
    final length = bindings.length(_diffPointer);
    return <Patch>[
      for (var i = 0; i < length; i++) Patch.fromDiff(diff: this, index: i)
    ];
  }

  /// The patch diff text.
  String get patch => bindings.addToBuf(_diffPointer);

  /// Accumulates diff statistics for all patches.
  ///
  /// Throws a [LibGit2Error] if error occured.
  DiffStats get stats => DiffStats(bindings.stats(_diffPointer));

  /// Merges one diff into another.
  void merge(Diff diff) {
    bindings.merge(
      ontoPointer: _diffPointer,
      fromPointer: diff.pointer,
    );
  }

  /// Applies the diff to the [repo]sitory, making changes in the provided
  /// [location].
  ///
  /// [repo] is the repository to apply to.
  ///
  /// [hunkIndex] is optional index of the hunk to apply.
  ///
  /// [location] is the location to apply (workdir, index or both).
  /// Defaults to workdir.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void apply({
    required Repository repo,
    int? hunkIndex,
    GitApplyLocation location = GitApplyLocation.workdir,
  }) {
    bindings.apply(
      repoPointer: repo.pointer,
      diffPointer: _diffPointer,
      hunkIndex: hunkIndex,
      location: location.value,
    );
  }

  /// Checks if the diff will apply to provided [location].
  ///
  /// [repo] is the repository to apply to.
  ///
  /// [hunkIndex] is optional index of the hunk to apply.
  ///
  /// [location] is the location to apply (workdir, index or both).
  /// Defaults to workdir.
  bool applies({
    required Repository repo,
    int? hunkIndex,
    GitApplyLocation location = GitApplyLocation.workdir,
  }) {
    return bindings.apply(
      repoPointer: repo.pointer,
      diffPointer: _diffPointer,
      hunkIndex: hunkIndex,
      location: location.value,
      check: true,
    );
  }

  /// Applies the diff to the [tree], and returns the resulting image as an
  /// index.
  ///
  /// [repo] is the repository to apply to.
  ///
  /// [tree] is the tree to apply the diff to.
  ///
  /// [hunkIndex] is optional index of the hunk to apply.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index applyToTree({
    required Repository repo,
    required Tree tree,
    int? hunkIndex,
  }) {
    return Index(
      bindings.applyToTree(
        repoPointer: repo.pointer,
        diffPointer: _diffPointer,
        treePointer: tree.pointer,
        hunkIndex: hunkIndex,
      ),
    );
  }

  /// Transforms a diff marking file renames, copies, etc.
  ///
  /// This modifies a diff in place, replacing old entries that look like
  /// renames or copies with new entries reflecting those changes. This also
  /// will, if requested, break modified files into add/remove pairs if the
  /// amount of change is above a threshold.
  ///
  /// [flags] is a combination of [GitDiffFind] flags. Defaults to
  /// [GitDiffFind.byConfig].
  ///
  /// [renameThreshold] is the threshold above which similar files will be
  /// considered renames. This is equivalent to the -M option. Defaults to 50.
  ///
  /// [copyThreshold] is the threshold above which similar files will be
  /// considered copies. This is equivalent to the -C option. Defaults to 50.
  ///
  /// [renameFromRewriteThreshold] is the threshold below which similar files
  /// will be eligible to be a rename source. This is equivalent to the first
  /// part of the -B option. Defaults to 50.
  ///
  /// [breakRewriteThreshold] is the treshold below which similar files will be
  /// split into a delete/add pair. This is equivalent to the last part of the -B
  /// option. Defaults to 60.
  ///
  /// [renameLimit] is the maximum number of matches to consider for a
  /// particular file. This is a little different from the -l option from Git
  /// because we will still process up to this many matches before abandoning
  /// the search. Defaults to 200.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void findSimilar({
    Set<GitDiffFind> flags = const {GitDiffFind.byConfig},
    int renameThreshold = 50,
    int copyThreshold = 50,
    int renameFromRewriteThreshold = 50,
    int breakRewriteThreshold = 60,
    int renameLimit = 200,
  }) {
    bindings.findSimilar(
      diffPointer: _diffPointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      renameThreshold: renameThreshold,
      copyThreshold: copyThreshold,
      renameFromRewriteThreshold: renameFromRewriteThreshold,
      breakRewriteThreshold: breakRewriteThreshold,
      renameLimit: renameLimit,
    );
  }

  /// Calculates a stable patch [Oid] for the given patch by summing the hash
  /// of the file diffs, ignoring whitespace and line numbers. This can be used
  /// to derive whether two diffs are the same with a high probability.
  ///
  /// Currently, this function only calculates stable patch IDs, as defined in
  /// `git-patch-id(1)`, and should in fact generate the same IDs as the
  /// upstream git project does.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid get patchOid => Oid(bindings.patchOid(_diffPointer));

  /// Releases memory allocated for diff object.
  void free() {
    bindings.free(_diffPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Diff{length: $length, patchOid: $patchOid}';
  }

  @override
  List<Object?> get props => [patchOid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_diff>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

@immutable
class DiffDelta extends Equatable {
  /// Initializes a new instance of [DiffDelta] class from provided
  /// pointer to diff delta object in memory.
  ///
  /// Note: For internal use.
  @internal
  const DiffDelta(this._diffDeltaPointer);

  /// Pointer to memory address for allocated diff delta object.
  final Pointer<git_diff_delta> _diffDeltaPointer;

  /// Type of change.
  GitDelta get status {
    return GitDelta.values.firstWhere(
      (e) => _diffDeltaPointer.ref.status == e.value,
    );
  }

  /// Single character abbreviation for a delta status code.
  ///
  /// When you run `git diff --name-status` it uses single letter codes in the
  /// output such as 'A' for added, 'D' for deleted, 'M' for modified, etc.
  /// This function converts a [GitDelta] value into these letters for your own
  /// purposes. [GitDelta.untracked] will return a space (i.e. ' ').
  String get statusChar => bindings.statusChar(_diffDeltaPointer.ref.status);

  /// Flags for the delta object.
  Set<GitDiffFlag> get flags {
    return GitDiffFlag.values
        .where((e) => _diffDeltaPointer.ref.flags & e.value == e.value)
        .toSet();
  }

  /// Similarity score for renamed or copied files between 0 and 100
  /// indicating how similar the old and new sides are.
  int get similarity => _diffDeltaPointer.ref.similarity;

  /// Number of files in this delta.
  int get numberOfFiles => _diffDeltaPointer.ref.nfiles;

  /// Represents the "from" side of the diff.
  DiffFile get oldFile => DiffFile._(_diffDeltaPointer.ref.old_file);

  /// Represents the "to" side of the diff.
  DiffFile get newFile => DiffFile._(_diffDeltaPointer.ref.new_file);

  @override
  String toString() {
    return 'DiffDelta{status: $status, flags: $flags, similarity: $similarity, '
        'numberOfFiles: $numberOfFiles, oldFile: $oldFile, newFile: $newFile}';
  }

  @override
  List<Object?> get props => [
        status,
        flags,
        similarity,
        numberOfFiles,
        oldFile,
        newFile,
      ];
}

/// Description of one side of a delta.
///
/// Although this is called a "file", it could represent a file, a symbolic
/// link, a submodule commit id, or even a tree (although that only if you
/// are tracking type changes or ignored/untracked directories).
@immutable
class DiffFile extends Equatable {
  /// Initializes a new instance of [DiffFile] class from provided diff file
  /// object.
  const DiffFile._(this._diffFile);

  final git_diff_file _diffFile;

  /// [Oid] of the item. If the entry represents an absent side of a diff
  /// then the oid will be zeroes.
  Oid get oid => Oid.fromRaw(_diffFile.id);

  /// Path to the entry relative to the working directory of the repository.
  String get path => _diffFile.path.toDartString();

  /// Size of the entry in bytes.
  int get size => _diffFile.size;

  /// Flags for the diff file object.
  Set<GitDiffFlag> get flags {
    return GitDiffFlag.values
        .where((e) => _diffFile.flags & e.value == e.value)
        .toSet();
  }

  /// One of the [GitFilemode] values.
  GitFilemode get mode {
    return GitFilemode.values.firstWhere((e) => _diffFile.mode == e.value);
  }

  @override
  String toString() {
    return 'DiffFile{oid: $oid, path: $path, size: $size, flags: $flags, '
        'mode: $mode}';
  }

  @override
  List<Object?> get props => [oid, path, size, flags, mode];
}

class DiffStats {
  /// Initializes a new instance of [DiffStats] class from provided
  /// pointer to diff stats object in memory.
  ///
  /// Note: For internal use.
  @internal
  DiffStats(this._diffStatsPointer) {
    _statsFinalizer.attach(this, _diffStatsPointer, detach: this);
  }

  /// Pointer to memory address for allocated diff delta object.
  final Pointer<git_diff_stats> _diffStatsPointer;

  /// Total number of insertions.
  int get insertions => bindings.statsInsertions(_diffStatsPointer);

  /// Total number of deletions.
  int get deletions => bindings.statsDeletions(_diffStatsPointer);

  /// Total number of files changed.
  int get filesChanged => bindings.statsFilesChanged(_diffStatsPointer);

  /// Prints diff statistics.
  ///
  /// Width for output only affects formatting of [GitDiffStats.full].
  ///
  /// Throws a [LibGit2Error] if error occured.
  String print({required Set<GitDiffStats> format, required int width}) {
    return bindings.statsPrint(
      statsPointer: _diffStatsPointer,
      format: format.fold(0, (acc, e) => acc | e.value),
      width: width,
    );
  }

  /// Releases memory allocated for diff stats object.
  void free() {
    bindings.freeStats(_diffStatsPointer);
    _statsFinalizer.detach(this);
  }

  @override
  String toString() {
    return 'DiffStats{insertions: $insertions, deletions: $deletions, '
        'filesChanged: $filesChanged}';
  }
}

// coverage:ignore-start
final _statsFinalizer = Finalizer<Pointer<git_diff_stats>>(
  (pointer) => bindings.freeStats(pointer),
);
// coverage:ignore-end
