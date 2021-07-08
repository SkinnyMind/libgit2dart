import 'dart:ffi';
import 'package:ffi/ffi.dart';
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
  /// [Repository] object should be close with [close] function to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Repository.open(String path) {
    libgit2.git_libgit2_init();

    try {
      _repoPointer = bindings.open(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Returns path to the `.git` folder for normal repositories
  /// or path to the repository itself for bare repositories.
  String path() => bindings.path(_repoPointer);

  /// Returns the path of the shared common directory for this repository.
  ///
  /// If the repository is bare, it is the root directory for the repository.
  /// If the repository is a worktree, it is the parent repo's `.git` folder.
  /// Otherwise, it is the `.git` folder.
  String commonDir() => bindings.commonDir(_repoPointer);

  /// Returns the currently active namespace for this repository.
  ///
  /// If there is no namespace, or the namespace is not a valid utf8 string,
  /// empty string is returned.
  String getNamespace() => bindings.getNamespace(_repoPointer);

  /// Checks whether this repository is a bare repository or not.
  bool isBare() => bindings.isBare(_repoPointer);

  /// Check if a repository is empty.
  ///
  /// An empty repository has just been initialized and contains no references
  /// apart from HEAD, which must be pointing to the unborn master branch.
  ///
  /// Throws a [LibGit2Error] if repository is corrupted.
  bool isEmpty() => bindings.isEmpty(_repoPointer);

  /// Checks if a repository's HEAD is detached.
  ///
  /// A repository's HEAD is detached when it points directly to a commit instead of a branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool isHeadDetached() {
    try {
      return bindings.isHeadDetached(_repoPointer);
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if the current branch is unborn.
  ///
  /// An unborn branch is one named from HEAD but which doesn't exist in the refs namespace,
  /// because it doesn't have any commit to point to.
  ///
  /// Throws a [LibGit2Error] if error occured.
  bool isBranchUnborn() {
    try {
      return bindings.isBranchUnborn(_repoPointer);
    } catch (e) {
      rethrow;
    }
  }

  /// Sets the identity to be used for writing reflogs.
  ///
  /// If both are set, this name and email will be used to write to the reflog.
  /// Pass NULL to unset. When unset, the identity will be taken from the repository's configuration.
  void setIdentity({required String? name, required String? email}) {
    bindings.setIdentity(_repoPointer, name, email);
  }

  /// Returns the configured identity to use for reflogs.
  Map<String, String> identity() => bindings.identity(_repoPointer);

  /// Checks if the repository was a shallow clone.
  bool isShallow() => bindings.isShallow(_repoPointer);

  /// Checks if a repository is a linked work tree.
  bool isWorktree() => bindings.isWorktree(_repoPointer);

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
  String message() {
    try {
      return bindings.message(_repoPointer);
    } catch (e) {
      rethrow;
    }
  }

  /// Removes git's prepared message.
  void removeMessage() => bindings.removeMessage(_repoPointer);

  /// Returns the status of a git repository - ie, whether an operation
  /// (merge, cherry-pick, etc) is in progress.
  // git_repository_state_t from libgit2_bindings.dart represents possible states
  int state() => bindings.state(_repoPointer);

  /// Removes all the metadata associated with an ongoing command like
  /// merge, revert, cherry-pick, etc. For example: MERGE_HEAD, MERGE_MSG, etc.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void stateCleanup() {
    try {
      bindings.stateCleanup(_repoPointer);
    } catch (e) {
      rethrow;
    }
  }

  /// Returns the path of the working directory for this repository.
  ///
  /// If the repository is bare, this function will always return empty string.
  String workdir() => bindings.workdir(_repoPointer);

  /// Releases memory allocated for repository object.
  void close() {
    calloc.free(_repoPointer);
    libgit2.git_libgit2_shutdown();
  }
}
