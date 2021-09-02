import 'dart:io';
import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'enums.dart';

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
      return GitFilemode.undreadable;
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
      return GitFilemode.undreadable;
  }
}

int gitFilemodeToInt(GitFilemode filemode) {
  switch (filemode) {
    case GitFilemode.undreadable:
      return 0;
    case GitFilemode.tree:
      return 16384;
    case GitFilemode.blob:
      return 33188;
    case GitFilemode.blobExecutable:
      return 33261;
    case GitFilemode.link:
      return 40960;
    case GitFilemode.commit:
      return 57344;
  }
}
