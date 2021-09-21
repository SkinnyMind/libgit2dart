import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Directly generate a patch from the difference between two buffers.
///
/// You can use the standard patch accessor functions to read the patch data, and
/// you must call `free()` on the patch when done.
///
/// Throws a [LibGit2Error] if error occured.
Map<String, dynamic> fromBuffers(
  String? oldBuffer,
  String? oldAsPath,
  String? newBuffer,
  String? newAsPath,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_patch>>();
  final oldBufferC = oldBuffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final oldLen = oldBuffer?.length ?? 0;
  final newBufferC = newBuffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final newAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final newLen = newBuffer?.length ?? 0;
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  final error = libgit2.git_patch_from_buffers(
    out,
    oldBufferC.cast(),
    oldLen,
    oldAsPathC,
    newBufferC.cast(),
    newLen,
    newAsPathC,
    opts,
  );

  final result = <String, dynamic>{};

  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);

  if (error < 0) {
    calloc.free(oldBufferC);
    calloc.free(newBufferC);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    // Returning map with pointers to patch and buffers because patch object does not
    // have refenrece to underlying buffers or blobs. So if the buffer or blob is freed/removed
    // the patch text becomes corrupted.
    result['patch'] = out.value;
    result['a'] = oldBufferC;
    result['b'] = newBufferC;
    return result;
  }
}

/// Directly generate a patch from the difference between two blobs.
///
/// You can use the standard patch accessor functions to read the patch data, and you
/// must call `free()` on the patch when done.
///
/// Throws a [LibGit2Error] if error occured.
Map<String, dynamic> fromBlobs(
  Pointer<git_blob>? oldBlob,
  String? oldAsPath,
  Pointer<git_blob>? newBlob,
  String? newAsPath,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final newAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  final error = libgit2.git_patch_from_blobs(
    out,
    oldBlob ?? nullptr,
    oldAsPathC,
    newBlob ?? nullptr,
    newAsPathC,
    opts,
  );

  final result = <String, dynamic>{};

  calloc.free(oldAsPathC);
  calloc.free(newAsPathC);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    // Returning map with pointers to patch and blobs because patch object does not
    // have refenrece to underlying blobs. So if the blob is freed/removed the patch
    // text becomes corrupted.
    result['patch'] = out.value;
    result['a'] = oldBlob;
    result['b'] = newBlob;
    return result;
  }
}

/// Directly generate a patch from the difference between a blob and a buffer.
///
/// You can use the standard patch accessor functions to read the patch data, and you must
/// call `free()` on the patch when done.
///
/// Throws a [LibGit2Error] if error occured.
Map<String, dynamic> fromBlobAndBuffer(
  Pointer<git_blob>? oldBlob,
  String? oldAsPath,
  String? buffer,
  String? bufferAsPath,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_patch>>();
  final oldAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final bufferC = buffer?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final bufferAsPathC = oldAsPath?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final bufferLen = buffer?.length ?? 0;
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  final error = libgit2.git_patch_from_blob_and_buffer(
    out,
    oldBlob ?? nullptr,
    oldAsPathC,
    bufferC.cast(),
    bufferLen,
    bufferAsPathC,
    opts,
  );

  final result = <String, dynamic>{};

  calloc.free(oldAsPathC);
  calloc.free(bufferAsPathC);
  calloc.free(opts);

  if (error < 0) {
    calloc.free(bufferC);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    // Returning map with pointers to patch and buffers because patch object does not
    // have refenrece to underlying buffers or blobs. So if the buffer or blob is freed/removed
    // the patch text becomes corrupted.
    result['patch'] = out.value;
    result['a'] = oldBlob;
    result['b'] = bufferC;
    return result;
  }
}

/// Return a patch for an entry in the diff list.
///
/// The newly created patch object contains the text diffs for the delta. You have to call
/// `free()` when you are done with it. You can use the patch object to loop over all the
/// hunks and lines in the diff of the one delta.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_patch> fromDiff(Pointer<git_diff> diff, int idx) {
  final out = calloc<Pointer<git_patch>>();
  final error = libgit2.git_patch_from_diff(out, diff, idx);

  if (error < 0) {
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
/// Given a patch and a hunk index into the patch, this returns detailed information about that hunk.
///
/// Throws a [LibGit2Error] if error occured.
Map<String, dynamic> hunk(Pointer<git_patch> patch, int hunkIdx) {
  final out = calloc<Pointer<git_diff_hunk>>();
  final linesInHunk = calloc<Int32>();
  final error =
      libgit2.git_patch_get_hunk(out, linesInHunk.cast(), patch, hunkIdx);
  final result = <String, dynamic>{};

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    result['hunk'] = out.value;
    result['linesN'] = linesInHunk.value;
    return result;
  }
}

/// Get data about a line in a hunk of a patch.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff_line> lines(
  Pointer<git_patch> patch,
  int hunkIdx,
  int lineOfHunk,
) {
  final out = calloc<Pointer<git_diff_line>>();
  final error =
      libgit2.git_patch_get_line_in_hunk(out, patch, hunkIdx, lineOfHunk);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the content of a patch as a single diff text.
///
/// Throws a [LibGit2Error] if error occured.
String text(Pointer<git_patch> patch) {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final error = libgit2.git_patch_to_buf(out, patch);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}

/// Look up size of patch diff data in bytes.
///
/// This returns the raw size of the patch data. This only includes the actual data from
/// the lines of the diff, not the file or hunk headers.
///
/// If you pass `includeContext` as true, this will be the size of all of the diff output;
/// if you pass it as false, this will only include the actual changed lines (as if
/// contextLines was 0).
int size(
  Pointer<git_patch> patch,
  bool includeContext,
  bool includeHunkHeaders,
  bool includeFileHeaders,
) {
  final includeContextC = includeContext ? 1 : 0;
  final includeHunkHeadersC = includeHunkHeaders ? 1 : 0;
  final includeFileHeadersC = includeFileHeaders ? 1 : 0;

  return libgit2.git_patch_size(
    patch,
    includeContextC,
    includeHunkHeadersC,
    includeFileHeadersC,
  );
}

/// Free a previously allocated patch object.
void free(Pointer<git_patch> patch) => libgit2.git_patch_free(patch);

Pointer<git_diff_options> _diffOptionsInit(
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final opts = calloc<git_diff_options>();
  final optsError =
      libgit2.git_diff_options_init(opts, GIT_DIFF_OPTIONS_VERSION);
  opts.ref.flags = flags;
  opts.ref.context_lines = contextLines;
  opts.ref.interhunk_lines = interhunkLines;

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return opts;
  }
}