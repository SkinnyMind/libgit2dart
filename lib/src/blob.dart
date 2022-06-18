import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/blob.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:meta/meta.dart';

@immutable
class Blob extends Equatable {
  /// Initializes a new instance of [Blob] class from provided pointer to
  /// blob object in memory.
  ///
  /// Note: For internal use. Use [Blob.lookup] instead.
  @internal
  Blob(this._blobPointer) {
    _finalizer.attach(this, _blobPointer, detach: this);
  }

  /// Lookups a blob object for provided [oid] in a [repo]sitory.
  Blob.lookup({required Repository repo, required Oid oid}) {
    _blobPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
    _finalizer.attach(this, _blobPointer, detach: this);
  }

  late final Pointer<git_blob> _blobPointer;

  /// Pointer to memory address for allocated blob object.
  ///
  /// Note: For internal use.
  @internal
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
  Blob duplicate() => Blob(bindings.duplicate(_blobPointer));

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
  void free() {
    bindings.free(_blobPointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Blob{oid: $oid, isBinary: $isBinary, size: $size}';
  }

  @override
  List<Object?> get props => [oid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_blob>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
