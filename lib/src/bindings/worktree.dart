import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Add a new working tree.
///
/// Add a new working tree for the repository, that is create the required
/// data structures inside the repository and check out the current HEAD at path.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_worktree> create({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String path,
  Pointer<git_reference>? refPointer,
}) {
  final out = calloc<Pointer<git_worktree>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final pathC = path.toNativeUtf8().cast<Int8>();

  final opts = calloc<git_worktree_add_options>();
  libgit2.git_worktree_add_options_init(opts, GIT_WORKTREE_ADD_OPTIONS_VERSION);

  opts.ref.ref = nullptr;
  if (refPointer != null) {
    opts.ref.ref = refPointer;
  }

  final error = libgit2.git_worktree_add(out, repoPointer, nameC, pathC, opts);

  calloc.free(nameC);
  calloc.free(pathC);
  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Lookup a working tree by its name for a given repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_worktree> lookup({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_worktree>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_worktree_lookup(out, repoPointer, nameC);

  calloc.free(nameC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Check if the worktree prunable.
///
/// A worktree is not prunable in the following scenarios:
/// - the worktree is linking to a valid on-disk worktree.
/// - the worktree is locked.
///
/// Throws a [LibGit2Error] if error occured.
bool isPrunable(Pointer<git_worktree> wt) {
  final opts = calloc<git_worktree_prune_options>();
  libgit2.git_worktree_prune_options_init(
    opts,
    GIT_WORKTREE_PRUNE_OPTIONS_VERSION,
  );

  return libgit2.git_worktree_is_prunable(wt, opts) > 0 ? true : false;
}

/// Prune working tree.
///
/// Prune the working tree, that is remove the git data structures on disk.
void prune(Pointer<git_worktree> wt) {
  libgit2.git_worktree_prune(wt, nullptr);
}

/// List names of linked working trees.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  final error = libgit2.git_worktree_list(out, repo);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = <String>[];
    for (var i = 0; i < out.ref.count; i++) {
      result.add(out.ref.strings[i].cast<Utf8>().toDartString());
    }
    calloc.free(out);
    return result;
  }
}

/// Retrieve the name of the worktree.
String name(Pointer<git_worktree> wt) {
  return libgit2.git_worktree_name(wt).cast<Utf8>().toDartString();
}

/// Retrieve the filesystem path for the worktree.
String path(Pointer<git_worktree> wt) {
  return libgit2.git_worktree_path(wt).cast<Utf8>().toDartString();
}

/// Check if worktree is locked.
///
/// A worktree may be locked if the linked working tree is stored on a portable
/// device which is not available.
bool isLocked(Pointer<git_worktree> wt) {
  return libgit2.git_worktree_is_locked(nullptr, wt) == 1 ? true : false;
}

/// Lock worktree if not already locked.
void lock(Pointer<git_worktree> wt) => libgit2.git_worktree_lock(wt, nullptr);

/// Unlock a locked worktree.
void unlock(Pointer<git_worktree> wt) => libgit2.git_worktree_unlock(wt);

/// Check if worktree is valid.
///
/// A valid worktree requires both the git data structures inside the linked parent
/// repository and the linked working copy to be present.
bool isValid(Pointer<git_worktree> wt) {
  return libgit2.git_worktree_validate(wt) == 0 ? true : false;
}

/// Free a previously allocated worktree.
void free(Pointer<git_worktree> wt) => libgit2.git_worktree_free(wt);
