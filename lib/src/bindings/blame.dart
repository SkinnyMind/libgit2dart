import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/oid.dart';
import 'package:libgit2dart/src/util.dart';

/// Get the blame for a single file. The returned blame must be freed with
/// [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_blame> file({
  required Pointer<git_repository> repoPointer,
  required String path,
  required int flags,
  int? minMatchCharacters,
  Oid? newestCommit,
  Oid? oldestCommit,
  int? minLine,
  int? maxLine,
}) {
  final out = calloc<Pointer<git_blame>>();
  final pathC = path.toChar();
  final options = calloc<git_blame_options>();
  libgit2.git_blame_options_init(options, GIT_BLAME_OPTIONS_VERSION);

  options.ref.flags = flags;

  if (minMatchCharacters != null) {
    options.ref.min_match_characters = minMatchCharacters;
  }

  if (newestCommit != null) {
    options.ref.newest_commit = newestCommit.pointer.ref;
  }

  if (oldestCommit != null) {
    options.ref.oldest_commit = oldestCommit.pointer.ref;
  }

  if (minLine != null) {
    options.ref.min_line = minLine;
  }

  if (maxLine != null) {
    options.ref.max_line = maxLine;
  }

  final error = libgit2.git_blame_file(out, repoPointer, pathC, options);

  final result = out.value;

  calloc.free(out);
  calloc.free(pathC);
  calloc.free(options);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get blame data for a file that has been modified in memory. The [reference]
/// parameter is a pre-calculated blame for the in-odb history of the file.
/// This means that once a file blame is completed (which can be expensive),
/// updating the buffer blame is very fast.
///
/// Lines that differ between the buffer and the committed version are marked
/// as having a zero OID for their finalCommitOid.
///
/// The returned blame must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_blame> buffer({
  required Pointer<git_blame> reference,
  required String buffer,
}) {
  final out = calloc<Pointer<git_blame>>();
  final bufferC = buffer.toChar();
  final error = libgit2.git_blame_buffer(
    out,
    reference,
    bufferC,
    buffer.length,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(bufferC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Gets the number of hunks that exist in the blame structure.
int hunkCount(Pointer<git_blame> blame) {
  return libgit2.git_blame_get_hunk_count(blame);
}

/// Gets the blame hunk at the given index.
///
/// Throws [RangeError] if index out of range.
Pointer<git_blame_hunk> getHunkByIndex({
  required Pointer<git_blame> blamePointer,
  required int index,
}) {
  final result = libgit2.git_blame_get_hunk_byindex(blamePointer, index);

  if (result == nullptr) {
    throw RangeError('$index is out of bounds');
  } else {
    return result;
  }
}

/// Gets the hunk that relates to the given line number (1-based) in the newest
/// commit.
///
/// Throws [RangeError] if [lineNumber] is out of range.
Pointer<git_blame_hunk> getHunkByLine({
  required Pointer<git_blame> blamePointer,
  required int lineNumber,
}) {
  final result = libgit2.git_blame_get_hunk_byline(blamePointer, lineNumber);

  if (result == nullptr) {
    throw RangeError('$lineNumber is out of bounds');
  } else {
    return result;
  }
}

/// Free memory allocated for blame object.
void free(Pointer<git_blame> blame) => libgit2.git_blame_free(blame);
