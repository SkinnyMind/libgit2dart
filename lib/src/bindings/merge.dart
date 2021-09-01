import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Find a merge base between two commits.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> mergeBase(
  Pointer<git_repository> repo,
  Pointer<git_oid> one,
  Pointer<git_oid> two,
) {
  final out = calloc<git_oid>();
  final error = libgit2.git_merge_base(out, repo, one, two);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}
