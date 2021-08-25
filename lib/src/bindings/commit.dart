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
Pointer<git_commit> lookup(Pointer<git_repository> repo, Pointer<git_oid> id) {
  return using((Arena arena) {
    final out = arena<Pointer<git_commit>>();
    final error = libgit2.git_commit_lookup(out, repo, id);

    if (error < 0) {
      throw LibGit2Error(libgit2.git_error_last());
    } else {
      return out.value;
    }
  });
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

  if (parentOid is int && parentOid as int < 0) {
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

/// Close an open commit.
///
/// IMPORTANT: It is necessary to call this method when you stop using a commit.
/// Failure to do so will cause a memory leak.
void free(Pointer<git_commit> commit) => libgit2.git_commit_free(commit);
