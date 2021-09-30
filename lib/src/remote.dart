import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';

import 'bindings/libgit2_bindings.dart';
import 'bindings/remote.dart' as bindings;
import 'git_types.dart';
import 'refspec.dart';
import 'repository.dart';

class Remotes {
  /// Initializes a new instance of the [References] class
  /// from provided [Repository] object.
  Remotes(Repository repo) {
    _repoPointer = repo.pointer;
  }

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Returns a list of the configured remotes for a repo.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<String> get list {
    return bindings.list(_repoPointer);
  }

  /// Returns number of the configured remotes for a repo.
  int get length => list.length;

  /// Returns [Remote] by looking up [name] in a repository.
  ///
  /// The name will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote operator [](String name) {
    return Remote(bindings.lookup(repoPointer: _repoPointer, name: name));
  }

  /// Adds a remote to the repository's configuration with the default [fetch]
  /// refspec if none provided .
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote create({
    required String name,
    required String url,
    String? fetch,
  }) {
    if (fetch == null) {
      return Remote(bindings.create(
        repoPointer: _repoPointer,
        name: name,
        url: url,
      ));
    } else {
      return Remote(bindings.createWithFetchSpec(
        repoPointer: _repoPointer,
        name: name,
        url: url,
        fetch: fetch,
      ));
    }
  }

  /// Deletes an existing persisted remote.
  ///
  /// All remote-tracking branches and configuration settings for the remote will be removed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void delete(String name) {
    bindings.delete(repoPointer: _repoPointer, name: name);
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
  List<String> rename({required String remote, required String newName}) {
    return bindings.rename(
      repoPointer: _repoPointer,
      name: remote,
      newName: newName,
    );
  }

  /// Sets the remote's url in the configuration.
  ///
  /// Remote objects already in memory will not be affected. This assumes the common
  /// case of a single-url remote and will otherwise return an error.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setUrl({required String remote, required String url}) {
    bindings.setUrl(
      repoPointer: _repoPointer,
      remote: remote,
      url: url,
    );
  }

  /// Sets the remote's url for pushing in the configuration.
  ///
  /// Remote objects already in memory will not be affected. This assumes the common
  /// case of a single-url remote and will otherwise return an error.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void setPushUrl({required String remote, required String url}) {
    bindings.setPushUrl(
      repoPointer: _repoPointer,
      remote: remote,
      url: url,
    );
  }

  /// Adds a fetch refspec to the remote's configuration.
  ///
  /// No loaded remote instances will be affected.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addFetch({required String remote, required String refspec}) {
    bindings.addFetch(
      repoPointer: _repoPointer,
      remote: remote,
      refspec: refspec,
    );
  }

  /// Adds a push refspec to the remote's configuration.
  ///
  /// No loaded remote instances will be affected.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void addPush({required String remote, required String refspec}) {
    bindings.addPush(
      repoPointer: _repoPointer,
      remote: remote,
      refspec: refspec,
    );
  }
}

class Remote {
  /// Initializes a new instance of [Remote] class from provided pointer
  /// to remote object in memory.
  const Remote(this._remotePointer);

  final Pointer<git_remote> _remotePointer;

  /// Pointer to memory address for allocated remote object.
  Pointer<git_remote> get pointer => _remotePointer;

  /// Returns the remote's name.
  String get name => bindings.name(_remotePointer);

  /// Returns the remote's url.
  String get url => bindings.url(_remotePointer);

  /// Returns the remote's url for pushing.
  ///
  /// Returns empty string if no special url for pushing is set.
  String get pushUrl => bindings.pushUrl(_remotePointer);

  /// Returns the number of refspecs for a remote.
  int get refspecCount => bindings.refspecCount(_remotePointer);

  /// Returns a [Refspec] object from the remote at provided position.
  Refspec getRefspec(int index) {
    return Refspec(bindings.getRefspec(
      remotePointer: _remotePointer,
      position: index,
    ));
  }

  /// Returns the remote's list of fetch refspecs.
  List<String> get fetchRefspecs => bindings.fetchRefspecs(_remotePointer);

  /// Get the remote's list of push refspecs.
  List<String> get pushRefspecs => bindings.pushRefspecs(_remotePointer);

  /// Get the remote repository's reference advertisement list.
  ///
  /// [proxy] can be 'auto' to try to auto-detect the proxy from the git configuration or some
  /// specified url. By default connection isn't done through proxy.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Map<String, dynamic>> ls({
    String? proxy,
    Callbacks callbacks = const Callbacks(),
  }) {
    bindings.connect(
      remotePointer: _remotePointer,
      direction: GitDirection.fetch.value,
      callbacks: callbacks,
      proxyOption: proxy,
    );
    final result = bindings.lsRemotes(_remotePointer);
    bindings.disconnect(_remotePointer);
    return result;
  }

  /// Downloads new data and updates tips.
  ///
  /// [proxy] can be 'auto' to try to auto-detect the proxy from the git configuration or some
  /// specified url. By default connection isn't done through proxy.
  ///
  /// [reflogMessage] is the message to insert into the reflogs. Default is "fetch".
  ///
  /// Throws a [LibGit2Error] if error occured.
  TransferProgress fetch({
    List<String> refspecs = const [],
    String? reflogMessage,
    GitFetchPrune prune = GitFetchPrune.unspecified,
    String? proxy,
    Callbacks callbacks = const Callbacks(),
  }) {
    bindings.fetch(
      remotePointer: _remotePointer,
      refspecs: refspecs,
      prune: prune.value,
      callbacks: callbacks,
      reflogMessage: reflogMessage,
      proxyOption: proxy,
    );
    return TransferProgress(bindings.stats(_remotePointer));
  }

  /// Performs a push.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void push({
    required List<String> refspecs,
    String? proxy,
    Callbacks callbacks = const Callbacks(),
  }) {
    bindings.push(
      remotePointer: _remotePointer,
      refspecs: refspecs,
      callbacks: callbacks,
      proxyOption: proxy,
    );
  }

  /// Prunes tracking refs that are no longer present on remote.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void prune([Callbacks callbacks = const Callbacks()]) {
    bindings.prune(
      remotePointer: _remotePointer,
      callbacks: callbacks,
    );
  }

  /// Releases memory allocated for remote object.
  void free() => bindings.free(_remotePointer);
}

/// Provides callers information about the progress of indexing a packfile, either
/// directly or part of a fetch or clone that downloads a packfile.
class TransferProgress {
  /// Initializes a new instance of [TransferProgress] class from provided pointer
  /// to transfer progress object in memory.
  const TransferProgress(this._transferProgressPointer);

  /// Pointer to memory address for allocated transfer progress object.
  final Pointer<git_indexer_progress> _transferProgressPointer;

  /// Returns total number of objects to download.
  int get totalObjects => _transferProgressPointer.ref.total_objects;

  /// Returns number of objects that have been indexed.
  int get indexedObjects => _transferProgressPointer.ref.indexed_objects;

  /// Returns number of objects that have been downloaded.
  int get receivedObjects => _transferProgressPointer.ref.received_objects;

  /// Returns number of local objects that have been used to fix the thin pack.
  int get localObjects => _transferProgressPointer.ref.local_objects;

  /// Returns total number of deltas in the pack.
  int get totalDeltas => _transferProgressPointer.ref.total_deltas;

  /// Returns number of deltas that have been indexed.
  int get indexedDeltas => _transferProgressPointer.ref.indexed_deltas;

  /// Returns number of bytes received up to now.
  int get receivedBytes => _transferProgressPointer.ref.received_bytes;
}
