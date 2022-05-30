import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Get the id of a tree.
Pointer<git_oid> id(Pointer<git_tree> tree) => libgit2.git_tree_id(tree);

/// Lookup a tree object from the repository. The returned tree must be freed
/// with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tree> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_tree>>();
  final error = libgit2.git_tree_lookup(out, repoPointer, oidPointer);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Lookup a tree entry by its position in the tree.
///
/// This returns a tree entry that is owned by the tree. You don't have to free
/// it, but you must not use it after the tree is released.
///
/// Throws [RangeError] when provided index is outside of valid range.
Pointer<git_tree_entry> getByIndex({
  required Pointer<git_tree> treePointer,
  required int index,
}) {
  final result = libgit2.git_tree_entry_byindex(treePointer, index);

  if (result == nullptr) {
    throw RangeError('Out of bounds');
  } else {
    return result;
  }
}

/// Lookup a tree entry by its filename.
///
/// This returns a tree entry that is owned by the tree. You don't have to free
/// it, but you must not use it after the tree is released.
///
/// Throws [ArgumentError] if nothing found for provided filename.
Pointer<git_tree_entry> getByName({
  required Pointer<git_tree> treePointer,
  required String filename,
}) {
  final filenameC = filename.toChar();
  final result = libgit2.git_tree_entry_byname(treePointer, filenameC);

  calloc.free(filenameC);

  if (result == nullptr) {
    throw ArgumentError.value('$filename was not found');
  } else {
    return result;
  }
}

/// Retrieve a tree entry contained in a tree or in any of its subtrees, given
/// its relative path.
///
/// Unlike the other lookup functions, the returned tree entry is owned by the
/// user and must be freed explicitly with [freeEntry].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_tree_entry> getByPath({
  required Pointer<git_tree> rootPointer,
  required String path,
}) {
  final out = calloc<Pointer<git_tree_entry>>();
  final pathC = path.toChar();
  final error = libgit2.git_tree_entry_bypath(out, rootPointer, pathC);

  final result = out.value;

  calloc.free(out);
  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the number of entries listed in a tree.
int entryCount(Pointer<git_tree> tree) => libgit2.git_tree_entrycount(tree);

/// Get the id of the object pointed by the entry.
Pointer<git_oid> entryId(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_id(entry);

/// Get the filename of a tree entry.
String entryName(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_name(entry).toDartString();

/// Get the UNIX file attributes of a tree entry.
int entryFilemode(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_filemode(entry);

/// Free a user-owned tree entry.
///
/// IMPORTANT: This function is only needed for tree entries owned by the user,
/// such as [getByPath].
void freeEntry(Pointer<git_tree_entry> entry) =>
    libgit2.git_tree_entry_free(entry);

/// Close an open tree to release memory.
void free(Pointer<git_tree> tree) => libgit2.git_tree_free(tree);
