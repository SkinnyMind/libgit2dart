import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import '../credentials.dart';
import '../callbacks.dart';
import '../repository.dart';
import '../oid.dart';
import '../remote.dart';
import 'libgit2_bindings.dart';
import 'credentials.dart' as credentials_bindings;

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

  /// [Credentials] object used for authentication in order to connect to remote.
  static Credentials? credentials;

  /// Credential acquisition callback that will be called if the remote host requires
  /// authentication in order to connect to it.
  static int credentialsCb(
    Pointer<Pointer<git_credential>> credPointer,
    Pointer<Int8> url,
    Pointer<Int8> username,
    int allowedTypes,
    Pointer<Void> payload,
  ) {
    final credentialType = credentials!.credentialType;
    if (allowedTypes & credentialType.value != credentialType.value) {
      throw ArgumentError('Invalid credential type $credentialType');
    }

    if (credentials is Username) {
      final cred = credentials as Username;
      credPointer[0] = credentials_bindings.username(cred.username);
    } else if (credentials is UserPass) {
      final cred = credentials as UserPass;
      credPointer[0] = credentials_bindings.userPass(
        username: cred.username,
        password: cred.password,
      );
    } else if (credentials is Keypair) {
      final cred = credentials as Keypair;
      credPointer[0] = credentials_bindings.sshKey(
        username: cred.username,
        publicKey: cred.pubKey,
        privateKey: cred.privateKey,
        passPhrase: cred.passPhrase,
      );
    } else if (credentials is KeypairFromAgent) {
      final cred = credentials as KeypairFromAgent;
      credPointer[0] = credentials_bindings.sshKeyFromAgent(cred.username);
    } else if (credentials is KeypairFromMemory) {
      final cred = credentials as KeypairFromMemory;
      credPointer[0] = credentials_bindings.sshKeyFromMemory(
        username: cred.username,
        publicKey: cred.pubKey,
        privateKey: cred.privateKey,
        passPhrase: cred.passPhrase,
      );
    }

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

    if (callbacks.credentials != null) {
      credentials = callbacks.credentials;
      callbacksOptions.credentials = Pointer.fromFunction(
        credentialsCb,
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
    credentials = null;
  }
}
