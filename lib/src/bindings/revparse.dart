import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Parse a revision string for from, to, and intent.
///
/// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_revspec> revParse({
  required Pointer<git_repository> repoPointer,
  required String spec,
}) {
  final out = calloc<git_revspec>();
  final specC = spec.toChar();

  final error = libgit2.git_revparse(out, repoPointer, specC);

  calloc.free(specC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Find a single object, as specified by a [spec] revision string.
/// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// The returned object should be freed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_object> revParseSingle({
  required Pointer<git_repository> repoPointer,
  required String spec,
}) {
  final out = calloc<Pointer<git_object>>();
  final specC = spec.toChar();

  final error = libgit2.git_revparse_single(out, repoPointer, specC);

  final result = out.value;

  calloc.free(out);
  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Find a single object and intermediate reference by a [spec] revision string.
///
/// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may
/// point to an intermediate reference. When such expressions are being passed
/// in, reference_out will be valued as well.
///
/// The returned object and reference should be freed.
///
/// Throws a [LibGit2Error] if error occured.
List<Pointer> revParseExt({
  required Pointer<git_repository> repoPointer,
  required String spec,
}) {
  final objectOut = calloc<Pointer<git_object>>();
  final referenceOut = calloc<Pointer<git_reference>>();
  final specC = spec.toChar();

  final error = libgit2.git_revparse_ext(
    objectOut,
    referenceOut,
    repoPointer,
    specC,
  );

  final result = <Pointer>[objectOut.value];
  if (referenceOut.value != nullptr) {
    result.add(referenceOut.value);
  }

  calloc.free(objectOut);
  calloc.free(referenceOut);
  calloc.free(specC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}
