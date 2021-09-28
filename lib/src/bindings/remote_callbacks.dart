import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../callbacks.dart';
import '../repository.dart';
import 'libgit2_bindings.dart';
import '../oid.dart';
import '../remote.dart';

class RemoteCallbacks {
  /// Callback function that reports transfer progress.
  static void Function(TransferProgress)? transferProgress;

  /// A callback that will be regularly called with the current count of progress
  /// done by the indexer during the download of new data.
  static int transferProgressCb(
    Pointer<git_indexer_progress> stats,
    Pointer<Void> payload,
  ) {
    transferProgress!(TransferProgress(stats));
    return 0;
  }

  /// Callback function that reports textual progress from the remote.
  static void Function(String)? sidebandProgress;

  /// Callback for messages received by the transport.
  static int sidebandProgressCb(
    Pointer<Int8> progressOutput,
    int length,
    Pointer<Void> payload,
  ) {
    sidebandProgress!(progressOutput.cast<Utf8>().toDartString(length: length));
    return 0;
  }

  /// Callback function that report reference updates.
  static void Function(String, Oid, Oid)? updateTips;

  /// A callback that will be called for every reference.
  static int updateTipsCb(
    Pointer<Int8> refname,
    Pointer<git_oid> oldOid,
    Pointer<git_oid> newOid,
    Pointer<Void> payload,
  ) {
    updateTips!(refname.cast<Utf8>().toDartString(), Oid(oldOid), Oid(newOid));
    return 0;
  }

  /// Callback function used to inform of the update status from the remote.
  static void Function(String, String)? pushUpdateReference;

  /// Callback called for each updated reference on push. If [message] is
  /// not empty, the update was rejected by the remote server
  /// and [message] contains the reason given.
  static int pushUpdateReferenceCb(
    Pointer<Int8> refname,
    Pointer<Int8> message,
    Pointer<Void> payload,
  ) {
    final messageResult =
        message == nullptr ? '' : message.cast<Utf8>().toDartString();
    pushUpdateReference!(refname.cast<Utf8>().toDartString(), messageResult);
    return 0;
  }

  /// A function matching the `Remote Function(Repository repo, String name, String url)` signature
  /// to override the remote creation and customization process during a clone operation.
  static Remote Function(Repository, String, String)? remoteFunction;

  /// A callback used to create the git remote, prior to its being used to perform
  /// the clone operation.
  static int remoteCb(
    Pointer<Pointer<git_remote>> remote,
    Pointer<git_repository> repo,
    Pointer<Int8> name,
    Pointer<Int8> url,
    Pointer<Void> payload,
  ) {
    remote[0] = remoteFunction!(
      Repository(repo),
      name.cast<Utf8>().toDartString(),
      url.cast<Utf8>().toDartString(),
    ).pointer;

    return 0;
  }

  /// A function matching the `Repository Function(String path, bool bare)` signature to override
  /// the repository creation and customization process during a clone operation.
  static Repository Function(String, bool)? repositoryFunction;

  /// A callback used to create the new repository into which to clone.
  static int repositoryCb(
    Pointer<Pointer<git_repository>> repo,
    Pointer<Int8> path,
    int bare,
    Pointer<Void> payload,
  ) {
    repo[0] = repositoryFunction!(
      path.cast<Utf8>().toDartString(),
      bare == 1 ? true : false,
    ).pointer;

    return 0;
  }

  /// Plugs provided callbacks into libgit2 callbacks.
  static void plug({
    required git_remote_callbacks callbacksOptions,
    required Callbacks callbacks,
  }) {
    const except = -1;

    if (callbacks.transferProgress != null) {
      transferProgress = callbacks.transferProgress;
      callbacksOptions.transfer_progress = Pointer.fromFunction(
        transferProgressCb,
        except,
      );
    }

    if (callbacks.sidebandProgress != null) {
      sidebandProgress = callbacks.sidebandProgress;
      callbacksOptions.sideband_progress = Pointer.fromFunction(
        sidebandProgressCb,
        except,
      );
    }

    if (callbacks.updateTips != null) {
      updateTips = callbacks.updateTips;
      callbacksOptions.update_tips = Pointer.fromFunction(
        updateTipsCb,
        except,
      );
    }

    if (callbacks.pushUpdateReference != null) {
      pushUpdateReference = callbacks.pushUpdateReference;
      callbacksOptions.push_update_reference = Pointer.fromFunction(
        pushUpdateReferenceCb,
        except,
      );
    }
  }

  /// Resets callback functions to their original null values.
  static void reset() {
    transferProgress = null;
    sidebandProgress = null;
    updateTips = null;
    pushUpdateReference = null;
    remoteFunction = null;
    repositoryFunction = null;
  }
}
