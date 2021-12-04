import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/util.dart';

/// Sets the current head to the specified commit oid and optionally resets the
/// index and working tree to match.
///
/// SOFT reset means the Head will be moved to the commit.
///
/// MIXED reset will trigger a SOFT reset, plus the index will be replaced with
/// the content of the commit tree.
///
/// HARD reset will trigger a MIXED reset and the working directory will be
/// replaced with the content of the index. (Untracked and ignored files will
/// be left alone, however.)
void reset({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> targetPointer,
  required int resetType,
  required Pointer<git_checkout_options> checkoutOptsPointer,
}) {
  libgit2.git_reset(repoPointer, targetPointer, resetType, checkoutOptsPointer);
}

/// Updates some entries in the index from the target commit tree.
///
/// The scope of the updated entries is determined by the paths being passed in
/// the pathspec parameters.
///
/// Throws a [LibGit2Error] if error occured.
void resetDefault({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> targetPointer,
  required List<String> pathspec,
}) {
  final pathspecC = calloc<git_strarray>();
  final pathPointers =
      pathspec.map((e) => e.toNativeUtf8().cast<Int8>()).toList();
  final strArray = calloc<Pointer<Int8>>(pathspec.length);

  for (var i = 0; i < pathspec.length; i++) {
    strArray[i] = pathPointers[i];
  }

  pathspecC.ref.strings = strArray;
  pathspecC.ref.count = pathspec.length;

  final error = libgit2.git_reset_default(
    repoPointer,
    targetPointer,
    pathspecC,
  );

  calloc.free(pathspecC);
  for (final p in pathPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}
