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
import 'branch.dart';
import 'commit.dart';
import 'config.dart';
import 'index.dart';
import 'odb.dart';
import 'oid.dart';
import 'reference.dart';
import 'revwalk.dart';
import 'revparse.dart';
import 'blob.dart';
import 'git_types.dart';
import 'signature.dart';
import 'tag.dart';
import 'tree.dart';
import 'util.dart';

class Repository {
  /// Initializes a new instance of the [Repository] class from provided
  /// pointer to repository object in memory.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Repository(this._repoPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of the [Repository] class by creating a new
  /// Git repository in the given folder.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.init(String path, {bool isBare = false}) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.init(path, isBare);
  }

  /// Initializes a new instance of the [Repository] class.
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
  static String discover(String startPath, [String ceilingDirs = '']) {
    return bindings.discover(startPath, ceilingDirs);
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
    bindings.setNamespace(_repoPointer, namespace);
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
      oid = Oid.fromSHA(this, target);
      bindings.setHeadDetached(_repoPointer, oid.pointer);
    } else {
      bindings.setHead(_repoPointer, target);
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
    bindings.setIdentity(_repoPointer, name, email);
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
        .singleWhere((flag) => stateInt == flag.value);
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
  void setWorkdir(String path, [bool updateGitlink = false]) {
    bindings.setWorkdir(_repoPointer, path, updateGitlink);
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
  Reference get head => Reference(_repoPointer, bindings.head(_repoPointer));

  /// Returns [References] object.
  References get references => References(this);

  /// Creates a new reference.
  ///
  /// The reference will be created in the repository and written to the disk.
  /// The generated [Reference] object must be freed by the user.
  ///
  /// Valid reference names must follow one of two patterns:
  ///
  /// Top-level names must contain only capital letters and underscores, and must begin and end
  /// with a letter. (e.g. "HEAD", "ORIG_HEAD").
  /// Names prefixed with "refs/" can be almost anything. You must avoid the characters
  /// '~', '^', ':', '\', '?', '[', and '*', and the sequences ".." and "@{" which have
  /// special meaning to revparse.
  /// Throws a [LibGit2Error] if a reference already exists with the given name
  /// unless force is true, in which case it will be overwritten.
  ///
  /// The message for the reflog will be ignored if the reference does not belong in the
  /// standard set (HEAD, branches and remote-tracking branches) and it does not have a reflog.
  Reference createReference({
    required String name,
    required Object target,
    bool force = false,
    String? logMessage,
  }) {
    late final Oid oid;
    late final bool isDirect;

    if (target is Oid) {
      oid = target;
      isDirect = true;
    } else if (isValidShaHex(target as String)) {
      oid = Oid.fromSHA(this, target);
      isDirect = true;
    } else {
      isDirect = false;
    }

    if (isDirect) {
      return Reference.createDirect(
        repo: this,
        name: name,
        oid: oid.pointer,
        force: force,
        logMessage: logMessage,
      );
    } else {
      return Reference.createSymbolic(
        repo: this,
        name: name,
        target: target as String,
        force: force,
        logMessage: logMessage,
      );
    }
  }

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
    final oid = Oid.fromSHA(this, sha);
    final object = object_bindings.lookup(
      _repoPointer,
      oid.pointer,
      GitObject.any.value,
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

  /// Returns the list of commits starting from provided [sha] hex string.
  ///
  /// If [sorting] isn't provided default will be used (reverse chronological order, like in git).
  List<Commit> log(String sha, [Set<GitSort> sorting = const {GitSort.none}]) {
    final oid = Oid.fromSHA(this, sha);
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
  Commit revParseSingle(String spec) => RevParse.single(this, spec);

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
  RevParse revParseExt(String spec) => RevParse.ext(this, spec);

  /// Parses a revision string for from, to, and intent.
  ///
  /// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RevSpec revParse(String spec) => RevParse.range(this, spec);

  /// Creates a new blob from a [content] string and writes it to ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlob(String content) => Blob.create(this, content);

  /// Creates a new blob from the file in working directory of a repository and writes
  /// it to the ODB. Provided [path] should be relative to the working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromWorkdir(String relativePath) =>
      Blob.createFromWorkdir(this, relativePath);

  /// Creates a new blob from the file in filesystem and writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid createBlobFromDisk(String path) => Blob.createFromDisk(this, path);

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
        repository: this,
        tagName: tagName,
        target: target,
        targetType: targetType,
        tagger: tagger,
        message: message,
        force: force);
  }

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
      final entry = status_bindings.getByIndex(list, i);
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
      for (var flag in GitStatus.values.skip(1)) {
        if (entry.ref.status & flag.value == flag.value) {
          statuses.add(flag);
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
    final statusInt = status_bindings.file(_repoPointer, path);
    var statuses = <GitStatus>{};

    if (statusInt == GitStatus.current.value) {
      statuses.add(GitStatus.current);
    } else {
      // Skipping GitStatus.current because `&` on `0` value falsly adds it to the set of flags
      for (var flag in GitStatus.values.skip(1)) {
        if (statusInt & flag.value == flag.value) {
          statuses.add(flag);
        }
      }
    }

    return statuses;
  }

  /// Finds a merge base between two commits.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid mergeBase(String one, String two) {
    final oidOne = Oid.fromSHA(this, one);
    final oidTwo = Oid.fromSHA(this, two);
    return Oid(merge_bindings.mergeBase(
      _repoPointer,
      oidOne.pointer,
      oidTwo.pointer,
    ));
  }

  /// Analyzes the given branch(es) and determines the opportunities for merging them
  /// into a reference (default is 'HEAD').
  ///
  /// Returns list with analysis result and preference for fast forward merge values
  /// respectively.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Set<dynamic>> mergeAnalysis(Oid theirHead, [String ourRef = 'HEAD']) {
    final ref = references[ourRef];
    final head = commit_bindings.annotatedLookup(
      _repoPointer,
      theirHead.pointer,
    );

    var result = <Set<dynamic>>[];
    var analysisSet = <GitMergeAnalysis>{};
    final analysisInt = merge_bindings.analysis(
      _repoPointer,
      ref.pointer,
      head,
      1,
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
      _repoPointer,
      oid.pointer,
    );

    merge_bindings.merge(_repoPointer, theirHead, 1);

    commit_bindings.annotatedFree(theirHead.value);
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
      _repoPointer,
      ourCommit.pointer,
      theirCommit.pointer,
      opts,
    );

    return Index(result);
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
      _repoPointer,
      ancestorTree.pointer,
      ourTree.pointer,
      theirTree.pointer,
      opts,
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
  void cherryPick(Commit commit) =>
      merge_bindings.cherryPick(_repoPointer, commit.pointer);

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
    String refName = '',
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    final int strat =
        strategy.fold(0, (previousValue, e) => previousValue | e.value);

    if (refName.isEmpty) {
      checkout_bindings.index(_repoPointer, strat, directory, paths);
    } else if (refName == 'HEAD') {
      checkout_bindings.head(_repoPointer, strat, directory, paths);
    } else {
      final ref = references[refName];
      final treeish = object_bindings.lookup(
          _repoPointer, ref.target.pointer, GitObject.any.value);
      checkout_bindings.tree(_repoPointer, treeish, strat, directory, paths);
      if (paths == null) {
        setHead(refName);
      }

      object_bindings.free(treeish);
      ref.free();
    }
  }
}
