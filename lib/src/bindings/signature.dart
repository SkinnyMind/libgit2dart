import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Create a new action signature.
///
/// Note: angle brackets ('<' and '>') characters are not allowed to be used in
/// either the name or the email parameter.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_signature> create(
  String name,
  String email,
  int time,
  int offset,
) {
  final out = calloc<Pointer<git_signature>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final emailC = email.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_signature_new(out, nameC, emailC, time, offset);

  calloc.free(nameC);
  calloc.free(emailC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new action signature with a timestamp of 'now'.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_signature> now(String name, String email) {
  final out = calloc<Pointer<git_signature>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final emailC = email.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_signature_now(out, nameC, emailC);

  calloc.free(nameC);
  calloc.free(emailC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new action signature with default user and now timestamp.
///
/// This looks up the user.name and user.email from the configuration and uses the
/// current time as the timestamp, and creates a new signature based on that information.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_signature> defaultSignature(Pointer<git_repository> repo) {
  final out = calloc<Pointer<git_signature>>();
  final error = libgit2.git_signature_default(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Free an existing signature.
void free(Pointer<git_signature> sig) => libgit2.git_signature_free(sig);
