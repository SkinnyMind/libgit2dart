import 'dart:ffi';
import 'odb.dart';
import 'reference.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/repository.dart' as bindings;
import 'util.dart';

/// A Repository is the primary interface into a git repository
class Repository {
  /// Initializes a new instance of the [Repository] class.
  /// For a standard repository, [path] should either point to the `.git` folder
  /// or to the working directory. For a bare repository, [path] should directly
  /// point to the repository folder.
  ///
  /// [Repository] object should be close with [free] function to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.open(String path) {
    libgit2.git_libgit2_init();

    _repoPointer = bindings.open(path);
  }

  late final Pointer<git_repository> _repoPointer;

  /// Pointer to memory address for allocated repository object.
  Pointer<git_repository> get pointer => _repoPointer;

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

  /// Makes the repository HEAD point to the specified reference.
  ///
  /// If the provided [reference] points to a Tree or a Blob, the HEAD is unaltered.
  ///
  /// If the provided [reference] points to a branch, the HEAD will point to that branch,
  /// staying attached, or become attached if it isn't yet.
  ///
  /// If the branch doesn't exist yet, the HEAD will be attached to an unborn branch.
  ///
  /// Otherwise, the HEAD will be detached and will directly point to the Commit.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setHead(String reference) {
    bindings.setHead(_repoPointer, reference);
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
  // git_repository_state_t from libgit2_bindings.dart represents possible states
  int get state => bindings.state(_repoPointer);

  /// Removes all the metadata associated with an ongoing command like
  /// merge, revert, cherry-pick, etc. For example: MERGE_HEAD, MERGE_MSG, etc.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stateCleanup() => bindings.stateCleanup(_repoPointer);

  /// Returns the path of the working directory for this repository.
  ///
  /// If the repository is bare, this function will always return empty string.
  String get workdir => bindings.workdir(_repoPointer);

  /// Releases memory allocated for repository object.
  void free() {
    bindings.free(_repoPointer);
    libgit2.git_libgit2_shutdown();
  }

  /// Returns [Reference] object pointing to repository head.
  Reference get head => Reference(bindings.head(_repoPointer));

  /// Returns [Odb] for this repository.
  ///
  /// ODB Object must be freed once it's no longer being used.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Odb get odb => Odb(bindings.odb(_repoPointer));
}
