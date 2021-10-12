import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import '../oid.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Get the blame for a single file.
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
  final pathC = path.toNativeUtf8().cast<Int8>();
  final options = calloc<git_blame_options>();
  final optionsError = libgit2.git_blame_options_init(
    options,
    GIT_BLAME_OPTIONS_VERSION,
  );

  if (optionsError < 0) {
    calloc.free(out);
    calloc.free(pathC);
    calloc.free(options);
    throw LibGit2Error(libgit2.git_error_last());
  }

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

  calloc.free(pathC);
  calloc.free(options);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
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

/// Gets the hunk that relates to the given line number (1-based) in the newest commit.
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
