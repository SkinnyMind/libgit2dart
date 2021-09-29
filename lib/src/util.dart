import 'dart:io';
import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';

DynamicLibrary loadLibrary() {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2.so.1.3.0');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2-1.2.0.dylib');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2-1.2.0.dll');
  }
  throw Exception('Platform not implemented');
}

final libgit2 = Libgit2(loadLibrary());

bool isValidShaHex(String str) {
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(str) &&
      (GIT_OID_MINPREFIXLEN <= str.length && GIT_OID_HEXSZ >= str.length);
}
