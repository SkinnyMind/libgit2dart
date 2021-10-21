import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Lookup a commit object from a repository.
///
/// The returned object should be released with `free()` when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_commit> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_commit>>();
  final error = libgit2.git_commit_lookup(out, repoPointer, oidPointer);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Creates an annotated commit from the given commit id. The resulting annotated commit
/// must be freed with [annotatedFree].
///
/// An annotated commit contains information about how it was looked up, which may be useful
/// for functions like merge or rebase to provide context to the operation. For example, conflict
/// files will include the name of the source or target branches being merged. It is therefore
/// preferable to use the most specific function (eg git_annotated_commit_from_ref) instead of
/// this one when that data is known.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<Pointer<git_annotated_commit>> annotatedLookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final error = libgit2.git_annotated_commit_lookup(
    out,
    repoPointer,
    oidPointer,
  );

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Frees an annotated commit.
void annotatedFree(Pointer<git_annotated_commit> commit) {
  libgit2.git_annotated_commit_free(commit);
}

/// Create new commit in the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create({
  required Pointer<git_repository> repoPointer,
  String? updateRef,
  required Pointer<git_signature> authorPointer,
  required Pointer<git_signature> committerPointer,
  String? messageEncoding,
  required String message,
  required Pointer<git_tree> treePointer,
  required int parentCount,
  required List<Pointer<git_commit>> parents,
}) {
  final out = calloc<git_oid>();
  final updateRefC = updateRef?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageEncodingC =
      messageEncoding?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageC = message.toNativeUtf8().cast<Int8>();
  final parentsC = calloc<Pointer<git_commit>>(parentCount);

  if (parents.isNotEmpty) {
    for (var i = 0; i < parentCount; i++) {
      parentsC[i] = parents[i];
    }
  } else {
    parentsC[0] = nullptr;
  }

  final error = libgit2.git_commit_create(
    out,
    repoPointer,
    updateRefC,
    authorPointer,
    committerPointer,
    messageEncodingC,
    messageC,
    treePointer,
    parentCount,
    parentsC,
  );

  calloc.free(updateRefC);
  calloc.free(messageEncodingC);
  calloc.free(messageC);
  calloc.free(parentsC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Amend an existing commit by replacing only non-null values.
///
/// This creates a new commit that is exactly the same as the old commit, except that
/// any non-null values will be updated. The new commit has the same parents as the old commit.
///
/// The [updateRef] value works as in the regular [create], updating the ref to point to
/// the newly rewritten commit. If you want to amend a commit that is not currently
/// the tip of the branch and then rewrite the following commits to reach a ref, pass
/// this as null and update the rest of the commit chain and ref separately.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> amend({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> commitPointer,
  String? updateRef,
  required Pointer<git_signature>? authorPointer,
  required Pointer<git_signature>? committerPointer,
  String? messageEncoding,
  required String? message,
  required Pointer<git_tree>? treePointer,
}) {
  final out = calloc<git_oid>();
  final updateRefC = updateRef?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageEncodingC =
      messageEncoding?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageC = message?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final error = libgit2.git_commit_amend(
    out,
    commitPointer,
    updateRefC,
    authorPointer ?? nullptr,
    committerPointer ?? nullptr,
    messageEncodingC,
    messageC,
    treePointer ?? nullptr,
  );

  calloc.free(updateRefC);
  calloc.free(messageEncodingC);
  calloc.free(messageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Get the encoding for the message of a commit, as a string representing a standard encoding name.
///
/// The encoding may be NULL if the encoding header in the commit is missing;
/// in that case UTF-8 is assumed.
String messageEncoding(Pointer<git_commit> commit) {
  final result = libgit2.git_commit_message_encoding(commit);
  return result == nullptr ? 'utf-8' : result.cast<Utf8>().toDartString();
}

/// Get the full message of a commit.
///
/// The returned message will be slightly prettified by removing any potential leading newlines.
String message(Pointer<git_commit> commit) {
  return libgit2.git_commit_message(commit).cast<Utf8>().toDartString();
}

/// Get the id of a commit.
Pointer<git_oid> id(Pointer<git_commit> commit) =>
    libgit2.git_commit_id(commit);

/// Get the number of parents of this commit.
int parentCount(Pointer<git_commit> commit) =>
    libgit2.git_commit_parentcount(commit);

/// Get the oid of a specified parent for a commit.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> parentId({
  required Pointer<git_commit> commitPointer,
  required int position,
}) {
  return libgit2.git_commit_parent_id(commitPointer, position);
}

/// Get the commit time (i.e. committer time) of a commit.
int time(Pointer<git_commit> commit) => libgit2.git_commit_time(commit);

/// Get the committer of a commit.
Pointer<git_signature> committer(Pointer<git_commit> commit) {
  return libgit2.git_commit_committer(commit);
}

/// Get the author of a commit.
Pointer<git_signature> author(Pointer<git_commit> commit) {
  return libgit2.git_commit_author(commit);
}

/// Get the id of the tree pointed to by a commit.
Pointer<git_oid> tree(Pointer<git_commit> commit) {
  return libgit2.git_commit_tree_id(commit);
}

/// Reverts the given commit against the given "our" commit, producing an index that
/// reflects the result of the revert.
///
/// The returned index must be freed explicitly with `free()`.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_index> revertCommit({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> revertCommitPointer,
  required Pointer<git_commit> ourCommitPointer,
  required int mainline,
}) {
  final out = calloc<Pointer<git_index>>();
  final opts = calloc<git_merge_options>();
  libgit2.git_merge_options_init(opts, GIT_MERGE_OPTIONS_VERSION);

  final error = libgit2.git_revert_commit(
    out,
    repoPointer,
    revertCommitPointer,
    ourCommitPointer,
    mainline,
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

/// Get the repository that contains the commit.
Pointer<git_repository> owner(Pointer<git_commit> commit) =>
    libgit2.git_commit_owner(commit);

/// Close an open commit to release memory.
void free(Pointer<git_commit> commit) => libgit2.git_commit_free(commit);
