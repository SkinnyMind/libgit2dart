import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/remote.dart' as bindings;

class Remote {
  /// Lookups remote with provided [name] in a [repo]sitory.
  ///
  /// The [name] will be checked for validity.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote.lookup({required Repository repo, required String name}) {
    _remotePointer = bindings.lookup(repoPointer: repo.pointer, name: name);
  }

  /// Adds remote with provided [name] and [url] to the [repo]sitory's
  /// configuration with the default [fetch] refspec if none provided.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote.create({
    required Repository repo,
    required String name,
    required String url,
    String? fetch,
  }) {
    if (fetch == null) {
      _remotePointer = bindings.create(
        repoPointer: repo.pointer,
        name: name,
        url: url,
      );
    } else {
      _remotePointer = bindings.createWithFetchSpec(
        repoPointer: repo.pointer,
        name: name,
        url: url,
        fetch: fetch,
      );
    }
  }

  late final Pointer<git_remote> _remotePointer;

  /// Pointer to memory address for allocated remote object.
  Pointer<git_remote> get pointer => _remotePointer;

  /// Deletes an existing persisted remote with provided [name].
  ///
  /// All remote-tracking branches and configuration settings for the remote
  /// will be removed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({required Repository repo, required String name}) {
    bindings.delete(repoPointer: repo.pointer, name: name);
  }

  /// Renames remote with provided [oldName].
  ///
  /// Returns list of non-default refspecs that cannot be renamed.
  ///
  /// All remote-tracking branches and configuration settings for the remote
  /// are updated.
  ///
  /// The [newName] will be checked for validity.
  ///
  /// No loaded instances of a the remote with the old name will change their
  /// name or their list of refspecs.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<String> rename({
    required Repository repo,
    required String oldName,
    required String newName,
  }) {
    return bindings.rename(
      repoPointer: repo.pointer,
      name: oldName,
      newName: newName,
    );
  }

  /// Returns a list of the configured remotes for a [repo]sitory.
  static List<String> list(Repository repo) {
    return bindings.list(repo.pointer);
  }

  /// Sets the [remote]'s [url] in the configuration.
  ///
  /// Remote objects already in memory will not be affected. This assumes the
  /// common case of a single-url remote and will otherwise return an error.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void setUrl({
    required Repository repo,
    required String remote,
    required String url,
  }) {
    bindings.setUrl(
      repoPointer: repo.pointer,
      remote: remote,
      url: url,
    );
  }

  /// Sets the [remote]'s [url] for pushing in the configuration.
  ///
  /// Remote objects already in memory will not be affected. This assumes the
  /// common case of a single-url remote and will otherwise return an error.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void setPushUrl({
    required Repository repo,
    required String remote,
    required String url,
  }) {
    bindings.setPushUrl(
      repoPointer: repo.pointer,
      remote: remote,
      url: url,
    );
  }

  /// Adds a fetch [refspec] to the [remote]'s configuration.
  ///
  /// No loaded remote instances will be affected.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void addFetch({
    required Repository repo,
    required String remote,
    required String refspec,
  }) {
    bindings.addFetch(
      repoPointer: repo.pointer,
      remote: remote,
      refspec: refspec,
    );
  }

  /// Adds a push [refspec] to the [remote]'s configuration.
  ///
  /// No loaded remote instances will be affected.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void addPush({
    required Repository repo,
    required String remote,
    required String refspec,
  }) {
    bindings.addPush(
      repoPointer: repo.pointer,
      remote: remote,
      refspec: refspec,
    );
  }

  /// Remote's name.
  String get name => bindings.name(_remotePointer);

  /// Remote's url.
  String get url => bindings.url(_remotePointer);

  /// Remote's url for pushing.
  ///
  /// Returns empty string if no special url for pushing is set.
  String get pushUrl => bindings.pushUrl(_remotePointer);

  /// Number of refspecs for a remote.
  int get refspecCount => bindings.refspecCount(_remotePointer);

  /// [Refspec] object from the remote at provided position.
  Refspec getRefspec(int index) {
    return Refspec(bindings.getRefspec(
      remotePointer: _remotePointer,
      position: index,
    ));
  }

  /// List of fetch refspecs.
  List<String> get fetchRefspecs => bindings.fetchRefspecs(_remotePointer);

  /// List of push refspecs.
  List<String> get pushRefspecs => bindings.pushRefspecs(_remotePointer);

  /// Returns the remote repository's reference list and their associated
  /// commit ids.
  ///
  /// [proxy] can be 'auto' to try to auto-detect the proxy from the git
  /// configuration or some specified url. By default connection isn't done
  /// through proxy.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// Returned map keys:
  /// - `local` is true if remote head is available locally, false otherwise.
  /// - `loid` is the oid of the object the local copy of the remote head is
  /// currently pointing to. null if there is no local copy of the remote head.
  /// - `name` is the name of the reference.
  /// - `oid` is the oid of the object the remote head is currently pointing to.
  /// - `symref` is the target of the symbolic reference or empty string.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Map<String, Object?>> ls({
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
  /// [refspecs] is the list of refspecs to use for this fetch. Defaults to the
  /// base refspecs.
  ///
  /// [reflogMessage] is the message to insert into the reflogs. Default is
  /// "fetch".
  ///
  /// [prune] determines whether to perform a prune after the fetch.
  ///
  /// [proxy] can be 'auto' to try to auto-detect the proxy from the git
  /// configuration or some specified url. By default connection isn't done
  /// through proxy.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
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
  /// [refspecs] is the list of refspecs to use for pushing. Defaults to the
  /// configured refspecs.
  ///
  /// [proxy] can be 'auto' to try to auto-detect the proxy from the git
  /// configuration or some specified url. By default connection isn't done
  /// through proxy.
  ///
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void push({
    List<String> refspecs = const [],
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
  /// [callbacks] is the combination of callback functions from [Callbacks]
  /// object.
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

  @override
  String toString() {
    return 'Remote{name: $name, url: $url, pushUrl: $pushUrl, '
        'refspecCount: $refspecCount}';
  }
}

/// Provides callers information about the progress of indexing a packfile,
/// either directly or part of a fetch or clone that downloads a packfile.
class TransferProgress {
  /// Initializes a new instance of [TransferProgress] class from provided
  /// pointer to transfer progress object in memory.
  const TransferProgress(this._transferProgressPointer);

  /// Pointer to memory address for allocated transfer progress object.
  final Pointer<git_indexer_progress> _transferProgressPointer;

  /// Total number of objects to download.
  int get totalObjects => _transferProgressPointer.ref.total_objects;

  /// Number of objects that have been indexed.
  int get indexedObjects => _transferProgressPointer.ref.indexed_objects;

  /// Number of objects that have been downloaded.
  int get receivedObjects => _transferProgressPointer.ref.received_objects;

  /// Number of local objects that have been used to fix the thin pack.
  int get localObjects => _transferProgressPointer.ref.local_objects;

  /// Total number of deltas in the pack.
  int get totalDeltas => _transferProgressPointer.ref.total_deltas;

  /// Number of deltas that have been indexed.
  int get indexedDeltas => _transferProgressPointer.ref.indexed_deltas;

  /// Number of bytes received up to now.
  int get receivedBytes => _transferProgressPointer.ref.received_bytes;

  @override
  String toString() {
    return 'TransferProgress{totalObjects: $totalObjects, '
        'indexedObjects: $indexedObjects, receivedObjects: $receivedObjects, '
        'localObjects: $localObjects, totalDeltas: $totalDeltas, '
        'indexedDeltas: $indexedDeltas, receivedBytes: $receivedBytes}';
  }
}
