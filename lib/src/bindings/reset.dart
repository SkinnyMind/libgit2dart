import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
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
///
/// Throws a [LibGit2Error] if error occured.
void reset({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> targetPointer,
  required int resetType,
  int? strategy,
  String? checkoutDirectory,
  List<String>? pathspec,
}) {
  final opts = calloc<git_checkout_options>();
  libgit2.git_checkout_options_init(opts, GIT_CHECKOUT_OPTIONS_VERSION);

  if (strategy != null) {
    opts.ref.checkout_strategy = strategy;
  }
  if (checkoutDirectory != null) {
    opts.ref.target_directory = checkoutDirectory.toChar();
  }
  var pathPointers = <Pointer<Char>>[];
  Pointer<Pointer<Char>> strArray = nullptr;
  if (pathspec != null) {
    pathPointers = pathspec.map((e) => e.toChar()).toList();
    strArray = calloc(pathspec.length);
    for (var i = 0; i < pathspec.length; i++) {
      strArray[i] = pathPointers[i];
    }
    opts.ref.paths.strings = strArray;
    opts.ref.paths.count = pathspec.length;
  }

  final error = libgit2.git_reset(repoPointer, targetPointer, resetType, opts);

  for (final p in pathPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Updates some entries in the index from the target commit tree.
///
/// The scope of the updated entries is determined by the paths being passed in
/// the [pathspec] parameters.
///
/// Passing a null [targetPointer] will result in removing entries in the index
/// matching the provided [pathspec]s.
///
/// Throws a [LibGit2Error] if error occured.
void resetDefault({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object>? targetPointer,
  required List<String> pathspec,
}) {
  final pathspecC = calloc<git_strarray>();
  final pathPointers = pathspec.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(pathspec.length);

  for (var i = 0; i < pathspec.length; i++) {
    strArray[i] = pathPointers[i];
  }

  pathspecC.ref.strings = strArray;
  pathspecC.ref.count = pathspec.length;

  final error = libgit2.git_reset_default(
    repoPointer,
    targetPointer ?? nullptr,
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
