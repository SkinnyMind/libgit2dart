import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/remote_callbacks.dart';
import 'package:libgit2dart/src/callbacks.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

/// List of submodule paths.
///
/// IMPORTANT: make sure to clear that list since it's a global variable.
List<String> _pathsList = [];

/// Function to be called with the name of each submodule.
int _listCb(
  Pointer<git_submodule> submodule,
  Pointer<Char> name,
  Pointer<Void> payload,
) {
  _pathsList.add(path(submodule));
  return 0;
}

/// Returns a list with all tracked submodules paths of a repository.
List<String> list(Pointer<git_repository> repo) {
  const except = -1;
  final callback = Pointer.fromFunction<
      Int Function(Pointer<git_submodule>, Pointer<Char>, Pointer<Void>)>(
    _listCb,
    except,
  );

  libgit2.git_submodule_foreach(repo, callback, nullptr);

  final result = _pathsList.toList(growable: false);
  _pathsList.clear();
  return result;
}

/// Lookup submodule information by name or path. The returned submodule must
/// be freed with [free].
///
/// Given either the submodule name or path (they are usually the same), this
/// returns a structure describing the submodule.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_submodule> lookup({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_submodule>>();
  final nameC = name.toChar();

  final error = libgit2.git_submodule_lookup(out, repoPointer, nameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Copy submodule info into `.git/config` file.
///
/// Just like `git submodule init`, this copies information about the
/// submodule into `.git/config`.
///
/// By default, existing entries will not be overwritten, but setting
/// [overwrite] to true forces them to be updated.
void init({
  required Pointer<git_submodule> submodulePointer,
  bool overwrite = false,
}) {
  final overwriteC = overwrite ? 1 : 0;
  libgit2.git_submodule_init(submodulePointer, overwriteC);
}

/// Update a submodule. This will clone a missing submodule and checkout the
/// subrepository to the commit specified in the index of the containing
/// repository. If the submodule repository doesn't contain the target commit
/// (e.g. because fetchRecurseSubmodules isn't set), then the submodule is
/// fetched using the fetch options supplied in [callbacks].
///
/// If the submodule is not initialized, setting [init] to true will initialize
/// the submodule before updating. Otherwise, this will return an error if
/// attempting to update an uninitialzed repository.
///
/// Throws a [LibGit2Error] if error occured.
void update({
  required Pointer<git_submodule> submodulePointer,
  bool init = false,
  required Callbacks callbacks,
}) {
  final initC = init ? 1 : 0;
  final options = calloc<git_submodule_update_options>();
  libgit2.git_submodule_update_options_init(
    options,
    GIT_SUBMODULE_UPDATE_OPTIONS_VERSION,
  );

  RemoteCallbacks.plug(
    callbacksOptions: options.ref.fetch_opts.callbacks,
    callbacks: callbacks,
  );

  final error = libgit2.git_submodule_update(submodulePointer, initC, options);

  calloc.free(options);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Open the repository for a submodule.
///
/// This is a newly opened repository object. The caller is responsible for
/// calling free on it when done. Multiple calls to this function will return
/// distinct git repository objects. This will only work if the submodule is
/// checked out into the working directory.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_repository> open(Pointer<git_submodule> submodule) {
  final out = calloc<Pointer<git_repository>>();
  final error = libgit2.git_submodule_open(out, submodule);

  final result = out.value;

  calloc.free(out);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Set up a new git submodule for checkout. The returned submodule must be
/// freed with [free].
///
/// This does `git submodule add` up to the fetch and checkout of the submodule
/// contents. It preps a new submodule, creates an entry in `.gitmodules` and
/// creates an empty initialized repository either at the given path in the
/// working directory or in `.git/modules` with a gitlink from the working
/// directory to the new repo.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_submodule> addSetup({
  required Pointer<git_repository> repoPointer,
  required String url,
  required String path,
  bool useGitlink = true,
}) {
  final out = calloc<Pointer<git_submodule>>();
  final urlC = url.toChar();
  final pathC = path.toChar();
  final useGitlinkC = useGitlink ? 1 : 0;
  final error = libgit2.git_submodule_add_setup(
    out,
    repoPointer,
    urlC,
    pathC,
    useGitlinkC,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(urlC);
  calloc.free(pathC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Perform the clone step for a newly created submodule.
///
/// Throws a [LibGit2Error] if error occured.
void clone({
  required Pointer<git_submodule> submodule,
  required Callbacks callbacks,
}) {
  final out = calloc<Pointer<git_repository>>();
  final options = calloc<git_submodule_update_options>();
  libgit2.git_submodule_update_options_init(
    options,
    GIT_SUBMODULE_UPDATE_OPTIONS_VERSION,
  );

  RemoteCallbacks.plug(
    callbacksOptions: options.ref.fetch_opts.callbacks,
    callbacks: callbacks,
  );

  final error = libgit2.git_submodule_clone(out, submodule, options);

  calloc.free(options);
  calloc.free(out);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Resolve the setup of a new git submodule.
///
/// This should be called on a submodule once you have called add setup and done
/// the clone of the submodule. This adds the `.gitmodules` file and the newly
/// cloned submodule to the index to be ready to be committed (but doesn't
/// actually do the commit).
void addFinalize(Pointer<git_submodule> submodule) {
  libgit2.git_submodule_add_finalize(submodule);
}

/// Get the status for a submodule.
///
/// This looks at a submodule and tries to determine the status. How deeply it
/// examines the working directory to do this will depend on the [ignore] value.
int status({
  required Pointer<git_repository> repoPointer,
  required String name,
  required int ignore,
}) {
  final out = calloc<UnsignedInt>();
  final nameC = name.toChar();
  libgit2.git_submodule_status(out, repoPointer, nameC, ignore);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);

  return result;
}

/// Copy submodule remote info into submodule repo.
///
/// This copies the information about the submodules URL into the checked out
/// submodule config, acting like `git submodule sync`. This is useful if you
/// have altered the URL for the submodule (or it has been altered by a fetch
/// of upstream changes) and you need to update your local repo.
void sync(Pointer<git_submodule> submodule) =>
    libgit2.git_submodule_sync(submodule);

/// Reread submodule info from config, index, and HEAD.
///
/// Call this to reread cached submodule information for this submodule if you
/// have reason to believe that it has changed.
///
/// Set [force] to true to reload even if the data doesn't seem out of date.
void reload({
  required Pointer<git_submodule> submodulePointer,
  bool force = false,
}) {
  final forceC = force ? 1 : 0;
  libgit2.git_submodule_reload(submodulePointer, forceC);
}

/// Get the name of submodule.
String name(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_name(submodule).toDartString();
}

/// Get the path to the submodule.
///
/// The path is almost always the same as the submodule name, but the two
/// are actually not required to match.
String path(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_path(submodule).toDartString();
}

/// Get the URL for the submodule.
String url(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_url(submodule).toDartString();
}

/// Set the URL for the submodule in the configuration.
///
/// After calling this, you may wish to call [sync] to write the changes to
/// the checked out submodule repository.
void setUrl({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String url,
}) {
  final nameC = name.toChar();
  final urlC = url.toChar();

  libgit2.git_submodule_set_url(repoPointer, nameC, urlC);

  calloc.free(nameC);
  calloc.free(urlC);
}

/// Get the branch for the submodule.
String branch(Pointer<git_submodule> submodule) {
  final result = libgit2.git_submodule_branch(submodule);
  return result == nullptr ? '' : result.toDartString();
}

/// Set the branch for the submodule in the configuration.
///
/// After calling this, you may wish to call [sync] to write the changes to
/// the checked out submodule repository.
void setBranch({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String branch,
}) {
  final nameC = name.toChar();
  final branchC = branch.toChar();

  libgit2.git_submodule_set_branch(repoPointer, nameC, branchC);

  calloc.free(nameC);
  calloc.free(branchC);
}

/// Get the OID for the submodule in the current HEAD tree.
///
/// Returns null if submodule is not in the HEAD.
Pointer<git_oid>? headId(Pointer<git_submodule> submodule) {
  final result = libgit2.git_submodule_head_id(submodule);
  return result == nullptr ? null : result;
}

/// Get the OID for the submodule in the index.
///
/// Returns null if submodule is not in index.
Pointer<git_oid>? indexId(Pointer<git_submodule> submodule) {
  final result = libgit2.git_submodule_index_id(submodule);
  return result == nullptr ? null : result;
}

/// Get the OID for the submodule in the current working directory.
///
/// This returns the OID that corresponds to looking up `HEAD` in the checked
/// out submodule. If there are pending changes in the index or anything else,
/// this won't notice that. You should call [status] for a more complete
/// picture about the state of the working directory.
///
/// Returns null if submodule is not checked out.
Pointer<git_oid>? workdirId(Pointer<git_submodule> submodule) {
  final result = libgit2.git_submodule_wd_id(submodule);
  return result == nullptr ? null : result;
}

/// Get the ignore rule that will be used for the submodule.
int ignore(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_ignore(submodule);
}

/// Set the ignore rule for the submodule in the configuration.
///
/// This does not affect any currently-loaded instances.
void setIgnore({
  required Pointer<git_repository> repoPointer,
  required String name,
  required int ignore,
}) {
  final nameC = name.toChar();
  libgit2.git_submodule_set_ignore(repoPointer, nameC, ignore);
  calloc.free(nameC);
}

/// Get the update rule that will be used for the submodule.
///
/// This value controls the behavior of the `git submodule update` command.
int updateRule(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_update_strategy(submodule);
}

/// Set the update rule for the submodule in the configuration.
///
/// This setting won't affect any existing instances.
void setUpdateRule({
  required Pointer<git_repository> repoPointer,
  required String name,
  required int update,
}) {
  final nameC = name.toChar();
  libgit2.git_submodule_set_update(repoPointer, nameC, update);
  calloc.free(nameC);
}

/// Get the containing repository for a submodule.
///
/// This returns a pointer to the repository that contains the submodule.
/// This is a just a reference to the repository that was passed to the original
/// [lookup] call, so if that repository has been freed, then this may be a
/// dangling reference.
Pointer<git_repository> owner(Pointer<git_submodule> submodule) {
  return libgit2.git_submodule_owner(submodule);
}

/// Release a submodule.
void free(Pointer<git_submodule> submodule) =>
    libgit2.git_submodule_free(submodule);
