import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Get the source specifier.
String source(Pointer<git_refspec> refspec) {
  return libgit2.git_refspec_src(refspec).toDartString();
}

/// Get the destination specifier.
String destination(Pointer<git_refspec> refspec) {
  return libgit2.git_refspec_dst(refspec).toDartString();
}

/// Get the force update setting.
bool force(Pointer<git_refspec> refspec) {
  return libgit2.git_refspec_force(refspec) == 1 || false;
}

/// Get the refspec's string.
String string(Pointer<git_refspec> refspec) {
  return libgit2.git_refspec_string(refspec).toDartString();
}

/// Get the refspec's direction.
int direction(Pointer<git_refspec> refspec) =>
    libgit2.git_refspec_direction(refspec);

/// Check if a refspec's source descriptor matches a reference.
bool matchesSource({
  required Pointer<git_refspec> refspecPointer,
  required String refname,
}) {
  final refnameC = refname.toChar();
  final result = libgit2.git_refspec_src_matches(refspecPointer, refnameC);

  calloc.free(refnameC);

  return result == 1 || false;
}

/// Check if a refspec's destination descriptor matches a reference.
bool matchesDestination({
  required Pointer<git_refspec> refspecPointer,
  required String refname,
}) {
  final refnameC = refname.toChar();
  final result = libgit2.git_refspec_dst_matches(refspecPointer, refnameC);

  calloc.free(refnameC);

  return result == 1 || false;
}

/// Transform a reference to its target following the refspec's rules.
///
/// Throws a [LibGit2Error] if error occured.
String transform({
  required Pointer<git_refspec> refspecPointer,
  required String name,
}) {
  final out = calloc<git_buf>();
  final nameC = name.toChar();
  final error = libgit2.git_refspec_transform(out, refspecPointer, nameC);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Transform a target reference to its source reference following the
/// refspec's rules.
///
/// Throws a [LibGit2Error] if error occured.
String rTransform({
  required Pointer<git_refspec> refspecPointer,
  required String name,
}) {
  final out = calloc<git_buf>();
  final nameC = name.toChar();
  final error = libgit2.git_refspec_rtransform(out, refspecPointer, nameC);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}
