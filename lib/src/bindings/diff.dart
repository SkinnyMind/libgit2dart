import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Create a diff between the repository index and the workdir directory.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> indexToWorkdir(
  Pointer<git_repository> repo,
  Pointer<git_index> index,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  libgit2.git_diff_index_to_workdir(out, repo, index, opts);

  calloc.free(opts);

  return out.value;
}

/// Create a diff between a tree and repository index.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToIndex(
  Pointer<git_repository> repo,
  Pointer<git_tree> oldTree,
  Pointer<git_index> index,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  libgit2.git_diff_tree_to_index(out, repo, oldTree, index, opts);

  calloc.free(opts);

  return out.value;
}

/// Create a diff between a tree and the working directory.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToWorkdir(
  Pointer<git_repository> repo,
  Pointer<git_tree> oldTree,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  libgit2.git_diff_tree_to_workdir(out, repo, oldTree, opts);

  calloc.free(opts);

  return out.value;
}

/// Create a diff with the difference between two tree objects.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> treeToTree(
  Pointer<git_repository> repo,
  Pointer<git_tree> oldTree,
  Pointer<git_tree> newTree,
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final out = calloc<Pointer<git_diff>>();
  final opts = _diffOptionsInit(flags, contextLines, interhunkLines);

  libgit2.git_diff_tree_to_tree(out, repo, oldTree, newTree, opts);

  calloc.free(opts);

  return out.value;
}

/// Query how many diff records are there in a diff.
int length(Pointer<git_diff> diff) => libgit2.git_diff_num_deltas(diff);

/// Merge one diff into another.
///
/// This merges items from the "from" list into the "onto" list. The resulting diff
/// will have all items that appear in either list. If an item appears in both lists,
/// then it will be "merged" to appear as if the old version was from the "onto" list
/// and the new version is from the "from" list (with the exception that if the item
/// has a pending DELETE in the middle, then it will show as deleted).
void merge(Pointer<git_diff> onto, Pointer<git_diff> from) {
  libgit2.git_diff_merge(onto, from);
}

/// Read the contents of a git patch file into a git diff object.
///
/// The diff object produced is similar to the one that would be produced if you actually
/// produced it computationally by comparing two trees, however there may be subtle differences.
/// For example, a patch file likely contains abbreviated object IDs, so the object IDs in a
/// diff delta produced by this function will also be abbreviated.
///
/// This function will only read patch files created by a git implementation, it will not
/// read unified diffs produced by the `diff` program, nor any other types of patch files.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff> parse(String content) {
  final out = calloc<Pointer<git_diff>>();
  final contentC = content.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_diff_from_buffer(out, contentC, content.length);

  calloc.free(contentC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Transform a diff marking file renames, copies, etc.
///
/// This modifies a diff in place, replacing old entries that look like renames or copies
/// with new entries reflecting those changes. This also will, if requested, break modified
/// files into add/remove pairs if the amount of change is above a threshold.
///
/// Throws a [LibGit2Error] if error occured.
void findSimilar(
    Pointer<git_diff> diff,
    int flags,
    int renameThreshold,
    int copyThreshold,
    int renameFromRewriteThreshold,
    int breakRewriteThreshold,
    int renameLimit) {
  final opts = calloc<git_diff_find_options>();
  final optsError =
      libgit2.git_diff_find_options_init(opts, GIT_DIFF_FIND_OPTIONS_VERSION);
  opts.ref.flags = flags;
  opts.ref.rename_threshold = renameThreshold;
  opts.ref.copy_threshold = copyThreshold;
  opts.ref.rename_from_rewrite_threshold = renameFromRewriteThreshold;
  opts.ref.break_rewrite_threshold = breakRewriteThreshold;
  opts.ref.rename_limit = renameLimit;

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final error = libgit2.git_diff_find_similar(diff, opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  calloc.free(opts);
}

/// Calculate the patch ID for the given patch.
///
/// Calculate a stable patch ID for the given patch by summing the hash of the file diffs,
/// ignoring whitespace and line numbers. This can be used to derive whether two diffs are
/// the same with a high probability.
///
/// Currently, this function only calculates stable patch IDs, as defined in `git-patch-id(1)`,
/// and should in fact generate the same IDs as the upstream git project does.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> patchId(Pointer<git_diff> diff) {
  final out = calloc<git_oid>();
  final error = libgit2.git_diff_patchid(out, diff, nullptr);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Return the diff delta for an entry in the diff list.
///
/// Throws [RangeError] if index out of range.
Pointer<git_diff_delta> getDeltaByIndex(Pointer<git_diff> diff, int idx) {
  final result = libgit2.git_diff_get_delta(diff, idx);

  if (result == nullptr) {
    throw RangeError('$idx is out of bounds');
  } else {
    return result;
  }
}

/// Look up the single character abbreviation for a delta status code.
///
/// When you run `git diff --name-status` it uses single letter codes in the output such as
/// 'A' for added, 'D' for deleted, 'M' for modified, etc. This function converts a [GitDelta]
/// value into these letters for your own purposes. [GitDelta.untracked] will return
/// a space (i.e. ' ').
String statusChar(int status) {
  final result = libgit2.git_diff_status_char(status);
  return String.fromCharCode(result);
}

/// Accumulate diff statistics for all patches.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_diff_stats> stats(Pointer<git_diff> diff) {
  final out = calloc<Pointer<git_diff_stats>>();
  final error = libgit2.git_diff_get_stats(out, diff);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
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
String statsPrint(
  Pointer<git_diff_stats> stats,
  int format,
  int width,
) {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final error = libgit2.git_diff_stats_to_buf(out, stats, format, width);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}

/// Add patch to buffer.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_buf> addToBuf(Pointer<git_patch> patch, Pointer<git_buf> buffer) {
  final error = libgit2.git_patch_to_buf(buffer, patch);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return buffer;
  }
}

/// Free a previously allocated diff stats.
void statsFree(Pointer<git_diff_stats> stats) =>
    libgit2.git_diff_stats_free(stats);

/// Free a previously allocated diff.
void free(Pointer<git_diff> diff) => libgit2.git_diff_free(diff);

Pointer<git_diff_options> _diffOptionsInit(
  int flags,
  int contextLines,
  int interhunkLines,
) {
  final opts = calloc<git_diff_options>();
  final optsError =
      libgit2.git_diff_options_init(opts, GIT_DIFF_OPTIONS_VERSION);
  opts.ref.flags = flags;
  opts.ref.context_lines = contextLines;
  opts.ref.interhunk_lines = interhunkLines;

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return opts;
  }
}
