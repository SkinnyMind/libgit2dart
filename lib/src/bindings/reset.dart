import 'dart:ffi';

import '../util.dart';
import 'libgit2_bindings.dart';

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
void reset({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> targetPointer,
  required int resetType,
  required Pointer<git_checkout_options> checkoutOptsPointer,
}) {
  libgit2.git_reset(repoPointer, targetPointer, resetType, checkoutOptsPointer);
}
