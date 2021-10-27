import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';

import 'package:libgit2dart/src/bindings/attr.dart' as attr_bindings;
import 'package:libgit2dart/src/bindings/checkout.dart' as checkout_bindings;
import 'package:libgit2dart/src/bindings/commit.dart' as commit_bindings;
import 'package:libgit2dart/src/bindings/describe.dart' as describe_bindings;
import 'package:libgit2dart/src/bindings/diff.dart' as diff_bindings;
import 'package:libgit2dart/src/bindings/graph.dart' as graph_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/merge.dart' as merge_bindings;
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;
import 'package:libgit2dart/src/bindings/repository.dart' as bindings;
import 'package:libgit2dart/src/bindings/reset.dart' as reset_bindings;
import 'package:libgit2dart/src/bindings/status.dart' as status_bindings;
import 'package:libgit2dart/src/util.dart';

class Repository {
  /// Initializes a new instance of the [Repository] class from provided
  /// pointer to repository object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Repository(this._repoPointer);

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
  /// **IMPORTANT**: Should be freed to release allocated memory.
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

    int flagsInt = flags.fold(0, (acc, e) => acc | e.value);

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

  /// Opens repository at provided [path].
  ///
  /// For a standard repository, [path] should either point to the ".git" folder
  /// or to the working directory. For a bare repository, [path] should directly
  /// point to the repository folder.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.open(String path) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.open(path);
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
  /// [remote] is the callback function with
  /// `Remote Function(Repository repo, String name, String url)` signature.
  /// The [Remote] it returns will be used instead of default one.
  ///
  /// [repository] is the callback function matching the
  /// `Repository Function(String path, bool bare)` signature. The [Repository]
  /// it returns will be used instead of creating a new one.
  ///
  /// [checkoutBranch] is the name of the branch to checkout after the clone.
  /// Defaults to using the remote's default branch.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
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
  Map<String, String> get identity => bindings.identity(_repoPointer);

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
    return GitRepositoryState.values.singleWhere(
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
  void free() => bindings.free(_repoPointer);

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
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Config get config => Config(bindings.config(_repoPointer));

  /// Snapshot of the repository's configuration.
  ///
  /// Convenience function to take a snapshot from the repository's
  /// configuration.
  ///
  /// The contents of this snapshot will not change, even if the underlying
  /// config files are modified.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Config get configSnapshot => Config(bindings.configSnapshot(_repoPointer));

  /// Repository's head.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Reference get head => Reference(bindings.head(_repoPointer));

  /// List of all the references names that can be found in a repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get references => Reference.list(this);

  /// Lookups reference [name] in a repository.
  ///
  /// The [name] will be checked for validity.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Reference lookupReference(String name) {
    return Reference.lookup(repo: this, name: name);
  }

  /// Creates a new reference for provided [target].
  ///
  /// The reference will be created in the repository and written to the disk.
  ///
  /// **IMPORTANT**: The generated [Reference] object should be freed to release
  /// allocated memory.
  ///
  /// Valid reference [name]s must follow one of two patterns:
  /// - Top-level names must contain only capital letters and underscores, and
  /// must begin and end with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// - Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// Throws a [LibGit2Error] if a reference already exists with the given
  /// [name] unless [force] is true, in which case it will be overwritten.
  ///
  /// The [logMessage] message for the reflog will be ignored if the reference
  /// does not belong in the standard set (HEAD, branches and remote-tracking
  /// branches) and it does not have a reflog.
  ///
  /// Throws a [LibGit2Error] if error occured or [ArgumentError] if provided
  /// [target] is not Oid or String reference name.
  Reference createReference({
    required String name,
    required Object target,
    bool force = false,
    String? logMessage,
  }) {
    return Reference.create(
      repo: this,
      name: name,
      target: target,
      force: force,
      logMessage: logMessage,
    );
  }

  /// Deletes an existing reference with provided [name].
  ///
  /// This method works for both direct and symbolic references.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteReference(String name) => Reference.delete(repo: this, name: name);

  /// Renames an existing reference with provided [oldName].
  ///
  /// This method works for both direct and symbolic references.
  ///
  /// The [newName] will be checked for validity.
  ///
  /// If the [force] flag is set to false, and there's already a reference with
  /// the given name, the renaming will fail.
  ///
  /// IMPORTANT: The user needs to write a proper reflog entry [logMessage] if
  /// the reflog is enabled for the repository. We only rename the reflog if it
  /// exists.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void renameReference({
    required String oldName,
    required String newName,
    bool force = false,
    String? logMessage,
  }) {
    Reference.rename(
      repo: this,
      oldName: oldName,
      newName: newName,
      force: force,
      logMessage: logMessage,
    );
  }

  /// Index file for this repository.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Index get index => Index(bindings.index(_repoPointer));

  /// ODB for this repository.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Odb get odb => Odb(bindings.odb(_repoPointer));

  /// Lookups a tree object for provided [oid].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Tree lookupTree(Oid oid) {
    return Tree.lookup(repo: this, oid: oid);
  }

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
  ///
  /// **IMPORTANT**: Commits should be freed to release allocated memory.
  List<Commit> log({
    required Oid oid,
    Set<GitSort> sorting = const {GitSort.none},
  }) {
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
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Commit revParseSingle(String spec) {
    return RevParse.single(repo: this, spec: spec);
  }

  /// Lookups commit object for provided [oid].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Commit lookupCommit(Oid oid) {
    return Commit.lookup(repo: this, oid: oid);
  }

  /// Creates new commit in the repository.
  ///
  /// [updateRef] is the name of the reference that will be updated to point to
  /// this commit. If the reference is not direct, it will be resolved to a
  /// direct reference. Use "HEAD" to update the HEAD of the current branch and
  /// make it point to this commit. If the reference doesn't exist yet, it will
  /// be created. If it does exist, the first parent
  /// must be the tip of this branch.
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
  /// for the commit.
  ///
  /// [parents] is a list of [Commit] objects that will be used as the parents
  /// for this commit. This list may be empty if parent count is 0 (root
  /// commit). All the given commits must be owned by the repo.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createCommit({
    required String message,
    required Signature author,
    required Signature commiter,
    required Tree tree,
    required List<Commit> parents,
    String? updateRef,
    String? messageEncoding,
  }) {
    return Commit.create(
      repo: this,
      message: message,
      author: author,
      committer: commiter,
      tree: tree,
      parents: parents,
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
  Oid amendCommit({
    required Commit commit,
    Signature? author,
    Signature? committer,
    Tree? tree,
    String? updateRef,
    String? message,
    String? messageEncoding,
  }) {
    return Commit.amend(
      repo: this,
      commit: commit,
      author: author,
      committer: committer,
      tree: tree,
      updateRef: updateRef,
      message: message,
      messageEncoding: messageEncoding,
    );
  }

  /// Reverts provided [revertCommit] against provided [ourCommit], producing
  /// an index that reflects the result of the revert.
  ///
  /// [mainline] is parent of the [revertCommit] if it is a merge (i.e. 1, 2).
  ///
  /// **IMPORTANT**: produced index should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index revertCommit({
    required Commit revertCommit,
    required Commit ourCommit,
    int mainline = 0,
  }) {
    return Index(
      commit_bindings.revertCommit(
        repoPointer: _repoPointer,
        revertCommitPointer: revertCommit.pointer,
        ourCommitPointer: ourCommit.pointer,
        mainline: mainline,
      ),
    );
  }

  /// Finds a single object and intermediate reference (if there is one) by a
  /// [spec] revision string.
  ///
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may
  /// point to an intermediate reference. When such expressions are being
  /// passed in, reference_out will be valued as well.
  ///
  /// **IMPORTANT**: the returned object and reference should be released when
  /// no longer needed.
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

  /// Lookups a blob object for provided [oid].
  ///
  /// Should be freed to release allocated memory.
  Blob lookupBlob(Oid oid) {
    return Blob.lookup(repo: this, oid: oid);
  }

  /// Creates a new blob from a [content] string and writes it to ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlob(String content) => Blob.create(repo: this, content: content);

  /// Creates a new blob from the file in working directory of a repository and
  /// writes it to the ODB. Provided [relativePath] should be relative to the
  /// working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromWorkdir(String relativePath) {
    return Blob.createFromWorkdir(
      repo: this,
      relativePath: relativePath,
    );
  }

  /// Creates a new blob from the file at provided [path] in filesystem and
  /// writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromDisk(String path) {
    return Blob.createFromDisk(repo: this, path: path);
  }

  /// List with all the tags names in the repository.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get tags => Tag.list(this);

  /// Lookups tag object for provided [oid].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Tag lookupTag(Oid oid) => Tag.lookup(repo: this, oid: oid);

  /// Creates a new tag in the repository for provided [target] object.
  ///
  /// A new reference will also be created pointing to this tag object. If
  /// [force] is true and a reference already exists with the given name, it'll
  /// be replaced.
  ///
  /// The [message] will not be cleaned up.
  ///
  /// The [tagName] will be checked for validity. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  ///
  /// [tagName] is the name for the tag. This name is validated for
  /// consistency. It should also not conflict with an already existing tag
  /// name.
  ///
  /// [target] is the object to which this tag points. This object must belong
  /// to the given [repo].
  ///
  /// [targetType] is one of the [GitObject] basic types: commit, tree, blob or
  /// tag.
  ///
  /// [tagger] is the signature of the tagger for this tag, and of the tagging
  /// time.
  ///
  /// [message] is the full message for this tag.
  ///
  /// [force] determines whether existing reference with the same [tagName]
  /// should be replaced.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createTag({
    required String tagName,
    required Oid target,
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
      force: force,
    );
  }

  /// Deletes an existing tag reference with provided [name].
  ///
  /// The tag [name] will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteTag(String name) => Tag.delete(repo: this, name: name);

  /// List of all branches that can be found in a repository.
  ///
  /// **IMPORTANT**: Branches should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branches => Branch.list(repo: this);

  /// List of local branches that can be found in a repository.
  ///
  /// **IMPORTANT**: Branches should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branchesLocal =>
      Branch.list(repo: this, type: GitBranch.local);

  /// List of remote branches that can be found in a repository.
  ///
  /// **IMPORTANT**: Branches should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Branch> get branchesRemote =>
      Branch.list(repo: this, type: GitBranch.remote);

  /// Lookups a branch by its [name] and [type] in a repository.
  ///
  /// The branch [name] will be checked for validity.
  ///
  /// If branch [type] is [GitBranch.remote] you must include the remote name
  /// in the [name] (e.g. "origin/master").
  ///
  /// **IMPORTANT**: Branches should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch lookupBranch({
    required String name,
    GitBranch type = GitBranch.local,
  }) {
    return Branch.lookup(repo: this, name: name, type: type);
  }

  /// Creates a new branch pointing at a [target] commit.
  ///
  /// A new direct reference will be created pointing to this target commit.
  /// If [force] is true and a reference already exists with the given name,
  /// it'll be replaced.
  ///
  /// [name] is the name for the branch, this name is validated for consistency.
  /// It should also not conflict with an already existing branch name.
  ///
  /// [target] is the commit to which this branch should point. This object must
  /// belong to the repo.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Branch createBranch({
    required String name,
    required Commit target,
    bool force = false,
  }) {
    return Branch.create(
      repo: this,
      name: name,
      target: target,
      force: force,
    );
  }

  /// Deletes an existing branch reference with provided [name].
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteBranch(String name) => Branch.delete(repo: this, name: name);

  /// Renames an existing local branch reference with provided [oldName].
  ///
  /// The new branch name [newName] will be checked for validity.
  ///
  /// If [force] is true, existing branch will be overwritten.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void renameBranch({
    required String oldName,
    required String newName,
    bool force = false,
  }) {
    Branch.rename(repo: this, oldName: oldName, newName: newName, force: force);
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

  /// Finds a merge base between two commits [a] and [b].
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid mergeBase({required Oid a, required Oid b}) {
    return Oid(
      merge_bindings.mergeBase(
        repoPointer: _repoPointer,
        aPointer: a.pointer,
        bPointer: b.pointer,
      ),
    );
  }

  /// Analyzes the given branch's [theirHead] oid and determines the
  /// opportunities for merging them into [ourRef] reference (default is
  /// 'HEAD').
  ///
  /// Returns list with analysis result and preference for fast forward merge
  /// values respectively.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List mergeAnalysis({
    required Oid theirHead,
    String ourRef = 'HEAD',
  }) {
    final ref = lookupReference(ourRef);
    final head = AnnotatedCommit.lookup(
      repo: this,
      oid: theirHead,
    );
    final analysisInt = merge_bindings.analysis(
      repoPointer: _repoPointer,
      ourRefPointer: ref.pointer,
      theirHeadPointer: head.pointer,
      theirHeadsLen: 1,
    );

    final analysisSet = GitMergeAnalysis.values
        .where((e) => analysisInt[0] & e.value == e.value)
        .toSet();
    final mergePreference = GitMergePreference.values.singleWhere(
      (e) => analysisInt[1] == e.value,
    );

    head.free();
    ref.free();

    return <Object>[analysisSet, mergePreference];
  }

  /// Merges the given commit [oid] into HEAD, writing the results into the
  /// working directory. Any changes are staged for commit and any conflicts
  /// are written to the index. Callers should inspect the repository's index
  /// after this completes, resolve any conflicts and prepare a commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void merge(Oid oid) {
    final theirHead = AnnotatedCommit.lookup(
      repo: this,
      oid: oid,
    );

    merge_bindings.merge(
      repoPointer: _repoPointer,
      theirHeadsPointer: theirHead.pointer,
      theirHeadsLen: 1,
    );

    theirHead.free();
  }

  /// Merges two files [ours] and [theirs] as they exist in the index, using the
  /// given common [ancestor] as the baseline, producing a string that reflects
  /// the merge result containing possible conflicts.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String mergeFileFromIndex({
    required IndexEntry? ancestor,
    required IndexEntry ours,
    required IndexEntry theirs,
  }) {
    return merge_bindings.mergeFileFromIndex(
      repoPointer: _repoPointer,
      ancestorPointer: ancestor?.pointer,
      oursPointer: ours.pointer,
      theirsPointer: theirs.pointer,
    );
  }

  /// Merges two commits, producing an index that reflects the result of the
  /// merge. The index may be written as-is to the working directory or checked
  /// out. If the index is to be converted to a tree, the caller should resolve
  /// any conflicts that arose as part of the merge.
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
  /// **IMPORTANT**: returned index should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index mergeCommits({
    required Commit ourCommit,
    required Commit theirCommit,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    Set<GitMergeFlag> mergeFlags = const {GitMergeFlag.findRenames},
    Set<GitMergeFileFlag> fileFlags = const {GitMergeFileFlag.defaults},
  }) {
    return Index(
      merge_bindings.mergeCommits(
        repoPointer: _repoPointer,
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
  /// [ancestorTree] is the common ancestor between the trees, or null if none.
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
  /// **IMPORTANT**: returned index should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Index mergeTrees({
    Tree? ancestorTree,
    required Tree ourTree,
    required Tree theirTree,
    GitMergeFileFavor favor = GitMergeFileFavor.normal,
    List<GitMergeFlag> mergeFlags = const [GitMergeFlag.findRenames],
    List<GitMergeFileFlag> fileFlags = const [GitMergeFileFlag.defaults],
  }) {
    return Index(
      merge_bindings.mergeTrees(
        repoPointer: _repoPointer,
        ancestorTreePointer: ancestorTree?.pointer ?? nullptr,
        ourTreePointer: ourTree.pointer,
        theirTreePointer: theirTree.pointer,
        favor: favor.value,
        mergeFlags: mergeFlags.fold(0, (acc, element) => acc | element.value),
        fileFlags: fileFlags.fold(0, (acc, element) => acc | element.value),
      ),
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
  void cherryPick(Commit commit) {
    merge_bindings.cherryPick(
      repoPointer: _repoPointer,
      commitPointer: commit.pointer,
    );
  }

  /// Checkouts the provided reference [refName] using the given strategy, and
  /// update the HEAD.
  ///
  /// If no reference [refName] is given, checkouts from the index.
  ///
  /// Default checkout strategy is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is alternative checkout path to workdir.
  ///
  /// [paths] is list of files to checkout from provided reference [refName].
  /// If paths are provided HEAD will not be set to the reference [refName].
  void checkout({
    String? refName,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    final int strat = strategy.fold(0, (acc, e) => acc | e.value);

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
      final ref = lookupReference(refName);
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
  /// Throws a [LibGit2Error] if error occured.
  void reset({required Oid oid, required GitReset resetType}) {
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

  /// Returns a [Diff] with changes between the trees, tree and index, tree and
  /// workdir or index and workdir.
  ///
  /// If [b] is null, by default the [a] tree compared to working directory. If
  /// [cached] is set to true the [a] tree compared to index/staging area.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
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
    final int flagsInt = flags.fold(0, (acc, e) => acc | e.value);

    if (a is Tree && b is Tree) {
      return Diff(
        diff_bindings.treeToTree(
          repoPointer: _repoPointer,
          oldTreePointer: a.pointer,
          newTreePointer: b.pointer,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        ),
      );
    } else if (a is Tree && b == null) {
      if (cached) {
        return Diff(
          diff_bindings.treeToIndex(
            repoPointer: _repoPointer,
            treePointer: a.pointer,
            indexPointer: index.pointer,
            flags: flagsInt,
            contextLines: contextLines,
            interhunkLines: interhunkLines,
          ),
        );
      } else {
        return Diff(
          diff_bindings.treeToWorkdir(
            repoPointer: _repoPointer,
            treePointer: a.pointer,
            flags: flagsInt,
            contextLines: contextLines,
            interhunkLines: interhunkLines,
          ),
        );
      }
    } else if (a == null && b == null) {
      return Diff(
        diff_bindings.indexToWorkdir(
          repoPointer: _repoPointer,
          indexPointer: index.pointer,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        ),
      );
    } else {
      throw ArgumentError.notNull('a');
    }
  }

  /// Returns a [Patch] with changes between the blobs.
  ///
  /// [a] is the blob for old side of diff.
  ///
  /// [b] is the blob for new side of diff.
  ///
  /// [aPath] treat [a] blob as if it had this filename, can be null.
  ///
  /// [bPath] treat [b] blob as if it had this filename, can be null.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
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

  /// Applies the [diff] to the repository, making changes in the provided
  /// [location] (directly in the working directory (default), the index or
  /// both).
  ///
  /// Throws a [LibGit2Error] if error occured.
  void apply({
    required Diff diff,
    GitApplyLocation location = GitApplyLocation.workdir,
  }) {
    diff_bindings.apply(
      repoPointer: _repoPointer,
      diffPointer: diff.pointer,
      location: location.value,
    );
  }

  /// Checks if the [diff] will apply to provided [location] (the working
  /// directory (default), the index or both).
  bool applies({
    required Diff diff,
    GitApplyLocation location = GitApplyLocation.workdir,
  }) {
    return diff_bindings.apply(
      repoPointer: _repoPointer,
      diffPointer: diff.pointer,
      location: location.value,
      check: true,
    );
  }

  /// Returns list of all the stashed states, first being the most recent.
  List<Stash> get stashes => Stash.list(this);

  /// Saves the local modifications to a new stash.
  ///
  /// [stasher] is the identity of the person performing the stashing.
  ///
  /// [message] is optional description along with the stashed state.
  ///
  /// [flags] is a combination of [GitStash] flags. Defaults to
  /// [GitStash.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createStash({
    required Signature stasher,
    String? message,
    Set<GitStash> flags = const {GitStash.defaults},
  }) {
    return Stash.create(
      repo: this,
      stasher: stasher,
      message: message,
      flags: flags,
    );
  }

  /// Applies a single stashed state from the stash list.
  ///
  /// [index] is the position of the stashed state in the list. Defaults to
  /// last saved.
  ///
  /// [reinstateIndex] whether to try to reinstate not only the working tree's
  /// changes, but also the index's changes.
  ///
  /// [strategy] is a combination of [GitCheckout] flags. Defaults to
  /// [GitCheckout.safe] with [GitCheckout.recreateMissing].
  ///
  /// [directory] is the alternative checkout path to workdir, can be null.
  ///
  /// [paths] is a list of wildmatch patterns or paths. By default, all paths
  /// are processed. If you pass a list of wildmatch patterns, those will be
  /// used to filter which paths should be taken into account.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void applyStash({
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    Stash.apply(
      repo: this,
      index: index,
      reinstateIndex: reinstateIndex,
      strategy: strategy,
      directory: directory,
      paths: paths,
    );
  }

  /// Removes a single stashed state from the stash list at provided [index].
  /// Defaults to the last saved stash.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void dropStash({int index = 0}) {
    Stash.drop(repo: this, index: index);
  }

  /// Applies a single stashed state from the stash list and remove it from
  /// the list if successful.
  ///
  /// [index] is the position of the stashed state in the list. Defaults to
  /// last saved.
  ///
  /// [reinstateIndex] whether to try to reinstate not only the working tree's
  /// changes, but also the index's changes.
  ///
  /// [strategy] is a combination of [GitCheckout] flags. Defaults to
  /// [GitCheckout.safe] with [GitCheckout.recreateMissing].
  ///
  /// [directory] is the alternative checkout path to workdir, can be null.
  ///
  /// [paths] is a list of wildmatch patterns or paths. By default, all paths
  /// are processed. If you pass a list of wildmatch patterns, those will be
  /// used to filter which paths should be taken into account.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void popStash({
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    Stash.pop(
      repo: this,
      index: index,
      reinstateIndex: reinstateIndex,
      strategy: strategy,
      directory: directory,
      paths: paths,
    );
  }

  /// List of the configured remotes names for a repository.
  List<String> get remotes => Remote.list(this);

  /// Lookups remote with provided [name].
  ///
  /// The [name] will be checked for validity.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote lookupRemote(String name) {
    return Remote.lookup(repo: this, name: name);
  }

  /// Adds remote with provided [name] and [url] to the repository's
  /// configuration with the default [fetch] refspec if none provided.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote createRemote({
    required String name,
    required String url,
    String? fetch,
  }) {
    return Remote.create(repo: this, name: name, url: url, fetch: fetch);
  }

  /// Deletes an existing persisted remote with provided [name].
  ///
  /// All remote-tracking branches and configuration settings for the remote
  /// will be removed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteRemote(String name) => Remote.delete(repo: this, name: name);

  /// Renames remote with provided [oldName].
  ///
  /// Returns list of non-default refspecs that cannot be renamed.
  ///
  /// All remote-tracking branches and configuration settings for the remote
  /// are updated.
  ///
  /// The [newName] will be checked for validity.
  ///
  /// No loaded instances of a the remote with the old name will change their
  /// name or their list of refspecs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> renameRemote({
    required String oldName,
    required String newName,
  }) {
    return Remote.rename(repo: this, oldName: oldName, newName: newName);
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

  /// Returns the blame for a single file.
  ///
  /// [path] is the path to file to consider.
  ///
  /// [flags] is a combination of [GitBlameFlag]s. Defaults to
  /// [GitBlameFlag.normal].
  ///
  /// [minMatchCharacters] is the lower bound on the number of alphanumeric
  /// characters that must be detected as moving/copying within a file for
  /// it to associate those lines with the parent commit. The default value is
  /// 20. This value only takes effect if any of the [GitBlameFlag.trackCopies*]
  /// flags are specified.
  ///
  /// [newestCommit] is the id of the newest commit to consider. The default is
  /// HEAD.
  ///
  /// [oldestCommit] is the id of the oldest commit to consider. The default is
  /// the first commit encountered with no parent.
  ///
  /// [minLine] is the first line in the file to blame. The default is 1
  /// (line numbers start with 1).
  ///
  /// [maxLine] is the last line in the file to blame. The default is the last
  /// line of the file.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
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

  /// List of notes for repository.
  ///
  /// **IMPORTANT**: Notes Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Note> get notes => Note.list(this);

  /// Lookups the note for an [annotatedOid].
  ///
  /// [annotatedOid] is the [Oid] of the git object to read the note from.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Note lookupNote({
    required Oid annotatedOid,
    String notesRef = 'refs/notes/commits',
  }) {
    return Note.lookup(
      repo: this,
      annotatedOid: annotatedOid,
      notesRef: notesRef,
    );
  }

  /// Creates a note for an [annotatedOid].
  ///
  /// [author] is the signature of the note's commit author.
  ///
  /// [committer] is the signature of the note's commit committer.
  ///
  /// [annotatedOid] is the [Oid] of the git object to decorate.
  ///
  /// [note] is the content of the note to add.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
  ///
  /// [force] determines whether existing note should be overwritten.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createNote({
    required Signature author,
    required Signature committer,
    required Oid annotatedOid,
    required String note,
    String notesRef = 'refs/notes/commits',
    bool force = false,
  }) {
    return Note.create(
      repo: this,
      author: author,
      committer: committer,
      annotatedOid: annotatedOid,
      note: note,
      notesRef: notesRef,
      force: force,
    );
  }

  /// Deletes the note for an [annotatedOid].
  ///
  /// [annotatedOid] is the [Oid] of the git object to remove the note from.
  ///
  /// [author] is the signature of the note's commit author.
  ///
  /// [committer] is the signature of the note's commit committer.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
  ///
  /// Throws a [LibGit2Error] if error occured.
  void deleteNote({
    required Oid annotatedOid,
    required Signature author,
    required Signature committer,
    String notesRef = 'refs/notes/commits',
  }) {
    Note.delete(
      repo: this,
      annotatedOid: annotatedOid,
      author: author,
      committer: committer,
      notesRef: notesRef,
    );
  }

  /// Checks if a provided [commit] is the descendant of another [ancestor]
  /// commit.
  ///
  /// Note that a commit is not considered a descendant of itself, in contrast
  /// to `git merge-base --is-ancestor`.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool descendantOf({required Oid commit, required Oid ancestor}) {
    return graph_bindings.descendantOf(
      repoPointer: _repoPointer,
      commitPointer: commit.pointer,
      ancestorPointer: ancestor.pointer,
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

    describe_bindings.describeResultFree(describeResult);

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

  /// List with all tracked submodules paths of a repository.
  List<String> get submodules => Submodule.list(this);

  /// Lookups submodule information by [name] or path (they are usually the
  /// same).
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Submodule lookupSubmodule(String name) {
    return Submodule.lookup(repo: this, name: name);
  }

  /// Copies submodule info into ".git/config" file.
  ///
  /// Just like `git submodule init`, this copies information about the
  /// submodule into ".git/config".
  ///
  /// By default, existing entries will not be overwritten, but setting
  /// [overwrite] to true forces them to be updated.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void initSubmodule({
    required String submodule,
    bool overwrite = false,
  }) {
    Submodule.init(repo: this, submodule: submodule, overwrite: overwrite);
  }

  /// Updates a submodule. This will clone a missing submodule and checkout the
  /// subrepository to the commit specified in the index of the containing
  /// repository. If the submodule repository doesn't contain the target commit
  /// (e.g. because fetchRecurseSubmodules isn't set), then the submodule is
  /// fetched using the fetch options supplied in [callbacks].
  ///
  /// If the submodule is not initialized, setting [init] to true will
  /// initialize the submodule before updating. Otherwise, this will return an
  /// error if attempting to update an uninitialzed repository.
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
  /// [url] is the URL for the submodule's remote.
  ///
  /// [path] is the path at which the submodule should be created.
  ///
  /// [useGitLink] determines if workdir should contain a gitlink to the repo in `.git/modules`
  /// vs. repo directly in workdir. Default is true.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
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

  /// List of linked working trees names.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get worktrees => Worktree.list(this);

  /// Lookups existing worktree with provided [name].
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree lookupWorktree(String name) {
    return Worktree.lookup(repo: this, name: name);
  }

  /// Creates new worktree.
  ///
  /// If [ref] is provided, no new branch will be created but specified [ref]
  /// will be used instead.
  ///
  /// [name] is the name of the working tree.
  ///
  /// [path] is the path to create working tree at.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Worktree createWorktree({
    required String name,
    required String path,
    Reference? ref,
  }) {
    return Worktree.create(repo: this, name: name, path: path, ref: ref);
  }
}
