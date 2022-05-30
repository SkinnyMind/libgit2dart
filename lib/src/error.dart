// coverage:ignore-file

import 'dart:ffi';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';

/// Details of the last error that occurred.
class LibGit2Error {
  LibGit2Error(this._errorPointer);

  final Pointer<git_error> _errorPointer;

  @override
  String toString() => _errorPointer.ref.message.toDartString();
}
