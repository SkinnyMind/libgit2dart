// coverage:ignore-file

import 'dart:ffi';
import 'dart:io';

import 'package:cli_util/cli_logging.dart' show Ansi, Logger;
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';

const tag = 'libs-v1.3.0';
const libUrl =
    'https://github.com/SkinnyMind/libgit2dart/releases/download/$tag/';
const libgit2Version = '1.3.0';
const libDir = '.dart_tool/libgit2/';

String getLibName() {
  var ext = 'so';

  if (Platform.isWindows) {
    ext = 'dll';
  } else if (Platform.isMacOS) {
    ext = 'dylib';
  } else if (!(Platform.isLinux || Platform.isAndroid)) {
    throw Exception('Unsupported platform.');
  }

  return 'libgit2-$libgit2Version.$ext';
}

/// Checks if [File]/[Link] exists for an [uri].
bool _doesFileExist(Uri uri) {
  return File.fromUri(uri).existsSync() || Link.fromUri(uri).existsSync();
}

String? _resolveLibUri(String name) {
  var libUri = Directory.current.uri.resolve(name);
  final dartToolDir = '$libDir${Platform.operatingSystem}';

  // If lib is in Present Working Directory.
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  // If lib is in Present Working Directory's .dart_tool folder.
  libUri = Directory.current.uri.resolve('$dartToolDir/$name');
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  return null;
}

DynamicLibrary loadLibrary(String name) {
  try {
    return DynamicLibrary.open(
      _resolveLibUri(name) ?? name,
    );
  } catch (e) {
    final logger = Logger.standard();
    final ansi = Ansi(Ansi.terminalSupportsAnsi);

    logger.stderr(
      '${ansi.red}Failed to open the library. Make sure that required '
      'library is in place.${ansi.none}',
    );
    logger.stdout(
      'To download the library, please run the following command from the '
      'root of your project:',
    );
    logger.stdout(
      '${ansi.yellow}dart run libgit2dart:setup${ansi.none} for '
      'dart application',
    );
    logger.stdout(ansi.none);
    logger.stdout(
      '${ansi.yellow}flutter pub run libgit2dart:setup${ansi.none} for '
      'flutter application',
    );
    logger.stdout(ansi.none);
    rethrow;
  }
}

final libgit2 = Libgit2(loadLibrary(getLibName()));

String getVersionNumber() {
  libgit2.git_libgit2_init();

  final major = calloc<Int32>();
  final minor = calloc<Int32>();
  final rev = calloc<Int32>();
  libgit2.git_libgit2_version(major, minor, rev);

  final version = '${major.value}.${minor.value}.${rev.value}';

  calloc.free(major);
  calloc.free(minor);
  calloc.free(rev);

  return version;
}

bool isValidShaHex(String str) {
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(str) &&
      (GIT_OID_MINPREFIXLEN <= str.length && GIT_OID_HEXSZ >= str.length);
}
