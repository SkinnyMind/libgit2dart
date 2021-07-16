import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Parse a hex formatted object id into a git_oid.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> fromSHA(String hex) {
  final out = calloc<git_oid>();
  final str = hex.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_oid_fromstr(out, str);
  calloc.free(str);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Format a git_oid into a hex string.
///
/// Throws a [LibGit2Error] if error occured.
String toSHA(Pointer<git_oid> id) {
  final out = calloc.allocate<Int8>(40);
  final error = libgit2.git_oid_fmt(out, id);
  final result = out.cast<Utf8>().toDartString(length: 40);
  malloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Compare two oid structures.
///
/// Returns <0 if a < b, 0 if a == b, >0 if a > b.
int compare(Pointer<git_oid> a, Pointer<git_oid> b) {
  return libgit2.git_oid_cmp(a, b);
}
