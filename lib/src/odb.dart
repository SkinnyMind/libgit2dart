import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/odb.dart' as bindings;

class Odb {
  /// Initializes a new instance of [Odb] class from provided
  /// pointer to Odb object in memory.
  const Odb(this._odbPointer);

  final Pointer<git_odb> _odbPointer;

  /// Pointer to memory address for allocated oid object.
  Pointer<git_odb> get pointer => _odbPointer;

  /// Determine if an object can be found in the object database by an abbreviated object ID.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Pointer<git_oid> existsPrefix(
    Pointer<git_oid> shortOid,
    int len,
  ) {
    return bindings.existsPrefix(_odbPointer, shortOid, len);
  }

  /// Releases memory allocated for odb object.
  void free() => bindings.free(_odbPointer);
}
