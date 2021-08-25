import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/oid.dart' as bindings;
import 'odb.dart';
import 'util.dart';

class Oid {
  /// Initializes a new instance of [Oid] class from provided
  /// pointer to Oid object in memory.
  Oid(this._oidPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Oid] class from provided
  /// hexadecimal [sha] string.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid.fromSHA(String sha) {
    libgit2.git_libgit2_init();

    _oidPointer = bindings.fromSHA(sha);
  }

  /// Initializes a new instance of [Oid] class by determining if an object can be found
  /// in the object database of repository with provided hexadecimal [sha] string that is
  /// lesser than 40 characters long and [Odb] object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid.fromShortSHA(String sha, Odb odb) {
    libgit2.git_libgit2_init();
    _oidPointer = odb.existsPrefix(bindings.fromStrN(sha), sha.length);
  }

  late final Pointer<git_oid> _oidPointer;

  /// Pointer to memory address for allocated oid object.
  Pointer<git_oid> get pointer => _oidPointer;

  /// Returns hexadecimal SHA-1 string.
  String get sha => bindings.toSHA(_oidPointer);

  @override
  bool operator ==(other) {
    return (other is Oid) &&
        (bindings.compare(_oidPointer, other._oidPointer) == 0);
  }

  bool operator <(other) {
    return (other is Oid) &&
        (bindings.compare(_oidPointer, other._oidPointer) == -1);
  }

  bool operator <=(other) {
    return (other is Oid) &&
        (bindings.compare(_oidPointer, other._oidPointer) == -1);
  }

  bool operator >(other) {
    return (other is Oid) &&
        (bindings.compare(_oidPointer, other._oidPointer) == 1);
  }

  bool operator >=(other) {
    return (other is Oid) &&
        (bindings.compare(_oidPointer, other._oidPointer) == 1);
  }

  @override
  int get hashCode => _oidPointer.address.hashCode;
}
