import 'dart:ffi';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/patch.dart' as bindings;
import 'package:libgit2dart/src/util.dart';

class Patch {
  /// Initializes a new instance of [Patch] class from provided
  /// pointer to patch object in memory and pointers to old and new blobs/buffers.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Patch(this._patchPointer);

  /// Directly generates a [Patch] from the difference between two blobs.
  ///
  /// [oldBlob] is the blob for old side of diff, or null for empty blob.
  ///
  /// [newBlob] is the blob for new side of diff, or null for empty blob.
  ///
  /// [oldBlobPath] treat old blob as if it had this filename, can be null.
  ///
  /// [newBlobPath] treat new blob as if it had this filename, can be null.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromBlobs({
    required Blob? oldBlob,
    required Blob? newBlob,
    String? oldBlobPath,
    String? newBlobPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _patchPointer = bindings.fromBlobs(
      oldBlobPointer: oldBlob?.pointer,
      oldAsPath: oldBlobPath,
      newBlobPointer: newBlob?.pointer,
      newAsPath: newBlobPath,
      flags: flags.fold(0, (int acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
  }

  /// Directly generates a [Patch] from the difference between the blob and a
  /// buffer.
  ///
  /// [blob] is the blob for old side of diff, or null for empty blob.
  ///
  /// [buffer] is the raw data for new side of diff, or null for empty.
  ///
  /// [blobPath] treat old blob as if it had this filename, can be null.
  ///
  /// [bufferPath] treat buffer as if it had this filename, can be null.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromBlobAndBuffer({
    required Blob? blob,
    required String? buffer,
    String? blobPath,
    String? bufferPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    _patchPointer = bindings.fromBlobAndBuffer(
      oldBlobPointer: blob?.pointer,
      oldAsPath: blobPath,
      buffer: buffer,
      bufferAsPath: bufferPath,
      flags: flags.fold(0, (int acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
  }

  /// Directly generates a [Patch] from the difference between two buffers
  ///
  /// [oldBuffer] is the raw data for old side of diff, or null for empty.
  ///
  /// [newBuffer] is the raw data for new side of diff, or null for empty.
  ///
  /// [oldBufferPath] treat old buffer as if it had this filename, can be null.
  ///
  /// [newBufferPath] treat new buffer as if it had this filename, can be null.
  ///
  /// [flags] is a combination of [GitDiff] flags. Defaults to [GitDiff.normal].
  ///
  /// [contextLines] is the number of unchanged lines that define the boundary
  /// of a hunk (and to display before and after). Defaults to 3.
  ///
  /// [interhunkLines] is the maximum number of unchanged lines between hunk
  /// boundaries before the hunks will be merged into one. Defaults to 0.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromBuffers({
    required String? oldBuffer,
    required String? newBuffer,
    String? oldBufferPath,
    String? newBufferPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    libgit2.git_libgit2_init();

    _patchPointer = bindings.fromBuffers(
      oldBuffer: oldBuffer,
      oldAsPath: oldBufferPath,
      newBuffer: newBuffer,
      newAsPath: newBufferPath,
      flags: flags.fold(0, (int acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );
  }

  /// Creates a patch for an entry in the diff list.
  ///
  /// [diff] is the [Diff] list object.
  ///
  /// [index] is the position of an entry in diff list.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromDiff({required Diff diff, required int index}) {
    _patchPointer = bindings.fromDiff(diffPointer: diff.pointer, index: index);
  }

  late final Pointer<git_patch> _patchPointer;

  /// Pointer to memory address for allocated patch object.
  Pointer<git_patch> get pointer => _patchPointer;

  /// Line counts of each type in a patch.
  PatchStats get stats {
    final result = bindings.lineStats(_patchPointer);

    return PatchStats(
      context: result['context']!,
      insertions: result['insertions']!,
      deletions: result['deletions']!,
    );
  }

  /// Content of a patch as a single diff text.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get text => bindings.text(_patchPointer);

  /// Size of patch diff data in bytes.
  ///
  /// This returns the raw size of the patch data. This only includes the
  /// actual data from the lines of the diff, not the file or hunk headers.
  ///
  /// If you pass `includeContext` as true, this will be the size of all of the
  /// diff output; if you pass it as false, this will only include the actual
  /// changed lines (as if contextLines was 0).
  ///
  /// If [includeHunkHeaders] and [includeFileHeaders] are set to true, they
  /// will be included in the total size.
  int size({
    bool includeContext = false,
    bool includeHunkHeaders = false,
    bool includeFileHeaders = false,
  }) {
    return bindings.size(
      patchPointer: _patchPointer,
      includeContext: includeContext,
      includeHunkHeaders: includeHunkHeaders,
      includeFileHeaders: includeFileHeaders,
    );
  }

  /// Delta associated with a patch.
  DiffDelta get delta => DiffDelta(bindings.delta(_patchPointer));

  /// List of hunks in a patch.
  List<DiffHunk> get hunks {
    final length = bindings.numHunks(_patchPointer);
    final hunks = <DiffHunk>[];

    for (var i = 0; i < length; i++) {
      final hunk = bindings.hunk(patchPointer: _patchPointer, hunkIndex: i);
      hunks.add(
        DiffHunk(
          _patchPointer,
          hunk['hunk']! as Pointer<git_diff_hunk>,
          hunk['linesN']! as int,
          i,
        ),
      );
    }

    return hunks;
  }

  /// Releases memory allocated for patch object.
  void free() => bindings.free(_patchPointer);

  @override
  String toString() => 'Patch{size: ${size()}, delta: $delta}';
}

/// Line counts of each type in a patch.
class PatchStats {
  const PatchStats({
    required this.context,
    required this.insertions,
    required this.deletions,
  });

  /// Count of context lines.
  final int context;

  /// Count of insertion lines.
  final int insertions;

  /// Count of deletion lines.
  final int deletions;

  @override
  String toString() {
    return 'PatchStats{context: $context, insertions: $insertions, '
        'deletions: $deletions}';
  }
}
