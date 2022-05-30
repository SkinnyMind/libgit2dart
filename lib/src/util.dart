// coverage:ignore-file

import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/libgit2_opts_bindings.dart';
import 'package:path/path.dart' as path;
import 'package:pub_cache/pub_cache.dart';

const libgit2Version = '1.4.3';
final libDir = path.join('.dart_tool', 'libgit2');

String getLibName() {
  var ext = 'so';

  if (Platform.isWindows) {
    ext = 'dll';
  } else if (Platform.isMacOS) {
    ext = 'dylib';
  } else if (!Platform.isLinux) {
    throw Exception('Unsupported platform.');
  }

  return 'libgit2-$libgit2Version.$ext';
}

/// Checks if [File]/[Link] exists for [path].
bool _doesFileExist(String path) {
  return File(path).existsSync() || Link(path).existsSync();
}

/// Returns path to dynamic library if found.
String? _resolveLibPath(String name) {
  var libPath = path.join(Directory.current.path, name);

  // If lib is in Present Working Directory.
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in Present Working Directory's '.dart_tool/libgit2/[platform]' folder.
  libPath = path.join(
    Directory.current.path,
    libDir,
    Platform.operatingSystem,
    name,
  );
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in Present Working Directory's '[platform]' folder.
  libPath = path.join(Directory.current.path, Platform.operatingSystem, name);
  if (_doesFileExist(libPath)) return libPath;

  String checkCache(PubCache pubCache) {
    final pubCacheDir =
        pubCache.getLatestVersion('libgit2dart')!.resolve()!.location;
    return path.join(pubCacheDir.path, Platform.operatingSystem, name);
  }

  // If lib is in Dart's '.pub_cache' folder.
  libPath = checkCache(PubCache());
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in Flutter's '.pub_cache' folder.
  final env = Platform.environment;
  if (env.containsKey('FLUTTER_ROOT')) {
    final flutterPubCache =
        PubCache(Directory(path.join(env['FLUTTER_ROOT']!, '.pub-cache')));
    libPath = checkCache(flutterPubCache);
    if (_doesFileExist(libPath)) return libPath;
  }

  return null;
}

DynamicLibrary loadLibrary(String name) {
  try {
    return DynamicLibrary.open(
      _resolveLibPath(name) ?? name,
    );
  } catch (e) {
    stderr.writeln(
      'Failed to open the library. Make sure that libgit2 library is bundled '
      'with the application.',
    );
    rethrow;
  }
}

final libgit2 = Libgit2(loadLibrary(getLibName()));
final libgit2Opts = Libgit2Opts(loadLibrary(getLibName()));
