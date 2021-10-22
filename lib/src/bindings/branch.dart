import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';

import '../error.dart';
import '../util.dart';
import 'libgit2_bindings.dart';
import 'reference.dart' as reference_bindings;

/// Return a list of branches.
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

  var result = <Pointer<git_reference>>[];
  var error = 0;

  while (error == 0) {
    final reference = calloc<Pointer<git_reference>>();
    final refType = calloc<Int32>();
    error = libgit2.git_branch_next(reference, refType, iterator.value);
    if (error == 0) {
      result.add(reference.value);
      calloc.free(refType);
    } else {
      break;
    }
  }

  libgit2.git_branch_iterator_free(iterator.value);
  return result;
}

/// Lookup a branch by its name in a repository.
///
/// The generated reference must be freed by the user. The branch name will be
/// checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> lookup({
  required Pointer<git_repository> repoPointer,
  required String branchName,
  required int branchType,
}) {
  final out = calloc<Pointer<git_reference>>();
  final branchNameC = branchName.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_branch_lookup(
    out,
    repoPointer,
    branchNameC,
    branchType,
  );

  calloc.free(branchNameC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new branch pointing at a target commit.
///
/// A new direct reference will be created pointing to this target commit.
/// If force is true and a reference already exists with the given name, it'll
/// be replaced.
///
/// The returned reference must be freed by the user.
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
  final branchNameC = branchName.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_branch_create(
    out,
    repoPointer,
    branchNameC,
    targetPointer,
    forceC,
  );

  calloc.free(branchNameC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Delete an existing branch reference.
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
/// Throws a [LibGit2Error] if error occured.
void rename({
  required Pointer<git_reference> branchPointer,
  required String newBranchName,
  required bool force,
}) {
  final out = calloc<Pointer<git_reference>>();
  final newBranchNameC = newBranchName.toNativeUtf8().cast<Int8>();
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
    return result == 1 ? true : false;
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
    return result == 1 ? true : false;
  }
}

/// Get the branch name.
///
/// Given a reference object, this will check that it really is a branch
/// (ie. it lives under "refs/heads/" or "refs/remotes/"), and return the branch part of it.
///
/// Throws a [LibGit2Error] if error occured.
String name(Pointer<git_reference> ref) {
  final out = calloc<Pointer<Int8>>();
  final error = libgit2.git_branch_name(out, ref);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.value.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}

/// Free the given reference to release memory.
void free(Pointer<git_reference> ref) => reference_bindings.free(ref);
