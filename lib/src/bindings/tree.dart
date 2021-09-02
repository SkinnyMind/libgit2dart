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
  final out = calloc<Pointer<git_tree>>();
  final error = libgit2.git_tree_lookup(out, repo, id);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the repository that contains the tree.
Pointer<git_repository> owner(Pointer<git_tree> tree) =>
    libgit2.git_tree_owner(tree);

/// Lookup a tree entry by its position in the tree.
///
/// This returns a tree entry that is owned by the tree. You don't have to free it,
/// but you must not use it after the tree is released.
///
/// Throws [RangeError] when provided index is outside of valid range.
Pointer<git_tree_entry> getByIndex(Pointer<git_tree> tree, int index) {
  final result = libgit2.git_tree_entry_byindex(tree, index);

  if (result == nullptr) {
    throw RangeError('Out of bounds');
  } else {
    return result;
  }
}

/// Lookup a tree entry by its filename.
///
/// This returns a tree entry that is owned by the tree. You don't have to free it,
/// but you must not use it after the tree is released.
///
/// Throws [ArgumentError] if nothing found for provided filename.
Pointer<git_tree_entry> getByName(Pointer<git_tree> tree, String filename) {
  final filenameC = filename.toNativeUtf8().cast<Int8>();
  final result = libgit2.git_tree_entry_byname(tree, filenameC);

  calloc.free(filenameC);

  if (result == nullptr) {
    throw ArgumentError.value('$filename was not found');
  } else {
    return result;
  }
}

/// Retrieve a tree entry contained in a tree or in any of its subtrees, given its relative path.
///
/// Unlike the other lookup functions, the returned tree entry is owned by the user and must be
/// freed explicitly with `entryFree()`.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tree_entry> getByPath(Pointer<git_tree> root, String path) {
  final out = calloc<Pointer<git_tree_entry>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_tree_entry_bypath(out, root, pathC);

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the number of entries listed in a tree.
int entryCount(Pointer<git_tree> tree) => libgit2.git_tree_entrycount(tree);

/// Get the id of the object pointed by the entry.
Pointer<git_oid> entryId(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_id(entry);

/// Get the filename of a tree entry.
String entryName(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_name(entry).cast<Utf8>().toDartString();

/// Get the UNIX file attributes of a tree entry.
int entryFilemode(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_filemode(entry);

/// Compare two tree entries.
///
/// Returns <0 if e1 is before e2, 0 if e1 == e2, >0 if e1 is after e2.
int compare(Pointer<git_tree_entry> e1, Pointer<git_tree_entry> e2) {
  return libgit2.git_tree_entry_cmp(e1, e2);
}

/// Free a user-owned tree entry.
///
/// IMPORTANT: This function is only needed for tree entries owned by the user,
/// such as `getByPath()`.
void entryFree(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_free(entry);

/// Close an open tree to release memory.
void free(Pointer<git_tree> tree) => libgit2.git_tree_free(tree);
