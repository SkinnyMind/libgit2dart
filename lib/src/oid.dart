import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/oid.dart' as bindings;
import 'repository.dart';
import 'util.dart';

class Oid {
  /// Initializes a new instance of [Oid] class from provided
  /// pointer to Oid object in memory.
  Oid(this._oidPointer) {
    libgit2.git_libgit2_init();
  }

  /// Initializes a new instance of [Oid] class by determining if an object can be found
  /// in the ODB of [repository] with provided hexadecimal [sha] string that is 40 characters
  /// long or shorter.
  ///
  /// Throws [ArgumentError] if provided [sha] hex string is not valid.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid.fromSHA(Repository repository, String sha) {
    if (isValidShaHex(sha)) {
      if (sha.length == 40) {
        _oidPointer = bindings.fromSHA(sha);
      } else {
        final odb = repository.odb;
        _oidPointer = odb.existsPrefix(bindings.fromStrN(sha), sha.length);
        odb.free();
      }
    } else {
      throw ArgumentError.value('$sha is not a valid sha hex string');
    }
  }

  /// Initializes a new instance of [Oid] class from provided raw git_oid.
  Oid.fromRaw(git_oid raw) {
    libgit2.git_libgit2_init();
    _oidPointer = bindings.fromRaw(raw.id);
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
