import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/blob.dart' as bindings;
import 'oid.dart';
import 'repository.dart';

class Blob {
  /// Initializes a new instance of [Blob] class from provided
  /// [Repository] and [Oid] objects.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Blob.lookup(Repository repo, Oid oid) {
    _blobPointer = bindings.lookup(repo.pointer, oid.pointer);
  }

  late final Pointer<git_blob> _blobPointer;

  /// Pointer to memory address for allocated blob object.
  Pointer<git_blob> get pointer => _blobPointer;

  /// Creates a new blob from a [content] string and writes it to ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create(Repository repo, String content) {
    return Oid(bindings.create(repo.pointer, content, content.length));
  }

  /// Creates a new blob from the file in working directory of a repository and writes
  /// it to the ODB. Provided [relativePath] should be relative to the working directory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromWorkdir(Repository repo, String relativePath) {
    return Oid(bindings.createFromWorkdir(repo.pointer, relativePath));
  }

  /// Creates a new blob from the file in filesystem and writes it to the ODB.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid createFromDisk(Repository repo, String path) {
    return Oid(bindings.createFromDisk(repo.pointer, path));
  }

  /// Returns the Oid of the blob.
  Oid get id => Oid(bindings.id(_blobPointer));

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

  /// Releases memory allocated for blob object.
  void free() => bindings.free(_blobPointer);
}
