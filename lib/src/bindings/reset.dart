import 'dart:ffi';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Sets the current head to the specified commit oid and optionally resets the index
/// and working tree to match.
///
/// SOFT reset means the Head will be moved to the commit.
///
/// MIXED reset will trigger a SOFT reset, plus the index will be replaced with the
/// content of the commit tree.
///
/// HARD reset will trigger a MIXED reset and the working directory will be replaced
/// with the content of the index. (Untracked and ignored files will be left alone, however.)
///
/// Throws a [LibGit2Error] if error occured.
void reset({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> targetPointer,
  required int resetType,
  required Pointer<git_checkout_options> checkoutOptsPointer,
}) {
  final error = libgit2.git_reset(
    repoPointer,
    targetPointer,
    resetType,
    checkoutOptsPointer,
  );

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}
