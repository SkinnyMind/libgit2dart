import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libgit2_bindings.dart';
import '../error.dart';
import '../util.dart';

/// Initialize a new packbuilder.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_packbuilder> init(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_packbuilder>>();
  final error = libgit2.git_packbuilder_new(out, repo);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Insert a single object.
///
/// For an optimal pack it's mandatory to insert objects in recency order,
/// commits followed by trees and blobs.
///
/// Throws a [LibGit2Error] if error occured.
void add({
  required Pointer<git_packbuilder> packbuilderPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final error = libgit2.git_packbuilder_insert(
    packbuilderPointer,
    oidPointer,
    nullptr,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Recursively insert an object and its referenced objects.
///
/// Insert the object as well as any object it references.
///
/// Throws a [LibGit2Error] if error occured.
void addRecursively({
  required Pointer<git_packbuilder> packbuilderPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final error = libgit2.git_packbuilder_insert_recur(
    packbuilderPointer,
    oidPointer,
    nullptr,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Write the new pack and corresponding index file to path.
///
/// Throws a [LibGit2Error] if error occured.
void write({
  required Pointer<git_packbuilder> packbuilderPointer,
  String? path,
}) {
  final pathC = path?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final error = libgit2.git_packbuilder_write(
    packbuilderPointer,
    pathC,
    0,
    nullptr,
    nullptr,
  );

  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the total number of objects the packbuilder will write out.
int length(Pointer<git_packbuilder> pb) {
  return libgit2.git_packbuilder_object_count(pb);
}

/// Get the number of objects the packbuilder has already written out.
int writtenCount(Pointer<git_packbuilder> pb) {
  return libgit2.git_packbuilder_written(pb);
}

/// Set number of threads to spawn.
///
/// By default, libgit2 won't spawn any threads at all; when set to 0,
/// libgit2 will autodetect the number of CPUs.
int setThreads({
  required Pointer<git_packbuilder> packbuilderPointer,
  required int number,
}) {
  return libgit2.git_packbuilder_set_threads(packbuilderPointer, number);
}

/// Free the packbuilder and all associated data.
void free(Pointer<git_packbuilder> pb) => libgit2.git_packbuilder_free(pb);
