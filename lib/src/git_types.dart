/// Basic type of any Git reference.
class ReferenceType {
  const ReferenceType._(this._value, this._name);
  final int _value;
  final String _name;

  /// Invalid reference.
  static const invalid = ReferenceType._(0, 'invalid');

  /// A reference that points at an object id.
  static const direct = ReferenceType._(1, 'direct');

  /// A reference that points at another reference.
  static const symbolic = ReferenceType._(2, 'symbolic');

  static const all = ReferenceType._(3, 'all');

  static const List<ReferenceType> values = [invalid, direct, symbolic, all];

  int get value => _value;

  @override
  String toString() => 'ReferenceType.$_name';
}

/// Valid modes for index and tree entries.
class GitFilemode {
  const GitFilemode._(this._value, this._name);
  final int _value;
  final String _name;

  static const unreadable = GitFilemode._(0, 'unreadable');
  static const tree = GitFilemode._(16384, 'tree');
  static const blob = GitFilemode._(33188, 'blob');
  static const blobExecutable = GitFilemode._(33261, 'blobExecutable');
  static const link = GitFilemode._(40960, 'link');
  static const commit = GitFilemode._(57344, 'commit');

  static const List<GitFilemode> values = [
    unreadable,
    tree,
    blob,
    blobExecutable,
    link,
    commit,
  ];

  int get value => _value;

  @override
  String toString() => 'GitFilemode.$_name';
}

/// Flags to specify the sorting which a revwalk should perform.
class GitSort {
  const GitSort._(this._value, this._name);
  final int _value;
  final String _name;

  /// Sort the output with the same default method from `git`: reverse
  /// chronological order. This is the default sorting for new walkers.
  static const none = GitSort._(0, 'none');

  /// Sort the repository contents in topological order (no parents before
  /// all of its children are shown); this sorting mode can be combined
  /// with time sorting to produce `git`'s `--date-order``.
  static const topological = GitSort._(1, 'topological');

  /// Sort the repository contents by commit time;
  /// this sorting mode can be combined with topological sorting.
  static const time = GitSort._(2, 'time');

  /// Iterate through the repository contents in reverse order; this sorting mode
  /// can be combined with any of the above.
  static const reverse = GitSort._(4, 'reverse');

  static const List<GitSort> values = [none, topological, time, reverse];

  int get value => _value;

  @override
  String toString() => 'GitSort.$_name';
}

/// Basic type (loose or packed) of any Git object.
class GitObject {
  const GitObject._(this._value, this._name);
  final int _value;
  final String _name;

  /// Object can be any of the following.
  static const any = GitObject._(-2, 'any');

  /// Object is invalid.
  static const invalid = GitObject._(-1, 'invalid');

  /// A commit object.
  static const commit = GitObject._(1, 'commit');

  /// A tree (directory listing) object.
  static const tree = GitObject._(2, 'tree');

  /// A file revision object.
  static const blob = GitObject._(3, 'blob');

  /// An annotated tag object.
  static const tag = GitObject._(4, 'tag');

  /// A delta, base is given by an offset.
  static const offsetDelta = GitObject._(6, 'offsetDelta');

  /// A delta, base is given by object id.
  static const refDelta = GitObject._(7, 'refDelta');

  static const List<GitObject> values = [
    any,
    invalid,
    commit,
    tree,
    blob,
    tag,
    offsetDelta,
    refDelta,
  ];

  int get value => _value;

  @override
  String toString() => 'GitObject.$_name';
}

/// Revparse flags, indicate the intended behavior of the spec.
class GitRevParse {
  const GitRevParse._(this._value, this._name);
  final int _value;
  final String _name;

  /// The spec targeted a single object.
  static const single = GitRevParse._(1, 'single');

  /// The spec targeted a range of commits.
  static const range = GitRevParse._(2, 'range');

  /// The spec used the '...' operator, which invokes special semantics.
  static const mergeBase = GitRevParse._(4, 'mergeBase');

  static const List<GitRevParse> values = [single, range, mergeBase];

  int get value => _value;

  @override
  String toString() => 'GitRevParse.$_name';
}

/// Basic type of any Git branch.
class GitBranch {
  const GitBranch._(this._value, this._name);
  final int _value;
  final String _name;

  static const local = GitBranch._(1, 'local');
  static const remote = GitBranch._(2, 'remote');
  static const all = GitBranch._(3, 'all');

  static const List<GitBranch> values = [local, remote, all];

  int get value => _value;

  @override
  String toString() => 'GitBranch.$_name';
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
  const GitStatus._(this._value, this._name);
  final int _value;
  final String _name;

  static const current = GitStatus._(0, 'current');
  static const indexNew = GitStatus._(1, 'indexNew');
  static const indexModified = GitStatus._(2, 'indexModified');
  static const indexDeleted = GitStatus._(4, 'indexDeleted');
  static const indexRenamed = GitStatus._(8, 'indexRenamed');
  static const indexTypeChange = GitStatus._(16, 'indexTypeChange');
  static const wtNew = GitStatus._(128, 'wtNew');
  static const wtModified = GitStatus._(256, 'wtModified');
  static const wtDeleted = GitStatus._(512, 'wtDeleted');
  static const wtTypeChange = GitStatus._(1024, 'wtTypeChange');
  static const wtRenamed = GitStatus._(2048, 'wtRenamed');
  static const wtUnreadable = GitStatus._(4096, 'wtUnreadable');
  static const ignored = GitStatus._(16384, 'ignored');
  static const conflicted = GitStatus._(32768, 'conflicted');

  static const List<GitStatus> values = [
    current,
    indexNew,
    indexModified,
    indexDeleted,
    indexRenamed,
    indexTypeChange,
    wtNew,
    wtModified,
    wtDeleted,
    wtTypeChange,
    wtRenamed,
    wtUnreadable,
    ignored,
    conflicted,
  ];

  int get value => _value;

  @override
  String toString() => 'GitStatus.$_name';
}

/// The results of `mergeAnalysis` indicate the merge opportunities.
class GitMergeAnalysis {
  const GitMergeAnalysis._(this._value, this._name);
  final int _value;
  final String _name;

  /// No merge is possible (unused).
  static const none = GitMergeAnalysis._(0, 'none');

  /// A "normal" merge; both HEAD and the given merge input have diverged
  /// from their common ancestor. The divergent commits must be merged.
  static const normal = GitMergeAnalysis._(1, 'normal');

  /// All given merge inputs are reachable from HEAD, meaning the
  /// repository is up-to-date and no merge needs to be performed.
  static const upToDate = GitMergeAnalysis._(2, 'upToDate');

  /// The given merge input is a fast-forward from HEAD and no merge
  /// needs to be performed. Instead, the client can check out the
  /// given merge input.
  static const fastForward = GitMergeAnalysis._(4, 'fastForward');

  /// The HEAD of the current repository is "unborn" and does not point to
  /// a valid commit. No merge can be performed, but the caller may wish
  /// to simply set HEAD to the target commit(s).
  static const unborn = GitMergeAnalysis._(8, 'unborn');

  static const List<GitMergeAnalysis> values = [
    normal,
    upToDate,
    fastForward,
    unborn,
  ];

  int get value => _value;

  @override
  String toString() => 'GitMergeAnalysis.$_name';
}

/// The user's stated preference for merges.
class GitMergePreference {
  const GitMergePreference._(this._value, this._name);
  final int _value;
  final String _name;

  /// No configuration was found that suggests a preferred behavior for merge.
  static const none = GitMergePreference._(0, 'none');

  /// There is a `merge.ff=false` configuration setting, suggesting that
  /// the user does not want to allow a fast-forward merge.
  static const noFastForward = GitMergePreference._(1, 'noFastForward');

  /// There is a `merge.ff=only` configuration setting, suggesting that
  /// the user only wants fast-forward merges.
  static const fastForwardOnly = GitMergePreference._(2, 'fastForwardOnly');

  static const List<GitMergePreference> values = [
    none,
    noFastForward,
    fastForwardOnly,
  ];

  int get value => _value;

  @override
  String toString() => 'GitMergePreference.$_name';
}

/// Repository state.
///
/// These values represent possible states for the repository to be in,
/// based on the current operation which is ongoing.
class GitRepositoryState {
  const GitRepositoryState._(this._value, this._name);
  final int _value;
  final String _name;

  static const none = GitRepositoryState._(0, 'none');
  static const merge = GitRepositoryState._(1, 'merge');
  static const revert = GitRepositoryState._(2, 'revert');
  static const revertSequence = GitRepositoryState._(3, 'revertSequence');
  static const cherrypick = GitRepositoryState._(4, 'cherrypick');
  static const cherrypickSequence =
      GitRepositoryState._(5, 'cherrypickSequence');
  static const bisect = GitRepositoryState._(6, 'bisect');
  static const rebase = GitRepositoryState._(7, 'rebase');
  static const rebaseInteractive = GitRepositoryState._(8, 'rebaseInteractive');
  static const rebaseMerge = GitRepositoryState._(9, 'rebaseMerge');
  static const applyMailbox = GitRepositoryState._(10, 'applyMailbox');
  static const applyMailboxOrRebase =
      GitRepositoryState._(11, 'applyMailboxOrRebase');

  static const List<GitRepositoryState> values = [
    none,
    merge,
    revert,
    revertSequence,
    cherrypick,
    cherrypickSequence,
    bisect,
    rebase,
    rebaseInteractive,
    rebaseMerge,
    applyMailbox,
    applyMailboxOrRebase,
  ];

  int get value => _value;

  @override
  String toString() => 'GitRepositoryState.$_name';
}

/// Flags for merge options.
class GitMergeFlag {
  const GitMergeFlag._(this._value, this._name);
  final int _value;
  final String _name;

  /// Detect renames that occur between the common ancestor and the "ours"
  /// side or the common ancestor and the "theirs" side.  This will enable
  /// the ability to merge between a modified and renamed file.
  static const findRenames = GitMergeFlag._(1, 'findRenames');

  /// If a conflict occurs, exit immediately instead of attempting to
  /// continue resolving conflicts.  The merge operation will fail with
  /// and no index will be returned.
  static const failOnConflict = GitMergeFlag._(2, 'failOnConflict');

  /// Do not write the REUC extension on the generated index.
  static const skipREUC = GitMergeFlag._(4, 'skipREUC');

  /// If the commits being merged have multiple merge bases, do not build
  /// a recursive merge base (by merging the multiple merge bases),
  /// instead simply use the first base.
  static const noRecursive = GitMergeFlag._(8, 'noRecursive');

  static const List<GitMergeFlag> values = [
    findRenames,
    failOnConflict,
    skipREUC,
    noRecursive,
  ];

  int get value => _value;

  @override
  String toString() => 'GitMergeFlag.$_name';
}

/// Merge file favor options to instruct the file-level merging functionality
/// on how to deal with conflicting regions of the files.
class GitMergeFileFavor {
  const GitMergeFileFavor._(this._value, this._name);
  final int _value;
  final String _name;

  /// When a region of a file is changed in both branches, a conflict
  /// will be recorded in the index. This is the default.
  static const normal = GitMergeFileFavor._(0, 'normal');

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "ours" side of any conflicting
  /// region. The index will not record a conflict.
  static const ours = GitMergeFileFavor._(1, 'ours');

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "theirs" side of any conflicting
  /// region. The index will not record a conflict.
  static const theirs = GitMergeFileFavor._(2, 'theirs');

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain each unique line from each side,
  /// which has the result of combining both files. The index will not
  /// record a conflict.
  static const union = GitMergeFileFavor._(3, 'union');

  static const List<GitMergeFileFavor> values = [
    normal,
    ours,
    theirs,
    union,
  ];

  int get value => _value;

  @override
  String toString() => 'GitMergeFileFavor.$_name';
}

/// File merging flags.
class GitMergeFileFlag {
  const GitMergeFileFlag._(this._value, this._name);
  final int _value;
  final String _name;

  /// Defaults.
  static const defaults = GitMergeFileFlag._(0, 'defaults');

  /// Create standard conflicted merge files.
  static const styleMerge = GitMergeFileFlag._(1, 'styleMerge');

  /// Create diff3-style files.
  static const styleDiff3 = GitMergeFileFlag._(2, 'styleDiff3');

  /// Condense non-alphanumeric regions for simplified diff file.
  static const simplifyAlnum = GitMergeFileFlag._(4, 'simplifyAlnum');

  /// Ignore all whitespace.
  static const ignoreWhitespace = GitMergeFileFlag._(8, 'ignoreWhitespace');

  /// Ignore changes in amount of whitespace.
  static const ignoreWhitespaceChange =
      GitMergeFileFlag._(16, 'ignoreWhitespaceChange');

  /// Ignore whitespace at end of line.
  static const ignoreWhitespaceEOL =
      GitMergeFileFlag._(32, 'ignoreWhitespaceEOL');

  /// Use the "patience diff" algorithm.
  static const diffPatience = GitMergeFileFlag._(64, 'diffPatience');

  /// Take extra time to find minimal diff.
  static const diffMinimal = GitMergeFileFlag._(128, 'diffMinimal');

  static const List<GitMergeFileFlag> values = [
    defaults,
    styleMerge,
    styleDiff3,
    simplifyAlnum,
    ignoreWhitespace,
    ignoreWhitespaceChange,
    ignoreWhitespaceEOL,
    diffPatience,
    diffMinimal,
  ];

  int get value => _value;

  @override
  String toString() => 'GitMergeFileFlag.$_name';
}

/// Checkout behavior flags.
///
/// In libgit2, checkout is used to update the working directory and index
/// to match a target tree.  Unlike git checkout, it does not move the HEAD
/// commit for you - use `setHead` or the like to do that.
class GitCheckout {
  const GitCheckout._(this._value, this._name);
  final int _value;
  final String _name;

  /// Default is a dry run, no actual updates.
  static const none = GitCheckout._(0, 'none');

  /// Allow safe updates that cannot overwrite uncommitted data.
  /// If the uncommitted changes don't conflict with the checked out files,
  /// the checkout will still proceed, leaving the changes intact.
  ///
  /// Mutually exclusive with [GitCheckout.force].
  /// [GitCheckout.force] takes precedence over [GitCheckout.safe].
  static const safe = GitCheckout._(1, 'safe');

  /// Allow all updates to force working directory to look like index.
  ///
  /// Mutually exclusive with [GitCheckout.safe].
  /// [GitCheckout.force] takes precedence over [GitCheckout.safe].
  static const force = GitCheckout._(2, 'force');

  /// Allow checkout to recreate missing files.
  static const recreateMissing = GitCheckout._(4, 'recreateMissing');

  /// Allow checkout to make safe updates even if conflicts are found.
  static const allowConflicts = GitCheckout._(16, 'allowConflicts');

  /// Remove untracked files not in index (that are not ignored).
  static const removeUntracked = GitCheckout._(32, 'removeUntracked');

  /// Remove ignored files not in index.
  static const removeIgnored = GitCheckout._(64, 'removeIgnored');

  /// Only update existing files, don't create new ones.
  static const updateOnly = GitCheckout._(128, 'updateOnly');

  /// Normally checkout updates index entries as it goes; this stops that.
  /// Implies [GitCheckout.dontWriteIndex].
  static const dontUpdateIndex = GitCheckout._(256, 'dontUpdateIndex');

  /// Don't refresh index/config/etc before doing checkout.
  static const noRefresh = GitCheckout._(512, 'noRefresh');

  /// Allow checkout to skip unmerged files.
  static const skipUnmerged = GitCheckout._(1024, 'skipUnmerged');

  /// For unmerged files, checkout stage 2 from index.
  static const useOurs = GitCheckout._(2048, 'useOurs');

  /// For unmerged files, checkout stage 3 from index.
  static const useTheirs = GitCheckout._(4096, 'useTheirs');

  /// Treat pathspec as simple list of exact match file paths.
  static const disablePathspecMatch =
      GitCheckout._(8192, 'disablePathspecMatch');

  /// Ignore directories in use, they will be left empty.
  static const skipLockedDirectories =
      GitCheckout._(262144, 'skipLockedDirectories');

  /// Don't overwrite ignored files that exist in the checkout target.
  static const dontOverwriteIgnored =
      GitCheckout._(524288, 'dontOverwriteIgnored');

  /// Write normal merge files for conflicts.
  static const conflictStyleMerge =
      GitCheckout._(1048576, 'conflictStyleMerge');

  /// Include common ancestor data in diff3 format files for conflicts.
  static const conflictStyleDiff3 =
      GitCheckout._(2097152, 'conflictStyleDiff3');

  /// Don't overwrite existing files or folders.
  static const dontRemoveExisting =
      GitCheckout._(4194304, 'dontRemoveExisting');

  /// Normally checkout writes the index upon completion; this prevents that.
  static const dontWriteIndex = GitCheckout._(8388608, 'dontWriteIndex');

  static const List<GitCheckout> values = [
    none,
    safe,
    force,
    recreateMissing,
    allowConflicts,
    removeUntracked,
    removeIgnored,
    updateOnly,
    dontUpdateIndex,
    noRefresh,
    skipUnmerged,
    useOurs,
    useTheirs,
    disablePathspecMatch,
    skipLockedDirectories,
    dontOverwriteIgnored,
    conflictStyleMerge,
    conflictStyleDiff3,
    dontRemoveExisting,
    dontWriteIndex,
  ];

  int get value => _value;

  @override
  String toString() => 'GitCheckout.$_name';
}

/// Kinds of reset operation.
class GitReset {
  const GitReset._(this._value, this._name);
  final int _value;
  final String _name;

  /// Move the head to the given commit.
  static const soft = GitReset._(1, 'soft');

  /// [GitReset.soft] plus reset index to the commit.
  static const mixed = GitReset._(2, 'mixed');

  /// [GitReset.mixed] plus changes in working tree discarded.
  static const hard = GitReset._(3, 'hard');

  static const List<GitReset> values = [soft, mixed, hard];

  int get value => _value;

  @override
  String toString() => 'GitReset.$_name';
}

/// Flags for diff options.  A combination of these flags can be passed.
class GitDiff {
  const GitDiff._(this._value, this._name);
  final int _value;
  final String _name;

  /// Normal diff, the default.
  static const normal = GitDiff._(0, 'normal');

  /// Reverse the sides of the diff.
  static const reverse = GitDiff._(1, 'reverse');

  /// Include ignored files in the diff.
  static const includeIgnored = GitDiff._(2, 'includeIgnored');

  /// Even with [GitDiff.includeUntracked], an entire ignored directory
  /// will be marked with only a single entry in the diff; this flag
  /// adds all files under the directory as IGNORED entries, too.
  static const recurseIgnoredDirs = GitDiff._(4, 'recurseIgnoredDirs');

  /// Include untracked files in the diff.
  static const includeUntracked = GitDiff._(8, 'includeUntracked');

  /// Even with [GitDiff.includeUntracked], an entire untracked
  /// directory will be marked with only a single entry in the diff
  /// (a la what core Git does in `git status`); this flag adds *all*
  /// files under untracked directories as UNTRACKED entries, too.
  static const recurseUntrackedDirs = GitDiff._(16, 'recurseUntrackedDirs');

  /// Include unmodified files in the diff.
  static const includeUnmodified = GitDiff._(32, 'includeUnmodified');

  /// Normally, a type change between files will be converted into a
  /// DELETED record for the old and an ADDED record for the new; this
  /// options enabled the generation of TYPECHANGE delta records.
  static const includeTypechange = GitDiff._(64, 'includeTypechange');

  /// Even with [GitDiff.includeTypechange], blob->tree changes still
  /// generally show as a DELETED blob.  This flag tries to correctly
  /// label blob->tree transitions as TYPECHANGE records with new_file's
  /// mode set to tree. Note: the tree SHA will not be available.
  static const includeTypechangeTrees =
      GitDiff._(128, 'includeTypechangeTrees');

  /// Ignore file mode changes.
  static const ignoreFilemode = GitDiff._(256, 'ignoreFilemode');

  /// Treat all submodules as unmodified.
  static const ignoreSubmodules = GitDiff._(512, 'ignoreSubmodules');

  /// Use case insensitive filename comparisons.
  static const ignoreCase = GitDiff._(1024, 'ignoreCase');

  /// May be combined with [GitDiff.ignoreCase] to specify that a file
  /// that has changed case will be returned as an add/delete pair.
  static const includeCaseChange = GitDiff._(2048, 'includeCaseChange');

  /// If the pathspec is set in the diff options, this flags indicates
  /// that the paths will be treated as literal paths instead of
  /// fnmatch patterns. Each path in the list must either be a full
  /// path to a file or a directory. (A trailing slash indicates that
  /// the path will _only_ match a directory). If a directory is
  /// specified, all children will be included.
  static const disablePathspecMatch = GitDiff._(4096, 'disablePathspecMatch');

  /// Disable updating of the `binary` flag in delta records.  This is
  /// useful when iterating over a diff if you don't need hunk and data
  /// callbacks and want to avoid having to load file completely.
  static const skipBinaryCheck = GitDiff._(8192, 'skipBinaryCheck');

  /// When diff finds an untracked directory, to match the behavior of
  /// core Git, it scans the contents for IGNORED and UNTRACKED files.
  /// If *all* contents are IGNORED, then the directory is IGNORED; if
  /// any contents are not IGNORED, then the directory is UNTRACKED.
  /// This is extra work that may not matter in many cases.  This flag
  /// turns off that scan and immediately labels an untracked directory
  /// as UNTRACKED (changing the behavior to not match core Git).
  static const enableFastUntrackedDirs =
      GitDiff._(16384, 'enableFastUntrackedDirs');

  /// When diff finds a file in the working directory with stat
  /// information different from the index, but the OID ends up being the
  /// same, write the correct stat information into the index. Note:
  /// without this flag, diff will always leave the index untouched.
  static const updateIndex = GitDiff._(32768, 'updateIndex');

  /// Include unreadable files in the diff.
  static const includeUnreadable = GitDiff._(65536, 'includeUnreadable');

  /// Include unreadable files in the diff.
  static const includeUnreadableAsUntracked =
      GitDiff._(131072, 'includeUnreadableAsUntracked');

  /// Use a heuristic that takes indentation and whitespace into account
  /// which generally can produce better diffs when dealing with ambiguous
  /// diff hunks.
  static const indentHeuristic = GitDiff._(262144, 'indentHeuristic');

  /// Treat all files as text, disabling binary attributes & detection.
  static const forceText = GitDiff._(1048576, 'forceText');

  /// Treat all files as binary, disabling text diffs.
  static const forceBinary = GitDiff._(2097152, 'forceBinary');

  /// Ignore all whitespace.
  static const ignoreWhitespace = GitDiff._(4194304, 'ignoreWhitespace');

  /// Ignore changes in amount of whitespace.
  static const ignoreWhitespaceChange =
      GitDiff._(8388608, 'ignoreWhitespaceChange');

  /// Ignore whitespace at end of line.
  static const ignoreWhitespaceEOL = GitDiff._(16777216, 'ignoreWhitespaceEOL');

  /// When generating patch text, include the content of untracked
  /// files. This automatically turns on [GitDiff.includeUntracked] but
  /// it does not turn on [GitDiff.recurseUntrackedDirs]. Add that
  /// flag if you want the content of every single UNTRACKED file.
  static const showUntrackedContent =
      GitDiff._(33554432, 'showUntrackedContent');

  /// When generating output, include the names of unmodified files if
  /// they are included in the git diff.  Normally these are skipped in
  /// the formats that list files (e.g. name-only, name-status, raw).
  /// Even with this, these will not be included in patch format.
  static const showUnmodified = GitDiff._(67108864, 'showUnmodified');

  /// Use the "patience diff" algorithm.
  static const patience = GitDiff._(268435456, 'patience');

  /// Take extra time to find minimal diff.
  static const minimal = GitDiff._(536870912, 'minimal');

  /// Include the necessary deflate / delta information so that `git-apply`
  /// can apply given diff information to binary files.
  static const showBinary = GitDiff._(1073741824, 'showBinary');

  static const List<GitDiff> values = [
    normal,
    reverse,
    includeIgnored,
    recurseIgnoredDirs,
    includeUntracked,
    recurseUntrackedDirs,
    includeUnmodified,
    includeTypechange,
    includeTypechangeTrees,
    ignoreFilemode,
    ignoreSubmodules,
    ignoreCase,
    includeCaseChange,
    disablePathspecMatch,
    skipBinaryCheck,
    enableFastUntrackedDirs,
    updateIndex,
    includeUnreadable,
    includeUnreadableAsUntracked,
    indentHeuristic,
    forceText,
    forceBinary,
    ignoreWhitespace,
    ignoreWhitespaceChange,
    ignoreWhitespaceEOL,
    showUntrackedContent,
    showUnmodified,
    patience,
    minimal,
    showBinary,
  ];

  int get value => _value;

  @override
  String toString() => 'GitDiff.$_name';
}

/// What type of change is described by a git_diff_delta?
///
/// [GitDelta.renamed] and [GitDelta.copied] will only show up if you run
/// `findSimilar()` on the diff object.
///
/// [GitDelta.typechange] only shows up given [GitDiff.includeTypechange]
/// in the option flags (otherwise type changes will be split into ADDED /
/// DELETED pairs).
class GitDelta {
  const GitDelta._(this._value, this._name);
  final int _value;
  final String _name;

  /// No changes.
  static const unmodified = GitDelta._(0, 'unmodified');

  /// Entry does not exist in old version.
  static const added = GitDelta._(1, 'added');

  /// Entry does not exist in new version.
  static const deleted = GitDelta._(2, 'deleted');

  /// Entry content changed between old and new.
  static const modified = GitDelta._(3, 'modified');

  /// Entry was renamed between old and new.
  static const renamed = GitDelta._(4, 'renamed');

  /// Entry was copied from another old entry.
  static const copied = GitDelta._(5, 'copied');

  /// Entry is ignored item in workdir.
  static const ignored = GitDelta._(6, 'ignored');

  /// Entry is is untracked item in workdir.
  static const untracked = GitDelta._(7, 'untracked');

  /// Type of entry changed between old and new.
  static const typechange = GitDelta._(8, 'typechange');

  /// Entry is unreadable.
  static const unreadable = GitDelta._(9, 'unreadable');

  /// Entry in the index is conflicted.
  static const conflicted = GitDelta._(10, 'conflicted');

  static const List<GitDelta> values = [
    unmodified,
    added,
    deleted,
    modified,
    renamed,
    copied,
    ignored,
    untracked,
    typechange,
    unreadable,
    conflicted,
  ];

  int get value => _value;

  @override
  String toString() => 'GitDelta.$_name';
}

/// Flags for the delta object and the file objects on each side.
class GitDiffFlag {
  const GitDiffFlag._(this._value, this._name);
  final int _value;
  final String _name;

  /// File(s) treated as binary data.
  static const binary = GitDiffFlag._(1, 'binary');

  /// File(s) treated as text data.
  static const notBinary = GitDiffFlag._(2, 'notBinary');

  /// `id` value is known correct.
  static const validId = GitDiffFlag._(4, 'validId');

  /// File exists at this side of the delta.
  static const exists = GitDiffFlag._(8, 'exists');

  static const List<GitDiffFlag> values = [binary, notBinary, validId, exists];

  int get value => _value;

  @override
  String toString() => 'GitDiffFlag.$_name';
}

/// Formatting options for diff stats.
class GitDiffStats {
  const GitDiffStats._(this._value, this._name);
  final int _value;
  final String _name;

  /// No stats.
  static const none = GitDiffStats._(0, 'none');

  /// Full statistics, equivalent of `--stat`.
  static const full = GitDiffStats._(1, 'full');

  /// Short statistics, equivalent of `--shortstat`.
  static const short = GitDiffStats._(2, 'short');

  /// Number statistics, equivalent of `--numstat`.
  static const number = GitDiffStats._(4, 'number');

  /// Extended header information such as creations, renames and mode changes,
  /// equivalent of `--summary`.
  static const includeSummary = GitDiffStats._(8, 'includeSummary');

  static const List<GitDiffStats> values = [
    none,
    full,
    short,
    number,
    includeSummary,
  ];

  int get value => _value;

  @override
  String toString() => 'GitDiffStats.$_name';
}

/// Formatting options for diff stats.
class GitDiffFind {
  const GitDiffFind._(this._value, this._name);
  final int _value;
  final String _name;

  /// Obey `diff.renames`. Overridden by any other [GitDiffFind] flag.
  static const byConfig = GitDiffFind._(0, 'byConfig');

  /// Look for renames? (`--find-renames`)
  static const renames = GitDiffFind._(1, 'renames');

  /// Consider old side of MODIFIED for renames? (`--break-rewrites=N`)
  static const renamesFromRewrites = GitDiffFind._(2, 'renamesFromRewrites');

  /// Look for copies? (a la `--find-copies`)
  static const copies = GitDiffFind._(4, 'copies');

  /// Consider UNMODIFIED as copy sources? (`--find-copies-harder`)
  ///
  /// For this to work correctly, use [GitDiff.includeUnmodified] when
  /// the initial git diff is being generated.
  static const copiesFromUnmodified = GitDiffFind._(8, 'copiesFromUnmodified');

  /// Mark significant rewrites for split (`--break-rewrites=/M`)
  static const rewrites = GitDiffFind._(16, 'rewrites');

  /// Actually split large rewrites into delete/add pairs.
  static const breakRewrites = GitDiffFind._(32, 'breakRewrites');

  /// Mark rewrites for split and break into delete/add pairs.
  static const andBreakRewrites = GitDiffFind._(48, 'andBreakRewrites');

  /// Find renames/copies for UNTRACKED items in working directory.
  ///
  /// For this to work correctly, use [GitDiff.includeUntracked] when the
  /// initial git diff is being generated (and obviously the diff must
  /// be against the working directory for this to make sense).
  static const forUntracked = GitDiffFind._(64, 'forUntracked');

  /// Turn on all finding features.
  static const all = GitDiffFind._(255, 'all');

  /// Measure similarity ignoring all whitespace.
  static const ignoreWhitespace = GitDiffFind._(4096, 'ignoreWhitespace');

  /// Measure similarity including all data.
  static const dontIgnoreWhitespace =
      GitDiffFind._(8192, 'dontIgnoreWhitespace');

  /// Measure similarity only by comparing SHAs (fast and cheap).
  static const exactMatchOnly = GitDiffFind._(16384, 'exactMatchOnly');

  /// Do not break rewrites unless they contribute to a rename.
  ///
  /// Normally, [GitDiffFind.andBreakRewrites] will measure the self-
  /// similarity of modified files and split the ones that have changed a
  /// lot into a DELETE / ADD pair.  Then the sides of that pair will be
  /// considered candidates for rename and copy detection.
  ///
  /// If you add this flag in and the split pair is *not* used for an
  /// actual rename or copy, then the modified record will be restored to
  /// a regular MODIFIED record instead of being split.
  static const breakRewritesForRenamesOnly =
      GitDiffFind._(32768, 'breakRewritesForRenamesOnly');

  /// Remove any UNMODIFIED deltas after find_similar is done.
  ///
  /// Using [GitDiffFind.copiesFromUnmodified] to emulate the
  /// --find-copies-harder behavior requires building a diff with the
  /// [GitDiff.includeUnmodified] flag. If you do not want UNMODIFIED
  /// records in the final result, pass this flag to have them removed.
  static const removeUnmodified = GitDiffFind._(65536, 'removeUnmodified');

  static const List<GitDiffFind> values = [
    byConfig,
    renames,
    renamesFromRewrites,
    copies,
    copiesFromUnmodified,
    rewrites,
    breakRewrites,
    andBreakRewrites,
    forUntracked,
    all,
    ignoreWhitespace,
    dontIgnoreWhitespace,
    exactMatchOnly,
    breakRewritesForRenamesOnly,
    removeUnmodified,
  ];

  int get value => _value;

  @override
  String toString() => 'GitDiffFind.$_name';
}
