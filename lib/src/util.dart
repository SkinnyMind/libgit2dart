// coverage:ignore-file

import 'dart:ffi';
import 'dart:io';

import 'package:cli_util/cli_logging.dart' show Ansi, Logger;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:path/path.dart' as path;
import 'package:pub_cache/pub_cache.dart';

const libgit2Version = '1.3.0';
const libDir = '.dart_tool/libgit2/';

String getLibName() {
  var ext = 'so';

  if (Platform.isWindows) {
    ext = 'dll';
  } else if (Platform.isMacOS) {
    ext = 'dylib';
  } else if (!(Platform.isLinux)) {
    throw Exception('Unsupported platform.');
  }

  return 'libgit2-$libgit2Version.$ext';
}

/// Checks if [File]/[Link] exists for an [uri].
bool _doesFileExist(Uri uri) {
  return File.fromUri(uri).existsSync() || Link.fromUri(uri).existsSync();
}

/// Returns path to dynamic library if found.
String? _resolveLibUri(String name) {
  var libUri = Directory.current.uri.resolve(name);

  // If lib is in Present Working Directory.
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  // If lib is in Present Working Directory's '.dart_tool/libgit2/[platform]' folder.
  libUri = Directory.current.uri.resolve(
    path.join(libDir, Platform.operatingSystem, name),
  );
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  // If lib is in Present Working Directory's '[platform]' folder.
  libUri = Directory.current.uri.resolve(
    path.join(Platform.operatingSystem, name),
  );
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  // If lib is in '.pub_cache' folder.
  final pubCache = PubCache();
  final pubCacheDir =
      pubCache.getLatestVersion('libgit2dart')!.resolve()!.location;
  libUri = pubCacheDir.uri.resolve(path.join(Platform.operatingSystem, name));
  if (_doesFileExist(libUri)) {
    return libUri.toFilePath(windows: Platform.isWindows);
  }

  return null;
}

DynamicLibrary loadLibrary(String name) {
  final resolvedUri = _resolveLibUri(name);
  try {
    return DynamicLibrary.open(
      resolvedUri ?? name,
    );
  } catch (e) {
    final logger = Logger.standard();
    final ansi = Ansi(Ansi.terminalSupportsAnsi);

    logger.stderr(
      '${ansi.red}Failed to open the library. Make sure that libgit2 '
      'library is bundled with the application.${ansi.none}',
    );
    logger.stdout(ansi.none);
    rethrow;
  }
}

final libgit2 = Libgit2(loadLibrary(getLibName()));

bool isValidShaHex(String str) {
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(str) &&
      (GIT_OID_MINPREFIXLEN <= str.length && GIT_OID_HEXSZ >= str.length);
}
