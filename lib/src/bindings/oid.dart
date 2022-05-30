import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Parse N characters of a hex formatted object id into a git_oid.
Pointer<git_oid> fromStrN(String hex) {
  final out = calloc<git_oid>();
  final hexC = hex.toChar();
  libgit2.git_oid_fromstrn(out, hexC, hex.length);

  calloc.free(hexC);

  return out;
}

/// Parse a hex formatted object id into a git_oid.
Pointer<git_oid> fromSHA(String hex) {
  final out = calloc<git_oid>();
  final hexC = hex.toChar();
  libgit2.git_oid_fromstr(out, hexC);

  calloc.free(hexC);

  return out;
}

/// Copy an already raw oid into a git_oid structure.
Pointer<git_oid> fromRaw(Array<UnsignedChar> raw) {
  final out = calloc<git_oid>();
  final rawC = calloc<UnsignedChar>(20);

  for (var i = 0; i < 20; i++) {
    rawC[i] = raw[i];
  }

  libgit2.git_oid_fromraw(out, rawC);

  calloc.free(rawC);

  return out;
}

/// Format a git_oid into a hex string.
String toSHA(Pointer<git_oid> id) {
  final out = calloc<Char>(40);
  libgit2.git_oid_fmt(out, id);

  final result = out.toDartString(length: 40);
  calloc.free(out);
  return result;
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

/// Copy an oid from one structure to another.
Pointer<git_oid> copy(Pointer<git_oid> src) {
  final out = calloc<git_oid>();
  libgit2.git_oid_cpy(out, src);
  return out;
}
