import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// Updates files in the index and the working tree to match the content of the
/// commit pointed at by HEAD.
///
/// Note that this is not the correct mechanism used to switch branches; do not
/// change your HEAD and then call this method, that would leave you with
/// checkout conflicts since your working directory would then appear to be
/// dirty. Instead, checkout the target of the branch and then update HEAD
/// using [setHead] to point to the branch you checked out.
///
/// Throws a [LibGit2Error] if error occured.
void head({
  required Pointer<git_repository> repoPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final initOpts = initOptions(
    strategy: strategy,
    directory: directory,
    paths: paths,
  );
  final optsC = initOpts[0];
  final pathPointers = initOpts[1];
  final strArray = initOpts[2];

  final error = libgit2.git_checkout_head(
    repoPointer,
    optsC as Pointer<git_checkout_options>,
  );

  for (final p in pathPointers as List) {
    calloc.free(p as Pointer);
  }
  calloc.free(strArray as Pointer);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Updates files in the working tree to match the content of the index.
///
/// Throws a [LibGit2Error] if error occured.
void index({
  required Pointer<git_repository> repoPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final initOpts = initOptions(
    strategy: strategy,
    directory: directory,
    paths: paths,
  );
  final optsC = initOpts[0];
  final pathPointers = initOpts[1];
  final strArray = initOpts[2];

  final error = libgit2.git_checkout_index(
    repoPointer,
    nullptr,
    optsC as Pointer<git_checkout_options>,
  );

  for (final p in pathPointers as List) {
    calloc.free(p as Pointer);
  }
  calloc.free(strArray as Pointer);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Updates files in the index and working tree to match the content of the tree
/// pointed at by the treeish.
void tree({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_object> treeishPointer,
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final initOpts = initOptions(
    strategy: strategy,
    directory: directory,
    paths: paths,
  );
  final optsC = initOpts[0];
  final pathPointers = initOpts[1];
  final strArray = initOpts[2];

  final error = libgit2.git_checkout_tree(
    repoPointer,
    treeishPointer,
    optsC as Pointer<git_checkout_options>,
  );

  for (final p in pathPointers as List) {
    calloc.free(p as Pointer);
  }
  calloc.free(strArray as Pointer);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

List<Object> initOptions({
  required int strategy,
  String? directory,
  List<String>? paths,
}) {
  final optsC = calloc<git_checkout_options>();
  libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);

  optsC.ref.checkout_strategy = strategy;

  if (directory != null) {
    optsC.ref.target_directory = directory.toChar();
  }

  var pathPointers = <Pointer<Char>>[];
  Pointer<Pointer<Char>> strArray = nullptr;
  if (paths != null) {
    pathPointers = paths.map((e) => e.toChar()).toList();
    strArray = calloc(paths.length);
    for (var i = 0; i < paths.length; i++) {
      strArray[i] = pathPointers[i];
    }
    optsC.ref.paths.strings = strArray;
    optsC.ref.paths.count = paths.length;
  }

  return [optsC, pathPointers, strArray];
}
