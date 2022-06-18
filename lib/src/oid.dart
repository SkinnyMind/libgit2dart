import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/odb.dart' as odb_bindings;
import 'package:libgit2dart/src/bindings/oid.dart' as bindings;
import 'package:libgit2dart/src/extensions.dart';
import 'package:meta/meta.dart';

@immutable
class Oid extends Equatable {
  /// Initializes a new instance of [Oid] class from provided
  /// pointer to Oid object in memory.
  ///
  /// Note: For internal use. Use [Oid.fromSHA] instead.
  @internal
  Oid(this._oidPointer);

  /// Initializes a new instance of [Oid] class by determining if an object can
  /// be found in the ODB of [repo]sitory with provided hexadecimal [sha]
  /// string that is 40 characters long or shorter.
  ///
  /// Throws [ArgumentError] if provided [sha] hex string is not valid.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Oid.fromSHA({required Repository repo, required String sha}) {
    if (sha.isValidSHA()) {
      if (sha.length == 40) {
        _oidPointer = bindings.fromSHA(sha);
      } else {
        _oidPointer = odb_bindings.existsPrefix(
          odbPointer: repo.odb.pointer,
          shortOidPointer: bindings.fromStrN(sha),
          length: sha.length,
        );
      }
    } else {
      throw ArgumentError.value('$sha is not a valid sha hex string');
    }
  }

  /// Initializes a new instance of [Oid] class from provided raw git_oid
  /// structure.
  ///
  /// Note: For internal use.
  @internal
  Oid.fromRaw(git_oid raw) {
    _oidPointer = bindings.fromRaw(raw.id);
  }

  late final Pointer<git_oid> _oidPointer;

  /// Pointer to memory address for allocated oid object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_oid> get pointer => _oidPointer;

  /// Hexadecimal SHA string.
  String get sha => bindings.toSHA(_oidPointer);

  bool operator <(Oid other) {
    return bindings.compare(
          aPointer: _oidPointer,
          bPointer: other._oidPointer,
        ) ==
        -1;
  }

  bool operator <=(Oid other) {
    return bindings.compare(
          aPointer: _oidPointer,
          bPointer: other._oidPointer,
        ) ==
        -1;
  }

  bool operator >(Oid other) {
    return bindings.compare(
          aPointer: _oidPointer,
          bPointer: other._oidPointer,
        ) ==
        1;
  }

  bool operator >=(Oid other) {
    return bindings.compare(
          aPointer: _oidPointer,
          bPointer: other._oidPointer,
        ) ==
        1;
  }

  @override
  String toString() => 'Oid{sha: $sha}';

  @override
  List<Object?> get props => [sha];
}
