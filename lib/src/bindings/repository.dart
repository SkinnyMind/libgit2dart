import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Attempt to open an already-existing repository at [path].
///
/// The [path] can point to either a normal or bare repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> open(String path) {
  final out = calloc<Pointer<git_repository>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_repository_open(out, pathC);
  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out.value;
}

/// Attempt to open an already-existing bare repository at [bare_path].
///
/// The [bare_path] can point to only a bare repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> openBare(String barePath) {
  final out = calloc<Pointer<git_repository>>();
  final barePathC = barePath.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_repository_open_bare(out, barePathC);
  calloc.free(barePathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out.value;
}

/// Look for a git repository and return its path. The lookup start from [startPath]
/// and walk across parent directories if nothing has been found. The lookup ends when
/// the first repository is found, or when reaching a directory referenced in [ceilingDirs].
///
/// The method will automatically detect if the repository is bare (if there is a repository).
///
/// Throws a [LibGit2Error] if error occured.
String discover(String startPath, String ceilingDirs) {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final startPathC = startPath.toNativeUtf8().cast<Int8>();
  final ceilingDirsC = ceilingDirs.toNativeUtf8().cast<Int8>();
  final error =
      libgit2.git_repository_discover(out, startPathC, 0, ceilingDirsC);
  var result = '';

  if (error == git_error_code.GIT_ENOTFOUND) {
    return result;
  } else if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  result = out.ref.ptr.cast<Utf8>().toDartString();
  calloc.free(out);
  calloc.free(startPathC);
  calloc.free(ceilingDirsC);

  return result;
}

/// Creates a new Git repository in the given folder.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> init(String path, bool isBare) {
  final out = calloc<Pointer<git_repository>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final isBareC = isBare ? 1 : 0;
  final error = libgit2.git_repository_init(out, pathC, isBareC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out.value;
}

/// Returns the path to the `.git` folder for normal repositories or the
/// repository itself for bare repositories.
String path(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_path(repo);
  return result.cast<Utf8>().toDartString();
}

/// Get the path of the shared common directory for this repository.
///
/// If the repository is bare, it is the root directory for the repository.
/// If the repository is a worktree, it is the parent repo's `.git` folder.
/// Otherwise, it is the `.git` folder.
String commonDir(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_commondir(repo);
  return result.cast<Utf8>().toDartString();
}

/// Get the currently active namespace for this repository.
///
/// If there is no namespace, or the namespace is not a valid utf8 string,
/// empty string is returned.
String getNamespace(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_get_namespace(repo);
  if (result == nullptr) {
    return '';
  } else {
    return result.cast<Utf8>().toDartString();
  }
}

/// Sets the active namespace for this repository.
///
/// This namespace affects all reference operations for the repo. See `man gitnamespaces`
///
/// The [namespace] should not include the refs folder, e.g. to namespace all references
/// under refs/namespaces/foo/, use foo as the namespace.
///
/// Throws a [LibGit2Error] if error occured.
void setNamespace(Pointer<git_repository> repo, String? namespace) {
  final nmspace = namespace?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_repository_set_namespace(repo, nmspace);
  calloc.free(nmspace);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Check if a repository is bare or not.
bool isBare(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_is_bare(repo);
  return result == 1 ? true : false;
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
    return error == 1 ? true : false;
  }
}

/// Retrieve and resolve the reference pointed at by HEAD.
///
/// The returned `git_reference` will be owned by caller and must be freed
/// to release the allocated memory and prevent a leak.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> head(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_reference>>();
  final error = libgit2.git_repository_head(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Check if a repository's HEAD is detached.
///
/// A repository's HEAD is detached when it points directly to a commit instead of a branch.
///
/// Throws a [LibGit2Error] if error occured.
bool isHeadDetached(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_head_detached(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 ? true : false;
  }
}

/// Check if the current branch is unborn.
///
/// An unborn branch is one named from HEAD but which doesn't exist in the refs namespace,
/// because it doesn't have any commit to point to.
///
/// Throws a [LibGit2Error] if error occured.
bool isBranchUnborn(Pointer<git_repository> repo) {
  final error = libgit2.git_repository_head_unborn(repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return error == 1 ? true : false;
  }
}

/// Set the identity to be used for writing reflogs.
///
/// If both are set, this name and email will be used to write to the reflog.
/// Pass NULL to unset. When unset, the identity will be taken from the repository's configuration.
void setIdentity(Pointer<git_repository> repo, String? name, String? email) {
  final nameC = name?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final emailC = email?.toNativeUtf8().cast<Int8>() ?? nullptr;

  libgit2.git_repository_set_ident(repo, nameC, emailC);

  calloc.free(nameC);
  calloc.free(emailC);
}

/// Retrieve the configured identity to use for reflogs.
Map<String, String> identity(Pointer<git_repository> repo) {
  final name = calloc<Pointer<Int8>>();
  final email = calloc<Pointer<Int8>>();
  libgit2.git_repository_ident(name, email, repo);
  var identity = <String, String>{};

  if (name.value == nullptr && email.value == nullptr) {
    return identity;
  } else {
    identity[name.value.cast<Utf8>().toDartString()] =
        email.value.cast<Utf8>().toDartString();
  }

  calloc.free(name);
  calloc.free(email);

  return identity;
}

/// Get the configuration file for this repository.
///
/// If a configuration file has not been set, the default config set for the repository
/// will be returned, including global and system configurations (if they are available).
///
/// The configuration file must be freed once it's no longer being used by the user.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> config(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_repository_config(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get a snapshot of the repository's configuration.
///
/// Convenience function to take a snapshot from the repository's configuration.
/// The contents of this snapshot will not change, even if the underlying config files are modified.
///
/// The configuration file must be freed once it's no longer being used by the user.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_config> configSnapshot(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_config>>();
  final error = libgit2.git_repository_config_snapshot(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the Index file for this repository.
///
/// If a custom index has not been set, the default index for the repository
/// will be returned (the one located in `.git/index`).
///
/// The index must be freed once it's no longer being used.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> index(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_index>>();
  final error = libgit2.git_repository_index(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Determine if the repository was a shallow clone.
bool isShallow(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_is_shallow(repo);
  return result == 1 ? true : false;
}

/// Check if a repository is a linked work tree.
bool isWorktree(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_is_worktree(repo);
  return result == 1 ? true : false;
}

/// Retrieve git's prepared message.
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
String message(Pointer<git_repository> repo) {
  final out = calloc<git_buf>();
  final error = libgit2.git_repository_message(out, repo);
  final result = out.ref.ptr.cast<Utf8>().toDartString();
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

/// Get the Object Database for this repository.
///
/// If a custom ODB has not been set, the default database for the repository
/// will be returned (the one located in `.git/objects`).
///
/// The ODB must be freed once it's no longer being used.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_odb> odb(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_odb>>();
  final error = libgit2.git_repository_odb(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the Reference Database Backend for this repository.
///
/// If a custom refsdb has not been set, the default database for the repository
/// will be returned (the one that manipulates loose and packed references in
/// the `.git` directory).
///
/// The refdb must be freed once it's no longer being used.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_refdb> refdb(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_refdb>>();
  final error = libgit2.git_repository_refdb(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Make the repository HEAD point to the specified reference.
///
/// If the provided reference points to a Tree or a Blob, the HEAD is unaltered.
///
/// If the provided reference points to a branch, the HEAD will point to that branch,
/// staying attached, or become attached if it isn't yet.
///
/// If the branch doesn't exist yet, the HEAD will be attached to an unborn branch.
///
/// Otherwise, the HEAD will be detached and will directly point to the Commit.
///
/// Throws a [LibGit2Error] if error occured.
void setHead(Pointer<git_repository> repo, String ref) {
  final refname = ref.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_repository_set_head(repo, refname);
  calloc.free(refname);

  if (error < 0 && error != -1) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Make the repository HEAD directly point to the commit.
///
/// If the provided committish cannot be found in the repository, the HEAD is unaltered.
///
/// If the provided commitish cannot be peeled into a commit, the HEAD is unaltered.
///
/// Otherwise, the HEAD will eventually be detached and will directly point to the peeled commit.
///
/// Throws a [LibGit2Error] if error occured.
void setHeadDetached(Pointer<git_repository> repo, Pointer<git_oid> commitish) {
  final error = libgit2.git_repository_set_head_detached(repo, commitish);

  if (error < 0 && (error != -1 || error != -3)) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Make the repository HEAD directly point to the commit.
///
/// This behaves like [setHeadDetached] but takes an annotated commit,
/// which lets you specify which extended sha syntax string was specified
/// by a user, allowing for more exact reflog messages.
///
/// See the documentation for [setHeadDetached].
void setHeadDetachedFromAnnotated(
  Pointer<git_repository> repo,
  Pointer<git_annotated_commit> commitish,
) {
  final error =
      libgit2.git_repository_set_head_detached_from_annotated(repo, commitish);

  if (error < 0 && (error != -1 || error != -3)) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the path to the working directory for this repository.
///
/// The working directory doesn't need to be the same one that contains the
/// `.git` folder for this repository.
///
/// If this repository is bare, setting its working directory will turn it into a
/// normal repository, capable of performing all the common workdir operations
/// (checkout, status, index manipulation, etc).
///
/// Throws a [LibGit2Error] if error occured.
void setWorkdir(
  Pointer<git_repository> repo,
  String path,
  bool updateGitlink,
) {
  final workdir = path.toNativeUtf8().cast<Int8>();
  final updateGitlinkC = updateGitlink ? 1 : 0;
  final error =
      libgit2.git_repository_set_workdir(repo, workdir, updateGitlinkC);
  calloc.free(workdir);

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

  if (result == nullptr) {
    return '';
  } else {
    return result.cast<Utf8>().toDartString();
  }
}

/// Create a "fake" repository to wrap an object database
///
/// Create a repository object to wrap an object database to be used with the API
/// when all you have is an object database. This doesn't have any paths associated
/// with it, so use with care.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> wrapODB(Pointer<git_odb> odb) {
  final out = calloc<Pointer<git_repository>>();
  final error = libgit2.git_repository_wrap_odb(out, odb);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Find a single object, as specified by a [spec] string.
///
/// The returned object should be released when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<Pointer<git_object>> revParseSingle(
  Pointer<git_repository> repo,
  String spec,
) {
  final out = calloc<Pointer<git_object>>();
  final specC = spec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_revparse_single(
    out,
    repo,
    specC,
  );
  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out;
}

/// Free a previously allocated repository.
void free(Pointer<git_repository> repo) => libgit2.git_repository_free(repo);
