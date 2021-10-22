import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';

/// Directly generate a patch from the difference between two buffers.
///
/// You can use the standard patch accessor functions to read the patch data,
/// and you must free the patch when done.
Map<String, Pointer?> fromBuffers({
  String? oldBuffer,
  String? oldAsPath,
  String? newBuffer,
  String? newAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldBufferC = oldBuffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final oldLen = oldBuffer?.length ?? 0;
  final newBufferC = newBuffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final newAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
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

  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);

  // Returning map with pointers to patch and buffers because patch object does
  // not have refenrece to underlying buffers or blobs. So if the buffer or blob is freed/removed
  // the patch text becomes corrupted.
  return {'patch': out.value, 'a': oldBufferC, 'b': newBufferC};
}

/// Directly generate a patch from the difference between two blobs.
///
/// You can use the standard patch accessor functions to read the patch data,
/// and you must free the patch when done.
Map<String, Pointer?> fromBlobs({
  required Pointer<git_blob> oldBlobPointer,
  String? oldAsPath,
  required Pointer<git_blob> newBlobPointer,
  String? newAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final newAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_patch_from_blobs(
    out,
    oldBlobPointer,
    oldAsPathC,
    newBlobPointer,
    newAsPathC,
    opts,
  );

  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);

  // Returning map with pointers to patch and blobs because patch object does
  // not have reference to underlying blobs. So if the blob is freed/removed the
  // patch text becomes corrupted.
  return {'patch': out.value, 'a': oldBlobPointer, 'b': newBlobPointer};
}

/// Directly generate a patch from the difference between a blob and a buffer.
///
/// You can use the standard patch accessor functions to read the patch data,
/// and you must free the patch when done.
Map<String, Pointer?> fromBlobAndBuffer({
  Pointer<git_blob>? oldBlobPointer,
  String? oldAsPath,
  String? buffer,
  String? bufferAsPath,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final bufferC = buffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final bufferAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
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

  calloc.free(oldAsPathC);
  calloc.free(bufferAsPathC);
  calloc.free(opts);

  // Returning map with pointers to patch and buffers because patch object does
  // not have reference to underlying buffers or blobs. So if the buffer or
  // blob is freed/removed the patch text becomes corrupted.
  return {'patch': out.value, 'a': oldBlobPointer, 'b': bufferC};
}

/// Return a patch for an entry in the diff list.
///
/// The newly created patch object contains the text diffs for the delta. You
/// have to call [free] when you are done with it. You can use the patch object
/// to loop over all the hunks and lines in the diff of the one delta.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_patch> fromDiff({
  required Pointer<git_diff> diffPointer,
  required int index,
}) {
  final out = calloc<Pointer<git_patch>>();
  final error = libgit2.git_patch_from_diff(out, diffPointer, index);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
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
  final linesInHunk = calloc<Int64>();
  libgit2.git_patch_get_hunk(out, linesInHunk.cast(), patchPointer, hunkIndex);

  final linesN = linesInHunk.value;
  calloc.free(linesInHunk);
  return {'hunk': out.value, 'linesN': linesN};
}

/// Get data about a line in a hunk of a patch.
Pointer<git_diff_line> lines({
  required Pointer<git_patch> patchPointer,
  required int hunkIndex,
  required int lineOfHunk,
}) {
  final out = calloc<Pointer<git_diff_line>>();
  libgit2.git_patch_get_line_in_hunk(out, patchPointer, hunkIndex, lineOfHunk);

  return out.value;
}

/// Get the content of a patch as a single diff text.
///
/// Throws a [LibGit2Error] if error occured.
String text(Pointer<git_patch> patch) {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final error = libgit2.git_patch_to_buf(out, patch);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString();
    calloc.free(out);
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
