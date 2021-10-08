import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/repository.dart' as bindings;
import 'bindings/merge.dart' as merge_bindings;
import 'bindings/object.dart' as object_bindings;
import 'bindings/status.dart' as status_bindings;
import 'bindings/commit.dart' as commit_bindings;
import 'bindings/checkout.dart' as checkout_bindings;
import 'bindings/reset.dart' as reset_bindings;
import 'bindings/diff.dart' as diff_bindings;
import 'bindings/stash.dart' as stash_bindings;
import 'bindings/attr.dart' as attr_bindings;
import 'bindings/graph.dart' as graph_bindings;
import 'bindings/describe.dart' as describe_bindings;
import 'util.dart';

class Repository {
  /// Initializes a new instance of the [Repository] class from provided
  /// pointer to repository object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Repository(this._repoPointer);

  /// Initializes a new instance of the [Repository] class by creating a new
  /// git repository in the given folder.
  ///
  /// Should be freed with `free()` to release allocated memory.
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

    int flagsInt = flags.fold(0, (previousValue, e) => previousValue | e.value);

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
  }

  /// Initializes a new instance of the [Repository] class by opening repository
  /// at provided [path].
  ///
  /// For a standard repository, [path] should either point to the `.git` folder
  /// or to the working directory. For a bare repository, [path] should directly
  /// point to the repository folder.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.open(String path) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.open(path);
  }

  /// Initializes a new instance of the [Repository] class by cloning a remote repository
  /// at provided [url] into [localPath].
  ///
  /// [remote] is the callback function with `Remote Function(Repository repo, String name, String url)`
  /// signature. The [Remote] it returns will be used instead of default one.
  ///
  /// [repository] is the callback function matching the `Repository Function(String path, bool bare)`
  /// signature. The [Repository] it returns will be used instead of creating a new one.
  ///
  /// [checkoutBranch] is the name of the branch to checkout after the clone. Defaults
  /// to using the remote's default branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.clone({
    required String url,
    required String localPath,
    bool bare = false,
    Remote Function(Repository, String, String)? remote,
    Repository Function(String, bool)? repository,
    String? checkoutBranch,
    Callbacks callbacks = const Callbacks(),
  }) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.clone(
      url: url,
      localPath: localPath,
      bare: bare,
      remote: remote,
      repository: repository,
      checkoutBranch: checkoutBranch,
      callbacks: callbacks,
    );
  }

  late final Pointer<git_repository> _repoPointer;

  /// Pointer to memory address for allocated repository object.
  Pointer<git_repository> get pointer => _repoPointer;

  /// Look for a git repository and return its path. The lookup start from [startPath]
  /// and walk across parent directories if nothing has been found. The lookup ends when
  /// the first repository is found, or when reaching a directory referenced in [ceilingDirs].
  ///
  /// The method will automatically detect if the repository is bare (if there is a repository).
  ///
  /// Throws a [LibGit2Error] if error occured.
  static String discover({required String startPath, String? ceilingDirs}) {
    return bindings.discover(
      startPath: startPath,
      ceilingDirs: ceilingDirs,
    );
  }

  /// Returns path to the `.git` folder for normal repositories
  /// or path to the repository itself for bare repositories.
  String get path => bindings.path(_repoPointer);

  /// Returns the path of the shared common directory for this repository.
  ///
  /// If the repository is bare, it is the root directory for the repository.
  /// If the repository is a worktree, it is the parent repo's `.git` folder.
  /// Otherwise, it is the `.git` folder.
  String get commonDir => bindings.commonDir(_repoPointer);

  /// Returns the currently active namespace for this repository.
  ///
  /// If there is no namespace, or the namespace is not a valid utf8 string,
  /// empty string is returned.
  String get namespace => bindings.getNamespace(_repoPointer);

  /// Sets the active namespace for this repository.
  ///
  /// This namespace affects all reference operations for the repo. See `man gitnamespaces`
  ///
  /// The [namespace] should not include the refs folder, e.g. to namespace all references
  /// under refs/namespaces/foo/, use foo as the namespace.
  ///
  /// Pass null to unset.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setNamespace(String? namespace) {
    bindings.setNamespace(
      repoPointer: _repoPointer,
      namespace: namespace,
    );
  }

  /// Checks whether this repository is a bare repository or not.
  bool get isBare => bindings.isBare(_repoPointer);

  /// Check if a repository is empty.
  ///
  /// An empty repository has just been initialized and contains no references
  /// apart from HEAD, which must be pointing to the unborn master branch.
  ///
  /// Throws a [LibGit2Error] if repository is corrupted.
  bool get isEmpty => bindings.isEmpty(_repoPointer);

  /// Checks if a repository's HEAD is detached.
  ///
  /// A repository's HEAD is detached when it points directly to a commit instead of a branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isHeadDetached {
    return bindings.isHeadDetached(_repoPointer);
  }

  /// Makes the repository HEAD point to the specified reference or commit.
  ///
  /// If the provided [target] points to a Tree or a Blob, the HEAD is unaltered.
  ///
  /// If the provided [target] points to a branch, the HEAD will point to that branch,
  /// staying attached, or become attached if it isn't yet.
  ///
  /// If the branch doesn't exist yet, the HEAD will be attached to an unborn branch.
  ///
  /// Otherwise, the HEAD will be detached and will directly point to the Commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setHead(String target) {
    late final Oid oid;

    if (isValidShaHex(target)) {
      oid = Oid.fromSHA(repo: this, sha: target);
      bindings.setHeadDetached(
        repoPointer: _repoPointer,
        commitishPointer: oid.pointer,
      );
    } else {
      bindings.setHead(repoPointer: _repoPointer, refname: target);
    }
  }

  /// Checks if the current branch is unborn.
  ///
  /// An unborn branch is one named from HEAD but which doesn't exist in the refs namespace,
  /// because it doesn't have any commit to point to.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool get isBranchUnborn {
    return bindings.isBranchUnborn(_repoPointer);
  }

  /// Sets the identity to be used for writing reflogs.
  ///
  /// If both are set, this name and email will be used to write to the reflog.
  /// Pass null to unset. When unset, the identity will be taken from the repository's configuration.
  void setIdentity({required String? name, required String? email}) {
    bindings.setIdentity(
      repoPointer: _repoPointer,
      name: name,
      email: email,
    );
  }

  /// Returns the configured identity to use for reflogs.
  Map<String, String> get identity => bindings.identity(_repoPointer);

  /// Checks if the repository was a shallow clone.
  bool get isShallow => bindings.isShallow(_repoPointer);

  /// Checks if a repository is a linked work tree.
  bool get isWorktree => bindings.isWorktree(_repoPointer);

  /// Retrieves git's prepared message.
  ///
  /// Operations such as git revert/cherry-pick/merge with the -n option
  /// stop just short of creating a commit with the changes and save their
  /// prepared message in .git/MERGE_MSG so the next git-commit execution
  /// can present it to the user for them to amend if they wish.
  ///
  /// Use this function to get the contents of this file.
  /// Don't forget to remove the file with [removeMessage] after you create the commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get message => bindings.message(_repoPointer);

  /// Removes git's prepared message.
  void removeMessage() => bindings.removeMessage(_repoPointer);

  /// Returns the status of a git repository - ie, whether an operation
  /// (merge, cherry-pick, etc) is in progress.
  GitRepositoryState get state {
    final stateInt = bindings.state(_repoPointer);
    return GitRepositoryState.values
        .singleWhere((state) => stateInt == state.value);
  }

  /// Removes all the metadata associated with an ongoing command like
  /// merge, revert, cherry-pick, etc. For example: MERGE_HEAD, MERGE_MSG, etc.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stateCleanup() => bindings.stateCleanup(_repoPointer);

  /// Returns the path of the working directory for this repository.
  ///
  /// If the repository is bare, this function will always return empty string.
  String get workdir => bindings.workdir(_repoPointer);

  /// Sets the path to the working directory for this repository.
  ///
  /// The working directory doesn't need to be the same one that contains the
  /// `.git` folder for this repository.
  ///
  /// If this repository is bare, setting its working directory will turn it into a
  /// normal repository, capable of performing all the common workdir operations
  /// (checkout, status, index manipulation, etc).
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
  void free() => bindings.free(_repoPointer);

  /// Returns the configuration file for this repository.
  ///
  /// If a configuration file has not been set, the default config set for the repository
  /// will be returned, including global and system configurations (if they are available).
  ///
  /// The configuration file must be freed once it's no longer being used by the user.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config get config => Config(bindings.config(_repoPointer));

  /// Returns a snapshot of the repository's configuration.
  ///
  /// Convenience function to take a snapshot from the repository's configuration.
  /// The contents of this snapshot will not change, even if the underlying config files are modified.
  ///
  /// The configuration file must be freed once it's no longer being used by the user.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Config get configSnapshot => Config(bindings.configSnapshot(_repoPointer));

  /// Returns [Reference] object pointing to repository head.
  ///
  /// Must be freed once it's no longer being used.
  Reference get head => Reference(bindings.head(_repoPointer));

  /// Returns [References] object.
  References get references => References(this);

  /// Returns [Index] file for this repository.
  ///
  /// Must be freed once it's no longer being used.
  Index get index => Index(bindings.index(_repoPointer));

  /// Returns [Odb] for this repository.
  ///
  /// ODB Object must be freed once it's no longer being used.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Odb get odb => Odb(bindings.odb(_repoPointer));

  /// Looksup git object (commit, tree, blob, tag) for provided [sha] hex string.
  ///
  /// Returned object should be explicitly downcasted to one of four of git object types.
  ///
  /// ```dart
  /// final commit = repo['s0m3sh4'] as Commit;
  /// final tree = repo['s0m3sh4'] as Tree;
  /// final blob = repo['s0m3sh4'] as Blob;
  /// final tag = repo['s0m3sh4'] as Tag;
  /// ```
  ///
  /// Throws [ArgumentError] if provided [sha] is not pointing to commit, tree, blob or tag.
  Object operator [](String sha) {
    final oid = Oid.fromSHA(repo: this, sha: sha);
    final object = object_bindings.lookup(
      repoPointer: _repoPointer,
      oidPointer: oid.pointer,
      type: GitObject.any.value,
    );
    final type = object_bindings.type(object);

    if (type == GitObject.commit.value) {
      return Commit(object.cast());
    } else if (type == GitObject.tree.value) {
      return Tree(object.cast());
    } else if (type == GitObject.blob.value) {
      return Blob(object.cast());
    } else if (type == GitObject.tag.value) {
      return Tag(object.cast());
    } else {
      throw ArgumentError.value(
          '$sha should be pointing to either commit, tree, blob or a tag');
    }
  }

  /// Creates a new action signature with default user and now timestamp.
  ///
  /// This looks up the user.name and user.email from the configuration and uses the
  /// current time as the timestamp, and creates a new signature based on that information.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Signature get defaultSignature => Signature.defaultSignature(this);

  /// Returns the list of commits starting from provided [sha] hex string.
  ///
  /// If [sorting] isn't provided default will be used (reverse chronological order, like in git).
  List<Commit> log({
    required String sha,
    Set<GitSort> sorting = const {GitSort.none},
  }) {
    final oid = Oid.fromSHA(repo: this, sha: sha);
    final walker = RevWalk(this);

    walker.sorting(sorting);
    walker.push(oid);
    final result = walker.walk();

    walker.free();

    return result;
  }

  /// Finds a single object, as specified by a [spec] revision string.
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// The returned object should be released when no longer needed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Commit revParseSingle(String spec) {
    return RevParse.single(repo: this, spec: spec);
  }

  /// Creates new commit in the repository.
  ///
  /// [updateRef] is name of the reference that will be updated to point to this commit.
  /// If the reference is not direct, it will be resolved to a direct reference. Use "HEAD"
  /// to update the HEAD of the current branch and make it point to this commit. If the
  /// reference doesn't exist yet, it will be created. If it does exist, the first parent
  /// must be the tip of this branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createCommit({
    required String message,
    required Signature author,
    required Signature commiter,
    required String treeSHA,
    required List<String> parents,
    String? updateRef,
    String? messageEncoding,
  }) {
    return Commit.create(
      repo: this,
      message: message,
      author: author,
      commiter: commiter,
      treeSHA: treeSHA,
      parents: parents,
    );
  }

  /// Finds a single object and intermediate reference (if there is one) by a [spec] revision string.
  ///
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may point to an
  /// intermediate reference. When such expressions are being passed in, reference_out will be
  /// valued as well.
  ///
  /// The returned object and reference should be released when no longer needed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RevParse revParseExt(String spec) {
    return RevParse.ext(repo: this, spec: spec);
  }

  /// Parses a revision string for from, to, and intent.
  ///
  /// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RevSpec revParse(String spec) {
    return RevParse.range(repo: this, spec: spec);
  }

  /// Creates a new blob from a [content] string and writes it to ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlob(String content) => Blob.create(repo: this, content: content);

  /// Creates a new blob from the file in working directory of a repository and writes
  /// it to the ODB. Provided [path] should be relative to the working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromWorkdir(String relativePath) {
    return Blob.createFromWorkdir(
      repo: this,
      relativePath: relativePath,
    );
  }

  /// Creates a new blob from the file in filesystem and writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromDisk(String path) {
    return Blob.createFromDisk(repo: this, path: path);
  }

  /// Creates a new tag in the repository from provided Oid object.
  ///
  /// A new reference will also be created pointing to this tag object. If force is true
  /// and a reference already exists with the given name, it'll be replaced.
  ///
  /// The message will not be cleaned up.
  ///
  /// The tag name will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createTag({
    required String tagName,
    required String target,
    required GitObject targetType,
    required Signature tagger,
    required String message,
    bool force = false,
  }) {
    return Tag.create(
        repo: this,
        tagName: tagName,
        target: target,
        targetType: targetType,
        tagger: tagger,
        message: message,
        force: force);
  }

  /// Returns a list with all the tags in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get tags => Tag.list(this);

  /// Returns a [Branches] object.
  Branches get branches => Branches(this);

  /// Checks status of the repository and returns map of file paths and their statuses.
  ///
  /// Returns empty map if there are no changes in statuses.
  Map<String, Set<GitStatus>> get status {
    var result = <String, Set<GitStatus>>{};
    var list = status_bindings.listNew(_repoPointer);
    var count = status_bindings.listEntryCount(list);

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

      var statuses = <GitStatus>{};
      // Skipping GitStatus.current because entry that is in the list can't be without changes
      // but `&` on `0` value falsly adds it to the set of flags
      for (var status in GitStatus.values.skip(1)) {
        if (entry.ref.status & status.value == status.value) {
          statuses.add(status);
        }
      }
      result[path] = statuses;
    }

    status_bindings.listFree(list);

    return result;
  }

  /// Returns file status for a single file.
  ///
  /// This does not do any sort of rename detection. Renames require a set of targets and because
  /// of the path filtering, there is not enough information to check renames correctly. To check
  /// file status with rename detection, there is no choice but to do a full [status] and scan
  /// through looking for the path that you are interested in.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Set<GitStatus> statusFile(String path) {
    final statusInt = status_bindings.file(
      repoPointer: _repoPointer,
      path: path,
    );

    var statuses = <GitStatus>{};
    if (statusInt == GitStatus.current.value) {
      statuses.add(GitStatus.current);
    } else {
      // Skipping GitStatus.current because `&` on `0` value falsly adds it to the set of flags
      for (var status in GitStatus.values.skip(1)) {
        if (statusInt & status.value == status.value) {
          statuses.add(status);
        }
      }
    }

    return statuses;
  }

  /// Finds a merge base between two commits.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid mergeBase({required String a, required String b}) {
    final oidA = Oid.fromSHA(repo: this, sha: a);
    final oidB = Oid.fromSHA(repo: this, sha: b);
    return Oid(merge_bindings.mergeBase(
      repoPointer: _repoPointer,
      aPointer: oidA.pointer,
      bPointer: oidB.pointer,
    ));
  }

  /// Analyzes the given branch(es) and determines the opportunities for merging them
  /// into a reference (default is 'HEAD').
  ///
  /// Returns list with analysis result and preference for fast forward merge values
  /// respectively.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Set<dynamic>> mergeAnalysis({
    required Oid theirHead,
    String ourRef = 'HEAD',
  }) {
    final ref = references[ourRef];
    final head = commit_bindings.annotatedLookup(
      repoPointer: _repoPointer,
      oidPointer: theirHead.pointer,
    );

    var result = <Set<dynamic>>[];
    var analysisSet = <GitMergeAnalysis>{};
    final analysisInt = merge_bindings.analysis(
      repoPointer: _repoPointer,
      ourRefPointer: ref.pointer,
      theirHeadPointer: head,
      theirHeadsLen: 1,
    );
    for (var analysis in GitMergeAnalysis.values) {
      if (analysisInt[0] & analysis.value == analysis.value) {
        analysisSet.add(analysis);
      }
    }
    result.add(analysisSet);
    result.add(
      {GitMergePreference.values.singleWhere((e) => analysisInt[1] == e.value)},
    );

    commit_bindings.annotatedFree(head.value);
    ref.free();

    return result;
  }

  /// Merges the given commit(s) oid into HEAD, writing the results into the working directory.
  /// Any changes are staged for commit and any conflicts are written to the index. Callers
  /// should inspect the repository's index after this completes, resolve any conflicts and
  /// prepare a commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void merge(Oid oid) {
    final theirHead = commit_bindings.annotatedLookup(
      repoPointer: _repoPointer,
      oidPointer: oid.pointer,
    );

    merge_bindings.merge(
      repoPointer: _repoPointer,
      theirHeadsPointer: theirHead,
      theirHeadsLen: 1,
    );

    commit_bindings.annotatedFree(theirHead.value);
  }

  /// Merges two files as they exist in the index, using the given common ancestor
  /// as the baseline, producing a string that reflects the merge result containing
  /// possible conflicts.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String mergeFileFromIndex({
    required IndexEntry? ancestor,
    required IndexEntry? ours,
    required IndexEntry? theirs,
  }) {
    return merge_bindings.mergeFileFromIndex(
      repoPointer: _repoPointer,
      ancestorPointer: ancestor?.pointer,
      oursPointer: ours?.pointer,
      theirsPointer: theirs?.pointer,
    );
  }

  /// Merges two commits, producing an index that reflects the result of the merge.
  /// The index may be written as-is to the working directory or checked out. If the index
  /// is to be converted to a tree, the caller should resolve any conflicts that arose as
  /// part of the merge.
  ///
  /// The returned index must be freed explicitly.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index mergeCommits({
    required Commit ourCommit,
    required Commit theirCommit,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFlag> mergeFlags = const {GitMergeFlag.findRenames},
    Set<GitMergeFileFlag> fileFlags = const {GitMergeFileFlag.defaults},
  }) {
    var opts = <String, int>{};
    opts['favor'] = favor.value;
    opts['mergeFlags'] =
        mergeFlags.fold(0, (previousValue, e) => previousValue | e.value);
    opts['fileFlags'] =
        fileFlags.fold(0, (previousValue, e) => previousValue | e.value);

    final result = merge_bindings.mergeCommits(
      repoPointer: _repoPointer,
      ourCommitPointer: ourCommit.pointer,
      theirCommitPointer: theirCommit.pointer,
      opts: opts,
    );

    return Index(result);
  }

  /// Reverts the given commit against the given "our" commit, producing an index that
  /// reflects the result of the revert.
  ///
  /// [mainline] is parent of the [revertCommit] if it is a merge (i.e. 1, 2).
  ///
  /// The returned index must be freed explicitly with `free()`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index revertCommit({
    required Commit revertCommit,
    required Commit ourCommit,
    mainline = 0,
  }) {
    return Index(commit_bindings.revertCommit(
      repoPointer: _repoPointer,
      revertCommitPointer: revertCommit.pointer,
      ourCommitPointer: ourCommit.pointer,
      mainline: mainline,
    ));
  }

  /// Merges two trees, producing an index that reflects the result of the merge.
  /// The index may be written as-is to the working directory or checked out. If the index
  /// is to be converted to a tree, the caller should resolve any conflicts that arose as part
  /// of the merge.
  ///
  /// The returned index must be freed explicitly.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index mergeTrees({
    required Tree ancestorTree,
    required Tree ourTree,
    required Tree theirTree,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    List<GitMergeFlag> mergeFlags = const [GitMergeFlag.findRenames],
    List<GitMergeFileFlag> fileFlags = const [GitMergeFileFlag.defaults],
  }) {
    var opts = <String, int>{};
    opts['favor'] = favor.value;
    opts['mergeFlags'] = mergeFlags.fold(
      0,
      (previousValue, element) => previousValue + element.value,
    );
    opts['fileFlags'] = fileFlags.fold(
      0,
      (previousValue, element) => previousValue + element.value,
    );

    final result = merge_bindings.mergeTrees(
      repoPointer: _repoPointer,
      ancestorTreePointer: ancestorTree.pointer,
      ourTreePointer: ourTree.pointer,
      theirTreePointer: theirTree.pointer,
      opts: opts,
    );

    return Index(result);
  }

  /// Cherry-picks the provided commit, producing changes in the index and working directory.
  ///
  /// Any changes are staged for commit and any conflicts are written to the index. Callers
  /// should inspect the repository's index after this completes, resolve any conflicts and
  /// prepare a commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void cherryPick(Commit commit) {
    merge_bindings.cherryPick(
      repoPointer: _repoPointer,
      commitPointer: commit.pointer,
    );
  }

  /// Checkouts the provided reference [refName] using the given strategy, and update the HEAD.
  ///
  /// If no reference [refName] is given, checkouts from the index.
  ///
  /// Default checkout strategy is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is alternative checkout path to workdir.
  ///
  /// [paths] is list of files to checkout from provided reference [refName]. If paths are provided
  /// HEAD will not be set to the reference [refName].
  void checkout({
    String? refName,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    final int strat =
        strategy.fold(0, (previousValue, e) => previousValue | e.value);

    if (refName == null) {
      checkout_bindings.index(
        repoPointer: _repoPointer,
        strategy: strat,
        directory: directory,
        paths: paths,
      );
    } else if (refName == 'HEAD') {
      checkout_bindings.head(
        repoPointer: _repoPointer,
        strategy: strat,
        directory: directory,
        paths: paths,
      );
    } else {
      final ref = references[refName];
      final treeish = object_bindings.lookup(
        repoPointer: _repoPointer,
        oidPointer: ref.target.pointer,
        type: GitObject.any.value,
      );
      checkout_bindings.tree(
        repoPointer: _repoPointer,
        treeishPointer: treeish,
        strategy: strat,
        directory: directory,
        paths: paths,
      );
      if (paths == null) {
        setHead(refName);
      }

      object_bindings.free(treeish);
      ref.free();
    }
  }

  /// Sets the current head to the specified commit and optionally resets the index
  /// and working tree to match.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void reset({required String target, required GitReset resetType}) {
    final oid = Oid.fromSHA(repo: this, sha: target);
    final object = object_bindings.lookup(
      repoPointer: _repoPointer,
      oidPointer: oid.pointer,
      type: GitObject.any.value,
    );

    reset_bindings.reset(
      repoPointer: _repoPointer,
      targetPointer: object,
      resetType: resetType.value,
      checkoutOptsPointer: nullptr,
    );

    object_bindings.free(object);
  }

  /// Returns a [Diff] with changes between the trees, tree and index, tree and workdir or
  /// index and workdir.
  ///
  /// If [b] is null, by default the [a] tree compared to working directory. If [cached] is
  /// set to true the [a] tree compared to index/staging area.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Diff diff({
    Tree? a,
    Tree? b,
    bool cached = false,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    final int flagsInt =
        flags.fold(0, (previousValue, e) => previousValue | e.value);

    if (a is Tree && b is Tree) {
      return Diff(diff_bindings.treeToTree(
        repoPointer: _repoPointer,
        oldTreePointer: a.pointer,
        newTreePointer: b.pointer,
        flags: flagsInt,
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ));
    } else if (a is Tree && b == null) {
      if (cached) {
        return Diff(diff_bindings.treeToIndex(
          repoPointer: _repoPointer,
          treePointer: a.pointer,
          indexPointer: index.pointer,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        ));
      } else {
        return Diff(diff_bindings.treeToWorkdir(
          repoPointer: _repoPointer,
          treePointer: a.pointer,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        ));
      }
    } else if (a == null && b == null) {
      return Diff(diff_bindings.indexToWorkdir(
        repoPointer: _repoPointer,
        indexPointer: index.pointer,
        flags: flagsInt,
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ));
    } else {
      throw ArgumentError.notNull('a');
    }
  }

  /// Returns a [Patch] with changes between the blobs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch diffBlobs({
    required Blob a,
    required Blob b,
    String? aPath,
    String? bPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return a.diff(newBlob: b, oldAsPath: aPath, newAsPath: bPath);
  }

  /// Applies the [diff] to the given repository, making changes directly in the working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void apply(Diff diff) {
    diff_bindings.apply(
      repoPointer: _repoPointer,
      diffPointer: diff.pointer,
      location: GitApplyLocation.workdir.value,
    );
  }

  /// Checks if the [diff] will apply to HEAD.
  bool applies(Diff diff) {
    return diff_bindings.apply(
      repoPointer: _repoPointer,
      diffPointer: diff.pointer,
      location: GitApplyLocation.index.value,
      check: true,
    );
  }

  /// Saves the local modifications to a new stash.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid stash({
    required Signature stasher,
    String? message,
    bool keepIndex = false,
    bool includeUntracked = false,
    bool includeIgnored = false,
  }) {
    int flags = 0;
    if (keepIndex) flags |= GitStash.keepIndex.value;
    if (includeUntracked) flags |= GitStash.includeUntracked.value;
    if (includeIgnored) flags |= GitStash.includeIgnored.value;

    return Oid(stash_bindings.stash(
      repoPointer: _repoPointer,
      stasherPointer: stasher.pointer,
      message: message,
      flags: flags,
    ));
  }

  /// Applies a single stashed state from the stash list.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stashApply({
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    int flags = reinstateIndex ? GitStashApply.reinstateIndex.value : 0;
    final int strat =
        strategy.fold(0, (previousValue, e) => previousValue | e.value);

    stash_bindings.apply(
      repoPointer: _repoPointer,
      index: index,
      flags: flags,
      strategy: strat,
      directory: directory,
      paths: paths,
    );
  }

  /// Removes a single stashed state from the stash list.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stashDrop([int index = 0]) {
    stash_bindings.drop(
      repoPointer: _repoPointer,
      index: index,
    );
  }

  /// Applies a single stashed state from the stash list and remove it from the list if successful.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stashPop({
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    int flags = reinstateIndex ? GitStashApply.reinstateIndex.value : 0;
    final int strat =
        strategy.fold(0, (previousValue, e) => previousValue | e.value);

    stash_bindings.pop(
      repoPointer: _repoPointer,
      index: index,
      flags: flags,
      strategy: strat,
      directory: directory,
      paths: paths,
    );
  }

  /// Returns list of all the stashed states, first being the most recent.
  List<Stash> get stashList {
    return stash_bindings.list(_repoPointer);
  }

  /// Returns [Remotes] object.
  Remotes get remotes => Remotes(this);

  /// Looks up the value of one git attribute for path.
  ///
  /// Returned value can be either `true`, `false`, `null` (if the attribute was not set at all),
  /// or a [String] value, if the attribute was set to an actual string.
  ///
  /// Throws a [LibGit2Error] if error occured.
  dynamic getAttribute({
    required String path,
    required String name,
    Set<GitAttributeCheck> flags = const {GitAttributeCheck.fileThenIndex},
  }) {
    final int flagsInt =
        flags.fold(0, (previousValue, e) => previousValue | e.value);

    return attr_bindings.getAttribute(
      repoPointer: _repoPointer,
      flags: flagsInt,
      path: path,
      name: name,
    );
  }

  /// Gets the blame for a single file.
  ///
  /// [flags] is a combination of [GitBlameFlag]s.
  ///
  /// [minMatchCharacters] is the lower bound on the number of alphanumeric
  /// characters that must be detected as moving/copying within a file for
  /// it to associate those lines with the parent commit. The default value is 20.
  /// This value only takes effect if any of the [GitBlameFlag.trackCopies*]
  /// flags are specified.
  ///
  /// [newestCommit] is the id of the newest commit to consider. The default is HEAD.
  ///
  /// [oldestCommit] is the id of the oldest commit to consider. The default is the
  /// first commit encountered with no parent.
  ///
  /// [minLine] is the first line in the file to blame. The default is 1
  /// (line numbers start with 1).
  ///
  /// [maxLine] is the last line in the file to blame. The default is the last
  /// line of the file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Blame blame({
    required String path,
    Set<GitBlameFlag> flags = const {GitBlameFlag.normal},
    int? minMatchCharacters,
    Oid? newestCommit,
    Oid? oldestCommit,
    int? minLine,
    int? maxLine,
  }) {
    return Blame.file(
      repo: this,
      path: path,
      flags: flags,
      minMatchCharacters: minMatchCharacters,
      newestCommit: newestCommit,
      oldestCommit: oldestCommit,
      minLine: minLine,
      maxLine: maxLine,
    );
  }

  /// Returns list of notes for repository.
  ///
  /// Notes must be freed manually.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Note> get notes => Notes(this).list;

  /// Reads the note for an object.
  ///
  /// The note must be freed manually.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Note lookupNote({
    required Oid annotatedId,
    String notesRef = 'refs/notes/commits',
  }) {
    return Notes.lookup(
      repo: this,
      annotatedId: annotatedId,
      notesRef: notesRef,
    );
  }

  /// Adds a note for an [object].
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createNote({
    required Signature author,
    required Signature committer,
    required Oid object,
    required String note,
    String notesRef = 'refs/notes/commits',
    bool force = false,
  }) {
    return Notes.create(
      repo: this,
      author: author,
      committer: committer,
      object: object,
      note: note,
      notesRef: notesRef,
      force: force,
    );
  }

  /// Checks if a commit is the descendant of another commit.
  ///
  /// Note that a commit is not considered a descendant of itself, in contrast to
  /// `git merge-base --is-ancestor`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool descendantOf({required String commitSHA, required String ancestorSHA}) {
    final commit = Oid.fromSHA(repo: this, sha: commitSHA);
    final ancestor = Oid.fromSHA(repo: this, sha: ancestorSHA);

    return graph_bindings.descendantOf(
      repoPointer: _repoPointer,
      commitPointer: commit.pointer,
      ancestorPointer: ancestor.pointer,
    );
  }

  /// Returns list with the `ahead` and `behind` number of unique commits respectively.
  ///
  /// There is no need for branches containing the commits to have any upstream relationship,
  /// but it helps to think of one as a branch and the other as its upstream, the ahead and
  /// behind values will be what git would report for the branches.
  List<int> aheadBehind({
    required String localSHA,
    required String upstreamSHA,
  }) {
    final local = Oid.fromSHA(repo: this, sha: localSHA);
    final upstream = Oid.fromSHA(repo: this, sha: upstreamSHA);

    return graph_bindings.aheadBehind(
      repoPointer: _repoPointer,
      localPointer: local.pointer,
      upstreamPointer: upstream.pointer,
    );
  }

  /// Describes a commit or the current worktree.
  ///
  /// [maxCandidatesTags] is the number of candidate tags to consider. Increasing above 10 will
  /// take slightly longer but may produce a more accurate result. A value of 0 will cause
  /// only exact matches to be output. Default is 10.
  ///
  /// [describeStrategy] is reference lookup strategy that is one of [GitDescribeStrategy].
  /// Default matches only annotated tags.
  ///
  /// [pattern] is pattern to use for tags matching, excluding the "refs/tags/" prefix.
  ///
  /// [onlyFollowFirstParent] checks whether or not to follow only the first parent
  /// commit upon seeing a merge commit.
  ///
  /// [showCommitOidAsFallback] determines if full id of the commit should be shown
  /// if no matching tag or reference is found.
  ///
  /// [abbreviatedSize] is the minimum number of hexadecimal digits to show for abbreviated
  /// object names. A value of 0 will suppress long format, only showing the closest tag.
  /// Default is 7.
  ///
  /// [alwaysUseLongFormat] determines if he long format (the nearest tag, the number of
  /// commits, and the abbrevated commit name) should be used even when the commit matches
  /// the tag.
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
    late final Pointer<git_describe_result> describeResult;

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

    describe_bindings.describeResultFree(describeResult);

    return result;
  }

  /// Packs the objects in the odb chosen by the [packDelegate] function and
  /// writes .pack and .idx files for them into provided [path] or default location.
  ///
  /// Returns the number of objects written to the pack.
  ///
  /// [packDelegate] is a function that will provide what objects should be added to the
  /// pack builder. Default is add all objects.
  ///
  /// [threads] is number of threads the PackBuilder will spawn. Default is none. 0 will
  /// let libgit2 to autodetect number of CPUs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  int pack(
      {String? path, void Function(PackBuilder)? packDelegate, int? threads}) {
    void packAll(PackBuilder packbuilder) {
      for (var object in odb.objects) {
        packbuilder.add(object);
      }
    }

    final _packDelegate = packDelegate ?? packAll;

    final packbuilder = PackBuilder(this);
    if (threads != null) {
      packbuilder.setThreads(threads);
    }
    _packDelegate(packbuilder);
    packbuilder.write(path);
    final result = packbuilder.writtenLength;

    packbuilder.free();

    return result;
  }

  /// Returns a list with all tracked submodules paths of a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get submodules => Submodule.list(this);

  /// Lookups submodule by name or path.
  ///
  /// You must free submodule when done with it.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Submodule lookupSubmodule(String submodule) {
    return Submodule.lookup(repo: this, submodule: submodule);
  }

  /// Copies submodule info into ".git/config" file.
  ///
  /// Just like `git submodule init`, this copies information about the
  /// submodule into `.git/config`.
  ///
  /// By default, existing entries will not be overwritten, but setting [overwrite]
  /// to true forces them to be updated.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void initSubmodule({
    required String submodule,
    bool overwrite = false,
  }) {
    Submodule.init(repo: this, submodule: submodule, overwrite: overwrite);
  }

  /// Updates a submodule. This will clone a missing submodule and checkout the
  /// subrepository to the commit specified in the index of the containing repository.
  /// If the submodule repository doesn't contain the target commit (e.g. because
  /// fetchRecurseSubmodules isn't set), then the submodule is fetched using the fetch
  /// options supplied in [callbacks].
  ///
  /// If the submodule is not initialized, setting [init] to true will initialize the
  /// submodule before updating. Otherwise, this will return an error if attempting
  /// to update an uninitialzed repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void updateSubmodule({
    required String submodule,
    bool init = false,
    Callbacks callbacks = const Callbacks(),
  }) {
    Submodule.update(
      repo: this,
      submodule: submodule,
      init: init,
      callbacks: callbacks,
    );
  }

  /// Adds a submodule to the index.
  ///
  /// [url] is URL for the submodule's remote.
  ///
  /// [path] is path at which the submodule should be created.
  ///
  /// [link] determines if workdir should contain a gitlink to the repo in `.git/modules`
  /// vs. repo directly in workdir. Default is true.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Submodule addSubmodule({
    required String url,
    required String path,
    bool useGitlink = true,
    Callbacks callbacks = const Callbacks(),
  }) {
    return Submodule.add(
      repo: this,
      url: url,
      path: path,
      useGitlink: useGitlink,
      callbacks: callbacks,
    );
  }
}
