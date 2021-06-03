import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Attempt to open an already-existing repository at [path].
///
/// The [path] can point to either a normal or bare repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<Pointer<git_repository>> open(String path) {
  final out = calloc<Pointer<git_repository>>();
  final pathC = path.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_repository_open(out, pathC);
  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out;
}

/// Attempt to open an already-existing bare repository at [bare_path].
///
/// The [bare_path] can point to only a bare repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<Pointer<git_repository>> openBare(String barePath) {
  final out = calloc<Pointer<git_repository>>();
  final barePathC = barePath.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_repository_open_bare(out, barePathC);
  calloc.free(barePathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out;
}

/// Returns the path to the `.git` folder for normal repositories or the
/// repository itself for bare repositories.
String path(Pointer<git_repository> repo) {
  final path = libgit2.git_repository_path(repo);
  return path.cast<Utf8>().toDartString();
}

/// Get the currently active namespace for this repository.
///
/// If there is no namespace, or the namespace is not a valid utf8 string,
/// empty string is returned.
String getNamespace(Pointer<git_repository> repo) {
  final namespace = libgit2.git_repository_get_namespace(repo);
  if (namespace == nullptr) {
    return '';
  } else {
    return namespace.cast<Utf8>().toDartString();
  }
}

/// Tests whether this repository is a bare repository or not.
bool isBare(Pointer<git_repository> repo) {
  final result = libgit2.git_repository_is_bare(repo);
  return result == 1 ? true : false;
}

/// Find a single object, as specified by a [spec] string.
///
/// Throws a [LibGit2Error] if error occured.
///
/// The returned object should be released when no longer needed.
Pointer<Pointer<git_object>> revParseSingle(
  Pointer<git_repository> repo,
  String spec,
) {
  final out = calloc<Pointer<git_object>>();
  final specC = spec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_revparse_single(
    out,
    repo,
    specC,
  );
  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  return out;
}
