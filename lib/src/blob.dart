import 'dart:ffi';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/blob.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/patch.dart' as patch_bindings;

class Blob {
  /// Initializes a new instance of [Blob] class from provided pointer to
  /// blob object in memory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Blob(this._blobPointer);

  /// Lookups a blob object for provided [oid] in a [repo]sitory.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Blob.lookup({required Repository repo, required Oid oid}) {
    _blobPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
  }

  late final Pointer<git_blob> _blobPointer;

  /// Pointer to memory address for allocated blob object.
  Pointer<git_blob> get pointer => _blobPointer;

  /// Creates a new blob from a [content] string and writes it to ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({required Repository repo, required String content}) {
    return Oid(
      bindings.create(
        repoPointer: repo.pointer,
        buffer: content,
        len: content.length,
      ),
    );
  }

  /// Creates a new blob from the file in working directory of a repository and
  /// writes it to the ODB. Provided [relativePath] should be relative to the
  /// working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromWorkdir({
    required Repository repo,
    required String relativePath,
  }) {
    return Oid(
      bindings.createFromWorkdir(
        repoPointer: repo.pointer,
        relativePath: relativePath,
      ),
    );
  }

  /// Creates a new blob from the file in filesystem and writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromDisk({required Repository repo, required String path}) {
    return Oid(bindings.createFromDisk(repoPointer: repo.pointer, path: path));
  }

  /// [Oid] of the blob.
  Oid get oid => Oid(bindings.id(_blobPointer));

  /// Whether the blob content is most certainly binary or not.
  ///
  /// The heuristic used to guess if a file is binary is taken from core git:
  /// Searching for NUL bytes and looking for a reasonable ratio of printable to
  /// non-printable characters among the first 8000 bytes.
  bool get isBinary => bindings.isBinary(_blobPointer);

  /// Read-only buffer with the raw content of a blob.
  String get content => bindings.content(_blobPointer);

  /// Size in bytes of the contents of a blob.
  int get size => bindings.size(_blobPointer);

  /// Creates an in-memory copy of a blob.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Blob duplicate() => Blob(bindings.duplicate(_blobPointer));

  /// Directly generates a [Patch] from the difference between two blobs.
  ///
  /// [newBlob] is the blob for new side of diff, or null for empty blob.
  ///
  /// [oldAsPath] treat old blob as if it had this filename, can be null.
  ///
  /// [newAsPath] treat new blob as if it had this filename, can be null.
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
  Patch diff({
    required Blob? newBlob,
    String? oldAsPath,
    String? newAsPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Patch(
      patch_bindings.fromBlobs(
        oldBlobPointer: _blobPointer,
        oldAsPath: oldAsPath,
        newBlobPointer: newBlob?.pointer ?? nullptr,
        newAsPath: newAsPath,
        flags: flags.fold(0, (acc, e) => acc | e.value),
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ),
    );
  }

  /// Directly generates a [Patch] from the difference between the blob and a
  /// buffer.
  ///
  /// [buffer] is the raw data for new side of diff, or null for empty.
  ///
  /// [oldAsPath] treat old blob as if it had this filename, can be null.
  ///
  /// [bufferAsPath] treat buffer as if it had this filename, can be null.
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
  Patch diffToBuffer({
    required String? buffer,
    String? oldAsPath,
    String? bufferAsPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    return Patch(
      patch_bindings.fromBlobAndBuffer(
        oldBlobPointer: _blobPointer,
        oldAsPath: oldAsPath,
        buffer: buffer,
        bufferAsPath: bufferAsPath,
        flags: flags.fold(0, (acc, e) => acc | e.value),
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      ),
    );
  }

  /// Returns filtered content of a blob.
  ///
  /// This applies filters as if the blob was being checked out to the working
  /// directory under the specified filename. This may apply CRLF filtering or
  /// other types of changes depending on the file attributes set for the blob
  /// and the content detected in it.
  ///
  /// [asPath] is path used for file attribute lookups, etc.
  ///
  /// [flags] is a combination of [GitBlobFilter] flags to use for filtering
  /// the blob. Defaults to none.
  ///
  /// [attributesCommit] is the commit to load attributes from, when
  /// [GitBlobFilter.attributesFromCommit] is provided in [flags].
  ///
  /// Throws a [LibGit2Error] if error occured.
  String filterContent({
    required String asPath,
    Set<GitBlobFilter> flags = const {},
    Commit? attributesCommit,
  }) {
    return bindings.filterContent(
      blobPointer: _blobPointer,
      asPath: asPath,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      attributesCommit: attributesCommit?.oid.pointer.ref,
    );
  }

  /// Releases memory allocated for blob object.
  void free() => bindings.free(_blobPointer);

  @override
  String toString() {
    return 'Blob{oid: $oid, isBinary: $isBinary, size: $size}';
  }
}
