import 'dart:ffi';
import 'dart:io';
import 'bindings/libgit2_bindings.dart';

DynamicLibrary loadLibrary() {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2-1.1.0/libgit2.so');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2-1.1.0/libgit2.dylib');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2-1.1.0/libgit2.dll');
  }
  throw Exception('Platform not implemented');
}

final libgit2 = Libgit2(loadLibrary());
