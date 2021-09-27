import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../error.dart';
import '../oid.dart';
import 'libgit2_bindings.dart';
import '../util.dart';

/// Get a list of the configured remotes for a repo.
///
/// Throws a [LibGit2Error] if error occured.
List<String> list(Pointer<git_repository> repo) {
  final out = calloc<git_strarray>();
  final error = libgit2.git_remote_list(out, repo);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final count = out.ref.count;
    var result = <String>[];
    for (var i = 0; i < count; i++) {
      result.add(out.ref.strings[i].cast<Utf8>().toDartString());
    }
    calloc.free(out);
    return result;
  }
}

/// Get the information for a particular remote.
///
/// The name will be checked for validity.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> lookup(Pointer<git_repository> repo, String name) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_lookup(out, repo, nameC);

  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Add a remote with the default fetch refspec to the repository's configuration.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> create(
  Pointer<git_repository> repo,
  String name,
  String url,
) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final urlC = url.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_create(out, repo, nameC, urlC);

  calloc.free(nameC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Add a remote with the provided fetch refspec to the repository's configuration.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_remote> createWithFetchSpec(
  Pointer<git_repository> repo,
  String name,
  String url,
  String fetch,
) {
  final out = calloc<Pointer<git_remote>>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final urlC = url.toNativeUtf8().cast<Int8>();
  final fetchC = fetch.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_create_with_fetchspec(
    out,
    repo,
    nameC,
    urlC,
    fetchC,
  );

  calloc.free(nameC);
  calloc.free(urlC);
  calloc.free(fetchC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Delete an existing persisted remote.
///
/// All remote-tracking branches and configuration settings for the remote will be removed.
///
/// Throws a [LibGit2Error] if error occured.
void delete(Pointer<git_repository> repo, String name) {
  final nameC = name.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_delete(repo, nameC);

  calloc.free(nameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Give the remote a new name.
///
/// Returns list of non-default refspecs that cannot be renamed.
///
/// All remote-tracking branches and configuration settings for the remote are updated.
///
/// The new name will be checked for validity.
///
/// No loaded instances of a the remote with the old name will change their name or
/// their list of refspecs.
///
/// Throws a [LibGit2Error] if error occured.
List<String> rename(Pointer<git_repository> repo, String name, String newName) {
  final out = calloc<git_strarray>();
  final nameC = name.toNativeUtf8().cast<Int8>();
  final newNameC = newName.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_rename(out, repo, nameC, newNameC);

  calloc.free(nameC);
  calloc.free(newNameC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    final count = out.ref.count;
    var result = <String>[];
    for (var i = 0; i < count; i++) {
      result.add(out.ref.strings[i].cast<Utf8>().toDartString());
    }
    calloc.free(out);
    return result;
  }
}

/// Set the remote's url in the configuration.
///
/// Remote objects already in memory will not be affected. This assumes the common
/// case of a single-url remote and will otherwise return an error.
///
/// Throws a [LibGit2Error] if error occured.
void setUrl(Pointer<git_repository> repo, String remote, String url) {
  final remoteC = remote.toNativeUtf8().cast<Int8>();
  final urlC = url.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_set_url(repo, remoteC, urlC);

  calloc.free(remoteC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Set the remote's url for pushing in the configuration.
///
/// Remote objects already in memory will not be affected. This assumes the common
/// case of a single-url remote and will otherwise return an error.
///
/// Throws a [LibGit2Error] if error occured.
void setPushUrl(Pointer<git_repository> repo, String remote, String url) {
  final remoteC = remote.toNativeUtf8().cast<Int8>();
  final urlC = url.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_set_pushurl(repo, remoteC, urlC);

  calloc.free(remoteC);
  calloc.free(urlC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the remote's repository.
Pointer<git_repository> owner(Pointer<git_remote> remote) {
  return libgit2.git_remote_owner(remote);
}

/// Get the remote's name.
String name(Pointer<git_remote> remote) {
  final result = libgit2.git_remote_name(remote);
  return result == nullptr ? '' : result.cast<Utf8>().toDartString();
}

/// Get the remote's url.
String url(Pointer<git_remote> remote) {
  return libgit2.git_remote_url(remote).cast<Utf8>().toDartString();
}

/// Get the remote's url for pushing.
///
/// Returns empty string if no special url for pushing is set.
String pushUrl(Pointer<git_remote> remote) {
  final result = libgit2.git_remote_pushurl(remote);
  return result == nullptr ? '' : result.cast<Utf8>().toDartString();
}

/// Get the number of refspecs for a remote.
int refspecCount(Pointer<git_remote> remote) =>
    libgit2.git_remote_refspec_count(remote);

/// Get a refspec from the remote at provided position.
Pointer<git_refspec> getRefspec(Pointer<git_remote> remote, int n) {
  return libgit2.git_remote_get_refspec(remote, n);
}

/// Get the remote's list of fetch refspecs.
List<String> fetchRefspecs(Pointer<git_remote> remote) {
  final out = calloc<git_strarray>();
  libgit2.git_remote_get_fetch_refspecs(out, remote);

  var result = <String>[];
  final count = out.ref.count;
  for (var i = 0; i < count; i++) {
    result.add(out.ref.strings[i].cast<Utf8>().toDartString());
  }
  calloc.free(out);
  return result;
}

/// Get the remote's list of push refspecs.
List<String> pushRefspecs(Pointer<git_remote> remote) {
  final out = calloc<git_strarray>();
  libgit2.git_remote_get_push_refspecs(out, remote);

  var result = <String>[];
  final count = out.ref.count;
  for (var i = 0; i < count; i++) {
    result.add(out.ref.strings[i].cast<Utf8>().toDartString());
  }
  calloc.free(out);
  return result;
}

/// Add a fetch refspec to the remote's configuration.
///
/// Add the given refspec to the fetch list in the configuration. No loaded remote
/// instances will be affected.
///
/// Throws a [LibGit2Error] if error occured.
void addFetch(Pointer<git_repository> repo, String remote, String refspec) {
  final remoteC = remote.toNativeUtf8().cast<Int8>();
  final refspecC = refspec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_add_fetch(repo, remoteC, refspecC);

  calloc.free(remoteC);
  calloc.free(refspecC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Add a push refspec to the remote's configuration.
///
/// Add the given refspec to the push list in the configuration. No loaded remote
/// instances will be affected.
///
/// Throws a [LibGit2Error] if error occured.
void addPush(Pointer<git_repository> repo, String remote, String refspec) {
  final remoteC = remote.toNativeUtf8().cast<Int8>();
  final refspecC = refspec.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_remote_add_push(repo, remoteC, refspecC);

  calloc.free(remoteC);
  calloc.free(refspecC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Open a connection to a remote.
///
/// The transport is selected based on the URL. The direction argument is due to a
/// limitation of the git protocol (over TCP or SSH) which starts up a specific binary
/// which can only do the one or the other.
///
/// Throws a [LibGit2Error] if error occured.
void connect(
  Pointer<git_remote> remote,
  int direction,
  String? proxyOption,
) {
  final callbacks = calloc<git_remote_callbacks>();
  final callbacksError = libgit2.git_remote_init_callbacks(
    callbacks,
    GIT_REMOTE_CALLBACKS_VERSION,
  );

  if (callbacksError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final error = libgit2.git_remote_connect(
    remote,
    direction,
    callbacks,
    proxyOptions,
    nullptr,
  );

  calloc.free(callbacks);
  calloc.free(proxyOptions);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the remote repository's reference advertisement list.
///
/// Get the list of references with which the server responds to a new connection.
///
/// The remote (or more exactly its transport) must have connected to the remote repository.
/// This list is available as soon as the connection to the remote is initiated and it
/// remains available after disconnecting.
///
/// Throws a [LibGit2Error] if error occured.
List<Map<String, dynamic>> lsRemotes(Pointer<git_remote> remote) {
  final out = calloc<Pointer<Pointer<git_remote_head>>>();
  final size = calloc<Uint64>();
  final error = libgit2.git_remote_ls(out, size, remote);

  var result = <Map<String, dynamic>>[];

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    for (var i = 0; i < size.value; i++) {
      var remote = <String, dynamic>{};
      Oid? loid;

      final bool local = out[0][i].ref.local == 1 ? true : false;
      if (local) {
        loid = Oid.fromRaw(out[0][i].ref.loid);
      }

      remote['local'] = local;
      remote['loid'] = loid;
      remote['name'] = out[0][i].ref.name == nullptr
          ? ''
          : out[0][i].ref.name.cast<Utf8>().toDartString();
      remote['symref'] = out[0][i].ref.symref_target == nullptr
          ? ''
          : out[0][i].ref.symref_target.cast<Utf8>().toDartString();
      remote['oid'] = Oid.fromRaw(out[0][i].ref.oid);

      result.add(remote);
    }

    return result;
  }
}

/// Download new data and update tips.
///
/// Convenience function to connect to a remote, download the data, disconnect and
/// update the remote-tracking branches.
///
/// Throws a [LibGit2Error] if error occured.
void fetch(
  Pointer<git_remote> remote,
  List<String> refspecs,
  String? reflogMessage,
  int prune,
  String? proxyOption,
) {
  var refspecsC = calloc<git_strarray>();
  final refspecsPointers =
      refspecs.map((e) => e.toNativeUtf8().cast<Int8>()).toList();
  final strArray = calloc<Pointer<Int8>>(refspecs.length);

  for (var i = 0; i < refspecs.length; i++) {
    strArray[i] = refspecsPointers[i];
  }

  refspecsC.ref.count = refspecs.length;
  refspecsC.ref.strings = strArray;

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final opts = calloc<git_fetch_options>();
  final optsError = libgit2.git_fetch_options_init(
    opts,
    GIT_FETCH_OPTIONS_VERSION,
  );

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  opts.ref.prune = prune;
  opts.ref.proxy_opts = proxyOptions.ref;

  final reflogMessageC = reflogMessage?.toNativeUtf8().cast<Int8>() ?? nullptr;

  final error = libgit2.git_remote_fetch(
    remote,
    refspecsC,
    opts,
    reflogMessageC,
  );

  for (var p in refspecsPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
  calloc.free(refspecsC);
  calloc.free(proxyOptions);
  calloc.free(reflogMessageC);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Perform a push.
///
/// Throws a [LibGit2Error] if error occured.
void push(
  Pointer<git_remote> remote,
  List<String> refspecs,
  String? proxyOption,
) {
  var refspecsC = calloc<git_strarray>();
  final refspecsPointers =
      refspecs.map((e) => e.toNativeUtf8().cast<Int8>()).toList();
  final strArray = calloc<Pointer<Int8>>(refspecs.length);

  for (var i = 0; i < refspecs.length; i++) {
    strArray[i] = refspecsPointers[i];
  }

  refspecsC.ref.count = refspecs.length;
  refspecsC.ref.strings = strArray;

  final proxyOptions = _proxyOptionsInit(proxyOption);

  final opts = calloc<git_push_options>();
  final optsError =
      libgit2.git_push_options_init(opts, GIT_PUSH_OPTIONS_VERSION);

  if (optsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  opts.ref.proxy_opts = proxyOptions.ref;

  final error = libgit2.git_remote_push(remote, refspecsC, opts);

  for (var p in refspecsPointers) {
    calloc.free(p);
  }
  calloc.free(strArray);
  calloc.free(refspecsC);
  calloc.free(proxyOptions);
  calloc.free(opts);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the statistics structure that is filled in by the fetch operation.
Pointer<git_indexer_progress> stats(Pointer<git_remote> remote) =>
    libgit2.git_remote_stats(remote);

/// Close the connection to the remote.
///
/// Throws a [LibGit2Error] if error occured.
void disconnect(Pointer<git_remote> remote) {
  final error = libgit2.git_remote_disconnect(remote);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Prune tracking refs that are no longer present on remote.
///
/// Throws a [LibGit2Error] if error occured.
void prune(Pointer<git_remote> remote) {
  final callbacks = calloc<git_remote_callbacks>();
  final callbacksError = libgit2.git_remote_init_callbacks(
    callbacks,
    GIT_REMOTE_CALLBACKS_VERSION,
  );

  if (callbacksError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  final error = libgit2.git_remote_prune(remote, callbacks);

  calloc.free(callbacks);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Free the memory associated with a remote.
///
/// This also disconnects from the remote, if the connection has not been closed
/// yet (using `disconnect()`).
void free(Pointer<git_remote> remote) => libgit2.git_remote_free(remote);

/// Initializes git_proxy_options structure.
Pointer<git_proxy_options> _proxyOptionsInit(String? proxyOption) {
  final proxyOptions = calloc<git_proxy_options>();
  final proxyOptionsError =
      libgit2.git_proxy_options_init(proxyOptions, GIT_PROXY_OPTIONS_VERSION);

  if (proxyOptionsError < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }

  if (proxyOption == null) {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_NONE;
  } else if (proxyOption == 'auto') {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_AUTO;
  } else {
    proxyOptions.ref.type = git_proxy_t.GIT_PROXY_SPECIFIED;
    proxyOptions.ref.url = proxyOption.toNativeUtf8().cast<Int8>();
  }

  return proxyOptions;
}
