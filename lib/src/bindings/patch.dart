import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Directly generate a patch from the difference between two buffers. The
/// returned patch must be freed with [free].
Pointer<git_patch> fromBuffers({
  String? oldBuffer,
  String? oldAsPath,
  String? newBuffer,
  String? newAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldBufferC = oldBuffer?.toChar() ?? nullptr;
  final oldAsPathC = oldAsPath?.toChar() ?? nullptr;
  final oldLen = oldBuffer?.length ?? 0;
  final newBufferC = newBuffer?.toChar() ?? nullptr;
  final newAsPathC = oldAsPath?.toChar() ?? nullptr;
  final newLen = newBuffer?.length ?? 0;
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_patch_from_buffers(
    out,
    oldBufferC.cast(),
    oldLen,
    oldAsPathC,
    newBufferC.cast(),
    newLen,
    newAsPathC,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);
  // We are not freeing buffers `oldBufferC` and `newBufferC` because patch
  // object does not have reference to underlying buffers. So if the buffer is
  // freed the patch text becomes corrupted.

  return result;
}

/// Directly generate a patch from the difference between two blobs. The
/// returned patch must be freed with [free].
Pointer<git_patch> fromBlobs({
  required Pointer<git_blob>? oldBlobPointer,
  String? oldAsPath,
  required Pointer<git_blob>? newBlobPointer,
  String? newAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toChar() ?? nullptr;
  final newAsPathC = oldAsPath?.toChar() ?? nullptr;
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_patch_from_blobs(
    out,
    oldBlobPointer ?? nullptr,
    oldAsPathC,
    newBlobPointer ?? nullptr,
    newAsPathC,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);

  return result;
}

/// Directly generate a patch from the difference between a blob and a buffer.
/// The returned patch must be freed with [free].
Pointer<git_patch> fromBlobAndBuffer({
  Pointer<git_blob>? oldBlobPointer,
  String? oldAsPath,
  String? buffer,
  String? bufferAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toChar() ?? nullptr;
  final bufferC = buffer?.toChar() ?? nullptr;
  final bufferAsPathC = oldAsPath?.toChar() ?? nullptr;
  final bufferLen = buffer?.length ?? 0;
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_patch_from_blob_and_buffer(
    out,
    oldBlobPointer ?? nullptr,
    oldAsPathC,
    bufferC.cast(),
    bufferLen,
    bufferAsPathC,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(oldAsPathC);
  calloc.free(bufferAsPathC);
  calloc.free(opts);
  // We are not freeing buffer `bufferC` because patch object does not have
  // reference to underlying buffers. So if the buffer is freed the patch text
  // becomes corrupted.

  return result;
}

/// Return a patch for an entry in the diff list. The returned patch must be
/// freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_patch> fromDiff({
  required Pointer<git_diff> diffPointer,
  required int index,
}) {
  final out = calloc<Pointer<git_patch>>();
  final error = libgit2.git_patch_from_diff(out, diffPointer, index);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the delta associated with a patch.
Pointer<git_diff_delta> delta(Pointer<git_patch> patch) =>
    libgit2.git_patch_get_delta(patch);

/// Get the number of hunks in a patch.
int numHunks(Pointer<git_patch> patch) => libgit2.git_patch_num_hunks(patch);

/// Get the information about a hunk in a patch.
///
/// Given a patch and a hunk index into the patch, this returns detailed
/// information about that hunk.
Map<String, Object> hunk({
  required Pointer<git_patch> patchPointer,
  required int hunkIndex,
}) {
  final out = calloc<Pointer<git_diff_hunk>>();
  final linesInHunk = calloc<Size>();
  libgit2.git_patch_get_hunk(out, linesInHunk, patchPointer, hunkIndex);

  final hunk = out.value;
  final linesN = linesInHunk.value;

  calloc.free(out);
  calloc.free(linesInHunk);

  return {'hunk': hunk, 'linesN': linesN};
}

/// Get line counts of each type in a patch.
Map<String, int> lineStats(Pointer<git_patch> patch) {
  final context = calloc<Size>();
  final insertions = calloc<Size>();
  final deletions = calloc<Size>();
  libgit2.git_patch_line_stats(
    context,
    insertions,
    deletions,
    patch,
  );

  final result = {
    'context': context.value,
    'insertions': insertions.value,
    'deletions': deletions.value,
  };

  calloc.free(context);
  calloc.free(insertions);
  calloc.free(deletions);

  return result;
}

/// Get data about a line in a hunk of a patch.
Pointer<git_diff_line> lines({
  required Pointer<git_patch> patchPointer,
  required int hunkIndex,
  required int lineOfHunk,
}) {
  final out = calloc<Pointer<git_diff_line>>();
  libgit2.git_patch_get_line_in_hunk(out, patchPointer, hunkIndex, lineOfHunk);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Get the content of a patch as a single diff text.
///
/// Throws a [LibGit2Error] if error occured.
String text(Pointer<git_patch> patch) {
  final out = calloc<git_buf>();
  final error = libgit2.git_patch_to_buf(out, patch);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Look up size of patch diff data in bytes.
///
/// This returns the raw size of the patch data. This only includes the actual
/// data from the lines of the diff, not the file or hunk headers.
///
/// If you pass `includeContext` as true, this will be the size of all of the
/// diff output; if you pass it as false, this will only include the actual
/// changed lines (as if contextLines was 0).
int size({
  required Pointer<git_patch> patchPointer,
  required bool includeContext,
  required bool includeHunkHeaders,
  required bool includeFileHeaders,
}) {
  final includeContextC = includeContext ? 1 : 0;
  final includeHunkHeadersC = includeHunkHeaders ? 1 : 0;
  final includeFileHeadersC = includeFileHeaders ? 1 : 0;

  return libgit2.git_patch_size(
    patchPointer,
    includeContextC,
    includeHunkHeadersC,
    includeFileHeadersC,
  );
}

/// Free a previously allocated patch object.
void free(Pointer<git_patch> patch) => libgit2.git_patch_free(patch);

Pointer<git_diff_options> _diffOptionsInit({
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final opts = calloc<git_diff_options>();
  libgit2.git_diff_options_init(opts, GIT_DIFF_OPTIONS_VERSION);

  opts.ref.flags = flags;
  opts.ref.context_lines = contextLines;
  opts.ref.interhunk_lines = interhunkLines;

  return opts;
}
