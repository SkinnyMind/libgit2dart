// coverage:ignore-file

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/libgit2_opts_bindings.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

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

/// Returns location of the most recent verison of the libgit2dart package
/// contained in the cache.
String? checkCache() {
  final cache = json.decode(
    Process.runSync('dart', ['pub', 'cache', 'list']).stdout as String,
  ) as Map<String, dynamic>;
  final packages = cache['packages'] as Map<String, dynamic>;
  final libPackages = packages['libgit2dart'] as Map<String, dynamic>?;
  final versions = libPackages?.keys.map((e) => Version.parse(e)).toList();
  final latestVersion = libPackages?[Version.primary(versions!).toString()]
      as Map<String, dynamic>?;
  return latestVersion?['location'] as String?;
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

  // If lib is in '.pub_cache' folder.
  final cachedLocation = checkCache();
  if (cachedLocation != null) {
    libPath = path.join(cachedLocation, Platform.operatingSystem, name);
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
