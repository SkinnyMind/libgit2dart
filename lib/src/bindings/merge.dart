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

/// Analyzes the given branch(es) and determines the opportunities for merging them
/// into a reference.
///
/// Throws a [LibGit2Error] if error occured.
List<int> analysis(
  Pointer<git_repository> repo,
  Pointer<git_reference> ourRef,
  Pointer<Pointer<git_annotated_commit>> theirHead,
  int theirHeadsLen,
) {
  final analysisOut = calloc<Int32>();
  final preferenceOut = calloc<Int32>();
  final error = libgit2.git_merge_analysis_for_ref(
    analysisOut,
    preferenceOut,
    repo,
    ourRef,
    theirHead,
    theirHeadsLen,
  );
  var result = <int>[];

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    result.add(analysisOut.value);
    result.add(preferenceOut.value);
    calloc.free(analysisOut);
    calloc.free(preferenceOut);
    return result;
  }
}
