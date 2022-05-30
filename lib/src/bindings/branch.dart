import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/reference.dart' as reference_bindings;
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Return a list of branches. The returned references must be freed with
/// [free].
///
/// Throws a [LibGit2Error] if error occured.
List<Pointer<git_reference>> list({
  required Pointer<git_repository> repoPointer,
  required int flags,
}) {
  final iterator = calloc<Pointer<git_branch_iterator>>();
  final iteratorError = libgit2.git_branch_iterator_new(
    iterator,
    repoPointer,
    flags,
  );

  if (iteratorError < 0) {
    libgit2.git_branch_iterator_free(iterator.value);
    throw LibGit2Error(libgit2.git_error_last());
  }

  final result = <Pointer<git_reference>>[];
  var error = 0;

  while (error == 0) {
    final reference = calloc<Pointer<git_reference>>();
    final refType = calloc<Int32>();
    error = libgit2.git_branch_next(reference, refType, iterator.value);
    if (error == 0) {
      result.add(reference.value);
    } else {
      break;
    }
    calloc.free(reference);
    calloc.free(refType);
  }

  libgit2.git_branch_iterator_free(iterator.value);
  calloc.free(iterator);
  return result;
}

/// Lookup a branch by its name in a repository. The returned reference must be
/// freed with [free].
///
/// The branch name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> lookup({
  required Pointer<git_repository> repoPointer,
  required String branchName,
  required int branchType,
}) {
  final out = calloc<Pointer<git_reference>>();
  final branchNameC = branchName.toChar();
  final error = libgit2.git_branch_lookup(
    out,
    repoPointer,
    branchNameC,
    branchType,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Create a new branch pointing at a target commit. The returned reference
/// must be freed with [free].
///
/// A new direct reference will be created pointing to this target commit.
/// If force is true and a reference already exists with the given name, it'll
/// be replaced.
///
/// The branch name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> create({
  required Pointer<git_repository> repoPointer,
  required String branchName,
  required Pointer<git_commit> targetPointer,
  required bool force,
}) {
  final out = calloc<Pointer<git_reference>>();
  final branchNameC = branchName.toChar();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_branch_create(
    out,
    repoPointer,
    branchNameC,
    targetPointer,
    forceC,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Delete an existing branch reference.
///
/// Note that if the deletion succeeds, the reference object will not be valid
/// anymore, and should be freed immediately with [free].
///
/// Throws a [LibGit2Error] if error occured.
void delete(Pointer<git_reference> branch) {
  final error = libgit2.git_branch_delete(branch);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Move/rename an existing local branch reference.
///
/// The new branch name will be checked for validity.
///
/// Note that if the move succeeds, the old reference object will not be valid
/// anymore, and should be freed immediately with [free].
///
/// Throws a [LibGit2Error] if error occured.
void rename({
  required Pointer<git_reference> branchPointer,
  required String newBranchName,
  required bool force,
}) {
  final out = calloc<Pointer<git_reference>>();
  final newBranchNameC = newBranchName.toChar();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_branch_move(
    out,
    branchPointer,
    newBranchNameC,
    forceC,
  );

  calloc.free(newBranchNameC);
  reference_bindings.free(out.value);
  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Determine if HEAD points to the given branch.
///
/// Throws a [LibGit2Error] if error occured.
bool isHead(Pointer<git_reference> branch) {
  final result = libgit2.git_branch_is_head(branch);

  if (result < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result == 1 || false;
  }
}

/// Determine if any HEAD points to the current branch.
///
/// This will iterate over all known linked repositories (usually in the form
/// of worktrees) and report whether any HEAD is pointing at the current branch.
///
/// Throws a [LibGit2Error] if error occured.
bool isCheckedOut(Pointer<git_reference> branch) {
  final result = libgit2.git_branch_is_checked_out(branch);

  if (result < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result == 1 || false;
  }
}

/// Get the branch name.
///
/// Given a reference object, this will check that it really is a branch
/// (ie. it lives under "refs/heads/" or "refs/remotes/"), and return the
/// branch part of it.
///
/// Throws a [LibGit2Error] if error occured.
String name(Pointer<git_reference> ref) {
  final out = calloc<Pointer<Char>>();
  final error = libgit2.git_branch_name(out, ref);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result.toDartString();
  }
}

/// Find the remote name of a remote-tracking branch.
///
/// This will return the name of the remote whose fetch refspec is matching the
/// given branch. E.g. given a branch "refs/remotes/test/master", it will extract
/// the "test" part.
///
/// Throws a [LibGit2Error] if refspecs from multiple remotes match or if error
/// occured.
String remoteName({
  required Pointer<git_repository> repoPointer,
  required String branchName,
}) {
  final out = calloc<git_buf>();
  final branchNameC = branchName.toChar();
  final error = libgit2.git_branch_remote_name(out, repoPointer, branchNameC);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Get the upstream of a branch. The returned reference must be freed with
/// [free].
///
/// Given a reference, this will return a new reference object corresponding to
/// its remote tracking branch. The reference must be a local branch.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> getUpstream(Pointer<git_reference> branch) {
  final out = calloc<Pointer<git_reference>>();
  final error = libgit2.git_branch_upstream(out, branch);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Set a branch's upstream branch.
///
/// This will update the configuration to set the branch named [branchName] as
/// the upstream of branch. Pass a null [branchName] to unset the upstream
/// information.
///
/// **Note**: The actual tracking reference must have been already created for
/// the operation to succeed.
///
/// Throws a [LibGit2Error] if error occured.
void setUpstream({
  required Pointer<git_reference> branchPointer,
  required String? branchName,
}) {
  final branchNameC = branchName?.toChar() ?? nullptr;
  final error = libgit2.git_branch_set_upstream(branchPointer, branchNameC);

  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the upstream name of a branch.
///
/// Given a local branch, this will return its remote-tracking branch
/// information, as a full reference name, ie. "feature/nice" would become
/// "refs/remotes/origin/feature/nice", depending on that branch's configuration.
///
/// Throws a [LibGit2Error] if error occured.
String upstreamName({
  required Pointer<git_repository> repoPointer,
  required String branchName,
}) {
  final out = calloc<git_buf>();
  final branchNameC = branchName.toChar();
  final error = libgit2.git_branch_upstream_name(out, repoPointer, branchNameC);

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Retrieve the upstream remote of a local branch.
///
/// This will return the currently configured "branch.*.remote" for a given
/// branch. This branch must be local.
///
/// Throws a [LibGit2Error] if error occured.
String upstreamRemote({
  required Pointer<git_repository> repoPointer,
  required String branchName,
}) {
  final out = calloc<git_buf>();
  final branchNameC = branchName.toChar();
  final error = libgit2.git_branch_upstream_remote(
    out,
    repoPointer,
    branchNameC,
  );

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Retrieve the upstream merge of a local branch.
///
/// This will return the currently configured "branch.*.merge" for a given
/// branch. This branch must be local.
///
/// Throws a [LibGit2Error] if error occured.
String upstreamMerge({
  required Pointer<git_repository> repoPointer,
  required String branchName,
}) {
  final out = calloc<git_buf>();
  final branchNameC = branchName.toChar();
  final error = libgit2.git_branch_upstream_merge(
    out,
    repoPointer,
    branchNameC,
  );

  final result = out.ref.ptr.toDartString(length: out.ref.size);

  libgit2.git_buf_dispose(out);
  calloc.free(out);
  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Free the given reference to release memory.
void free(Pointer<git_reference> ref) => reference_bindings.free(ref);
