import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Create a new tree builder.
///
/// The tree builder can be used to create or modify trees in memory and write
/// them as tree objects to the database.
///
/// If the source parameter is not null, the tree builder will be initialized
/// with the entries of the given tree.
///
/// If the source parameter is null, the tree builder will start with no entries
/// and will have to be filled manually.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_treebuilder> create({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree> sourcePointer,
}) {
  final out = calloc<Pointer<git_treebuilder>>();
  final error = libgit2.git_treebuilder_new(out, repoPointer, sourcePointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Write the contents of the tree builder as a tree object.
Pointer<git_oid> write(Pointer<git_treebuilder> bld) {
  final out = calloc<git_oid>();
  libgit2.git_treebuilder_write(out, bld);
  return out;
}

/// Clear all the entires in the builder.
void clear(Pointer<git_treebuilder> bld) => libgit2.git_treebuilder_clear(bld);

/// Get the number of entries listed in a treebuilder.
int entryCount(Pointer<git_treebuilder> bld) =>
    libgit2.git_treebuilder_entrycount(bld);

/// Get an entry from the builder from its filename.
///
/// The returned entry is owned by the builder and should not be freed manually.
///
/// Throws [ArgumentError] if nothing found for provided filename.
Pointer<git_tree_entry> getByFilename({
  required Pointer<git_treebuilder> builderPointer,
  required String filename,
}) {
  final filenameC = filename.toNativeUtf8().cast<Int8>();
  final result = libgit2.git_treebuilder_get(builderPointer, filenameC);

  calloc.free(filenameC);

  if (result == nullptr) {
    throw ArgumentError.value('$filename was not found');
  } else {
    return result;
  }
}

/// Add or update an entry to the builder.
///
/// Insert a new entry for filename in the builder with the given attributes.
///
/// If an entry named filename already exists, its attributes will be updated
/// with the given ones.
///
/// By default the entry that you are inserting will be checked for validity;
/// that it exists in the object database and is of the correct type.
///
/// Throws a [LibGit2Error] if error occured.
void add({
  required Pointer<git_treebuilder> builderPointer,
  required String filename,
  required Pointer<git_oid> oidPointer,
  required int filemode,
}) {
  final filenameC = filename.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_treebuilder_insert(
    nullptr,
    builderPointer,
    filenameC,
    oidPointer,
    filemode,
  );

  calloc.free(filenameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Remove an entry from the builder by its filename.
///
/// Throws a [LibGit2Error] if error occured.
void remove({
  required Pointer<git_treebuilder> builderPointer,
  required String filename,
}) {
  final filenameC = filename.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_treebuilder_remove(builderPointer, filenameC);

  calloc.free(filenameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Free a tree builder and all the entries to release memory.
void free(Pointer<git_treebuilder> bld) => libgit2.git_treebuilder_free(bld);
