/// Basic type of any Git reference.
class ReferenceType {
  const ReferenceType._(this._value);
  final int _value;

  /// Invalid reference.
  static const invalid = ReferenceType._(0);

  /// A reference that points at an object id.
  static const direct = ReferenceType._(1);

  /// A reference that points at another reference.
  static const symbolic = ReferenceType._(2);

  static const all = ReferenceType._(3);

  int get value => _value;
}

/// Valid modes for index and tree entries.
class GitFilemode {
  const GitFilemode._(this._value);
  final int _value;

  static const unreadable = GitFilemode._(0);
  static const tree = GitFilemode._(16384);
  static const blob = GitFilemode._(33188);
  static const blobExecutable = GitFilemode._(33261);
  static const link = GitFilemode._(40960);
  static const commit = GitFilemode._(57344);

  int get value => _value;
}

/// Flags to specify the sorting which a revwalk should perform.
class GitSort {
  const GitSort._(this._value);
  final int _value;

  /// Sort the output with the same default method from `git`: reverse
  /// chronological order. This is the default sorting for new walkers.
  static const none = GitSort._(0);

  /// Sort the repository contents in topological order (no parents before
  /// all of its children are shown); this sorting mode can be combined
  /// with time sorting to produce `git`'s `--date-order``.
  static const topological = GitSort._(1);

  /// Sort the repository contents by commit time;
  /// this sorting mode can be combined with topological sorting.
  static const time = GitSort._(2);

  /// Iterate through the repository contents in reverse order; this sorting mode
  /// can be combined with any of the above.
  static const reverse = GitSort._(4);

  int get value => _value;
}

/// Basic type (loose or packed) of any Git object.
class GitObject {
  const GitObject._(this._value);
  final int _value;

  /// Object can be any of the following.
  static const any = GitObject._(-2);

  /// Object is invalid.
  static const invalid = GitObject._(-1);

  /// A commit object.
  static const commit = GitObject._(1);

  /// A tree (directory listing) object.
  static const tree = GitObject._(2);

  /// A file revision object.
  static const blob = GitObject._(3);

  /// An annotated tag object.
  static const tag = GitObject._(4);

  /// A delta, base is given by an offset.
  static const offsetDelta = GitObject._(6);

  /// A delta, base is given by object id.
  static const refDelta = GitObject._(7);

  int get value => _value;
}

/// Revparse flags, indicate the intended behavior of the spec.
class GitRevParse {
  const GitRevParse._(this._value);
  final int _value;

  /// The spec targeted a single object.
  static const single = GitRevParse._(1);

  /// The spec targeted a range of commits.
  static const range = GitRevParse._(2);

  /// The spec used the '...' operator, which invokes special semantics.
  static const mergeBase = GitRevParse._(4);

  int get value => _value;
}

/// Basic type of any Git branch.
class GitBranch {
  const GitBranch._(this._value);
  final int _value;

  static const local = GitBranch._(1);
  static const remote = GitBranch._(2);
  static const all = GitBranch._(3);

  int get value => _value;
}

/// Status flags for a single file.
///
/// A combination of these values will be returned to indicate the status of
/// a file.  Status compares the working directory, the index, and the
/// current HEAD of the repository.  The `GitStatus.index` set of flags
/// represents the status of file in the index relative to the HEAD, and the
/// `GitStatus.wt` set of flags represent the status of the file in the
/// working directory relative to the index.
class GitStatus {
  const GitStatus._(this._value);
  final int _value;

  static const current = GitStatus._(0);
  static const indexNew = GitStatus._(1);
  static const indexModified = GitStatus._(2);
  static const indexDeleted = GitStatus._(4);
  static const indexRenamed = GitStatus._(8);
  static const indexTypeChange = GitStatus._(16);
  static const wtNew = GitStatus._(128);
  static const wtModified = GitStatus._(256);
  static const wtDeleted = GitStatus._(512);
  static const wtTypeChange = GitStatus._(1024);
  static const wtRenamed = GitStatus._(2048);
  static const wtUnreadable = GitStatus._(4096);
  static const ignored = GitStatus._(16384);
  static const conflicted = GitStatus._(32768);

  int get value => _value;
}

/// The results of `mergeAnalysis` indicate the merge opportunities.
class GitMergeAnalysis {
  const GitMergeAnalysis._(this._value);
  final int _value;

  /// No merge is possible (unused).
  static const none = GitMergeAnalysis._(0);

  /// A "normal" merge; both HEAD and the given merge input have diverged
  /// from their common ancestor.  The divergent commits must be merged.
  static const normal = GitMergeAnalysis._(1);

  /// All given merge inputs are reachable from HEAD, meaning the
  /// repository is up-to-date and no merge needs to be performed.
  static const upToDate = GitMergeAnalysis._(2);

  /// The given merge input is a fast-forward from HEAD and no merge
  /// needs to be performed.  Instead, the client can check out the
  /// given merge input.
  static const fastForward = GitMergeAnalysis._(4);

  /// The HEAD of the current repository is "unborn" and does not point to
  /// a valid commit.  No merge can be performed, but the caller may wish
  /// to simply set HEAD to the target commit(s).
  static const unborn = GitMergeAnalysis._(8);

  int get value => _value;
}

/// The user's stated preference for merges.
class GitMergePreference {
  const GitMergePreference._(this._value);
  final int _value;

  /// No configuration was found that suggests a preferred behavior for merge.
  static const none = GitMergePreference._(0);

  /// There is a `merge.ff=false` configuration setting, suggesting that
  /// the user does not want to allow a fast-forward merge.
  static const noFastForward = GitMergePreference._(1);

  /// There is a `merge.ff=only` configuration setting, suggesting that
  /// the user only wants fast-forward merges.
  static const fastForwardOnly = GitMergePreference._(2);

  int get value => _value;
}

/// Repository state.
///
/// These values represent possible states for the repository to be in,
/// based on the current operation which is ongoing.
class GitRepositoryState {
  const GitRepositoryState._(this._value);
  final int _value;

  static const none = GitRepositoryState._(0);
  static const merge = GitRepositoryState._(1);
  static const revert = GitRepositoryState._(2);
  static const reverSequence = GitRepositoryState._(3);
  static const cherrypick = GitRepositoryState._(4);
  static const cherrypickSequence = GitRepositoryState._(5);
  static const bisect = GitRepositoryState._(6);
  static const rebase = GitRepositoryState._(7);
  static const rebaseInteractive = GitRepositoryState._(8);
  static const rebaseMerge = GitRepositoryState._(9);
  static const applyMailbox = GitRepositoryState._(10);
  static const applyMailboxOrRebase = GitRepositoryState._(11);

  int get value => _value;
}

/// Flags for merge options.
class GitMergeFlag {
  const GitMergeFlag._(this._value);
  final int _value;

  /// Detect renames that occur between the common ancestor and the "ours"
  /// side or the common ancestor and the "theirs" side.  This will enable
  /// the ability to merge between a modified and renamed file.
  static const findRenames = GitMergeFlag._(1);

  /// If a conflict occurs, exit immediately instead of attempting to
  /// continue resolving conflicts.  The merge operation will fail with
  /// and no index will be returned.
  static const failOnConflict = GitMergeFlag._(2);

  /// Do not write the REUC extension on the generated index.
  static const skipREUC = GitMergeFlag._(4);

  /// If the commits being merged have multiple merge bases, do not build
  /// a recursive merge base (by merging the multiple merge bases),
  /// instead simply use the first base.
  static const noRecursive = GitMergeFlag._(8);

  int get value => _value;
}

/// Merge file favor options to instruct the file-level merging functionality
/// on how to deal with conflicting regions of the files.
class GitMergeFileFavor {
  const GitMergeFileFavor._(this._value);
  final int _value;

  /// When a region of a file is changed in both branches, a conflict
  /// will be recorded in the index. This is the default.
  static const normal = GitMergeFileFavor._(0);

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "ours" side of any conflicting
  /// region. The index will not record a conflict.
  static const ours = GitMergeFileFavor._(1);

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "theirs" side of any conflicting
  /// region. The index will not record a conflict.
  static const theirs = GitMergeFileFavor._(2);

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain each unique line from each side,
  /// which has the result of combining both files. The index will not
  /// record a conflict.
  static const union = GitMergeFileFavor._(3);

  int get value => _value;
}

/// File merging flags.
class GitMergeFileFlag {
  const GitMergeFileFlag._(this._value);
  final int _value;

  /// Defaults.
  static const defaults = GitMergeFileFlag._(0);

  /// Create standard conflicted merge files.
  static const styleMerge = GitMergeFileFlag._(1);

  /// Create diff3-style files.
  static const styleDiff3 = GitMergeFileFlag._(2);

  /// Condense non-alphanumeric regions for simplified diff file.
  static const simplifyAlnum = GitMergeFileFlag._(4);

  /// Ignore all whitespace.
  static const ignoreWhitespace = GitMergeFileFlag._(8);

  /// Ignore changes in amount of whitespace.
  static const ignoreWhitespaceChange = GitMergeFileFlag._(16);

  /// Ignore whitespace at end of line.
  static const ignoreWhitespaceEOL = GitMergeFileFlag._(32);

  /// Use the "patience diff" algorithm.
  static const diffPatience = GitMergeFileFlag._(64);

  /// Take extra time to find minimal diff.
  static const diffMinimal = GitMergeFileFlag._(128);

  int get value => _value;
}
