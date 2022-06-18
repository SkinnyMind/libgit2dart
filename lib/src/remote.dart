import 'dart:ffi';
import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/remote.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Remote extends Equatable {
  /// Lookups remote with provided [name] in a [repo]sitory.
  ///
  /// The [name] will be checked for validity.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Remote.lookup({required Repository repo, required String name}) {
    _remotePointer = bindings.lookup(repoPointer: repo.pointer, name: name);
    _finalizer.attach(this, _remotePointer, detach: this);
  }

  /// Adds remote with provided [name] and [url] to the [repo]sitory's
  /// configuration with the default [fetch] refspec if none provided.
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
    _finalizer.attach(this, _remotePointer, detach: this);
  }

  /// Pointer to memory address for allocated remote object.
  late final Pointer<git_remote> _remotePointer;

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
    return Refspec(
      bindings.getRefspec(
        remotePointer: _remotePointer,
        position: index,
      ),
    );
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
  /// Throws a [LibGit2Error] if error occured.
  List<RemoteReference> ls({
    String? proxy,
    Callbacks callbacks = const Callbacks(),
  }) {
    bindings.connect(
      remotePointer: _remotePointer,
      direction: GitDirection.fetch.value,
      callbacks: callbacks,
      proxyOption: proxy,
    );
    final refs = bindings.lsRemotes(_remotePointer);
    bindings.disconnect(_remotePointer);

    return <RemoteReference>[
      for (final ref in refs)
        RemoteReference._(
          isLocal: ref['local']! as bool,
          localId: ref['loid'] as Oid?,
          name: ref['name']! as String,
          oid: ref['oid']! as Oid,
          symRef: ref['symref']! as String,
        )
    ];
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
  void free() {
    bindings.free(_remotePointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Remote{name: $name, url: $url, pushUrl: $pushUrl, '
        'refspecCount: $refspecCount}';
  }

  @override
  List<Object?> get props => [name];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_remote>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end

/// Provides callers information about the progress of indexing a packfile,
/// either directly or part of a fetch or clone that downloads a packfile.
class TransferProgress {
  /// Initializes a new instance of [TransferProgress] class from provided
  /// pointer to transfer progress object in memory.
  ///
  /// Note: For internal use.
  @internal
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

class RemoteCallback {
  /// Values used to override the remote creation and customization process
  /// during a repository clone operation.
  ///
  /// Remote will have provided [name] and [url] with the default [fetch]
  /// refspec if none provided.
  const RemoteCallback({required this.name, required this.url, this.fetch});

  /// Remote's name.
  final String name;

  /// Remote's url.
  final String url;

  /// Remote's fetch refspec.
  final String? fetch;
}

@immutable
class RemoteReference extends Equatable {
  const RemoteReference._({
    required this.isLocal,
    required this.localId,
    required this.name,
    required this.oid,
    required this.symRef,
  });

  /// Whether remote head is available locally.
  final bool isLocal;

  /// Oid of the object the local copy of the remote head is currently pointing
  /// to. Null if there is no local copy of the remote head.
  final Oid? localId;

  /// Name of the reference.
  final String name;

  /// Oid of the object the remote head is currently pointing to.
  final Oid oid;

  /// Target of the symbolic reference or empty string if reference is direct.
  final String symRef;

  @override
  String toString() {
    return 'RemoteReference{isLocal: $isLocal, localId: $localId, '
        'name: $name, oid: $oid, symRef: $symRef}';
  }

  @override
  List<Object?> get props => [isLocal, localId, name, oid, symRef];
}
