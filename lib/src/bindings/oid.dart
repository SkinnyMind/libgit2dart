import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Parse N characters of a hex formatted object id into a git_oid.
///
/// If N is odd, the last byte's high nibble will be read in and the low nibble set to zero.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> fromStrN(String hex) {
  final out = calloc<git_oid>();
  final str = hex.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_oid_fromstrn(out, str, hex.length);
  calloc.free(str);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

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

/// Copy an already raw oid into a git_oid structure.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> fromRaw(Array<Uint8> raw) {
  final out = calloc<git_oid>();
  var rawC = calloc<Uint8>(20);
  for (var i = 0; i < 20; i++) {
    rawC[i] = raw[i];
  }
  final error = libgit2.git_oid_fromraw(out, rawC);

  calloc.free(rawC);

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
  final out = calloc<Int8>(40);
  final error = libgit2.git_oid_fmt(out, id);
  final result = out.cast<Utf8>().toDartString(length: 40);

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Compare two oid structures.
///
/// Returns <0 if a < b, 0 if a == b, >0 if a > b.
int compare({
  required Pointer<git_oid> aPointer,
  required Pointer<git_oid> bPointer,
}) {
  return libgit2.git_oid_cmp(aPointer, bPointer);
}
