import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Create a diff with the difference between two index objects. The returned
/// diff must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> indexToIndex({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_index> oldIndexPointer,
  required Pointer<git_index> newIndexPointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  final error = libgit2.git_diff_index_to_index(
    out,
    repoPointer,
    oldIndexPointer,
    newIndexPointer,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a diff between the repository index and the workdir directory. The
/// returned diff must be freed with [free].
Pointer<git_diff> indexToWorkdir({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_index> indexPointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_diff_index_to_workdir(out, repoPointer, indexPointer, opts);

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  return result;
}

/// Create a diff between a tree and repository index. The returned diff must
/// be freed with [free].
Pointer<git_diff> treeToIndex({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree>? treePointer,
  required Pointer<git_index> indexPointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  libgit2.git_diff_tree_to_index(
    out,
    repoPointer,
    treePointer ?? nullptr,
    indexPointer,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  return result;
}

/// Create a diff between a tree and the working directory. The returned
/// diff must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToWorkdir({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree>? treePointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  final error = libgit2.git_diff_tree_to_workdir(
    out,
    repoPointer,
    treePointer ?? nullptr,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a diff between a tree and the working directory using index data to
/// account for staged deletes, tracked files, etc. The returned diff must be
/// freed with [free].
///
/// This emulates `git diff <tree>` by diffing the tree to the index and the
/// index to the working directory and blending the results into a single diff
/// that includes staged deleted, etc.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToWorkdirWithIndex({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree>? treePointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  final error = libgit2.git_diff_tree_to_workdir_with_index(
    out,
    repoPointer,
    treePointer ?? nullptr,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a diff with the difference between two tree objects. The returned
/// diff must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToTree({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree>? oldTreePointer,
  required Pointer<git_tree>? newTreePointer,
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(
    flags: flags,
    contextLines: contextLines,
    interhunkLines: interhunkLines,
  );

  final error = libgit2.git_diff_tree_to_tree(
    out,
    repoPointer,
    oldTreePointer ?? nullptr,
    newTreePointer ?? nullptr,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Query how many diff records are there in a diff.
int length(Pointer<git_diff> diff) => libgit2.git_diff_num_deltas(diff);

/// Merge one diff into another.
///
/// This merges items from the "from" list into the "onto" list. The resulting
/// diff will have all items that appear in either list. If an item appears in
/// both lists, then it will be "merged" to appear as if the old version was
/// from the "onto" list and the new version is from the "from" list (with the
/// exception that if the item has a pending DELETE in the middle, then it will
/// show as deleted).
void merge({
  required Pointer<git_diff> ontoPointer,
  required Pointer<git_diff> fromPointer,
}) {
  libgit2.git_diff_merge(ontoPointer, fromPointer);
}

/// Read the contents of a git patch file into a git diff object. The returned
/// diff must be freed with [free].
///
/// The diff object produced is similar to the one that would be produced if
/// you actually produced it computationally by comparing two trees, however
/// there may be subtle differences. For example, a patch file likely contains
/// abbreviated object IDs, so the object IDs in a diff delta produced by this
/// function will also be abbreviated.
///
/// This function will only read patch files created by a git implementation,
/// it will not read unified diffs produced by the `diff` program, nor any
/// other types of patch files.
Pointer<git_diff> parse(String content) {
  final out = calloc<Pointer<git_diff>>();
  final contentC = content.toChar();
  libgit2.git_diff_from_buffer(out, contentC, content.length);

  final result = out.value;

  calloc.free(out);
  calloc.free(contentC);

  return result;
}

/// Transform a diff marking file renames, copies, etc.
///
/// This modifies a diff in place, replacing old entries that look like renames
/// or copies with new entries reflecting those changes. This also will, if
/// requested, break modified files into add/remove pairs if the amount of
/// change is above a threshold.
///
/// Throws a [LibGit2Error] if error occured.
void findSimilar({
  required Pointer<git_diff> diffPointer,
  required int flags,
  required int renameThreshold,
  required int copyThreshold,
  required int renameFromRewriteThreshold,
  required int breakRewriteThreshold,
  required int renameLimit,
}) {
  final opts = calloc<git_diff_find_options>();
  libgit2.git_diff_find_options_init(opts, GIT_DIFF_FIND_OPTIONS_VERSION);

  opts.ref.flags = flags;
  opts.ref.rename_threshold = renameThreshold;
  opts.ref.copy_threshold = copyThreshold;
  opts.ref.rename_from_rewrite_threshold = renameFromRewriteThreshold;
  opts.ref.break_rewrite_threshold = breakRewriteThreshold;
  opts.ref.rename_limit = renameLimit;

  final error = libgit2.git_diff_find_similar(diffPointer, opts);

  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Calculate the patch ID for the given patch.
///
/// Calculate a stable patch ID for the given patch by summing the hash of the
/// file diffs, ignoring whitespace and line numbers. This can be used to
/// derive whether two diffs are the same with a high probability.
///
/// Currently, this function only calculates stable patch IDs, as defined in
/// `git-patch-id(1)`, and should in fact generate the same IDs as the upstream
/// git project does.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> patchOid(Pointer<git_diff> diff) {
  final out = calloc<git_oid>();
  final error = libgit2.git_diff_patchid(out, diff, nullptr);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Return the diff delta for an entry in the diff list.
Pointer<git_diff_delta> getDeltaByIndex({
  required Pointer<git_diff> diffPointer,
  required int index,
}) {
  return libgit2.git_diff_get_delta(diffPointer, index);
}

/// Look up the single character abbreviation for a delta status code.
///
/// When you run `git diff --name-status` it uses single letter codes in the
/// output such as 'A' for added, 'D' for deleted, 'M' for modified, etc. This
/// function converts a [GitDelta] value into these letters for your own
/// purposes. [GitDelta.untracked] will return a space (i.e. ' ').
String statusChar(int status) {
  return String.fromCharCode(libgit2.git_diff_status_char(status));
}

/// Accumulate diff statistics for all patches. The returned diff stats must be
/// freed with [freeStats].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff_stats> stats(Pointer<git_diff> diff) {
  final out = calloc<Pointer<git_diff_stats>>();
  final error = libgit2.git_diff_get_stats(out, diff);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the total number of insertions in a diff.
int statsInsertions(Pointer<git_diff_stats> stats) =>
    libgit2.git_diff_stats_insertions(stats);

/// Get the total number of deletions in a diff.
int statsDeletions(Pointer<git_diff_stats> stats) =>
    libgit2.git_diff_stats_deletions(stats);

/// Get the total number of files changed in a diff.
int statsFilesChanged(Pointer<git_diff_stats> stats) =>
    libgit2.git_diff_stats_files_changed(stats);

/// Print diff statistics.
///
/// Throws a [LibGit2Error] if error occured.
String statsPrint({
  required Pointer<git_diff_stats> statsPointer,
  required int format,
  required int width,
}) {
  final out = calloc<git_buf>();
  final error = libgit2.git_diff_stats_to_buf(out, statsPointer, format, width);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Produce the complete formatted text output from a diff into a buffer.
String addToBuf(Pointer<git_diff> diff) {
  final out = calloc<git_buf>();
  libgit2.git_diff_to_buf(out, diff, git_diff_format_t.GIT_DIFF_FORMAT_PATCH);

  final result = out.ref.ptr == nullptr
      ? ''
      : out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);

  return result;
}

/// Counter for hunk number being applied.
///
/// **IMPORTANT**: make sure to reset it to 0 before using since it's a global
/// variable.
int _counter = 0;

/// When applying a patch, callback that will be made per hunk.
int _hunkCb(Pointer<git_diff_hunk> hunk, Pointer<Void> payload) {
  final index = payload.cast<Int32>().value;
  if (_counter == index) {
    _counter++;
    return 0;
  } else {
    _counter++;
    return 1;
  }
}

/// Apply a diff to the given repository, making changes directly in the
/// working directory, the index, or both.
///
/// Throws a [LibGit2Error] if error occured.
bool apply({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_diff> diffPointer,
  int? hunkIndex,
  required int location,
  bool check = false,
}) {
  final opts = calloc<git_apply_options>();
  libgit2.git_apply_options_init(opts, GIT_APPLY_OPTIONS_VERSION);
  if (check) {
    opts.ref.flags |= git_apply_flags_t.GIT_APPLY_CHECK;
  }
  Pointer<Int32> payload = nullptr;
  if (hunkIndex != null) {
    _counter = 0;
    const except = -1;
    // ignore: omit_local_variable_types
    final git_apply_hunk_cb callback = Pointer.fromFunction(_hunkCb, except);
    payload = calloc<Int32>()..value = hunkIndex;
    opts.ref.payload = payload.cast();
    opts.ref.hunk_cb = callback;
  }
  final error = libgit2.git_apply(repoPointer, diffPointer, location, opts);

  calloc.free(payload);
  calloc.free(opts);

  if (error < 0) {
    return check ? false : throw LibGit2Error(libgit2.git_error_last());
  } else {
    return true;
  }
}

/// Apply a diff to a tree, and return the resulting image as an index. The
/// returned index must be freed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> applyToTree({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_tree> treePointer,
  required Pointer<git_diff> diffPointer,
  int? hunkIndex,
}) {
  final out = calloc<Pointer<git_index>>();
  final opts = calloc<git_apply_options>();
  libgit2.git_apply_options_init(opts, GIT_APPLY_OPTIONS_VERSION);
  Pointer<Int32> payload = nullptr;
  if (hunkIndex != null) {
    _counter = 0;
    const except = -1;
    // ignore: omit_local_variable_types
    final git_apply_hunk_cb callback = Pointer.fromFunction(_hunkCb, except);
    payload = calloc<Int32>()..value = hunkIndex;
    opts.ref.payload = payload.cast();
    opts.ref.hunk_cb = callback;
  }
  final error = libgit2.git_apply_to_tree(
    out,
    repoPointer,
    treePointer,
    diffPointer,
    opts,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(payload);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Free a previously allocated diff stats.
void freeStats(Pointer<git_diff_stats> stats) =>
    libgit2.git_diff_stats_free(stats);

/// Free a previously allocated diff.
void free(Pointer<git_diff> diff) => libgit2.git_diff_free(diff);

Pointer<git_diff_options> _diffOptionsInit({
  required int flags,
  required int contextLines,
  required int interhunkLines,
}) {
  final opts = calloc<git_diff_options>();
  libgit2.git_diff_options_init(opts, GIT_DIFF_OPTIONS_VERSION);

  opts.ref.flags = flags;
  opts.ref.context_lines = contextLines;
  opts.ref.interhunk_lines = interhunkLines;
  return opts;
}
