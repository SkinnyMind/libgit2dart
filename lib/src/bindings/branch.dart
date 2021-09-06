import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'libgit2_bindings.dart';
import 'reference.dart' as reference_bindings;
import '../error.dart';
import '../util.dart';

/// Return a list of branches.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo, int listFlags) {
  final iterator = calloc<Pointer<git_branch_iterator>>();
  final iteratorError = libgit2.git_branch_iterator_new(
    iterator,
    repo,
    listFlags,
  );

  if (iteratorError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  var result = <String>[];
  var error = 0;

  while (error == 0) {
    final reference = calloc<Pointer<git_reference>>();
    final refType = calloc<Int32>();
    error = libgit2.git_branch_next(reference, refType, iterator.value);
    if (error == 0) {
      final refName = reference_bindings.shorthand(reference.value);
      result.add(refName);
      calloc.free(refType);
      calloc.free(reference);
    } else {
      break;
    }
  }

  libgit2.git_branch_iterator_free(iterator.value);
  return result;
}

/// Lookup a branch by its name in a repository.
///
/// The generated reference must be freed by the user. The branch name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> lookup(
  Pointer<git_repository> repo,
  String branchName,
  int branchType,
) {
  final out = calloc<Pointer<git_reference>>();
  final branchNameC = branchName.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_branch_lookup(out, repo, branchNameC, branchType);

  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Create a new branch pointing at a target commit.
///
/// A new direct reference will be created pointing to this target commit.
/// If force is true and a reference already exists with the given name, it'll be replaced.
///
/// The returned reference must be freed by the user.
///
/// The branch name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> create(
  Pointer<git_repository> repo,
  String branchName,
  Pointer<git_commit> target,
  bool force,
) {
  final out = calloc<Pointer<git_reference>>();
  final branchNameC = branchName.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_branch_create(
    out,
    repo,
    branchNameC,
    target,
    forceC,
  );

  calloc.free(branchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Delete an existing branch reference.
///
/// Note that if the deletion succeeds, the reference object will not be valid anymore,
/// and will be freed.
///
/// Throws a [LibGit2Error] if error occured.
void delete(Pointer<git_reference> branch) {
  final error = libgit2.git_branch_delete(branch);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    reference_bindings.free(branch);
  }
}

/// Move/rename an existing local branch reference.
///
/// The new branch name will be checked for validity.
///
/// Note that if the move succeeds, the old reference object will not be valid anymore,
/// and will be freed immediately.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_reference> rename(
  Pointer<git_reference> branch,
  String newBranchName,
  bool force,
) {
  final out = calloc<Pointer<git_reference>>();
  final newBranchNameC = newBranchName.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_branch_move(out, branch, newBranchNameC, forceC);

  calloc.free(newBranchNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    reference_bindings.free(branch);
    return out.value;
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
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = out.value.cast<Utf8>().toDartString();
    calloc.free(out);
    return result;
  }
}

/// Free the given reference to release memory.
void free(Pointer<git_reference> ref) => reference_bindings.free(ref);
