import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/util.dart';

/// Get the object type of an object.
int type(Pointer<git_object> obj) => libgit2.git_object_type(obj);

/// Lookup a reference to one of the objects in a repository. The returned
/// reference must be freed with [free].
///
/// The 'type' parameter must match the type of the object in the odb; the
/// method will fail otherwise. The special value 'GIT_OBJECT_ANY' may be
/// passed to let the method guess the object's type.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
  required int type,
}) {
  final out = calloc<Pointer<git_object>>();
  final error = libgit2.git_object_lookup(out, repoPointer, oidPointer, type);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Close an open object to release memory.
///
/// This method instructs the library to close an existing object; note that
/// git_objects are owned and cached by the repository so the object may or may
/// not be freed after this library call, depending on how aggressive is the
/// caching mechanism used by the repository.
void free(Pointer<git_object> object) => libgit2.git_object_free(object);
