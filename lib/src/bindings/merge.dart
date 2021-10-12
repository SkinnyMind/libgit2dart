import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Find a merge base between two commits.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> mergeBase({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> aPointer,
  required Pointer<git_oid> bPointer,
}) {
  final out = calloc<git_oid>();
  final error = libgit2.git_merge_base(out, repoPointer, aPointer, bPointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Analyzes the given branch(es) and determines the opportunities for merging them
/// into a reference.
///
/// Throws a [LibGit2Error] if error occured.
List<int> analysis({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_reference> ourRefPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadPointer,
  required int theirHeadsLen,
}) {
  final analysisOut = calloc<Int32>();
  final preferenceOut = calloc<Int32>();
  final error = libgit2.git_merge_analysis_for_ref(
    analysisOut,
    preferenceOut,
    repoPointer,
    ourRefPointer,
    theirHeadPointer,
    theirHeadsLen,
  );
  var result = <int>[];

  if (error < 0) {
    calloc.free(analysisOut);
    calloc.free(preferenceOut);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    result.add(analysisOut.value);
    result.add(preferenceOut.value);
    calloc.free(analysisOut);
    calloc.free(preferenceOut);
    return result;
  }
}

/// Merges the given commit(s) into HEAD, writing the results into the working directory.
/// Any changes are staged for commit and any conflicts are written to the index. Callers
/// should inspect the repository's index after this completes, resolve any conflicts and
/// prepare a commit.
///
/// Throws a [LibGit2Error] if error occured.
void merge({
  required Pointer<git_repository> repoPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadsPointer,
  required int theirHeadsLen,
}) {
  final mergeOpts = calloc<git_merge_options>();
  final mergeError = libgit2.git_merge_options_init(
    mergeOpts,
    GIT_MERGE_OPTIONS_VERSION,
  );

  if (mergeError < 0) {
    calloc.free(mergeOpts);
    throw LibGit2Error(libgit2.git_error_last());
  }

  final checkoutOpts = calloc<git_checkout_options>();
  final checkoutError = libgit2.git_checkout_options_init(
    checkoutOpts,
    GIT_CHECKOUT_OPTIONS_VERSION,
  );

  if (checkoutError < 0) {
    calloc.free(mergeOpts);
    calloc.free(checkoutOpts);
    throw LibGit2Error(libgit2.git_error_last());
  }

  checkoutOpts.ref.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE |
          git_checkout_strategy_t.GIT_CHECKOUT_RECREATE_MISSING;

  final error = libgit2.git_merge(
    repoPointer,
    theirHeadsPointer,
    theirHeadsLen,
    mergeOpts,
    checkoutOpts,
  );

  calloc.free(mergeOpts);
  calloc.free(checkoutOpts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Merge two files as they exist in the index, using the given common ancestor
/// as the baseline, producing a string that reflects the merge result containing
/// possible conflicts.
///
/// Throws a [LibGit2Error] if error occured.
String mergeFileFromIndex({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_index_entry>? ancestorPointer,
  required Pointer<git_index_entry>? oursPointer,
  required Pointer<git_index_entry>? theirsPointer,
}) {
  final out = calloc<git_merge_file_result>();
  final error = libgit2.git_merge_file_from_index(
    out,
    repoPointer,
    ancestorPointer ?? nullptr,
    oursPointer ?? nullptr,
    theirsPointer ?? nullptr,
    nullptr,
  );

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString(length: out.ref.len);
    calloc.free(out);
    return result;
  }
}

/// Merge two commits, producing a git_index that reflects the result of the merge.
/// The index may be written as-is to the working directory or checked out. If the index
/// is to be converted to a tree, the caller should resolve any conflicts that arose as
/// part of the merge.
///
/// The returned index must be freed explicitly.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> mergeCommits({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> ourCommitPointer,
  required Pointer<git_commit> theirCommitPointer,
  required int favor,
  required int mergeFlags,
  required int fileFlags,
}) {
  final out = calloc<Pointer<git_index>>();
  final opts = _initMergeOptions(
    favor: favor,
    mergeFlags: mergeFlags,
    fileFlags: fileFlags,
  );

  final error = libgit2.git_merge_commits(
    out,
    repoPointer,
    ourCommitPointer,
    theirCommitPointer,
    opts,
  );

  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Merge two trees, producing a git_index that reflects the result of the merge.
/// The index may be written as-is to the working directory or checked out. If the index
/// is to be converted to a tree, the caller should resolve any conflicts that arose as part
/// of the merge.
///
/// The returned index must be freed explicitly.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> mergeTrees({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree> ancestorTreePointer,
  required Pointer<git_tree> ourTreePointer,
  required Pointer<git_tree> theirTreePointer,
  required int favor,
  required int mergeFlags,
  required int fileFlags,
}) {
  final out = calloc<Pointer<git_index>>();
  final opts = _initMergeOptions(
    favor: favor,
    mergeFlags: mergeFlags,
    fileFlags: fileFlags,
  );

  final error = libgit2.git_merge_trees(
    out,
    repoPointer,
    ancestorTreePointer,
    ourTreePointer,
    theirTreePointer,
    opts,
  );

  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Cherry-pick the given commit, producing changes in the index and working directory.
///
/// Throws a [LibGit2Error] if error occured.
void cherryPick({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> commitPointer,
}) {
  final opts = calloc<git_cherrypick_options>();
  final optsError = libgit2.git_cherrypick_options_init(
    opts,
    GIT_CHERRYPICK_OPTIONS_VERSION,
  );

  if (optsError < 0) {
    calloc.free(opts);
    throw LibGit2Error(libgit2.git_error_last());
  }

  opts.ref.checkout_opts.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE;

  final error = libgit2.git_cherrypick(repoPointer, commitPointer, opts);

  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

Pointer<git_merge_options> _initMergeOptions({
  required int favor,
  required int mergeFlags,
  required int fileFlags,
}) {
  final opts = calloc<git_merge_options>();
  final error = libgit2.git_merge_options_init(
    opts,
    GIT_MERGE_OPTIONS_VERSION,
  );

  if (error < 0) {
    calloc.free(opts);
    throw LibGit2Error(libgit2.git_error_last());
  }

  opts.ref.file_favor = favor;
  opts.ref.flags = mergeFlags;
  opts.ref.file_flags = fileFlags;

  return opts;
}
