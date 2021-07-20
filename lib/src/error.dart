import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';

class LibGit2Error {
  LibGit2Error(this.errorPointer);
  final Pointer<git_error> errorPointer;

  @override
  String toString() {
    return errorPointer.ref.message.cast<Utf8>().toDartString();
  }
}
