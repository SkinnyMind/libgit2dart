import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Get the id of a tree.
Pointer<git_oid> id(Pointer<git_tree> tree) => libgit2.git_tree_id(tree);

/// Lookup a tree object from the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tree> lookup(Pointer<git_repository> repo, Pointer<git_oid> id) {
  return using((Arena arena) {
    final out = arena<Pointer<git_tree>>();
    final error = libgit2.git_tree_lookup(out, repo, id);

    if (error < 0) {
      throw LibGit2Error(libgit2.git_error_last());
    } else {
      return out.value;
    }
  });
}

/// Lookup a tree object from the repository, given a prefix of its identifier (short id).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tree> lookupPrefix(
  Pointer<git_repository> repo,
  Pointer<git_oid> id,
  int len,
) {
  return using((Arena arena) {
    final out = arena<Pointer<git_tree>>();
    final error = libgit2.git_tree_lookup_prefix(out, repo, id, len);

    if (error < 0) {
      throw LibGit2Error(libgit2.git_error_last());
    } else {
      return out.value;
    }
  });
}

/// Close an open tree.
///
/// You can no longer use the git_tree pointer after this call.
///
/// IMPORTANT: You MUST call this method when you stop using a tree to release memory.
/// Failure to do so will cause a memory leak.
void free(Pointer<git_tree> tree) => libgit2.git_tree_free(tree);
