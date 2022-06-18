/// Basic type of any Git reference.
enum ReferenceType {
  /// Invalid reference.
  invalid(0),

  /// A reference that points at an object id.
  direct(1),

  /// A reference that points at another reference.
  symbolic(2),

  all(3);

  const ReferenceType(this.value);
  final int value;
}

/// Valid modes for index and tree entries.
enum GitFilemode {
  unreadable(0),
  tree(16384),
  blob(33188),
  blobExecutable(33261),
  link(40960),
  commit(57344);

  const GitFilemode(this.value);
  final int value;
}

/// Flags to specify the sorting which a revwalk should perform.
enum GitSort {
  /// Sort the output with the same default method from `git`: reverse
  /// chronological order. This is the default sorting for new walkers.
  none(0),

  /// Sort the repository contents in topological order (no parents before
  /// all of its children are shown); this sorting mode can be combined
  /// with time sorting to produce `git`'s `--date-order``.
  topological(1),

  /// Sort the repository contents by commit time;
  /// this sorting mode can be combined with topological sorting.
  time(2),

  /// Iterate through the repository contents in reverse order; this sorting
  /// mode can be combined with any of the above.
  reverse(4);

  const GitSort(this.value);
  final int value;
}

/// Basic type (loose or packed) of any Git object.
enum GitObject {
  /// Object can be any of the following.
  any(-2),

  /// Object is invalid.
  invalid(-1),

  /// A commit object.
  commit(1),

  /// A tree (directory listing) object.
  tree(2),

  /// A file revision object.
  blob(3),

  /// An annotated tag object.
  tag(4),

  /// A delta, base is given by an offset.
  offsetDelta(6),

  /// A delta, base is given by object id.
  refDelta(7);

  const GitObject(this.value);
  final int value;
}

/// Revparse flags, indicate the intended behavior of the spec.
enum GitRevSpec {
  /// The spec targeted a single object.
  single(1),

  /// The spec targeted a range of commits.
  range(2),

  /// The spec used the '...' operator, which invokes special semantics.
  mergeBase(4);

  const GitRevSpec(this.value);
  final int value;
}

/// Basic type of any Git branch.
enum GitBranch {
  local(1),
  remote(2),
  all(3);

  const GitBranch(this.value);
  final int value;
}

/// Status flags for a single file.
///
/// A combination of these values will be returned to indicate the status of
/// a file.  Status compares the working directory, the index, and the
/// current HEAD of the repository.  The `GitStatus.index` set of flags
/// represents the status of file in the index relative to the HEAD, and the
/// `GitStatus.wt` set of flags represent the status of the file in the
/// working directory relative to the index.
enum GitStatus {
  current(0),
  indexNew(1),
  indexModified(2),
  indexDeleted(4),
  indexRenamed(8),
  indexTypeChange(16),
  wtNew(128),
  wtModified(256),
  wtDeleted(512),
  wtTypeChange(1024),
  wtRenamed(2048),
  wtUnreadable(4096),
  ignored(16384),
  conflicted(32768);

  const GitStatus(this.value);
  final int value;
}

/// The results of `mergeAnalysis` indicate the merge opportunities.
enum GitMergeAnalysis {
  /// A "normal" merge; both HEAD and the given merge input have diverged
  /// from their common ancestor. The divergent commits must be merged.
  normal(1),

  /// All given merge inputs are reachable from HEAD, meaning the
  /// repository is up-to-date and no merge needs to be performed.
  upToDate(2),

  /// The given merge input is a fast-forward from HEAD and no merge
  /// needs to be performed. Instead, the client can check out the
  /// given merge input.
  fastForward(4),

  /// The HEAD of the current repository is "unborn" and does not point to
  /// a valid commit. No merge can be performed, but the caller may wish
  /// to simply set HEAD to the target commit(s).
  unborn(8);

  const GitMergeAnalysis(this.value);
  final int value;
}

/// The user's stated preference for merges.
enum GitMergePreference {
  /// No configuration was found that suggests a preferred behavior for merge.
  none(0),

  /// There is a `merge.ff=false` configuration setting, suggesting that
  /// the user does not want to allow a fast-forward merge.
  noFastForward(1),

  /// There is a `merge.ff=only` configuration setting, suggesting that
  /// the user only wants fast-forward merges.
  fastForwardOnly(2);

  const GitMergePreference(this.value);
  final int value;
}

/// Repository state.
///
/// These values represent possible states for the repository to be in,
/// based on the current operation which is ongoing.
enum GitRepositoryState {
  none(0),
  merge(1),
  revert(2),
  revertSequence(3),
  cherrypick(4),
  cherrypickSequence(5),
  bisect(6),
  rebase(7),
  rebaseInteractive(8),
  rebaseMerge(9),
  applyMailbox(10),
  applyMailboxOrRebase(11);

  const GitRepositoryState(this.value);
  final int value;
}

/// Flags for merge options.
enum GitMergeFlag {
  /// Detect renames that occur between the common ancestor and the "ours"
  /// side or the common ancestor and the "theirs" side.  This will enable
  /// the ability to merge between a modified and renamed file.
  findRenames(1),

  /// If a conflict occurs, exit immediately instead of attempting to
  /// continue resolving conflicts.  The merge operation will fail with
  /// and no index will be returned.
  failOnConflict(2),

  /// Do not write the REUC extension on the generated index.
  skipREUC(4),

  /// If the commits being merged have multiple merge bases, do not build
  /// a recursive merge base (by merging the multiple merge bases),
  /// instead simply use the first base.
  noRecursive(8);

  const GitMergeFlag(this.value);
  final int value;
}

/// Merge file favor options to instruct the file-level merging functionality
/// on how to deal with conflicting regions of the files.
enum GitMergeFileFavor {
  /// When a region of a file is changed in both branches, a conflict
  /// will be recorded in the index. This is the default.
  normal(0),

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "ours" side of any conflicting
  /// region. The index will not record a conflict.
  ours(1),

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain the "theirs" side of any conflicting
  /// region. The index will not record a conflict.
  theirs(2),

  /// When a region of a file is changed in both branches, the file
  /// created in the index will contain each unique line from each side,
  /// which has the result of combining both files. The index will not
  /// record a conflict.
  union(3);

  const GitMergeFileFavor(this.value);
  final int value;
}

/// File merging flags.
enum GitMergeFileFlag {
  /// Defaults.
  defaults(0),

  /// Create standard conflicted merge files.
  styleMerge(1),

  /// Create diff3-style files.
  styleDiff3(2),

  /// Condense non-alphanumeric regions for simplified diff file.
  simplifyAlnum(4),

  /// Ignore all whitespace.
  ignoreWhitespace(8),

  /// Ignore changes in amount of whitespace.
  ignoreWhitespaceChange(16),

  /// Ignore whitespace at end of line.
  ignoreWhitespaceEOL(32),

  /// Use the "patience diff" algorithm.
  diffPatience(64),

  /// Take extra time to find minimal diff.
  diffMinimal(128),

  /// Create zdiff3 ("zealous diff3")-style files.
  styleZdiff3(256),

  /// Do not produce file conflicts when common regions have
  /// changed; keep the conflict markers in the file and accept
  /// that as the merge result.
  acceptConflicts(512);

  const GitMergeFileFlag(this.value);
  final int value;
}

/// Checkout behavior flags.
///
/// In libgit2, checkout is used to update the working directory and index
/// to match a target tree.  Unlike git checkout, it does not move the HEAD
/// commit for you - use `setHead` or the like to do that.
enum GitCheckout {
  /// Default is a dry run, no actual updates.
  none(0),

  /// Allow safe updates that cannot overwrite uncommitted data.
  /// If the uncommitted changes don't conflict with the checked out files,
  /// the checkout will still proceed, leaving the changes intact.
  ///
  /// Mutually exclusive with [GitCheckout.force].
  /// [GitCheckout.force] takes precedence over [GitCheckout.safe].
  safe(1),

  /// Allow all updates to force working directory to look like index.
  ///
  /// Mutually exclusive with [GitCheckout.safe].
  /// [GitCheckout.force] takes precedence over [GitCheckout.safe].
  force(2),

  /// Allow checkout to recreate missing files.
  recreateMissing(4),

  /// Allow checkout to make safe updates even if conflicts are found.
  allowConflicts(16),

  /// Remove untracked files not in index (that are not ignored).
  removeUntracked(32),

  /// Remove ignored files not in index.
  removeIgnored(64),

  /// Only update existing files, don't create new ones.
  updateOnly(128),

  /// Normally checkout updates index entries as it goes; this stops that.
  /// Implies [GitCheckout.dontWriteIndex].
  dontUpdateIndex(256),

  /// Don't refresh index/config/etc before doing checkout.
  noRefresh(512),

  /// Allow checkout to skip unmerged files.
  skipUnmerged(1024),

  /// For unmerged files, checkout stage 2 from index.
  useOurs(2048),

  /// For unmerged files, checkout stage 3 from index.
  useTheirs(4096),

  /// Treat pathspec as simple list of exact match file paths.
  disablePathspecMatch(8192),

  /// Ignore directories in use, they will be left empty.
  skipLockedDirectories(262144),

  /// Don't overwrite ignored files that exist in the checkout target.
  dontOverwriteIgnored(524288),

  /// Write normal merge files for conflicts.
  conflictStyleMerge(1048576),

  /// Include common ancestor data in diff3 format files for conflicts.
  conflictStyleDiff3(2097152),

  /// Don't overwrite existing files or folders.
  dontRemoveExisting(4194304),

  /// Normally checkout writes the index upon completion; this prevents that.
  dontWriteIndex(8388608),

  /// Show what would be done by a checkout. Stop after sending
  /// notifications; don't update the working directory or index.
  dryRun(16777216),

  /// Include common ancestor data in zdiff3 format for conflicts.
  conflictStyleZdiff3(33554432);

  const GitCheckout(this.value);
  final int value;
}

/// Kinds of reset operation.
enum GitReset {
  /// Move the head to the given commit.
  soft(1),

  /// [GitReset.soft] plus reset index to the commit.
  mixed(2),

  /// [GitReset.mixed] plus changes in working tree discarded.
  hard(3);

  const GitReset(this.value);
  final int value;
}

/// Flags for diff options.  A combination of these flags can be passed.
enum GitDiff {
  /// Normal diff, the default.
  normal(0),

  /// Reverse the sides of the diff.
  reverse(1),

  /// Include ignored files in the diff.
  includeIgnored(2),

  /// Even with [GitDiff.includeUntracked], an entire ignored directory
  /// will be marked with only a single entry in the diff; this flag
  /// adds all files under the directory as IGNORED entries, too.
  recurseIgnoredDirs(4),

  /// Include untracked files in the diff.
  includeUntracked(8),

  /// Even with [GitDiff.includeUntracked], an entire untracked
  /// directory will be marked with only a single entry in the diff
  /// (a la what core Git does in `git status`); this flag adds *all*
  /// files under untracked directories as UNTRACKED entries, too.
  recurseUntrackedDirs(16),

  /// Include unmodified files in the diff.
  includeUnmodified(32),

  /// Normally, a type change between files will be converted into a
  /// DELETED record for the old and an ADDED record for the new; this
  /// options enabled the generation of TYPECHANGE delta records.
  includeTypechange(64),

  /// Even with [GitDiff.includeTypechange], blob->tree changes still
  /// generally show as a DELETED blob.  This flag tries to correctly
  /// label blob->tree transitions as TYPECHANGE records with new_file's
  /// mode set to tree. Note: the tree SHA will not be available.
  includeTypechangeTrees(128),

  /// Ignore file mode changes.
  ignoreFilemode(256),

  /// Treat all submodules as unmodified.
  ignoreSubmodules(512),

  /// Use case insensitive filename comparisons.
  ignoreCase(1024),

  /// May be combined with [GitDiff.ignoreCase] to specify that a file
  /// that has changed case will be returned as an add/delete pair.
  includeCaseChange(2048),

  /// If the pathspec is set in the diff options, this flags indicates
  /// that the paths will be treated as literal paths instead of
  /// fnmatch patterns. Each path in the list must either be a full
  /// path to a file or a directory. (A trailing slash indicates that
  /// the path will _only_ match a directory). If a directory is
  /// specified, all children will be included.
  disablePathspecMatch(4096),

  /// Disable updating of the `binary` flag in delta records.  This is
  /// useful when iterating over a diff if you don't need hunk and data
  /// callbacks and want to avoid having to load file completely.
  skipBinaryCheck(8192),

  /// When diff finds an untracked directory, to match the behavior of
  /// core Git, it scans the contents for IGNORED and UNTRACKED files.
  /// If *all* contents are IGNORED, then the directory is IGNORED; if
  /// any contents are not IGNORED, then the directory is UNTRACKED.
  /// This is extra work that may not matter in many cases.  This flag
  /// turns off that scan and immediately labels an untracked directory
  /// as UNTRACKED (changing the behavior to not match core Git).
  enableFastUntrackedDirs(16384),

  /// When diff finds a file in the working directory with stat
  /// information different from the index, but the OID ends up being the
  /// same, write the correct stat information into the index. Note:
  /// without this flag, diff will always leave the index untouched.
  updateIndex(32768),

  /// Include unreadable files in the diff.
  includeUnreadable(65536),

  /// Include unreadable files in the diff.
  includeUnreadableAsUntracked(131072),

  /// Use a heuristic that takes indentation and whitespace into account
  /// which generally can produce better diffs when dealing with ambiguous
  /// diff hunks.
  indentHeuristic(262144),

  /// Treat all files as text, disabling binary attributes & detection.
  forceText(1048576),

  /// Treat all files as binary, disabling text diffs.
  forceBinary(2097152),

  /// Ignore all whitespace.
  ignoreWhitespace(4194304),

  /// Ignore changes in amount of whitespace.
  ignoreWhitespaceChange(8388608),

  /// Ignore whitespace at end of line.
  ignoreWhitespaceEOL(16777216),

  /// When generating patch text, include the content of untracked
  /// files. This automatically turns on [GitDiff.includeUntracked] but
  /// it does not turn on [GitDiff.recurseUntrackedDirs]. Add that
  /// flag if you want the content of every single UNTRACKED file.
  showUntrackedContent(33554432),

  /// When generating output, include the names of unmodified files if
  /// they are included in the git diff.  Normally these are skipped in
  /// the formats that list files (e.g. name-only, name-status, raw).
  /// Even with this, these will not be included in patch format.
  showUnmodified(67108864),

  /// Use the "patience diff" algorithm.
  patience(268435456),

  /// Take extra time to find minimal diff.
  minimal(536870912),

  /// Include the necessary deflate / delta information so that `git-apply`
  /// can apply given diff information to binary files.
  showBinary(1073741824);

  const GitDiff(this.value);
  final int value;
}

/// What type of change is described by a git_diff_delta?
///
/// [GitDelta.renamed] and [GitDelta.copied] will only show up if you run
/// `findSimilar()` on the diff object.
///
/// [GitDelta.typechange] only shows up given [GitDiff.includeTypechange]
/// in the option flags (otherwise type changes will be split into ADDED /
/// DELETED pairs).
enum GitDelta {
  /// No changes.
  unmodified(0),

  /// Entry does not exist in old version.
  added(1),

  /// Entry does not exist in new version.
  deleted(2),

  /// Entry content changed between old and new.
  modified(3),

  /// Entry was renamed between old and new.
  renamed(4),

  /// Entry was copied from another old entry.
  copied(5),

  /// Entry is ignored item in workdir.
  ignored(6),

  /// Entry is is untracked item in workdir.
  untracked(7),

  /// Type of entry changed between old and new.
  typechange(8),

  /// Entry is unreadable.
  unreadable(9),

  /// Entry in the index is conflicted.
  conflicted(10);

  const GitDelta(this.value);
  final int value;
}

/// Flags for the delta object and the file objects on each side.
enum GitDiffFlag {
  /// File(s) treated as binary data.
  binary(1),

  /// File(s) treated as text data.
  notBinary(2),

  /// `id` value is known correct.
  validId(4),

  /// File exists at this side of the delta.
  exists(8);

  const GitDiffFlag(this.value);
  final int value;
}

/// Formatting options for diff stats.
enum GitDiffStats {
  /// No stats.
  none(0),

  /// Full statistics, equivalent of `--stat`.
  full(1),

  /// Short statistics, equivalent of `--shortstat`.
  short(2),

  /// Number statistics, equivalent of `--numstat`.
  number(4),

  /// Extended header information such as creations, renames and mode changes,
  /// equivalent of `--summary`.
  includeSummary(8);

  const GitDiffStats(this.value);
  final int value;
}

/// Formatting options for diff stats.
enum GitDiffFind {
  /// Obey `diff.renames`. Overridden by any other [GitDiffFind] flag.
  byConfig(0),

  /// Look for renames, equivalent of `--find-renames`
  renames(1),

  /// Consider old side of MODIFIED for renames, equivalent of
  /// `--break-rewrites=N`
  renamesFromRewrites(2),

  /// Look for copies, equivalent of `--find-copies`
  copies(4),

  /// Consider UNMODIFIED as copy sources, equivalent of `--find-copies-harder`
  ///
  /// For this to work correctly, use [GitDiff.includeUnmodified] when
  /// the initial git diff is being generated.
  copiesFromUnmodified(8),

  /// Mark significant rewrites for split, equivalent of `--break-rewrites=/M`
  rewrites(16),

  /// Actually split large rewrites into delete/add pairs.
  breakRewrites(32),

  /// Mark rewrites for split and break into delete/add pairs.
  andBreakRewrites(48),

  /// Find renames/copies for UNTRACKED items in working directory.
  ///
  /// For this to work correctly, use [GitDiff.includeUntracked] when the
  /// initial git diff is being generated (and obviously the diff must
  /// be against the working directory for this to make sense).
  forUntracked(64),

  /// Turn on all finding features.
  all(255),

  /// Measure similarity ignoring all whitespace.
  ignoreWhitespace(4096),

  /// Measure similarity including all data.
  dontIgnoreWhitespace(8192),

  /// Measure similarity only by comparing SHAs (fast and cheap).
  exactMatchOnly(16384),

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
  breakRewritesForRenamesOnly(32768),

  /// Remove any UNMODIFIED deltas after find_similar is done.
  ///
  /// Using [GitDiffFind.copiesFromUnmodified] to emulate the
  /// --find-copies-harder behavior requires building a diff with the
  /// [GitDiff.includeUnmodified] flag. If you do not want UNMODIFIED
  /// records in the final result, pass this flag to have them removed.
  removeUnmodified(65536);

  const GitDiffFind(this.value);
  final int value;
}

/// Line origin, describing where a line came from.
enum GitDiffLine {
  context(32),
  addition(43),
  deletion(45),

  /// Both files have no LF at end.
  contextEOFNL(61),

  /// Old has no LF at end, new does.
  addEOFNL(62),

  /// Old has LF at end, new does not.
  delEOFNL(60),

  fileHeader(70),
  hunkHeader(72),

  /// For "Binary files x and y differ"
  binary(66);

  const GitDiffLine(this.value);
  final int value;
}

/// Possible application locations for `apply()`
class GitApplyLocation {
  const GitApplyLocation._(this._value, this._name);
  final int _value;
  final String _name;

  /// Apply the patch to the workdir, leaving the index untouched.
  /// This is the equivalent of `git apply` with no location argument.
  static const workdir = GitApplyLocation._(0, 'workdir');

  /// Apply the patch to the index, leaving the working directory
  /// untouched. This is the equivalent of `git apply --cached`.
  static const index = GitApplyLocation._(1, 'index');

  /// Apply the patch to both the working directory and the index.
  /// This is the equivalent of `git apply --index`.
  static const both = GitApplyLocation._(2, 'both');

  static const List<GitApplyLocation> values = [workdir, index, both];

  int get value => _value;

  @override
  String toString() => 'GitApplyLocation.$_name';
}

/// Priority level of a config file.
/// These priority levels correspond to the natural escalation logic
/// (from higher to lower) when searching for config entries in git.
enum GitConfigLevel {
  /// System-wide on Windows, for compatibility with portable git.
  programData(1),

  /// System-wide configuration file; /etc/gitconfig on Linux systems.
  system(2),

  /// XDG compatible configuration file; typically ~/.config/git/config
  xdg(3),

  /// User-specific configuration file (also called Global configuration
  /// file); typically ~/.gitconfig
  global(4),

  /// Repository specific configuration file; $WORK_DIR/.git/config on
  /// non-bare repos.
  local(5),

  /// Application specific configuration file; freely defined by applications.
  app(6),

  /// Represents the highest level available config file (i.e. the most
  /// specific config file available that actually is loaded).
  highest(-1);

  const GitConfigLevel(this.value);
  final int value;
}

/// Stash flags.
enum GitStash {
  /// No option, default.
  defaults(0),

  /// All changes already added to the index are left intact in
  /// the working directory.
  keepIndex(1),

  /// All untracked files are also stashed and then cleaned up
  /// from the working directory.
  includeUntracked(2),

  /// All ignored files are also stashed and then cleaned up from
  /// the working directory.
  includeIgnored(4);

  const GitStash(this.value);
  final int value;
}

/// Stash application flags.
enum GitStashApply {
  defaults(0),

  /// Try to reinstate not only the working tree's changes,
  /// but also the index's changes.
  reinstateIndex(1);

  const GitStashApply(this.value);
  final int value;
}

/// Direction of the connection.
enum GitDirection {
  fetch(0),
  push(1);

  const GitDirection(this.value);
  final int value;
}

/// Acceptable prune settings when fetching.
enum GitFetchPrune {
  /// Use the setting from the configuration.
  unspecified(0),

  /// Force pruning on. Removes any remote branch in the local repository
  /// that does not exist in the remote
  prune(1),

  /// Force pruning off. Keeps the remote branches.
  noPrune(2);

  const GitFetchPrune(this.value);
  final int value;
}

/// Option flags for [Repository] init.
enum GitRepositoryInit {
  /// Create a bare repository with no working directory.
  bare(1),

  /// Return an GIT_EEXISTS error if the repo path appears to already be
  /// an git repository.
  noReinit(2),

  /// Normally a "/.git/" will be appended to the repo path for
  /// non-bare repos (if it is not already there), but passing this flag
  /// prevents that behavior.
  noDotGitDir(4),

  /// Make the repo path (and workdir path) as needed. Init is always willing
  /// to create the ".git" directory even without this flag. This flag tells
  /// init to create the trailing component of the repo and workdir paths
  /// as needed.
  mkdir(8),

  /// Recursively make all components of the repo and workdir paths as
  /// necessary.
  mkpath(16),

  /// libgit2 normally uses internal templates to initialize a new repo.
  /// This flags enables external templates, looking the [templatePath] from
  /// the options if set, or the `init.templatedir` global config if not,
  /// or falling back on "/usr/share/git-core/templates" if it exists.
  externalTemplate(32),

  /// If an alternate workdir is specified, use relative paths for the gitdir
  /// and core.worktree.
  relativeGitlink(64);

  const GitRepositoryInit(this.value);
  final int value;
}

/// Supported credential types.
///
/// This represents the various types of authentication methods supported by
/// the library.
enum GitCredential {
  /// A vanilla user/password request.
  userPassPlainText(1),

  /// An SSH key-based authentication request.
  sshKey(2),

  /// An SSH key-based authentication request, with a custom signature.
  sshCustom(4),

  /// An NTLM/Negotiate-based authentication request.
  defaultAuth(8),

  /// An SSH interactive authentication request.
  sshInteractive(16),

  /// Username-only authentication request.
  ///
  /// Used as a pre-authentication step if the underlying transport
  /// (eg. SSH, with no username in its URL) does not know which username
  /// to use.
  username(32),

  /// An SSH key-based authentication request.
  ///
  /// Allows credentials to be read from memory instead of files.
  /// Note that because of differences in crypto backend support, it might
  /// not be functional.
  sshMemory(64);

  const GitCredential(this.value);
  final int value;
}

/// Combinations of these values describe the features with which libgit2
/// was compiled.
enum GitFeature {
  /// If set, libgit2 was built thread-aware and can be safely used from
  /// multiple threads.
  threads(1),

  /// If set, libgit2 was built with and linked against a TLS implementation.
  /// Custom TLS streams may still be added by the user to support HTTPS
  /// regardless of this.
  https(2),

  /// If set, libgit2 was built with and linked against libssh2. A custom
  /// transport may still be added by the user to support libssh2 regardless of
  /// this.
  ssh(4),

  /// If set, libgit2 was built with support for sub-second resolution in file
  /// modification times.
  nsec(8);

  const GitFeature(this.value);
  final int value;
}

/// Combinations of these values determine the lookup order for attribute.
enum GitAttributeCheck {
  fileThenIndex(0),
  indexThenFile(1),
  indexOnly(2),
  noSystem(4),
  includeHead(8),
  includeCommit(16);

  const GitAttributeCheck(this.value);
  final int value;
}

/// Flags for indicating option behavior for git blame APIs.
enum GitBlameFlag {
  /// Normal blame, the default.
  normal(0),

  /// Track lines that have moved within a file (like `git blame -M`).
  ///
  /// This is not yet implemented and reserved for future use.
  trackCopiesSameFile(1),

  /// Track lines that have moved across files in the same commit
  /// (like `git blame -C`).
  ///
  /// This is not yet implemented and reserved for future use.
  trackCopiesSameCommitMoves(2),

  /// Track lines that have been copied from another file that exists
  /// in the same commit (like `git blame -CC`).  Implies SAME_FILE.
  ///
  /// This is not yet implemented and reserved for future use.
  trackCopiesSameCommitCopies(4),

  /// Track lines that have been copied from another file that exists in
  /// *any* commit (like `git blame -CCC`).  Implies SAME_COMMIT_COPIES.
  ///
  /// This is not yet implemented and reserved for future use.
  trackCopiesAnyCommitCopies(8),

  /// Restrict the search of commits to those reachable following only
  /// the first parents.
  firstParent(16),

  /// Use mailmap file to map author and committer names and email
  /// addresses to canonical real names and email addresses. The
  /// mailmap will be read from the working directory, or HEAD in a
  /// bare repository.
  useMailmap(32),

  /// Ignore whitespace differences.
  ignoreWhitespace(64);

  const GitBlameFlag(this.value);
  final int value;
}

/// Type of rebase operation in-progress after calling rebase's `next()`.
enum GitRebaseOperation {
  /// The given commit is to be cherry-picked. The client should commit
  /// the changes and continue if there are no conflicts.
  pick(0),

  /// The given commit is to be cherry-picked, but the client should prompt
  /// the user to provide an updated commit message.
  reword(1),

  /// The given commit is to be cherry-picked, but the client should stop
  /// to allow the user to edit the changes before committing them.
  edit(2),

  /// The given commit is to be squashed into the previous commit. The
  /// commit message will be merged with the previous message.
  squash(3),

  /// The given commit is to be squashed into the previous commit. The
  /// commit message from this commit will be discarded.
  fixup(4),

  /// No commit will be cherry-picked. The client should run the given
  /// command and (if successful) continue.
  exec(5);

  const GitRebaseOperation(this.value);
  final int value;
}

/// Reference lookup strategy.
///
/// These behave like the --tags and --all options to git-describe,
/// namely they say to look for any reference in either refs/tags/ or
/// refs/ respectively.
enum GitDescribeStrategy {
  /// Only match annotated tags.
  defaultStrategy(0),

  /// Match everything under `refs/tags/` (includes lightweight tags).
  tags(1),

  /// Match everything under `refs/` (includes branches).
  all(2);

  const GitDescribeStrategy(this.value);
  final int value;
}

/// Submodule ignore values.
///
/// These values represent settings for the `submodule.$name.ignore`
/// configuration value which says how deeply to look at the working
/// directory when getting submodule status.
enum GitSubmoduleIgnore {
  // Use the submodule's configuration.
  unspecified(-1),

  /// Don't ignore any change - i.e. even an untracked file, will mark the
  /// submodule as dirty.  Ignored files are still ignored, of course.
  none(1),

  /// Ignore untracked files; only changes to tracked files, or the index or
  /// the HEAD commit will matter.
  untracked(2),

  /// Ignore changes in the working directory, only considering changes if
  /// the HEAD of submodule has moved from the value in the superproject.
  dirty(3),

  /// Never check if the submodule is dirty.
  all(4);

  const GitSubmoduleIgnore(this.value);
  final int value;
}

/// Submodule update values
///
/// These values represent settings for the `submodule.$name.update`
/// configuration value which says how to handle `git submodule update` for
/// this submodule.  The value is usually set in the `.gitmodules` file and
/// copied to `.git/config` when the submodule is initialized.
enum GitSubmoduleUpdate {
  /// The default; when a submodule is updated, checkout the new detached HEAD
  /// to the submodule directory.
  checkout(1),

  /// Update by rebasing the current checked out branch onto the commit from
  /// the superproject.
  rebase(2),

  /// Update by merging the commit in the superproject into the current checkout
  /// out branch of the submodule.
  merge(3),

  /// Do not update this submodule even when the commit in the superproject is
  /// updated.
  none(4);

  const GitSubmoduleUpdate(this.value);
  final int value;
}

/// A combination of these flags will be returned to describe the status of a
/// submodule.  Depending on the "ignore" property of the submodule, some of
/// the flags may never be returned because they indicate changes that are
/// supposed to be ignored.
///
/// Submodule info is contained in 4 places: the HEAD tree, the index, config
/// files (both .git/config and .gitmodules), and the working directory.  Any
/// or all of those places might be missing information about the submodule
/// depending on what state the repo is in.  We consider all four places to
/// build the combination of status flags.
enum GitSubmoduleStatus {
  /// Superproject head contains submodule.
  inHead(1),

  /// Superproject index contains submodule.
  inIndex(2),

  /// Superproject gitmodules has submodule.
  inConfig(4),

  /// Superproject workdir has submodule.
  inWorkdir(8),

  /// In index, not in head.
  indexAdded(16),

  /// In head, not in index.
  indexDeleted(32),

  /// Index and head don't match.
  indexModified(64),

  /// Workdir contains empty directory.
  workdirUninitialized(128),

  /// In workdir, not index.
  workdirAdded(256),

  /// In index, not workdir.
  workdirDeleted(512),

  /// Index and workdir head don't match.
  workdirModified(1024),

  /// Submodule workdir index is dirty.
  workdirIndexModified(2048),

  /// Submodule workdir has modified files.
  smWorkdirModified(4096),

  /// Workdir contains untracked files.
  workdirUntracked(8192);

  const GitSubmoduleStatus(this.value);
  final int value;
}

/// Capabilities of system that affect index actions.
enum GitIndexCapability {
  ignoreCase(1),
  noFileMode(2),
  noSymlinks(4),
  fromOwner(-1);

  const GitIndexCapability(this.value);
  final int value;
}

/// Flags to control the functionality of blob content filtering.
enum GitBlobFilter {
  /// When set, filters will not be applied to binary files.
  checkForBinary(1),

  /// When set, filters will not load configuration from the
  /// system-wide `gitattributes` in `/etc` (or system equivalent).
  noSystemAttributes(2),

  /// When set, filters will be loaded from a `.gitattributes` file
  /// in the HEAD commit.
  attributesFromHead(4),

  /// When set, filters will be loaded from a `.gitattributes` file
  /// in the specified commit.
  attributesFromCommit(8);

  const GitBlobFilter(this.value);
  final int value;
}

/// Flags for APIs that add files matching pathspec.
enum GitIndexAddOption {
  defaults(0),

  /// Skip the checking of ignore rules.
  force(1),

  /// Disable glob expansion and force exact matching of files in working
  /// directory.
  disablePathspecMatch(2),

  /// Check that each entry in the pathspec is an exact match to a filename on
  /// disk is either not ignored or already in the index.
  checkPathspec(4);

  const GitIndexAddOption(this.value);
  final int value;
}

/// Flags to alter working tree pruning behavior.
enum GitWorktree {
  /// Prune working tree even if working tree is valid.
  pruneValid(1),

  /// Prune working tree even if it is locked.
  pruneLocked(2),

  /// Prune checked out working tree.
  pruneWorkingTree(4);

  const GitWorktree(this.value);
  final int value;
}
