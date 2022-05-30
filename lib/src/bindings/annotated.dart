import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Creates an annotated commit from the given commit id. The returned
/// annotated commit must be freed with [annotatedFree].
///
/// An annotated commit contains information about how it was looked up, which
/// may be useful for functions like merge or rebase to provide context to the
/// operation. For example, conflict files will include the name of the source
/// or target branches being merged. It is therefore preferable to use the most
/// specific function (e.g. [annotatedFromRef]) instead of this one when that
/// data is known.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_annotated_commit> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final error = libgit2.git_annotated_commit_lookup(
    out,
    repoPointer,
    oidPointer,
  );

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Creates an annotated commit from the given reference. The returned
/// annotated commit must be freed with [annotatedFree].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_annotated_commit> fromRef({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_reference> referencePointer,
}) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final error = libgit2.git_annotated_commit_from_ref(
    out,
    repoPointer,
    referencePointer,
  );

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Creates an annotated commit from a revision string. The returned
/// annotated commit must be freed with [annotatedFree].
///
/// See `man gitrevisions`, or http://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
/// for information on the syntax accepted.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_annotated_commit> fromRevSpec({
  required Pointer<git_repository> repoPointer,
  required String revspec,
}) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final revspecC = revspec.toChar();
  final error = libgit2.git_annotated_commit_from_revspec(
    out,
    repoPointer,
    revspecC,
  );

  final result = out.value;

  calloc.free(revspecC);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Creates an annotated commit from the given fetch head data. The returned
/// annotated commit must be freed with [annotatedFree].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_annotated_commit> fromFetchHead({
  required Pointer<git_repository> repoPointer,
  required String branchName,
  required String remoteUrl,
  required Pointer<git_oid> oid,
}) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final branchNameC = branchName.toChar();
  final remoteUrlC = remoteUrl.toChar();
  final error = libgit2.git_annotated_commit_from_fetchhead(
    out,
    repoPointer,
    branchNameC,
    remoteUrlC,
    oid,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(branchNameC);
  calloc.free(remoteUrlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Gets the commit ID that the given annotated commit refers to.
Pointer<git_oid> oid(Pointer<git_annotated_commit> commit) =>
    libgit2.git_annotated_commit_id(commit);

/// Get the refname that the given annotated commit refers to.
String refName(Pointer<git_annotated_commit> commit) {
  final result = libgit2.git_annotated_commit_ref(commit);
  return result == nullptr ? '' : result.toDartString();
}

/// Frees an annotated commit.
void free(Pointer<git_annotated_commit> commit) {
  libgit2.git_annotated_commit_free(commit);
}
