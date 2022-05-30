import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/checkout.dart' as checkout_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/oid.dart';
import 'package:libgit2dart/src/stash.dart';
import 'package:libgit2dart/src/util.dart';

/// Save the local modifications to a new stash.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> save({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_signature> stasherPointer,
  String? message,
  required int flags,
}) {
  final out = calloc<git_oid>();
  final messageC = message?.toChar() ?? nullptr;
  final error = libgit2.git_stash_save(
    out,
    repoPointer,
    stasherPointer,
    messageC,
    flags,
  );

  calloc.free(messageC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Apply a single stashed state from the stash list.
///
/// Throws a [LibGit2Error] if error occured.
void apply({
  required Pointer<git_repository> repoPointer,
  required int index,
  required int flags,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final options = calloc<git_stash_apply_options>();
  libgit2.git_stash_apply_options_init(
    options,
    GIT_STASH_APPLY_OPTIONS_VERSION,
  );

  final checkoutOptions = checkout_bindings.initOptions(
    strategy: strategy,
    directory: directory,
    paths: paths,
  );
  final optsC = checkoutOptions[0];
  final pathPointers = checkoutOptions[1];
  final strArray = checkoutOptions[2];

  options.ref.flags = flags;
  options.ref.checkout_options = (optsC as Pointer<git_checkout_options>).ref;

  final error = libgit2.git_stash_apply(repoPointer, index, options);

  for (final p in pathPointers as List) {
    calloc.free(p as Pointer);
  }
  calloc.free(strArray as Pointer);
  calloc.free(optsC);
  calloc.free(options);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Remove a single stashed state from the stash list.
///
/// Throws a [LibGit2Error] if error occured.
void drop({required Pointer<git_repository> repoPointer, required int index}) {
  final error = libgit2.git_stash_drop(repoPointer, index);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Apply a single stashed state from the stash list and remove it from the
/// list if successful.
///
/// Throws a [LibGit2Error] if error occured.
void pop({
  required Pointer<git_repository> repoPointer,
  required int index,
  required int flags,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final options = calloc<git_stash_apply_options>();
  libgit2.git_stash_apply_options_init(
    options,
    GIT_STASH_APPLY_OPTIONS_VERSION,
  );

  final checkoutOptions = checkout_bindings.initOptions(
    strategy: strategy,
    directory: directory,
    paths: paths,
  );
  final optsC = checkoutOptions[0];
  final pathPointers = checkoutOptions[1];
  final strArray = checkoutOptions[2];

  options.ref.flags = flags;
  options.ref.checkout_options = (optsC as Pointer<git_checkout_options>).ref;

  final error = libgit2.git_stash_pop(repoPointer, index, options);

  for (final p in pathPointers as List) {
    calloc.free(p as Pointer);
  }
  calloc.free(strArray as Pointer);
  calloc.free(optsC);
  calloc.free(options);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// List of stashed states.
///
/// IMPORTANT: make sure to clear that list since it's a global variable.
var _stashList = <Stash>[];

/// A callback function to iterate over all the stashed states.
int _stashCb(
  int index,
  Pointer<Char> message,
  Pointer<git_oid> oid,
  Pointer<Void> payload,
) {
  _stashList.add(
    Stash(index: index, message: message.toDartString(), oid: Oid(oid)),
  );
  return 0;
}

/// Loop over all the stashed states.
List<Stash> list(Pointer<git_repository> repo) {
  const except = -1;
  // ignore: omit_local_variable_types
  final git_stash_cb callBack = Pointer.fromFunction(_stashCb, except);
  libgit2.git_stash_foreach(repo, callBack, nullptr);

  final result = _stashList.toList(growable: false);
  _stashList.clear();

  return result;
}
