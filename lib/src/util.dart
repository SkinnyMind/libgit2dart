import 'dart:io';
import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'git_types.dart';

DynamicLibrary loadLibrary() {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2-1.1.1.so');
  }
  if (Platform.isMacOS) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2-1.1.1.dylib');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(
        '${Directory.current.path}/libgit2/libgit2-1.1.1.dll');
  }
  throw Exception('Platform not implemented');
}

final libgit2 = Libgit2(loadLibrary());

bool isValidShaHex(String str) {
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(str) &&
      (GIT_OID_MINPREFIXLEN <= str.length && GIT_OID_HEXSZ >= str.length);
}

GitFilemode intToGitFilemode(int i) {
  switch (i) {
    case 0:
      return GitFilemode.unreadable;
    case 16384:
      return GitFilemode.tree;
    case 33188:
      return GitFilemode.blob;
    case 33261:
      return GitFilemode.blobExecutable;
    case 40960:
      return GitFilemode.link;
    case 57344:
      return GitFilemode.commit;
    default:
      return GitFilemode.unreadable;
  }
}
