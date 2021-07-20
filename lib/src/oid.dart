import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/oid.dart' as bindings;
import 'util.dart';

class Oid {
  /// Initializes a new instance of [Oid] class from provided
  /// hexadecimal [sha] string.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid.fromSHA(String sha) {
    libgit2.git_libgit2_init();

    try {
      _oidPointer = bindings.fromSHA(sha);
    } catch (e) {
      rethrow;
    }
  }

  /// Pointer to memory address for allocated oid object.
  late Pointer<git_oid> _oidPointer;

  /// Returns hexadecimal SHA-1 string.
  String get sha {
    try {
      return bindings.toSHA(_oidPointer);
    } catch (e) {
      rethrow;
    }
  }

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
