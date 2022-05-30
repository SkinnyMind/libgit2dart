import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Lookup a blob object from a repository. The returned blob must be freed
/// with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_blob> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_blob>>();
  final error = libgit2.git_blob_lookup(out, repoPointer, oidPointer);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the id of a blob.
Pointer<git_oid> id(Pointer<git_blob> blob) => libgit2.git_blob_id(blob);

/// Determine if the blob content is most certainly binary or not.
///
/// The heuristic used to guess if a file is binary is taken from core git:
/// Searching for NUL bytes and looking for a reasonable ratio of printable to
/// non-printable characters among the first 8000 bytes.
bool isBinary(Pointer<git_blob> blob) {
  return libgit2.git_blob_is_binary(blob) == 1 || false;
}

/// Get a read-only buffer with the raw content of a blob.
String content(Pointer<git_blob> blob) {
  return libgit2.git_blob_rawcontent(blob).cast<Utf8>().toDartString();
}

/// Get the size in bytes of the contents of a blob.
int size(Pointer<git_blob> blob) => libgit2.git_blob_rawsize(blob);

/// Write content of a string buffer to the ODB as a blob.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create({
  required Pointer<git_repository> repoPointer,
  required String buffer,
  required int len,
}) {
  final out = calloc<git_oid>();
  final bufferC = buffer.toNativeUtf8().cast<Void>();
  final error = libgit2.git_blob_create_from_buffer(
    out,
    repoPointer,
    bufferC,
    len,
  );

  calloc.free(bufferC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Read a file from the working folder of a repository and write it to the
/// Object Database as a loose blob.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> createFromWorkdir({
  required Pointer<git_repository> repoPointer,
  required String relativePath,
}) {
  final out = calloc<git_oid>();
  final relativePathC = relativePath.toChar();
  final error = libgit2.git_blob_create_from_workdir(
    out,
    repoPointer,
    relativePathC,
  );

  calloc.free(relativePathC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Read a file from the filesystem and write its content to the Object
/// Database as a loose blob.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> createFromDisk({
  required Pointer<git_repository> repoPointer,
  required String path,
}) {
  final out = calloc<git_oid>();
  final pathC = path.toChar();
  final error = libgit2.git_blob_create_from_disk(out, repoPointer, pathC);

  calloc.free(pathC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Create an in-memory copy of a blob. The returned copy must be freed with
/// [free].
Pointer<git_blob> duplicate(Pointer<git_blob> source) {
  final out = calloc<Pointer<git_blob>>();
  libgit2.git_blob_dup(out, source);
  final result = out.value;

  calloc.free(out);

  return result;
}

/// Get a buffer with the filtered content of a blob.
///
/// This applies filters as if the blob was being checked out to the working
/// directory under the specified filename. This may apply CRLF filtering or
/// other types of changes depending on the file attributes set for the blob
/// and the content detected in it.
///
/// Throws a [LibGit2Error] if error occured.
String filterContent({
  required Pointer<git_blob> blobPointer,
  required String asPath,
  required int flags,
  git_oid? attributesCommit,
}) {
  final out = calloc<git_buf>();
  final asPathC = asPath.toChar();
  final opts = calloc<git_blob_filter_options>();
  libgit2.git_blob_filter_options_init(opts, GIT_BLOB_FILTER_OPTIONS_VERSION);
  opts.ref.flags = flags;
  if (attributesCommit != null) {
    opts.ref.attr_commit_id = attributesCommit;
  }

  final error = libgit2.git_blob_filter(out, blobPointer, asPathC, opts);

  late final String result;
  if (out.ref.ptr != nullptr) {
    result = out.ref.ptr.toDartString(length: out.ref.size);
  }

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(asPathC);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Close an open blob to release memory.
void free(Pointer<git_blob> blob) => libgit2.git_blob_free(blob);
