import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/blob.dart' as bindings;
import 'bindings/patch.dart' as patch_bindings;

class Blob {
  /// Initializes a new instance of [Blob] class from provided pointer to
  /// blob object in memory.
  ///
  /// Should be freed to release allocated memory.
  Blob(this._blobPointer);

  /// Lookups a blob object for provided [oid] in a [repo]sitory.
  ///
  /// Should be freed to release allocated memory.
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
    return Oid(bindings.create(
      repoPointer: repo.pointer,
      buffer: content,
      len: content.length,
    ));
  }

  /// Creates a new blob from the file in working directory of a repository and writes
  /// it to the ODB. Provided [relativePath] should be relative to the working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromWorkdir({
    required Repository repo,
    required String relativePath,
  }) {
    return Oid(bindings.createFromWorkdir(
      repoPointer: repo.pointer,
      relativePath: relativePath,
    ));
  }

  /// Creates a new blob from the file in filesystem and writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromDisk({required Repository repo, required String path}) {
    return Oid(bindings.createFromDisk(repoPointer: repo.pointer, path: path));
  }

  /// Returns the [Oid] of the blob.
  Oid get oid => Oid(bindings.id(_blobPointer));

  /// Determines if the blob content is most certainly binary or not.
  ///
  /// The heuristic used to guess if a file is binary is taken from core git:
  /// Searching for NUL bytes and looking for a reasonable ratio of printable to
  /// non-printable characters among the first 8000 bytes.
  bool get isBinary => bindings.isBinary(_blobPointer);

  /// Returns a read-only buffer with the raw content of a blob.
  String get content => bindings.content(_blobPointer);

  /// Returns the size in bytes of the contents of a blob.
  int get size => bindings.size(_blobPointer);

  /// Directly generate a [Patch] from the difference between two blobs.
  ///
  /// Should be freed with `free()` to release allocated memory.
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
    final result = patch_bindings.fromBlobs(
      oldBlobPointer: _blobPointer,
      oldAsPath: oldAsPath,
      newBlobPointer: newBlob?.pointer ?? nullptr,
      newAsPath: newAsPath,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );

    return Patch(
      result['patch'] as Pointer<git_patch>,
      result['a'],
      result['b'],
    );
  }

  /// Directly generate a [Patch] from the difference between the blob and a buffer.
  ///
  /// Should be freed with `free()` to release allocated memory.
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
    final result = patch_bindings.fromBlobAndBuffer(
      oldBlobPointer: _blobPointer,
      oldAsPath: oldAsPath,
      buffer: buffer,
      bufferAsPath: bufferAsPath,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      contextLines: contextLines,
      interhunkLines: interhunkLines,
    );

    return Patch(
      result['patch'] as Pointer<git_patch>,
      result['a'],
      result['b'],
    );
  }

  /// Releases memory allocated for blob object.
  void free() => bindings.free(_blobPointer);

  @override
  String toString() {
    return 'Blob{oid: $oid, isBinary: $isBinary, size: $size}';
  }
}
