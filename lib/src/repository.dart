import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/attr.dart' as attr_bindings;
import 'package:libgit2dart/src/bindings/describe.dart' as describe_bindings;
import 'package:libgit2dart/src/bindings/graph.dart' as graph_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;
import 'package:libgit2dart/src/bindings/repository.dart' as bindings;
import 'package:libgit2dart/src/bindings/reset.dart' as reset_bindings;
import 'package:libgit2dart/src/bindings/status.dart' as status_bindings;
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

@immutable
class Repository extends Equatable {
  /// Initializes a new instance of the [Repository] class from provided
  /// pointer to repository object in memory.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Repository.init]
  /// - [Repository.open]
  /// - [Repository.clone]
  @internal
  Repository(Pointer<git_repository> pointer) {
    _repoPointer = pointer;
    _finalizer.attach(this, _repoPointer, detach: this);
  }

  /// Creates new git repository at the provided [path].
  ///
  /// [path] is the path to the repository.
  ///
  /// [bare] whether new repository should be bare.
  ///
  /// [flags] is a combination of [GitRepositoryInit] flags. Defaults to
  /// [GitRepositoryInit.mkdir].
  ///
  /// [mode] is the permissions for the folder. Default to 0 (permissions
  /// configured by umask).
  ///
  /// [workdirPath] is the path to the working directory. Can be null for
  /// default path.
  ///
  /// [description] if set will be used to initialize the "description" file in
  /// the repository, instead of using the template content.
  ///
  /// [templatePath] is the the path to use for the template directory if
  /// [GitRepositoryInit.externalTemplate] is set. Defaults to the config or
  /// default directory options.
  ///
  /// [initialHead] is the name of the head to point HEAD at. If null, then
  /// this will be treated as "master" and the HEAD ref will be set to
  /// "refs/heads/master". If this begins with "refs/" it will be used
  /// verbatim, otherwise "refs/heads/" will be prefixed.
  ///
  /// [originUrl] if set, then after the rest of the repository initialization
  /// is completed, an "origin" remote will be added pointing to this URL.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.init({
    required String path,
    bool bare = false,
    Set<GitRepositoryInit> flags = const {GitRepositoryInit.mkpath},
    int mode = 0,
    String? workdirPath,
    String? description,
    String? templatePath,
    String? initialHead,
    String? originUrl,
  }) {
    libgit2.git_libgit2_init();

    var flagsInt = flags.fold(0, (int acc, e) => acc | e.value);

    if (bare) {
      flagsInt |= GitRepositoryInit.bare.value;
    }

    _repoPointer = bindings.init(
      path: path,
      flags: flagsInt,
      mode: mode,
      workdirPath: workdirPath,
      description: description,
      templatePath: templatePath,
      initialHead: initialHead,
      originUrl: originUrl,
    );

    _finalizer.attach(this, _repoPointer, detach: this);
  }

  /// Opens repository at provided [path].
  ///
  /// For a standard repository, [path] should either point to the ".git" folder
  /// or to the working directory. For a bare repository, [path] should directly
  /// point to the repository folder.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.open(String path) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.open(path);

    _finalizer.attach(this, _repoPointer, detach: this);
  }

  /// Clones a remote repository at provided [url] into [localPath].
  ///
  /// By default this creates its repository and initial remote to match git's
  /// defaults. You can use the [remote] and [repository] options to customize
  /// how these are created.
  ///
  /// [url] is the remote repository to clone.
  ///
  /// [localPath] is the local directory to clone to.
  ///
  /// [bare] whether cloned repo should be bare.
  ///
  /// [remoteCallback] is the [RemoteCallback] object values that will be used
  /// in creation and customization process of remote instead of default ones.
  ///
  /// [repositoryCallback] is the [RepositoryCallback] object values that will
  /// be used in creation and customization process of repository.
  ///
  /// [checkoutBranch] is the name of the branch to checkout after the clone.
  /// Defaults to using the remote's default branch.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.clone({
    required String url,
    required String localPath,
    bool bare = false,
    RemoteCallback? remoteCallback,
    RepositoryCallback? repositoryCallback,
    String? checkoutBranch,
    Callbacks callbacks = const Callbacks(),
  }) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.clone(
      url: url,
      localPath: localPath,
      bare: bare,
      remoteCallback: remoteCallback,
      repositoryCallback: repositoryCallback,
      checkoutBranch: checkoutBranch,
      callbacks: callbacks,
    );

    _finalizer.attach(this, _repoPointer, detach: this);
  }

  late final Pointer<git_repository> _repoPointer;

  /// Pointer to memory address for allocated repository object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_repository> get pointer => _repoPointer;

  /// Looks for a git repository and return its path. The lookup start from
  /// [startPath] and walk across parent directories if nothing has been found.
  /// The lookup ends when the first repository is found, or when reaching a
  /// directory referenced in [ceilingDirs].
  ///
  /// The method will automatically detect if the repository is bare (if there
  /// is a repository).
  static String discover({required String startPath, String? ceilingDirs}) {
    return bindings.discover(
      startPath: startPath,
      ceilingDirs: ceilingDirs,
    );
  }

  /// Returns [Oid] object if it can be found in the ODB of repository with
  /// provided hexadecimal [sha] string that is 40 characters long or shorter.
  ///
  /// Throws [ArgumentError] if provided [sha] hex string is not valid or
  /// [LibGit2Error] if error occured.
  Oid operator [](String sha) {
    return Oid.fromSHA(repo: this, sha: sha);
  }

  /// Path to the ".git" folder for normal repositories or path to the
  /// repository itself for bare repositories.
  String get path => bindings.path(_repoPointer);

  /// Path of the shared common directory for this repository.
  ///
  /// If the repository is bare, it is the root directory for the repository.
  /// If the repository is a worktree, it is the parent repo's ".git" folder.
  /// Otherwise, it is the ".git" folder.
  String get commonDir => bindings.commonDir(_repoPointer);

  /// Currently active namespace for this repository.
  ///
  /// If there is no namespace, or the namespace is not a valid utf8 string,
  /// empty string is returned.
  String get namespace => bindings.getNamespace(_repoPointer);

  /// Sets the active [namespace] for this repository.
  ///
  /// This namespace affects all reference operations for the repo. See
  /// `man gitnamespaces`.
  ///
  /// The [namespace] should not include the refs folder, e.g. to namespace all
  /// references under "refs/namespaces/foo/", use "foo" as the namespace.
  ///
  /// Pass null to unset.
  void setNamespace(String? namespace) {
    bindings.setNamespace(
      repoPointer: _repoPointer,
      namespace: namespace,
    );
  }

  /// Whether repository is a bare repository.
  bool get isBare => bindings.isBare(_repoPointer);

  /// Whether repository is empty.
  ///
  /// An empty repository has just been initialized and contains no references
  /// apart from HEAD, which must be pointing to the unborn master branch.
  ///
  /// Throws a [LibGit2Error] if repository is corrupted.
  bool get isEmpty => bindings.isEmpty(_repoPointer);

  /// Whether repository's HEAD is detached.
  ///
  /// A repository's HEAD is detached when it points directly to a commit
  /// instead of a branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isHeadDetached {
    return bindings.isHeadDetached(_repoPointer);
  }

  /// Makes the repository HEAD point to the specified reference or commit.
  ///
  /// If the provided [target] points to a Tree or a Blob, the HEAD is
  /// unaltered.
  ///
  /// If the provided [target] points to a branch, the HEAD will point to that
  /// branch, staying attached, or become attached if it isn't yet.
  ///
  /// If the branch doesn't exist yet, the HEAD will be attached to an unborn
  /// branch.
  ///
  /// Otherwise, the HEAD will be detached and will directly point to the
  /// Commit.
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if provided
  /// [target] is not [Oid] or string.
  void setHead(Object target) {
    if (target is Oid) {
      bindings.setHeadDetached(
        repoPointer: _repoPointer,
        commitishPointer: target.pointer,
      );
    } else if (target is String) {
      bindings.setHead(repoPointer: _repoPointer, refname: target);
    } else {
      throw ArgumentError.value(
        '$target must be either Oid or String reference name',
      );
    }
  }

  /// Whether current branch is unborn.
  ///
  /// An unborn branch is one named from HEAD but which doesn't exist in the
  /// refs namespace, because it doesn't have any commit to point to.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isBranchUnborn {
    return bindings.isBranchUnborn(_repoPointer);
  }

  /// Sets the identity to be used for writing reflogs.
  ///
  /// If both are set, this [name] and [email] will be used to write to the
  /// reflog.
  ///
  /// Pass null to unset. When unset, the identity will be taken from the
  /// repository's configuration.
  void setIdentity({required String? name, required String? email}) {
    bindings.setIdentity(
      repoPointer: _repoPointer,
      name: name,
      email: email,
    );
  }

  /// Configured identity to use for reflogs.
  Identity get identity {
    final identity = bindings.identity(_repoPointer);
    return identity.isNotEmpty
        ? Identity(name: identity[0], email: identity[1])
        : const Identity(name: '', email: '');
  }

  /// Whether repository was a shallow clone.
  bool get isShallow => bindings.isShallow(_repoPointer);

  /// Whether repository is a linked work tree.
  bool get isWorktree => bindings.isWorktree(_repoPointer);

  /// Git's prepared message.
  ///
  /// Operations such as `git revert/cherry-pick/merge` with the "-n" option
  /// stop just short of creating a commit with the changes and save their
  /// prepared message in ".git/MERGE_MSG" so the next git-commit execution
  /// can present it to the user for them to amend if they wish.
  ///
  /// Use this function to get the contents of this file.
  ///
  /// **IMPORTANT**: remove the file with [removeMessage] after you create the
  /// commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get message => bindings.message(_repoPointer);

  /// Removes git's prepared message.
  void removeMessage() => bindings.removeMessage(_repoPointer);

  /// Status of a git repository - ie, whether an operation (merge,
  /// cherry-pick, etc) is in progress.
  GitRepositoryState get state {
    final stateInt = bindings.state(_repoPointer);
    return GitRepositoryState.values.firstWhere(
      (state) => stateInt == state.value,
    );
  }

  /// Removes all the metadata associated with an ongoing command like
  /// merge, revert, cherry-pick, etc. For example: MERGE_HEAD, MERGE_MSG, etc.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stateCleanup() => bindings.stateCleanup(_repoPointer);

  /// Path of the working directory for this repository.
  ///
  /// If the repository is bare, this method will always return empty string.
  String get workdir => bindings.workdir(_repoPointer);

  /// Sets the [path] to the working directory for this repository.
  ///
  /// The working directory doesn't need to be the same one that contains the
  /// ".git" folder for this repository.
  ///
  /// If this repository is bare, setting its working directory will turn it
  /// into a normal repository, capable of performing all the common workdir
  /// operations (checkout, status, index manipulation, etc).
  ///
  /// [updateGitLink] if set creates/updates gitlink in workdir and sets config
  /// "core.worktree" (if workdir is not the parent of the ".git" directory)
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setWorkdir({required String path, bool updateGitlink = false}) {
    bindings.setWorkdir(
      repoPointer: _repoPointer,
      path: path,
      updateGitlink: updateGitlink,
    );
  }

  /// Releases memory allocated for repository object.
  void free() {
    bindings.free(_repoPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Repository{path: $path, commonDir: $commonDir, '
        'namespace: $namespace, isBare: $isBare, isEmpty: $isEmpty, '
        'isHeadDetached: $isHeadDetached, isBranchUnborn: $isBranchUnborn, '
        'isShallow: $isShallow, isWorktree: $isWorktree, state: $state, '
        'workdir: $workdir}';
  }

  /// Configuration file for this repository.
  ///
  /// If a configuration file has not been set, the default config set for the
  /// repository will be returned, including global and system configurations
  /// (if they are available).
  Config get config => Config(bindings.config(_repoPointer));

  /// Snapshot of the repository's configuration.
  ///
  /// Convenience function to take a snapshot from the repository's
  /// configuration.
  ///
  /// The contents of this snapshot will not change, even if the underlying
  /// config files are modified.
  Config get configSnapshot => Config(bindings.configSnapshot(_repoPointer));

  /// Repository's head.
  Reference get head => Reference(bindings.head(_repoPointer));

  /// Index file for this repository.
  Index get index => Index(bindings.index(_repoPointer));

  /// ODB for this repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Odb get odb => Odb(bindings.odb(_repoPointer));

  /// List of all the references names that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get references => Reference.list(this);

  /// List with all the tags names in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get tags => Tag.list(this);

  /// List of all branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branches => Branch.list(repo: this);

  /// List of local branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branchesLocal =>
      Branch.list(repo: this, type: GitBranch.local);

  /// List of remote branches that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branchesRemote =>
      Branch.list(repo: this, type: GitBranch.remote);

  /// List of all the stashed states, first being the most recent.
  List<Stash> get stashes => Stash.list(this);

  /// List of the configured remotes names for a repository.
  List<String> get remotes => Remote.list(this);

  /// List with all tracked submodules paths of a repository.
  List<String> get submodules => Submodule.list(this);

  /// List of linked working trees names.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get worktrees => Worktree.list(this);

  /// Creates a new action signature with default user and now timestamp.
  ///
  /// This looks up the "user.name" and "user.email" from the configuration and
  /// uses the current time as the timestamp, and creates a new signature based
  /// on that information.
  Signature get defaultSignature => Signature.defaultSignature(this);

  /// Returns the list of commits starting from provided commit [oid].
  ///
  /// If [sorting] isn't provided default will be used (reverse chronological
  /// order, like in git).
  List<Commit> log({
    required Oid oid,
    Set<GitSort> sorting = const {GitSort.none},
  }) {
    final walker = RevWalk(this);

    walker.sorting(sorting);
    walker.push(oid);
    final result = walker.walk();

    return result;
  }

  /// Status of the repository.
  ///
  /// Returns map of file paths and their statuses.
  ///
  /// Returns empty map if there are no changes in statuses.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Map<String, Set<GitStatus>> get status {
    final result = <String, Set<GitStatus>>{};
    final list = status_bindings.listNew(_repoPointer);
    final count = status_bindings.listEntryCount(list);

    for (var i = 0; i < count; i++) {
      late String path;
      final entry = status_bindings.getByIndex(
        statuslistPointer: list,
        index: i,
      );

      if (entry.ref.head_to_index != nullptr) {
        path = entry.ref.head_to_index.ref.old_file.path
            .cast<Utf8>()
            .toDartString();
      } else {
        path = entry.ref.index_to_workdir.ref.old_file.path
            .cast<Utf8>()
            .toDartString();
      }

      // Skipping GitStatus.current because entry that is in the list can't be
      // without changes but `&` on `0` value falsly adds it to the set of flags
      result[path] = GitStatus.values
          .skip(1)
          .where((e) => entry.ref.status & e.value == e.value)
          .toSet();
    }

    status_bindings.listFree(list);

    return result;
  }

  /// Returns file status for a single file at provided [path].
  ///
  /// This does not do any sort of rename detection. Renames require a set of
  /// targets and because of the path filtering, there is not enough
  /// information to check renames correctly. To check file status with rename
  /// detection, there is no choice but to do a full [status] and scan through
  /// looking for the path that you are interested in.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Set<GitStatus> statusFile(String path) {
    final statusInt = status_bindings.file(
      repoPointer: _repoPointer,
      path: path,
    );

    if (statusInt == GitStatus.current.value) {
      return {GitStatus.current};
    } else {
      // Skipping GitStatus.current because `&` on `0` value falsly adds it to
      // the set of flags
      return GitStatus.values
          .skip(1)
          .where((e) => statusInt & e.value == e.value)
          .toSet();
    }
  }

  /// Sets the current head to the specified commit [oid] and optionally resets
  /// the index and working tree to match.
  ///
  /// [oid] is the committish to which the HEAD should be moved to. This object
  /// can either be a commit or a tag. When a tag oid is being passed, it
  /// should be dereferencable to a commit which oid will be used as the target
  /// of the branch.
  ///
  /// [resetType] is one of the [GitReset] flags.
  ///
  /// [strategy], [checkoutDirectory] and [pathspec] are optional checkout
  /// options to be used for a HARD reset.
  ///
  /// [strategy] is optional combination of [GitCheckout] flags.
  ///
  /// [checkoutDirectory] is optional alternative checkout path to workdir.
  ///
  /// [pathspec] is optional list of files to checkout.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void reset({
    required Oid oid,
    required GitReset resetType,
    Set<GitCheckout>? strategy,
    String? checkoutDirectory,
    List<String>? pathspec,
  }) {
    final object = object_bindings.lookup(
      repoPointer: _repoPointer,
      oidPointer: oid.pointer,
      type: GitObject.any.value,
    );

    reset_bindings.reset(
      repoPointer: _repoPointer,
      targetPointer: object,
      resetType: resetType.value,
      strategy: strategy?.fold(0, (acc, e) => acc! | e.value),
      checkoutDirectory: checkoutDirectory,
      pathspec: pathspec,
    );

    object_bindings.free(object);
  }

  /// Updates some entries in the index from the [oid] commit tree.
  ///
  /// The scope of the updated entries is determined by the paths being passed
  /// in the [pathspec].
  ///
  /// Passing a null [oid] will result in removing entries in the index
  /// matching the provided [pathspec]s.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void resetDefault({required Oid? oid, required List<String> pathspec}) {
    Pointer<git_object>? object;
    if (oid != null) {
      object = object_bindings.lookup(
        repoPointer: _repoPointer,
        oidPointer: oid.pointer,
        type: GitObject.commit.value,
      );
    }

    reset_bindings.resetDefault(
      repoPointer: _repoPointer,
      targetPointer: object,
      pathspec: pathspec,
    );
  }

  /// Lookups the value of one git attribute with provided [name] for [path].
  ///
  /// Returned value can be either `true`, `false`, `null` (if the attribute
  /// was not set at all), or a [String] value, if the attribute was set to an
  /// actual string.
  Object? getAttribute({
    required String path,
    required String name,
    Set<GitAttributeCheck> flags = const {GitAttributeCheck.fileThenIndex},
  }) {
    return attr_bindings.getAttribute(
      repoPointer: _repoPointer,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      path: path,
      name: name,
    );
  }

  /// Returns list with the `ahead` and `behind` number of unique commits
  /// respectively.
  ///
  /// There is no need for branches containing the commits to have any upstream
  /// relationship, but it helps to think of one as a branch and the other as
  /// its upstream, the ahead and behind values will be what git would report
  /// for the branches.
  ///
  /// [local] is the commit oid for local.
  ///
  /// [upstream] is the commit oid for upstream.
  List<int> aheadBehind({
    required Oid local,
    required Oid upstream,
  }) {
    return graph_bindings.aheadBehind(
      repoPointer: _repoPointer,
      localPointer: local.pointer,
      upstreamPointer: upstream.pointer,
    );
  }

  /// Describes a [commit] if provided or the current worktree.
  ///
  /// [maxCandidatesTags] is the number of candidate tags to consider.
  /// Increasing above 10 will take slightly longer but may produce a more
  /// accurate result. A value of 0 will cause only exact matches to be output.
  /// Default is 10.
  ///
  /// [describeStrategy] is reference lookup strategy that is one of
  /// [GitDescribeStrategy]. Default matches only annotated tags.
  ///
  /// [pattern] is pattern to use for tags matching, excluding the "refs/tags/" prefix.
  ///
  /// [onlyFollowFirstParent] checks whether or not to follow only the first
  /// parent commit upon seeing a merge commit.
  ///
  /// [showCommitOidAsFallback] determines if full id of the commit should be
  /// shown if no matching tag or reference is found.
  ///
  /// [abbreviatedSize] is the minimum number of hexadecimal digits to show for
  /// abbreviated object names. A value of 0 will suppress long format, only
  /// showing the closest tag. Default is 7.
  ///
  /// [alwaysUseLongFormat] determines if he long format (the nearest tag, the
  /// number of commits, and the abbrevated commit name) should be used even
  /// when the commit matches the tag.
  ///
  /// [dirtySuffix] is a string to append if the working tree is dirty.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String describe({
    Commit? commit,
    int? maxCandidatesTags,
    GitDescribeStrategy? describeStrategy,
    String? pattern,
    bool? onlyFollowFirstParent,
    bool? showCommitOidAsFallback,
    int? abbreviatedSize,
    bool? alwaysUseLongFormat,
    String? dirtySuffix,
  }) {
    Pointer<git_describe_result> describeResult = nullptr;

    if (commit != null) {
      describeResult = describe_bindings.commit(
        commitPointer: commit.pointer,
        maxCandidatesTags: maxCandidatesTags,
        describeStrategy: describeStrategy?.value,
        pattern: pattern,
        onlyFollowFirstParent: onlyFollowFirstParent,
        showCommitOidAsFallback: showCommitOidAsFallback,
      );
    } else {
      describeResult = describe_bindings.workdir(
        repo: _repoPointer,
        maxCandidatesTags: maxCandidatesTags,
        describeStrategy: describeStrategy?.value,
        pattern: pattern,
        onlyFollowFirstParent: onlyFollowFirstParent,
        showCommitOidAsFallback: showCommitOidAsFallback,
      );
    }

    final result = describe_bindings.format(
      describeResultPointer: describeResult,
      abbreviatedSize: abbreviatedSize,
      alwaysUseLongFormat: alwaysUseLongFormat,
      dirtySuffix: dirtySuffix,
    );

    describe_bindings.free(describeResult);

    return result;
  }

  /// Packs the objects in the odb chosen by the [packDelegate] function and
  /// writes ".pack" and ".idx" files for them into provided [path] or default
  /// location.
  ///
  /// Returns the number of objects written to the pack.
  ///
  /// [packDelegate] is a function that will provide what objects should be
  /// added to the pack builder. Default is add all objects.
  ///
  /// [threads] is number of threads the PackBuilder will spawn. Default is
  /// none. 0 will let libgit2 to autodetect number of CPUs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  int pack({
    String? path,
    void Function(PackBuilder)? packDelegate,
    int? threads,
  }) {
    void packAll(PackBuilder packbuilder) {
      for (final object in odb.objects) {
        packbuilder.add(object);
      }
    }

    // ignore: no_leading_underscores_for_local_identifiers
    final _packDelegate = packDelegate ?? packAll;

    final packbuilder = PackBuilder(this);
    if (threads != null) {
      packbuilder.setThreads(threads);
    }
    _packDelegate(packbuilder);
    packbuilder.write(path);

    return packbuilder.writtenLength;
  }

  @override
  List<Object?> get props => [path];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_repository>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

class RepositoryCallback {
  /// Values used to override the repository creation and customization process
  /// during a clone operation.
  ///
  /// [path] is the path to the repository.
  ///
  /// [bare] whether new repository should be bare.
  ///
  /// [flags] is a combination of [GitRepositoryInit] flags. Defaults to
  /// [GitRepositoryInit.mkdir].
  ///
  /// [mode] is the permissions for the folder. Default to 0 (permissions
  /// configured by umask).
  ///
  /// [workdirPath] is the path to the working directory. Can be null for
  /// default path.
  ///
  /// [description] if set will be used to initialize the "description" file in
  /// the repository, instead of using the template content.
  ///
  /// [templatePath] is the the path to use for the template directory if
  /// [GitRepositoryInit.externalTemplate] is set. Defaults to the config or
  /// default directory options.
  ///
  /// [initialHead] is the name of the head to point HEAD at. If null, then
  /// this will be treated as "master" and the HEAD ref will be set to
  /// "refs/heads/master". If this begins with "refs/" it will be used
  /// verbatim, otherwise "refs/heads/" will be prefixed.
  ///
  /// [originUrl] if set, then after the rest of the repository initialization
  /// is completed, an "origin" remote will be added pointing to this URL.
  const RepositoryCallback({
    required this.path,
    this.bare = false,
    this.flags = const {GitRepositoryInit.mkpath},
    this.mode = 0,
    this.workdirPath,
    this.description,
    this.templatePath,
    this.initialHead,
    this.originUrl,
  });

  /// Path to the repository.
  final String path;

  /// Whether repository is bare.
  final bool bare;

  /// Combination of [GitRepositoryInit] flags.
  final Set<GitRepositoryInit> flags;

  /// Permissions for the repository folder.
  final int mode;

  /// Path to the working directory.
  final String? workdirPath;

  /// Description used to initialize the "description" file in the repository.
  final String? description;

  /// Path used for the template directory.
  final String? templatePath;

  /// Name of the head HEAD points at.
  final String? initialHead;

  /// "origin" remote URL that will be added after the rest of the repository
  /// initialization is completed.
  final String? originUrl;
}

@immutable
class Identity extends Equatable {
  /// Identity to use for reflogs.
  const Identity({required this.name, required this.email});

  final String name;
  final String email;

  @override
  List<Object?> get props => [name, email];
}
