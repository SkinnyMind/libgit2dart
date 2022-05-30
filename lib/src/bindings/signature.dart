import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Create a new action signature. The returned signature must be freed with
/// [free].
///
/// Note: angle brackets ('<' and '>') characters are not allowed to be used in
/// either the name or the email parameter.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_signature> create({
  required String name,
  required String email,
  required int time,
  required int offset,
}) {
  final out = calloc<Pointer<git_signature>>();
  final nameC = name.toChar();
  final emailC = email.toChar();
  final error = libgit2.git_signature_new(out, nameC, emailC, time, offset);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);
  calloc.free(emailC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a new action signature with a timestamp of 'now'. The returned
/// signature must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_signature> now({required String name, required String email}) {
  final out = calloc<Pointer<git_signature>>();
  final nameC = name.toChar();
  final emailC = email.toChar();
  final error = libgit2.git_signature_now(out, nameC, emailC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);
  calloc.free(emailC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a new action signature with default user and now timestamp. The
/// returned signature must be freed with [free].
///
/// This looks up the user.name and user.email from the configuration and uses
/// the current time as the timestamp, and creates a new signature based on
/// that information.
Pointer<git_signature> defaultSignature(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_signature>>();
  libgit2.git_signature_default(out, repo);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Create a copy of an existing signature. The returned signature must be
/// freed with [free].
Pointer<git_signature> duplicate(Pointer<git_signature> sig) {
  final out = calloc<Pointer<git_signature>>();
  libgit2.git_signature_dup(out, sig);

  final result = out.value;

  calloc.free(out);

  return result;
}

/// Free an existing signature.
void free(Pointer<git_signature> sig) => libgit2.git_signature_free(sig);
