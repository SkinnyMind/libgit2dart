import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/remote_callbacks.dart';
import 'package:libgit2dart/src/callbacks.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/remote.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/util.dart';

/// Attempt to open an already-existing repository at [path]. The returned
/// repository must be freed with [free].
///
/// The [path] can point to either a normal or bare repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> open(String path) {
  final out = calloc<Pointer<git_repository>>();
  final pathC = path.toChar();
  final error = libgit2.git_repository_open(out, pathC);

  final result = out.value;

  calloc.free(out);
  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Look for a git repository and return its path. The lookup start from
/// [startPath] and walk across parent directories if nothing has been found.
/// The lookup ends when the first repository is found, or when reaching a
/// directory referenced in [ceilingDirs].
///
/// The method will automatically detect if the repository is bare (if there is
/// a repository).
String discover({
  required String startPath,
  String? ceilingDirs,
}) {
  final out = calloc<git_buf>();
  final startPathC = startPath.toChar();
  final ceilingDirsC = ceilingDirs?.toChar() ?? nullptr;

  libgit2.git_repository_discover(out, startPathC, 0, ceilingDirsC);

  calloc.free(startPathC);
  calloc.free(ceilingDirsC);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  return result;
}

/// Creates a new Git repository in the given folder. The returned repository
/// must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> init({
  required String path,
  required int flags,
  required int mode,
  String? workdirPath,
  String? description,
  String? templatePath,
  String? initialHead,
  String? originUrl,
}) {
  final out = calloc<Pointer<git_repository>>();
  final pathC = path.toChar();
  final workdirPathC = workdirPath?.toChar() ?? nullptr;
  final descriptionC = description?.toChar() ?? nullptr;
  final templatePathC = templatePath?.toChar() ?? nullptr;
  final initialHeadC = initialHead?.toChar() ?? nullptr;
  final originUrlC = originUrl?.toChar() ?? nullptr;
  final opts = calloc<git_repository_init_options>();
  libgit2.git_repository_init_options_init(
    opts,
    GIT_REPOSITORY_INIT_OPTIONS_VERSION,
  );

  opts.ref.flags = flags;
  opts.ref.mode = mode;
  opts.ref.workdir_path = workdirPathC;
  opts.ref.description = descriptionC;
  opts.ref.template_path = templatePathC;
  opts.ref.initial_head = initialHeadC;
  opts.ref.origin_url = originUrlC;

  final error = libgit2.git_repository_init_ext(out, pathC, opts);

  final result = out.value;

  calloc.free(out);
  calloc.free(pathC);
  calloc.free(workdirPathC);
  calloc.free(descriptionC);
  calloc.free(templatePathC);
  calloc.free(initialHeadC);
  calloc.free(originUrlC);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Clone a remote repository. The returned repository must be freed with
/// [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> clone({
  required String url,
  required String localPath,
  required bool bare,
  RemoteCallback? remoteCallback,
  RepositoryCallback? repositoryCallback,
  String? checkoutBranch,
  required Callbacks callbacks,
}) {
  final out = calloc<Pointer<git_repository>>();
  final urlC = url.toChar();
  final localPathC = localPath.toChar();
  final checkoutBranchC = checkoutBranch?.toChar() ?? nullptr;

  final cloneOptions = calloc<git_clone_options>();
  libgit2.git_clone_options_init(cloneOptions, GIT_CLONE_OPTIONS_VERSION);

  final fetchOptions = calloc<git_fetch_options>();
  libgit2.git_fetch_options_init(fetchOptions, GIT_FETCH_OPTIONS_VERSION);

  RemoteCallbacks.plug(
    callbacksOptions: fetchOptions.ref.callbacks,
    callbacks: callbacks,
  );

  const except = -1;

  git_remote_create_cb remoteCb = nullptr;
  if (remoteCallback != null) {
    RemoteCallbacks.remoteCbData = remoteCallback;
    remoteCb = Pointer.fromFunction(RemoteCallbacks.remoteCb, except);
  }

  git_repository_create_cb repositoryCb = nullptr;
  if (repositoryCallback != null) {
    RemoteCallbacks.repositoryCbData = repositoryCallback;
    repositoryCb = Pointer.fromFunction(RemoteCallbacks.repositoryCb, except);
  }

  cloneOptions.ref.bare = bare ? 1 : 0;
  cloneOptions.ref.remote_cb = remoteCb;
  cloneOptions.ref.checkout_branch = checkoutBranchC;
  cloneOptions.ref.repository_cb = repositoryCb;
  cloneOptions.ref.fetch_opts = fetchOptions.ref;

  final error = libgit2.git_clone(out, urlC, localPathC, cloneOptions);

  final result = out.value;

  calloc.free(out);
  calloc.free(urlC);
  calloc.free(localPathC);
  calloc.free(checkoutBranchC);
  calloc.free(cloneOptions);
  calloc.free(fetchOptions);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Returns the path to the `.git` folder for normal repositories or the
/// repository itself for bare repositories.
String path(Pointer<git_repository> repo) {
  return libgit2.git_repository_path(repo).toDartString();
}

/// Get the path of the shared common directory for this repository.
///
/// If the repository is bare, it is the root directory for the repository.
/// If the repository is a worktree, it is the parent repo's `.git` folder.
/// Otherwise, it is the `.git` folder.
String commonDir(Pointer<git_repository> repo) {
  return libgit2.git_repository_commondir(repo).toDartString();
}

/// Get the currently active namespace for this repository.
///
/// If there is no namespace, or the namespace is not a valid utf8 string,
/// empty string is returned.
String getNamespace(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_get_namespace(repo);
  return result == nullptr ? '' : result.toDartString();
}

/// Sets the active namespace for this repository.
///
/// This namespace affects all reference operations for the repo. See
/// `man gitnamespaces`.
///
/// The [namespace] should not include the refs folder, e.g. to namespace all
/// references under refs/namespaces/foo/, use foo as the namespace.
void setNamespace({
  required Pointer<git_repository> repoPointer,
  String? namespace,
}) {
  final namespaceC = namespace?.toChar() ?? nullptr;
  libgit2.git_repository_set_namespace(repoPointer, namespaceC);
  calloc.free(namespaceC);
}

/// Check if a repository is bare or not.
bool isBare(Pointer<git_repository> repo) {
  return libgit2.git_repository_is_bare(repo) == 1 || false;
}

/// Check if a repository is empty.
///
/// An empty repository has just been initialized and contains no references
/// apart from HEAD, which must be pointing to the unborn master branch.
///
/// Throws a [LibGit2Error] if repository is corrupted.
bool isEmpty(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_is_empty(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 || false;
  }
}

/// Retrieve and resolve the reference pointed at by HEAD. The returned
/// reference must be freed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> head(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_reference>>();
  final error = libgit2.git_repository_head(out, repo);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Check if a repository's HEAD is detached.
///
/// A repository's HEAD is detached when it points directly to a commit instead
/// of a branch.
///
/// Throws a [LibGit2Error] if error occured.
bool isHeadDetached(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_head_detached(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 || false;
  }
}

/// Check if the current branch is unborn.
///
/// An unborn branch is one named from HEAD but which doesn't exist in the refs
/// namespace, because it doesn't have any commit to point to.
///
/// Throws a [LibGit2Error] if error occured.
bool isBranchUnborn(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_head_unborn(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 || false;
  }
}

/// Set the identity to be used for writing reflogs.
///
/// If both are set, this name and email will be used to write to the reflog.
/// Pass NULL to unset. When unset, the identity will be taken from the
/// repository's configuration.
void setIdentity({
  required Pointer<git_repository> repoPointer,
  String? name,
  String? email,
}) {
  final nameC = name?.toChar() ?? nullptr;
  final emailC = email?.toChar() ?? nullptr;

  libgit2.git_repository_set_ident(repoPointer, nameC, emailC);

  calloc.free(nameC);
  calloc.free(emailC);
}

/// Retrieve the configured identity to use for reflogs.
///
/// Returns list with name and email respectively.
List<String> identity(Pointer<git_repository> repo) {
  final name = calloc<Pointer<Char>>();
  final email = calloc<Pointer<Char>>();
  libgit2.git_repository_ident(name, email, repo);
  final identity = <String>[];

  if (name.value == nullptr && email.value == nullptr) {
    return identity;
  } else {
    identity.add(name.value.toDartString());
    identity.add(email.value.toDartString());
  }

  calloc.free(name);
  calloc.free(email);

  return identity;
}

/// Get the configuration file for this repository. The returned config must be
/// freed.
///
/// If a configuration file has not been set, the default config set for the
/// repository will be returned, including global and system configurations (if
/// they are available).
Pointer<git_config> config(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_config>>();
  libgit2.git_repository_config(out, repo);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Get a snapshot of the repository's configuration. The returned config must
/// be freed.
///
/// Convenience function to take a snapshot from the repository's configuration.
/// The contents of this snapshot will not change, even if the underlying
/// config files are modified.
Pointer<git_config> configSnapshot(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_config>>();
  libgit2.git_repository_config_snapshot(out, repo);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Get the Index file for this repository. The returned index must be freed.
///
/// If a custom index has not been set, the default index for the repository
/// will be returned (the one located in `.git/index`).
Pointer<git_index> index(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_index>>();
  libgit2.git_repository_index(out, repo);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Determine if the repository was a shallow clone.
bool isShallow(Pointer<git_repository> repo) {
  return libgit2.git_repository_is_shallow(repo) == 1 || false;
}

/// Check if a repository is a linked work tree.
bool isWorktree(Pointer<git_repository> repo) {
  return libgit2.git_repository_is_worktree(repo) == 1 || false;
}

/// Retrieve git's prepared message.
///
/// Operations such as git revert/cherry-pick/merge with the -n option
/// stop just short of creating a commit with the changes and save their
/// prepared message in .git/MERGE_MSG so the next git-commit execution
/// can present it to the user for them to amend if they wish.
///
/// Use this function to get the contents of this file.
/// Don't forget to remove the file with [removeMessage] after you create the
/// commit.
///
/// Throws a [LibGit2Error] if error occured.
String message(Pointer<git_repository> repo) {
  final out = calloc<git_buf>();
  final error = libgit2.git_repository_message(out, repo);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Remove git's prepared message.
void removeMessage(Pointer<git_repository> repo) {
  libgit2.git_repository_message_remove(repo);
}

/// Get the Object Database for this repository. The returned odb must be freed.
///
/// If a custom ODB has not been set, the default database for the repository
/// will be returned (the one located in `.git/objects`).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb> odb(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_odb>>();
  final error = libgit2.git_repository_odb(out, repo);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the Reference Database Backend for this repository. The returned refdb
/// must be freed.
///
/// If a custom refsdb has not been set, the default database for the repository
/// will be returned (the one that manipulates loose and packed references in
/// the `.git` directory).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_refdb> refdb(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_refdb>>();
  final error = libgit2.git_repository_refdb(out, repo);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Make the repository HEAD point to the specified reference.
///
/// If the provided reference points to a Tree or a Blob, the HEAD is unaltered.
///
/// If the provided reference points to a branch, the HEAD will point to that
/// branch, staying attached, or become attached if it isn't yet.
///
/// If the branch doesn't exist yet, the HEAD will be attached to an unborn
/// branch.
///
/// Otherwise, the HEAD will be detached and will directly point to the Commit.
///
/// Throws a [LibGit2Error] if error occured.
void setHead({
  required Pointer<git_repository> repoPointer,
  required String refname,
}) {
  final refnameC = refname.toChar();
  final error = libgit2.git_repository_set_head(repoPointer, refnameC);

  calloc.free(refnameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Make the repository HEAD directly point to the commit.
///
/// If the provided committish cannot be found in the repository, the HEAD is
/// unaltered.
///
/// If the provided commitish cannot be peeled into a commit, the HEAD is
/// unaltered.
///
/// Otherwise, the HEAD will eventually be detached and will directly point to
/// the peeled commit.
///
/// Throws a [LibGit2Error] if error occured.
void setHeadDetached({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> commitishPointer,
}) {
  final error = libgit2.git_repository_set_head_detached(
    repoPointer,
    commitishPointer,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the path to the working directory for this repository.
///
/// The working directory doesn't need to be the same one that contains the
/// `.git` folder for this repository.
///
/// If this repository is bare, setting its working directory will turn it into
/// a normal repository, capable of performing all the common workdir operations
/// (checkout, status, index manipulation, etc).
///
/// Throws a [LibGit2Error] if error occured.
void setWorkdir({
  required Pointer<git_repository> repoPointer,
  required String path,
  required bool updateGitlink,
}) {
  final workdirC = path.toChar();
  final updateGitlinkC = updateGitlink ? 1 : 0;
  final error = libgit2.git_repository_set_workdir(
    repoPointer,
    workdirC,
    updateGitlinkC,
  );

  calloc.free(workdirC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Determines the status of a git repository - ie, whether an operation
/// (merge, cherry-pick, etc) is in progress.
int state(Pointer<git_repository> repo) => libgit2.git_repository_state(repo);

/// Remove all the metadata associated with an ongoing command like
/// merge, revert, cherry-pick, etc. For example: MERGE_HEAD, MERGE_MSG, etc.
///
/// Throws a [LibGit2Error] if error occured.
void stateCleanup(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_state_cleanup(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the path of the working directory for this repository.
///
/// If the repository is bare, this function will always return empty string.
String workdir(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_workdir(repo);
  return result == nullptr ? '' : result.toDartString();
}

/// Free a previously allocated repository.
void free(Pointer<git_repository> repo) => libgit2.git_repository_free(repo);
