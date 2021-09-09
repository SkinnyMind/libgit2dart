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

/// Merges the given commit(s) into HEAD, writing the results into the working directory.
/// Any changes are staged for commit and any conflicts are written to the index. Callers
/// should inspect the repository's index after this completes, resolve any conflicts and
/// prepare a commit.
///
/// Throws a [LibGit2Error] if error occured.
void merge(
  Pointer<git_repository> repo,
  Pointer<Pointer<git_annotated_commit>> theirHeads,
  int theirHeadsLen,
) {
  final mergeOpts = calloc<git_merge_options>(sizeOf<git_merge_options>());
  libgit2.git_merge_options_init(mergeOpts, 1);

  final checkoutOpts =
      calloc<git_checkout_options>(sizeOf<git_checkout_options>());
  libgit2.git_checkout_options_init(checkoutOpts, 1);
  checkoutOpts.ref.checkout_strategy =
      git_checkout_strategy_t.GIT_CHECKOUT_SAFE +
          git_checkout_strategy_t.GIT_CHECKOUT_RECREATE_MISSING;

  final error = libgit2.git_merge(
    repo,
    theirHeads,
    theirHeadsLen,
    mergeOpts,
    checkoutOpts,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
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
Pointer<git_index> mergeCommits(
  Pointer<git_repository> repo,
  Pointer<git_commit> ourCommit,
  Pointer<git_commit> theirCommit,
  Map<String, int> opts,
) {
  final out = calloc<Pointer<git_index>>();
  final optsC = calloc<git_merge_options>(sizeOf<git_merge_options>());
  optsC.ref.file_favor = opts['favor']!;
  optsC.ref.flags = opts['mergeFlags']!;
  optsC.ref.file_flags = opts['fileFlags']!;
  optsC.ref.version = GIT_MERGE_OPTIONS_VERSION;

  final error = libgit2.git_merge_commits(
    out,
    repo,
    ourCommit,
    theirCommit,
    optsC,
  );

  calloc.free(optsC);

  if (error < 0) {
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
Pointer<git_index> mergeTrees(
  Pointer<git_repository> repo,
  Pointer<git_tree> ancestorTree,
  Pointer<git_tree> ourTree,
  Pointer<git_tree> theirTree,
  Map<String, int> opts,
) {
  final out = calloc<Pointer<git_index>>();
  final optsC = calloc<git_merge_options>(sizeOf<git_merge_options>());
  optsC.ref.file_favor = opts['favor']!;
  optsC.ref.flags = opts['mergeFlags']!;
  optsC.ref.file_flags = opts['fileFlags']!;
  optsC.ref.version = GIT_MERGE_OPTIONS_VERSION;

  final error = libgit2.git_merge_trees(
    out,
    repo,
    ancestorTree,
    ourTree,
    theirTree,
    optsC,
  );

  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}
