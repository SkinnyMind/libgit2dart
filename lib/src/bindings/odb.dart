import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Determine if an object can be found in the object database by an abbreviated object ID.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> existsPrefix(
  Pointer<git_odb> db,
  Pointer<git_oid> shortOid,
  int len,
) {
  final out = calloc<git_oid>();
  final error = libgit2.git_odb_exists_prefix(out, db, shortOid, len);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Close an open object database.
void free(Pointer<git_odb> db) => libgit2.git_odb_free(db);
