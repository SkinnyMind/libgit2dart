import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/odb.dart' as bindings;
import 'util.dart';

class Odb {
  /// Initializes a new instance of [Odb] class from provided
  /// pointer to Odb object in memory.
  Odb(this._odbPointer) {
    libgit2.git_libgit2_init();
  }

  /// Pointer to memory address for allocated oid object.
  late final Pointer<git_odb> _odbPointer;

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
  void free() {
    bindings.free(_odbPointer);
    libgit2.git_libgit2_shutdown();
  }
}
