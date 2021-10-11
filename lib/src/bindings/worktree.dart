import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'libgit2_bindings.dart';
import '../error.dart';
import '../util.dart';

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
  final optsError = libgit2.git_worktree_add_options_init(
    opts,
    GIT_WORKTREE_ADD_OPTIONS_VERSION,
  );

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  opts.ref.ref = nullptr;
  if (refPointer != null) {
    opts.ref.ref = refPointer;
  }

  final error = libgit2.git_worktree_add(out, repoPointer, nameC, pathC, opts);

  calloc.free(nameC);
  calloc.free(pathC);
  calloc.free(opts);

  if (error < 0) {
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
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Prune working tree.
///
/// Prune the working tree, that is remove the git data structures on disk.
///
/// Throws a [LibGit2Error] if error occured.
void prune(Pointer<git_worktree> wt) {
  final error = libgit2.git_worktree_prune(wt, nullptr);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// List names of linked working trees.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  final error = libgit2.git_worktree_list(out, repo);
  final result = <String>[];

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
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

/// Free a previously allocated worktree.
void free(Pointer<git_worktree> wt) => libgit2.git_worktree_free(wt);
