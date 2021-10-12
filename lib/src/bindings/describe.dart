import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'libgit2_bindings.dart';
import '../error.dart';
import '../util.dart';

/// Describe a commit.
///
/// Perform the describe operation on the given committish object.
///
/// Returned object should be freed with `describeResultFree()` once no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_describe_result> commit({
  required Pointer<git_commit> commitPointer,
  int? maxCandidatesTags,
  int? describeStrategy,
  String? pattern,
  bool? onlyFollowFirstParent,
  bool? showCommitOidAsFallback,
}) {
  final out = calloc<Pointer<git_describe_result>>();
  final opts = _initOpts(
    maxCandidatesTags: maxCandidatesTags,
    describeStrategy: describeStrategy,
    pattern: pattern,
    onlyFollowFirstParent: onlyFollowFirstParent,
    showCommitOidAsFallback: showCommitOidAsFallback,
  );

  final error = libgit2.git_describe_commit(out, commitPointer.cast(), opts);

  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Describe a commit.
///
/// Perform the describe operation on the current commit and the worktree.
/// After peforming describe on HEAD, a status is run and the description is
/// considered to be dirty if there are.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_describe_result> workdir({
  required Pointer<git_repository> repo,
  int? maxCandidatesTags,
  int? describeStrategy,
  String? pattern,
  bool? onlyFollowFirstParent,
  bool? showCommitOidAsFallback,
}) {
  final out = calloc<Pointer<git_describe_result>>();
  final opts = _initOpts(
    maxCandidatesTags: maxCandidatesTags,
    describeStrategy: describeStrategy,
    pattern: pattern,
    onlyFollowFirstParent: onlyFollowFirstParent,
    showCommitOidAsFallback: showCommitOidAsFallback,
  );

  final error = libgit2.git_describe_workdir(out, repo, opts);

  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Print the describe result to a buffer.
///
/// Throws a [LibGit2Error] if error occured.
String format({
  required Pointer<git_describe_result> describeResultPointer,
  int? abbreviatedSize,
  bool? alwaysUseLongFormat,
  String? dirtySuffix,
}) {
  final out = calloc<git_buf>(sizeOf<git_buf>());
  final opts = calloc<git_describe_format_options>();
  final optsError = libgit2.git_describe_format_options_init(
    opts,
    GIT_DESCRIBE_FORMAT_OPTIONS_VERSION,
  );

  if (optsError < 0) {
    calloc.free(out);
    calloc.free(opts);
    throw LibGit2Error(libgit2.git_error_last());
  }

  if (abbreviatedSize != null) {
    opts.ref.abbreviated_size = abbreviatedSize;
  }
  if (alwaysUseLongFormat != null) {
    opts.ref.always_use_long_format = alwaysUseLongFormat ? 1 : 0;
  }
  if (dirtySuffix != null) {
    opts.ref.dirty_suffix = dirtySuffix.toNativeUtf8().cast<Int8>();
  }

  final error = libgit2.git_describe_format(out, describeResultPointer, opts);

  calloc.free(opts);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}

/// Free the describe result.
void describeResultFree(Pointer<git_describe_result> result) {
  libgit2.git_describe_result_free(result);
}

/// Initialize git_describe_options structure.
Pointer<git_describe_options> _initOpts({
  int? maxCandidatesTags,
  int? describeStrategy,
  String? pattern,
  bool? onlyFollowFirstParent,
  bool? showCommitOidAsFallback,
}) {
  final opts = calloc<git_describe_options>();
  final error = libgit2.git_describe_options_init(
    opts,
    GIT_DESCRIBE_OPTIONS_VERSION,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  if (maxCandidatesTags != null) {
    opts.ref.max_candidates_tags = maxCandidatesTags;
  }
  if (describeStrategy != null) {
    opts.ref.describe_strategy = describeStrategy;
  }
  if (pattern != null) {
    opts.ref.pattern = pattern.toNativeUtf8().cast<Int8>();
  }
  if (onlyFollowFirstParent != null) {
    opts.ref.only_follow_first_parent = onlyFollowFirstParent ? 1 : 0;
  }
  if (showCommitOidAsFallback != null) {
    opts.ref.show_commit_oid_as_fallback = showCommitOidAsFallback ? 1 : 0;
  }

  return opts;
}
