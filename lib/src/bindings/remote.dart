import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/remote_callbacks.dart';
import 'package:libgit2dart/src/callbacks.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/oid.dart';
import 'package:libgit2dart/src/util.dart';

/// Get a list of the configured remotes for a repo.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  libgit2.git_remote_list(out, repo);

  final result = <String>[
    for (var i = 0; i < out.ref.count; i++) out.ref.strings[i].toDartString()
  ];

  calloc.free(out);

  return result;
}

/// Get the information for a particular remote. The returned remote must be
/// freed with [free].
///
/// The name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> lookup({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toChar();
  final error = libgit2.git_remote_lookup(out, repoPointer, nameC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Add a remote with the default fetch refspec to the repository's
/// configuration. The returned remote must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> create({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String url,
}) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toChar();
  final urlC = url.toChar();
  final error = libgit2.git_remote_create(out, repoPointer, nameC, urlC);

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Add a remote with the provided fetch refspec to the repository's
/// configuration. The returned remote must be freed with [free].
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> createWithFetchSpec({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String url,
  required String fetch,
}) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toChar();
  final urlC = url.toChar();
  final fetchC = fetch.toChar();
  final error = libgit2.git_remote_create_with_fetchspec(
    out,
    repoPointer,
    nameC,
    urlC,
    fetchC,
  );

  final result = out.value;

  calloc.free(out);
  calloc.free(nameC);
  calloc.free(urlC);
  calloc.free(fetchC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return result;
  }
}

/// Delete an existing persisted remote.
///
/// All remote-tracking branches and configuration settings for the remote will
/// be removed.
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_repository> repoPointer,
  required String name,
}) {
  final nameC = name.toChar();
  final error = libgit2.git_remote_delete(repoPointer, nameC);

  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Give the remote a new name.
///
/// Returns list of non-default refspecs that cannot be renamed.
///
/// All remote-tracking branches and configuration settings for the remote are
/// updated.
///
/// The new name will be checked for validity.
///
/// No loaded instances of a the remote with the old name will change their
/// name or their list of refspecs.
///
/// Throws a [LibGit2Error] if error occured.
List<String> rename({
  required Pointer<git_repository> repoPointer,
  required String name,
  required String newName,
}) {
  final out = calloc<git_strarray>();
  final nameC = name.toChar();
  final newNameC = newName.toChar();
  final error = libgit2.git_remote_rename(out, repoPointer, nameC, newNameC);

  calloc.free(nameC);
  calloc.free(newNameC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final result = <String>[
      for (var i = 0; i < out.ref.count; i++) out.ref.strings[i].toDartString()
    ];

    calloc.free(out);

    return result;
  }
}

/// Set the remote's url in the configuration.
///
/// Remote objects already in memory will not be affected. This assumes the
/// common case of a single-url remote and will otherwise return an error.
///
/// Throws a [LibGit2Error] if error occured.
void setUrl({
  required Pointer<git_repository> repoPointer,
  required String remote,
  required String url,
}) {
  final remoteC = remote.toChar();
  final urlC = url.toChar();
  final error = libgit2.git_remote_set_url(repoPointer, remoteC, urlC);

  calloc.free(remoteC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the remote's url for pushing in the configuration.
///
/// Remote objects already in memory will not be affected. This assumes the
/// common case of a single-url remote and will otherwise return an error.
///
/// Throws a [LibGit2Error] if error occured.
void setPushUrl({
  required Pointer<git_repository> repoPointer,
  required String remote,
  required String url,
}) {
  final remoteC = remote.toChar();
  final urlC = url.toChar();
  final error = libgit2.git_remote_set_pushurl(repoPointer, remoteC, urlC);

  calloc.free(remoteC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the remote's name.
String name(Pointer<git_remote> remote) {
  final result = libgit2.git_remote_name(remote);
  return result == nullptr ? '' : result.toDartString();
}

/// Get the remote's url.
String url(Pointer<git_remote> remote) {
  return libgit2.git_remote_url(remote).toDartString();
}

/// Get the remote's url for pushing.
///
/// Returns empty string if no special url for pushing is set.
String pushUrl(Pointer<git_remote> remote) {
  final result = libgit2.git_remote_pushurl(remote);
  return result == nullptr ? '' : result.toDartString();
}

/// Get the number of refspecs for a remote.
int refspecCount(Pointer<git_remote> remote) =>
    libgit2.git_remote_refspec_count(remote);

/// Get a refspec from the remote at provided position.
Pointer<git_refspec> getRefspec({
  required Pointer<git_remote> remotePointer,
  required int position,
}) {
  return libgit2.git_remote_get_refspec(remotePointer, position);
}

/// Get the remote's list of fetch refspecs.
List<String> fetchRefspecs(Pointer<git_remote> remote) {
  final out = calloc<git_strarray>();
  libgit2.git_remote_get_fetch_refspecs(out, remote);

  final result = <String>[
    for (var i = 0; i < out.ref.count; i++) out.ref.strings[i].toDartString()
  ];

  calloc.free(out);

  return result;
}

/// Get the remote's list of push refspecs.
List<String> pushRefspecs(Pointer<git_remote> remote) {
  final out = calloc<git_strarray>();
  libgit2.git_remote_get_push_refspecs(out, remote);

  final result = <String>[
    for (var i = 0; i < out.ref.count; i++) out.ref.strings[i].toDartString()
  ];

  calloc.free(out);

  return result;
}

/// Add a fetch refspec to the remote's configuration.
///
/// Add the given refspec to the fetch list in the configuration. No loaded
/// remote instances will be affected.
///
/// Throws a [LibGit2Error] if error occured.
void addFetch({
  required Pointer<git_repository> repoPointer,
  required String remote,
  required String refspec,
}) {
  final remoteC = remote.toChar();
  final refspecC = refspec.toChar();
  final error = libgit2.git_remote_add_fetch(repoPointer, remoteC, refspecC);

  calloc.free(remoteC);
  calloc.free(refspecC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add a push refspec to the remote's configuration.
///
/// Add the given refspec to the push list in the configuration. No loaded
/// remote instances will be affected.
///
/// Throws a [LibGit2Error] if error occured.
void addPush({
  required Pointer<git_repository> repoPointer,
  required String remote,
  required String refspec,
}) {
  final remoteC = remote.toChar();
  final refspecC = refspec.toChar();
  final error = libgit2.git_remote_add_push(repoPointer, remoteC, refspecC);

  calloc.free(remoteC);
  calloc.free(refspecC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Open a connection to a remote.
///
/// The transport is selected based on the URL. The direction argument is due
/// to a limitation of the git protocol (over TCP or SSH) which starts up a
/// specific binary which can only do the one or the other.
///
/// Throws a [LibGit2Error] if error occured.
void connect({
  required Pointer<git_remote> remotePointer,
  required int direction,
  required Callbacks callbacks,
  String? proxyOption,
}) {
  final callbacksOptions = calloc<git_remote_callbacks>();
  libgit2.git_remote_init_callbacks(
    callbacksOptions,
    GIT_REMOTE_CALLBACKS_VERSION,
  );

  RemoteCallbacks.plug(
    callbacksOptions: callbacksOptions.ref,
    callbacks: callbacks,
  );

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final error = libgit2.git_remote_connect(
    remotePointer,
    direction,
    callbacksOptions,
    proxyOptions,
    nullptr,
  );

  calloc.free(callbacksOptions);
  calloc.free(proxyOptions);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the remote repository's reference advertisement list.
///
/// Get the list of references with which the server responds to a new
/// connection.
///
/// The remote (or more exactly its transport) must have connected to the
/// remote repository. This list is available as soon as the connection to the
/// remote is initiated and it remains available after disconnecting.
///
/// Throws a [LibGit2Error] if error occured.
List<Map<String, Object?>> lsRemotes(Pointer<git_remote> remote) {
  final out = calloc<Pointer<Pointer<git_remote_head>>>();
  final size = calloc<Size>();
  libgit2.git_remote_ls(out, size, remote);

  final result = <Map<String, Object?>>[];

  for (var i = 0; i < size.value; i++) {
    final remote = <String, Object?>{};

    final local = out[0][i].ref.local == 1 || false;

    remote['local'] = local;
    remote['loid'] = local ? Oid.fromRaw(out[0][i].ref.loid) : null;
    remote['name'] =
        out[0][i].ref.name == nullptr ? '' : out[0][i].ref.name.toDartString();
    remote['symref'] = out[0][i].ref.symref_target == nullptr
        ? ''
        : out[0][i].ref.symref_target.toDartString();
    remote['oid'] = Oid.fromRaw(out[0][i].ref.oid);

    result.add(remote);
  }

  calloc.free(out);
  calloc.free(size);

  return result;
}

/// Download new data and update tips.
///
/// Convenience function to connect to a remote, download the data, disconnect
/// and update the remote-tracking branches.
///
/// Throws a [LibGit2Error] if error occured.
void fetch({
  required Pointer<git_remote> remotePointer,
  required List<String> refspecs,
  required int prune,
  required Callbacks callbacks,
  String? reflogMessage,
  String? proxyOption,
}) {
  final refspecsC = calloc<git_strarray>();
  final refspecsPointers = refspecs.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(refspecs.length);

  for (var i = 0; i < refspecs.length; i++) {
    strArray[i] = refspecsPointers[i];
  }

  refspecsC.ref.count = refspecs.length;
  refspecsC.ref.strings = strArray;
  final reflogMessageC = reflogMessage?.toChar() ?? nullptr;

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final opts = calloc<git_fetch_options>();
  libgit2.git_fetch_options_init(opts, GIT_FETCH_OPTIONS_VERSION);

  RemoteCallbacks.plug(
    callbacksOptions: opts.ref.callbacks,
    callbacks: callbacks,
  );
  opts.ref.prune = prune;
  opts.ref.proxy_opts = proxyOptions.ref;

  final error = libgit2.git_remote_fetch(
    remotePointer,
    refspecsC,
    opts,
    reflogMessageC,
  );

  for (final p in refspecsPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
  calloc.free(refspecsC);
  calloc.free(proxyOptions);
  calloc.free(reflogMessageC);
  calloc.free(opts);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Perform a push.
///
/// Throws a [LibGit2Error] if error occured.
void push({
  required Pointer<git_remote> remotePointer,
  required List<String> refspecs,
  required Callbacks callbacks,
  String? proxyOption,
}) {
  final refspecsC = calloc<git_strarray>();
  final refspecsPointers = refspecs.map((e) => e.toChar()).toList();
  final strArray = calloc<Pointer<Char>>(refspecs.length);

  for (var i = 0; i < refspecs.length; i++) {
    strArray[i] = refspecsPointers[i];
  }

  refspecsC.ref.count = refspecs.length;
  refspecsC.ref.strings = strArray;

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final opts = calloc<git_push_options>();
  libgit2.git_push_options_init(opts, GIT_PUSH_OPTIONS_VERSION);

  RemoteCallbacks.plug(
    callbacksOptions: opts.ref.callbacks,
    callbacks: callbacks,
  );
  opts.ref.proxy_opts = proxyOptions.ref;

  final error = libgit2.git_remote_push(remotePointer, refspecsC, opts);

  for (final p in refspecsPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
  calloc.free(refspecsC);
  calloc.free(proxyOptions);
  calloc.free(opts);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the statistics structure that is filled in by the fetch operation.
Pointer<git_indexer_progress> stats(Pointer<git_remote> remote) =>
    libgit2.git_remote_stats(remote);

/// Close the connection to the remote.
void disconnect(Pointer<git_remote> remote) =>
    libgit2.git_remote_disconnect(remote);

/// Prune tracking refs that are no longer present on remote.
///
/// Throws a [LibGit2Error] if error occured.
void prune({
  required Pointer<git_remote> remotePointer,
  required Callbacks callbacks,
}) {
  final callbacksOptions = calloc<git_remote_callbacks>();
  libgit2.git_remote_init_callbacks(
    callbacksOptions,
    GIT_REMOTE_CALLBACKS_VERSION,
  );

  RemoteCallbacks.plug(
    callbacksOptions: callbacksOptions.ref,
    callbacks: callbacks,
  );

  final error = libgit2.git_remote_prune(remotePointer, callbacksOptions);

  calloc.free(callbacksOptions);
  RemoteCallbacks.reset();

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Free the memory associated with a remote.
///
/// This also disconnects from the remote, if the connection has not been closed
/// yet (using [disconnect]).
void free(Pointer<git_remote> remote) => libgit2.git_remote_free(remote);

/// Initializes git_proxy_options structure.
Pointer<git_proxy_options> _proxyOptionsInit(String? proxyOption) {
  final proxyOptions = calloc<git_proxy_options>();
  libgit2.git_proxy_options_init(proxyOptions, GIT_PROXY_OPTIONS_VERSION);

  if (proxyOption == null) {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_NONE;
  } else if (proxyOption == 'auto') {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_AUTO;
  } else {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_SPECIFIED;
    proxyOptions.ref.url = proxyOption.toChar();
  }

  return proxyOptions;
}
