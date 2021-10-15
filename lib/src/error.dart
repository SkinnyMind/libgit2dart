import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';

/// Details of the last error that occurred.
class LibGit2Error {
  LibGit2Error(this._errorPointer);

  final Pointer<git_error> _errorPointer;

  @override
  String toString() {
    return _errorPointer.ref.message.cast<Utf8>().toDartString();
  }
}
