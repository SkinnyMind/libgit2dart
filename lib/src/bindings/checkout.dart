import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Updates files in the index and the working tree to match the content of the commit
/// pointed at by HEAD.
///
/// Note that this is not the correct mechanism used to switch branches; do not change
/// your HEAD and then call this method, that would leave you with checkout conflicts
/// since your working directory would then appear to be dirty. Instead, checkout the
/// target of the branch and then update HEAD using `setHead` to point to the branch you checked out.
///
/// Throws a [LibGit2Error] if error occured.
void head(
  Pointer<git_repository> repo,
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final initOptions = _initOptions(strategy, directory, paths);
  final optsC = initOptions[0];
  final pathPointers = initOptions[1];
  final strArray = initOptions[2];

  final error = libgit2.git_checkout_head(repo, optsC);

  for (var p in pathPointers) {
    calloc.free(p);
  }

  calloc.free(strArray);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Updates files in the working tree to match the content of the index.
///
/// Throws a [LibGit2Error] if error occured.
void index(
  Pointer<git_repository> repo,
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final initOptions = _initOptions(strategy, directory, paths);
  final optsC = initOptions[0];
  final pathPointers = initOptions[1];
  final strArray = initOptions[2];

  final error = libgit2.git_checkout_index(repo, nullptr, optsC);

  for (var p in pathPointers) {
    calloc.free(p);
  }

  calloc.free(strArray);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Updates files in the index and working tree to match the content of the tree
/// pointed at by the treeish.
///
/// Throws a [LibGit2Error] if error occured.
void tree(
  Pointer<git_repository> repo,
  Pointer<git_object> treeish,
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final initOptions = _initOptions(strategy, directory, paths);
  final optsC = initOptions[0];
  final pathPointers = initOptions[1];
  final strArray = initOptions[2];

  final error = libgit2.git_checkout_tree(repo, treeish, optsC);

  for (var p in pathPointers) {
    calloc.free(p);
  }

  calloc.free(strArray);
  calloc.free(optsC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

List<dynamic> _initOptions(
  int strategy,
  String? directory,
  List<String>? paths,
) {
  final optsC = calloc<git_checkout_options>(sizeOf<git_checkout_options>());
  libgit2.git_checkout_options_init(optsC, GIT_CHECKOUT_OPTIONS_VERSION);
  optsC.ref.checkout_strategy = strategy;
  if (directory != null) {
    optsC.ref.target_directory = directory.toNativeUtf8().cast<Int8>();
  }
  List<Pointer<Int8>> pathPointers = [];
  Pointer<Pointer<Int8>> strArray = nullptr;
  if (paths != null) {
    pathPointers = paths.map((e) => e.toNativeUtf8().cast<Int8>()).toList();
    strArray = calloc(paths.length);
    for (var i = 0; i < paths.length; i++) {
      strArray[i] = pathPointers[i];
    }
    optsC.ref.paths.strings = strArray;
    optsC.ref.paths.count = paths.length;
  }

  var result = <dynamic>[];
  result.add(optsC);
  result.add(pathPointers);
  result.add(strArray);
  return result;
}
