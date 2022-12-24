// coverage:ignore-file

import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/libgit2_opts_bindings.dart';
import 'package:path/path.dart' as path;
import 'package:pub_cache/pub_cache.dart';

const libgit2Version = '1.5.0';
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
  // If lib is in Present Working Directory's '.dart_tool/libgit2/[platform]' folder.
  var libPath = path.join(
    Directory.current.path,
    libDir,
    Platform.operatingSystem,
    name,
  );
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in Present Working Directory's '[platform]' folder.
  libPath = path.join(Directory.current.path, Platform.operatingSystem, name);
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in executable's folder.
  libPath = path.join(path.dirname(Platform.resolvedExecutable), name);
  if (_doesFileExist(libPath)) return libPath;

  // If lib is in executable's bundled 'lib' folder.
  libPath = path.join(path.dirname(Platform.resolvedExecutable), 'lib', name);
  if (_doesFileExist(libPath)) return libPath;

  // If lib is installed in system dir.
  if (Platform.isMacOS || Platform.isLinux) {
    final paths = [
      '/usr/local/lib/libgit2.$libgit2Version.dylib',
      '/usr/local/lib/libgit2.so.$libgit2Version',
      '/usr/lib64/libgit2.so.$libgit2Version'
    ];
    for (final path in paths) {
      if (_doesFileExist(path)) return path;
    }
  }

  String checkCache(PubCache pubCache) {
    final pubCacheDir =
        pubCache.getLatestVersion('libgit2dart')!.resolve()!.location;
    return path.join(pubCacheDir.path, Platform.operatingSystem, name);
  }

  // If lib is in Flutter's '.pub_cache' folder.
  final env = Platform.environment;
  if (env.containsKey('FLUTTER_ROOT')) {
    libPath = checkCache(PubCache());
    if (_doesFileExist(libPath)) return libPath;
  }

  return null;
}

DynamicLibrary loadLibrary(String name) {
  try {
    return DynamicLibrary.open(_resolveLibPath(name) ?? name);
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
