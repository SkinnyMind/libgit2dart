import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/patch.dart' as bindings;
import 'package:libgit2dart/src/util.dart';
import 'package:meta/meta.dart';

@immutable
class Patch extends Equatable {
  /// Initializes a new instance of [Patch] class from provided
  /// pointer to patch object in memory and pointers to old and new blobs/buffers.
  ///
  /// Note: For internal use. Instead, use one of:
  /// - [Patch.fromBlobs]
  /// - [Patch.fromBlobAndBuffer]
  /// - [Patch.fromBuffers]
  /// - [Patch.fromDiff]
  @internal
  Patch(this._patchPointer) {
    _finalizer.attach(this, _patchPointer, detach: this);
  }

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
    _finalizer.attach(this, _patchPointer, detach: this);
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
    _finalizer.attach(this, _patchPointer, detach: this);
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
    _finalizer.attach(this, _patchPointer, detach: this);
  }

  /// Creates a patch for an entry in the diff list.
  ///
  /// [diff] is the [Diff] list object.
  ///
  /// [index] is the position of an entry in diff list.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromDiff({required Diff diff, required int index}) {
    _patchPointer = bindings.fromDiff(diffPointer: diff.pointer, index: index);
    _finalizer.attach(this, _patchPointer, detach: this);
  }

  late final Pointer<git_patch> _patchPointer;

  /// Line counts of each type in a patch.
  ///
  /// This helps imitate a `diff --numstat` type of output.
  PatchStats get stats {
    final result = bindings.lineStats(_patchPointer);

    return PatchStats._(
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

    for (var index = 0; index < length; index++) {
      final hunk = bindings.hunk(patchPointer: _patchPointer, hunkIndex: index);
      final hunkPointer = hunk['hunk']! as Pointer<git_diff_hunk>;
      final linesCount = hunk['linesN']! as int;

      final lines = <DiffLine>[];
      for (var i = 0; i < linesCount; i++) {
        final linePointer = bindings.lines(
          patchPointer: _patchPointer,
          hunkIndex: index,
          lineOfHunk: i,
        );
        lines.add(
          DiffLine._(
            origin: GitDiffLine.values.firstWhere(
              (e) => linePointer.ref.origin == e.value,
            ),
            oldLineNumber: linePointer.ref.old_lineno,
            newLineNumber: linePointer.ref.new_lineno,
            numLines: linePointer.ref.num_lines,
            contentOffset: linePointer.ref.content_offset,
            content: linePointer.ref.content
                .cast<Utf8>()
                .toDartString(length: linePointer.ref.content_len),
          ),
        );
      }

      final intHeader = <int>[
        for (var i = 0; i < hunkPointer.ref.header_len; i++)
          hunkPointer.ref.header[i]
      ];

      hunks.add(
        DiffHunk._(
          linesCount: linesCount,
          index: index,
          oldStart: hunkPointer.ref.old_start,
          oldLines: hunkPointer.ref.old_lines,
          newStart: hunkPointer.ref.new_start,
          newLines: hunkPointer.ref.new_lines,
          header: String.fromCharCodes(intHeader),
          lines: lines,
        ),
      );
    }

    return hunks;
  }

  /// Releases memory allocated for patch object.
  void free() {
    bindings.free(_patchPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() => 'Patch{size: ${size()}, delta: $delta}';

  @override
  List<Object?> get props => [delta];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_patch>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

/// Line counts of each type in a patch.
class PatchStats {
  const PatchStats._({
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

@immutable
class DiffHunk extends Equatable {
  const DiffHunk._({
    required this.linesCount,
    required this.index,
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.header,
    required this.lines,
  });

  /// Number of total lines in this hunk.
  final int linesCount;

  /// Index of this hunk in the patch.
  final int index;

  /// Starting line number in 'old file'.
  final int oldStart;

  /// Number of lines in 'old file'.
  final int oldLines;

  /// Starting line number in 'new file'.
  final int newStart;

  /// Number of lines in 'new file'.
  final int newLines;

  /// Header of a hunk.
  final String header;

  /// List of lines in a hunk of a patch.
  final List<DiffLine> lines;

  @override
  String toString() {
    return 'DiffHunk{linesCount: $linesCount, index: $index, '
        'oldStart: $oldStart, oldLines: $oldLines, newStart: $newStart, '
        'newLines: $newLines, header: $header}';
  }

  @override
  List<Object?> get props => [
        linesCount,
        index,
        oldStart,
        oldLines,
        newStart,
        newLines,
        header,
        lines
      ];
}

@immutable
class DiffLine extends Equatable {
  const DiffLine._({
    required this.origin,
    required this.oldLineNumber,
    required this.newLineNumber,
    required this.numLines,
    required this.contentOffset,
    required this.content,
  });

  /// Type of the line.
  final GitDiffLine origin;

  /// Line number in old file or -1 for added line.
  final int oldLineNumber;

  /// Line number in new file or -1 for deleted line.
  final int newLineNumber;

  /// Number of newline characters in content.
  final int numLines;

  /// Offset in the original file to the content.
  final int contentOffset;

  /// Content of the diff line.
  final String content;

  @override
  String toString() {
    return 'DiffLine{oldLineNumber: $oldLineNumber, '
        'newLineNumber: $newLineNumber, numLines: $numLines, '
        'contentOffset: $contentOffset, content: $content}';
  }

  @override
  List<Object?> get props => [
        origin,
        oldLineNumber,
        newLineNumber,
        numLines,
        contentOffset,
        content,
      ];
}
