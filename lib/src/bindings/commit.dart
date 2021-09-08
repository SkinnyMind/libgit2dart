import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';
import 'oid.dart' as oid_bindings;

/// Lookup a commit object from a repository.
///
/// The returned object should be released with `free()` when no longer needed.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_commit> lookup(Pointer<git_repository> repo, Pointer<git_oid> id) {
  final out = calloc<Pointer<git_commit>>();
  final error = libgit2.git_commit_lookup(out, repo, id);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Lookup a commit object from a repository, given a prefix of its identifier (short id).
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_commit> lookupPrefix(
  Pointer<git_repository> repo,
  Pointer<git_oid> id,
  int len,
) {
  final out = calloc<Pointer<git_commit>>();
  final error = libgit2.git_commit_lookup_prefix(out, repo, id, len);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Creates a git_annotated_commit from the given commit id. The resulting git_annotated_commit
/// must be freed with git_annotated_commit_free.
///
/// An annotated commit contains information about how it was looked up, which may be useful
/// for functions like merge or rebase to provide context to the operation. For example, conflict
/// files will include the name of the source or target branches being merged. It is therefore
/// preferable to use the most specific function (eg git_annotated_commit_from_ref) instead of
/// this one when that data is known.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<Pointer<git_annotated_commit>> annotatedLookup(
  Pointer<git_repository> repo,
  Pointer<git_oid> id,
) {
  final out = calloc<Pointer<git_annotated_commit>>();
  final error = libgit2.git_annotated_commit_lookup(out, repo, id);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Frees a git_annotated_commit.
void annotatedFree(Pointer<git_annotated_commit> commit) {
  libgit2.git_annotated_commit_free(commit);
}

/// Create new commit in the repository.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create(
  Pointer<git_repository> repo,
  String? updateRef,
  Pointer<git_signature> author,
  Pointer<git_signature> committer,
  String? messageEncoding,
  String message,
  Pointer<git_tree> tree,
  int parentCount,
  List<String> parents,
) {
  final out = calloc<git_oid>();
  final updateRefC = updateRef?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageEncodingC =
      messageEncoding?.toNativeUtf8().cast<Int8>() ?? nullptr;
  final messageC = message.toNativeUtf8().cast<Int8>();
  Pointer<Pointer<git_commit>> parentsC =
      calloc.call<Pointer<git_commit>>(parentCount);

  if (parents.isNotEmpty) {
    for (var i = 0; i < parentCount; i++) {
      final oid = oid_bindings.fromSHA(parents[i]);
      var commit = calloc<IntPtr>();
      commit = lookup(repo, oid).cast();
      parentsC[i] = commit.cast();
    }
  } else {
    final commit = calloc<IntPtr>();
    parentsC[0] = commit.cast();
  }

  final error = libgit2.git_commit_create(
    out,
    repo,
    updateRefC,
    author,
    committer,
    messageEncodingC,
    messageC,
    tree,
    parentCount,
    parentsC,
  );

  calloc.free(updateRefC);
  calloc.free(messageEncodingC);
  calloc.free(messageC);
  for (var i = 0; i < parentCount; i++) {
    free(parentsC[i]);
  }
  calloc.free(parentsC);

  if (error < 0) {
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

  if (result == nullptr) {
    return 'utf-8';
  } else {
    return result.cast<Utf8>().toDartString();
  }
}

/// Get the full message of a commit.
///
/// The returned message will be slightly prettified by removing any potential leading newlines.
String message(Pointer<git_commit> commit) {
  final out = libgit2.git_commit_message(commit);
  return out.cast<Utf8>().toDartString();
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
Pointer<git_oid> parentId(Pointer<git_commit> commit, int n) {
  final parentOid = libgit2.git_commit_parent_id(commit, n);

  if (parentOid == nullptr) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return parentOid;
  }
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

/// Get the repository that contains the commit.
Pointer<git_repository> owner(Pointer<git_commit> commit) =>
    libgit2.git_commit_owner(commit);

/// Close an open commit to release memory.
void free(Pointer<git_commit> commit) => libgit2.git_commit_free(commit);
