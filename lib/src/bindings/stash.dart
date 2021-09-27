import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import '../oid.dart';
import '../stash.dart';
import 'checkout.dart' as checkout_bindings;
import 'libgit2_bindings.dart';
import '../util.dart';

/// Save the local modifications to a new stash.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> stash(
  Pointer<git_repository> repo,
  Pointer<git_signature> stasher,
  String message,
  int flags,
) {
  final out = calloc<git_oid>();
  final messageC =
      message.isNotEmpty ? message.toNativeUtf8().cast<Int8>() : nullptr;
  final error = libgit2.git_stash_save(out, repo, stasher, messageC, flags);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Apply a single stashed state from the stash list.
///
/// Throws a [LibGit2Error] if error occured.
void apply(
  Pointer<git_repository> repo,
  int index,
  int flags,
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final options =
      calloc<git_stash_apply_options>(sizeOf<git_stash_apply_options>());
  final optionsError = libgit2.git_stash_apply_options_init(
      options, GIT_STASH_APPLY_OPTIONS_VERSION);

  if (optionsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final checkoutOptions =
      checkout_bindings.initOptions(strategy, directory, paths);
  final optsC = checkoutOptions[0];
  final pathPointers = checkoutOptions[1];
  final strArray = checkoutOptions[2];

  options.ref.flags = flags;
  options.ref.checkout_options = (optsC as Pointer<git_checkout_options>).ref;

  final error = libgit2.git_stash_apply(repo, index, options);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  for (var p in pathPointers) {
    calloc.free(p);
  }

  calloc.free(strArray);
  calloc.free(optsC);
  calloc.free(options);
}

/// Remove a single stashed state from the stash list.
///
/// Throws a [LibGit2Error] if error occured.
void drop(Pointer<git_repository> repo, int index) {
  libgit2.git_stash_drop(repo, index);
}

/// Apply a single stashed state from the stash list and remove it from the list if successful.
///
/// Throws a [LibGit2Error] if error occured.
void pop(
  Pointer<git_repository> repo,
  int index,
  int flags,
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final options =
      calloc<git_stash_apply_options>(sizeOf<git_stash_apply_options>());
  final optionsError = libgit2.git_stash_apply_options_init(
      options, GIT_STASH_APPLY_OPTIONS_VERSION);

  if (optionsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final checkoutOptions =
      checkout_bindings.initOptions(strategy, directory, paths);
  final optsC = checkoutOptions[0];
  final pathPointers = checkoutOptions[1];
  final strArray = checkoutOptions[2];

  options.ref.flags = flags;
  options.ref.checkout_options = (optsC as Pointer<git_checkout_options>).ref;

  final error = libgit2.git_stash_pop(repo, index, options);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  for (var p in pathPointers) {
    calloc.free(p);
  }

  calloc.free(strArray);
  calloc.free(optsC);
  calloc.free(options);
}

var _stashList = <Stash>[];

/// Loop over all the stashed states.
List<Stash> list(Pointer<git_repository> repo) {
  const except = -1;
  git_stash_cb callBack = Pointer.fromFunction(_stashCb, except);
  libgit2.git_stash_foreach(repo, callBack, nullptr);

  final result = _stashList.toList(growable: false);
  _stashList.clear();

  return result;
}

int _stashCb(
  int index,
  Pointer<Int8> message,
  Pointer<git_oid> oid,
  Pointer<Void> payload,
) {
  _stashList.add(Stash(
    index: index,
    message: message.cast<Utf8>().toDartString(),
    oid: Oid(oid),
  ));
  return 0;
}
