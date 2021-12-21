import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/util.dart';

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

/// Find a merge base given a list of commits.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> mergeBaseMany({
  required Pointer<git_repository> repoPointer,
  required List<git_oid> commits,
}) {
  final out = calloc<git_oid>();
  final commitsC = calloc<git_oid>(commits.length * 20);
  for (var i = 0; i < commits.length; i++) {
    commitsC[i].id = commits[i].id;
  }

  final error = libgit2.git_merge_base_many(
    out,
    repoPointer,
    commits.length,
    commitsC,
  );

  calloc.free(commitsC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Find a merge base in preparation for an octopus merge.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> mergeBaseOctopus({
  required Pointer<git_repository> repoPointer,
  required List<git_oid> commits,
}) {
  final out = calloc<git_oid>();
  final commitsC = calloc<git_oid>(commits.length * 20);
  for (var i = 0; i < commits.length; i++) {
    commitsC[i].id = commits[i].id;
  }

  final error = libgit2.git_merge_base_octopus(
    out,
    repoPointer,
    commits.length,
    commitsC,
  );

  calloc.free(commitsC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Analyzes the given branch(es) and determines the opportunities for merging
/// them into a reference.
List<int> analysis({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_reference> ourRefPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadPointer,
  required int theirHeadsLen,
}) {
  final analysisOut = calloc<Int32>();
  final preferenceOut = calloc<Int32>();
  libgit2.git_merge_analysis_for_ref(
    analysisOut,
    preferenceOut,
    repoPointer,
    ourRefPointer,
    theirHeadPointer,
    theirHeadsLen,
  );

  final result = [analysisOut.value, preferenceOut.value];

  calloc.free(analysisOut);
  calloc.free(preferenceOut);

  return result;
}

/// Merges the given commit(s) into HEAD, writing the results into the working
/// directory. Any changes are staged for commit and any conflicts are written
/// to the index. Callers should inspect the repository's index after this
/// completes, resolve any conflicts and prepare a commit.
void merge({
  required Pointer<git_repository> repoPointer,
  required Pointer<Pointer<git_annotated_commit>> theirHeadsPointer,
  required int theirHeadsLen,
  required int favor,
  required int mergeFlags,
  required int fileFlags,
}) {
  final mergeOpts = _initMergeOptions(
    favor: favor,
    mergeFlags: mergeFlags,
    fileFlags: fileFlags,
  );

  final checkoutOpts = calloc<git_checkout_options>();
  libgit2.git_checkout_options_init(checkoutOpts, GIT_CHECKOUT_OPTIONS_VERSION);

  checkoutOpts.ref.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE |
          git_checkout_strategy_t.GIT_CHECKOUT_RECREATE_MISSING;

  libgit2.git_merge(
    repoPointer,
    theirHeadsPointer,
    theirHeadsLen,
    mergeOpts,
    checkoutOpts,
  );

  calloc.free(mergeOpts);
  calloc.free(checkoutOpts);
}

/// Merge two files as they exist in the in-memory data structures, using the
/// given common ancestor as the baseline, producing a string that reflects the
/// merge result.
///
/// Note that this function does not reference a repository and any
/// configuration must be passed.
String mergeFile({
  required String ancestor,
  required String ancestorLabel,
  required String ours,
  required String oursLabel,
  required String theirs,
  required String theirsLabel,
  required int favor,
  required int flags,
}) {
  final out = calloc<git_merge_file_result>();
  final ancestorC = calloc<git_merge_file_input>();
  final oursC = calloc<git_merge_file_input>();
  final theirsC = calloc<git_merge_file_input>();
  libgit2.git_merge_file_input_init(ancestorC, GIT_MERGE_FILE_INPUT_VERSION);
  libgit2.git_merge_file_input_init(oursC, GIT_MERGE_FILE_INPUT_VERSION);
  libgit2.git_merge_file_input_init(theirsC, GIT_MERGE_FILE_INPUT_VERSION);
  ancestorC.ref.ptr = ancestor.toNativeUtf8().cast<Int8>();
  ancestorC.ref.size = ancestor.length;
  oursC.ref.ptr = ours.toNativeUtf8().cast<Int8>();
  oursC.ref.size = ours.length;
  theirsC.ref.ptr = theirs.toNativeUtf8().cast<Int8>();
  theirsC.ref.size = theirs.length;

  final opts = calloc<git_merge_file_options>();
  libgit2.git_merge_file_options_init(opts, GIT_MERGE_FILE_OPTIONS_VERSION);
  opts.ref.favor = favor;
  opts.ref.flags = flags;
  if (ancestorLabel.isNotEmpty) {
    opts.ref.ancestor_label = ancestorLabel.toNativeUtf8().cast<Int8>();
  }
  if (oursLabel.isNotEmpty) {
    opts.ref.our_label = oursLabel.toNativeUtf8().cast<Int8>();
  }
  if (theirsLabel.isNotEmpty) {
    opts.ref.their_label = theirsLabel.toNativeUtf8().cast<Int8>();
  }

  libgit2.git_merge_file(out, ancestorC, oursC, theirsC, opts);

  calloc.free(ancestorC);
  calloc.free(oursC);
  calloc.free(theirsC);
  calloc.free(opts);

  final result = out.ref.ptr.cast<Utf8>().toDartString(length: out.ref.len);
  calloc.free(out);

  return result;
}

/// Merge two files as they exist in the index, using the given common ancestor
/// as the baseline, producing a string that reflects the merge result
/// containing possible conflicts.
///
/// Throws a [LibGit2Error] if error occured.
String mergeFileFromIndex({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_index_entry>? ancestorPointer,
  required Pointer<git_index_entry> oursPointer,
  required Pointer<git_index_entry> theirsPointer,
}) {
  final out = calloc<git_merge_file_result>();
  final error = libgit2.git_merge_file_from_index(
    out,
    repoPointer,
    ancestorPointer ?? nullptr,
    oursPointer,
    theirsPointer,
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

/// Merge two commits, producing a git_index that reflects the result of the
/// merge. The index may be written as-is to the working directory or checked
/// out. If the index is to be converted to a tree, the caller should resolve
/// any conflicts that arose as part of the merge.
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

/// Merge two trees, producing a git_index that reflects the result of the
/// merge. The index may be written as-is to the working directory or checked
/// out. If the index is to be converted to a tree, the caller should resolve
/// any conflicts that arose as part of the merge.
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

/// Cherry-pick the given commit, producing changes in the index and working
/// directory.
///
/// Throws a [LibGit2Error] if error occured.
void cherryPick({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> commitPointer,
}) {
  final opts = calloc<git_cherrypick_options>();
  libgit2.git_cherrypick_options_init(opts, GIT_CHERRYPICK_OPTIONS_VERSION);

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
  libgit2.git_merge_options_init(opts, GIT_MERGE_OPTIONS_VERSION);

  opts.ref.file_favor = favor;
  opts.ref.flags = mergeFlags;
  opts.ref.file_flags = fileFlags;

  return opts;
}
