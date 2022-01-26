import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/util.dart';

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

/// Create new commit in the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create({
  required Pointer<git_repository> repoPointer,
  required String updateRef,
  required Pointer<git_signature> authorPointer,
  required Pointer<git_signature> committerPointer,
  String? messageEncoding,
  required String message,
  required Pointer<git_tree> treePointer,
  required int parentCount,
  required List<Pointer<git_commit>> parents,
}) {
  final out = calloc<git_oid>();
  final updateRefC = updateRef.toNativeUtf8().cast<Int8>();
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

/// Create a commit and write it into a buffer.
///
/// Create a commit as with [create] but instead of writing it to the objectdb,
/// write the contents of the object into a buffer.
///
/// Throws a [LibGit2Error] if error occured.
String createBuffer({
  required Pointer<git_repository> repoPointer,
  required String updateRef,
  required Pointer<git_signature> authorPointer,
  required Pointer<git_signature> committerPointer,
  String? messageEncoding,
  required String message,
  required Pointer<git_tree> treePointer,
  required int parentCount,
  required List<Pointer<git_commit>> parents,
}) {
  final out = calloc<git_buf>();
  final updateRefC = updateRef.toNativeUtf8().cast<Int8>();
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

  final error = libgit2.git_commit_create_buffer(
    out,
    repoPointer,
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
    final result = out.ref.ptr.cast<Utf8>().toDartString(length: out.ref.size);
    calloc.free(out);
    return result;
  }
}

/// Amend an existing commit by replacing only non-null values.
///
/// This creates a new commit that is exactly the same as the old commit,
/// except that any non-null values will be updated. The new commit has the
/// same parents as the old commit.
///
/// The [updateRef] value works as in the regular [create], updating the ref to
/// point to the newly rewritten commit. If you want to amend a commit that is
/// not currently the tip of the branch and then rewrite the following commits
/// to reach a ref, pass this as null and update the rest of the commit chain
/// and ref separately.
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

/// Create an in-memory copy of a commit. The copy must be explicitly free'd or
/// it will leak.
Pointer<git_commit> duplicate(Pointer<git_commit> source) {
  final out = calloc<Pointer<git_commit>>();
  libgit2.git_commit_dup(out, source);
  return out.value;
}

/// Get the encoding for the message of a commit, as a string representing a
/// standard encoding name.
///
/// The encoding may be NULL if the encoding header in the commit is missing;
/// in that case UTF-8 is assumed.
String messageEncoding(Pointer<git_commit> commit) {
  final result = libgit2.git_commit_message_encoding(commit);
  return result == nullptr ? 'utf-8' : result.cast<Utf8>().toDartString();
}

/// Get the full message of a commit.
///
/// The returned message will be slightly prettified by removing any potential
/// leading newlines.
String message(Pointer<git_commit> commit) {
  return libgit2.git_commit_message(commit).cast<Utf8>().toDartString();
}

/// Get the short "summary" of the git commit message.
///
/// The returned message is the summary of the commit, comprising the first
/// paragraph of the message with whitespace trimmed and squashed.
///
/// Throws a [LibGit2Error] if error occured.
String summary(Pointer<git_commit> commit) {
  final result = libgit2.git_commit_summary(commit);

  if (result == nullptr) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result.cast<Utf8>().toDartString();
  }
}

/// Get the long "body" of the git commit message.
///
/// The returned message is the body of the commit, comprising everything but
/// the first paragraph of the message. Leading and trailing whitespaces are
/// trimmed.
String body(Pointer<git_commit> commit) {
  final result = libgit2.git_commit_body(commit);
  return result == nullptr ? '' : result.cast<Utf8>().toDartString();
}

/// Get an arbitrary header field.
///
/// Throws a [LibGit2Error] if error occured.
String headerField({
  required Pointer<git_commit> commitPointer,
  required String field,
}) {
  final out = calloc<git_buf>();
  final fieldC = field.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_commit_header_field(out, commitPointer, fieldC);

  calloc.free(fieldC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.ref.ptr.cast<Utf8>().toDartString(length: out.ref.size);
    calloc.free(out);
    return result;
  }
}

/// Get the id of a commit.
Pointer<git_oid> id(Pointer<git_commit> commit) =>
    libgit2.git_commit_id(commit);

/// Get the number of parents of this commit.
int parentCount(Pointer<git_commit> commit) =>
    libgit2.git_commit_parentcount(commit);

/// Get the oid of a specified parent for a commit.
Pointer<git_oid> parentId({
  required Pointer<git_commit> commitPointer,
  required int position,
}) {
  return libgit2.git_commit_parent_id(commitPointer, position);
}

/// Get the specified parent of the commit (0-based).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_commit> parent({
  required Pointer<git_commit> commitPointer,
  required int position,
}) {
  final out = calloc<Pointer<git_commit>>();
  final error = libgit2.git_commit_parent(out, commitPointer, position);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the commit object that is the th generation ancestor of the named
/// commit object, following only the first parents. The returned commit has to
/// be freed by the caller.
///
/// Passing 0 as the generation number returns another instance of the base
/// commit itself.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_commit> nthGenAncestor({
  required Pointer<git_commit> commitPointer,
  required int n,
}) {
  final out = calloc<Pointer<git_commit>>();
  final error = libgit2.git_commit_nth_gen_ancestor(out, commitPointer, n);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Get the commit time (i.e. committer time) of a commit.
int time(Pointer<git_commit> commit) => libgit2.git_commit_time(commit);

/// Get the commit timezone offset in minutes (i.e. committer's preferred
/// timezone) of a commit.
int timeOffset(Pointer<git_commit> commit) =>
    libgit2.git_commit_time_offset(commit);

/// Get the committer of a commit.
Pointer<git_signature> committer(Pointer<git_commit> commit) {
  return libgit2.git_commit_committer(commit);
}

/// Get the author of a commit.
Pointer<git_signature> author(Pointer<git_commit> commit) {
  return libgit2.git_commit_author(commit);
}

/// Get the id of the tree pointed to by a commit.
Pointer<git_oid> treeOid(Pointer<git_commit> commit) {
  return libgit2.git_commit_tree_id(commit);
}

/// Get the tree pointed to by a commit.
Pointer<git_tree> tree(Pointer<git_commit> commit) {
  final out = calloc<Pointer<git_tree>>();
  libgit2.git_commit_tree(out, commit);
  return out.value;
}

/// Reverts the given commit, producing changes in the index and working
/// directory.
///
/// Throws a [LibGit2Error] if error occured.
void revert({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_commit> commitPointer,
}) {
  final error = libgit2.git_revert(repoPointer, commitPointer, nullptr);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Reverts the given commit against the given "our" commit, producing an index
/// that reflects the result of the revert.
///
/// The returned index must be freed explicitly with [free].
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
