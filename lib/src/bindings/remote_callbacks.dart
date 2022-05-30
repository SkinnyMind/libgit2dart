import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/credentials.dart'
    as credentials_bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/remote.dart' as remote_bindings;
import 'package:libgit2dart/src/bindings/repository.dart'
    as repository_bindings;
import 'package:libgit2dart/src/extensions.dart';
import 'package:libgit2dart/src/util.dart';

class RemoteCallbacks {
  /// Callback function that reports transfer progress.
  static void Function(TransferProgress)? transferProgress;

  /// A callback that will be regularly called with the current count of
  /// progress done by the indexer during the download of new data.
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
    Pointer<Char> progressOutput,
    int length,
    Pointer<Void> payload,
  ) {
    sidebandProgress!(progressOutput.toDartString(length: length));
    return 0;
  }

  /// Callback function that report reference updates.
  static void Function(String, Oid, Oid)? updateTips;

  /// A callback that will be called for every reference.
  static int updateTipsCb(
    Pointer<Char> refname,
    Pointer<git_oid> oldOid,
    Pointer<git_oid> newOid,
    Pointer<Void> payload,
  ) {
    updateTips!(refname.toDartString(), Oid(oldOid), Oid(newOid));
    return 0;
  }

  /// Callback function used to inform of the update status from the remote.
  static void Function(String, String)? pushUpdateReference;

  /// Callback called for each updated reference on push. If [message] is
  /// not empty, the update was rejected by the remote server
  /// and [message] contains the reason given.
  static int pushUpdateReferenceCb(
    Pointer<Char> refname,
    Pointer<Char> message,
    Pointer<Void> payload,
  ) {
    final messageResult = message == nullptr ? '' : message.toDartString();
    pushUpdateReference!(refname.toDartString(), messageResult);
    return 0;
  }

  /// Values used to override the remote creation and customization process
  /// during a clone operation.
  static RemoteCallback? remoteCbData;

  /// A callback used to create the git remote, prior to its being used to
  /// perform the clone operation.
  static int remoteCb(
    Pointer<Pointer<git_remote>> remote,
    Pointer<git_repository> repo,
    Pointer<Char> name,
    Pointer<Char> url,
    Pointer<Void> payload,
  ) {
    late final Pointer<git_remote> remotePointer;

    if (remoteCbData!.fetch == null) {
      remotePointer = remote_bindings.create(
        repoPointer: repo,
        name: remoteCbData!.name,
        url: remoteCbData!.url,
      );
    } else {
      remotePointer = remote_bindings.createWithFetchSpec(
        repoPointer: repo,
        name: remoteCbData!.name,
        url: remoteCbData!.url,
        fetch: remoteCbData!.fetch!,
      );
    }

    remote[0] = remotePointer;

    return 0;
  }

  /// Values used to override the repository creation and customization process
  /// during a clone operation.
  static RepositoryCallback? repositoryCbData;

  /// A callback used to create the new repository into which to clone.
  static int repositoryCb(
    Pointer<Pointer<git_repository>> repo,
    Pointer<Char> path,
    int bare,
    Pointer<Void> payload,
  ) {
    var flagsInt = repositoryCbData!.flags.fold(
      0,
      (int acc, e) => acc | e.value,
    );

    if (repositoryCbData!.bare) {
      flagsInt |= GitRepositoryInit.bare.value;
    }

    final repoPointer = repository_bindings.init(
      path: repositoryCbData!.path,
      flags: flagsInt,
      mode: repositoryCbData!.mode,
      workdirPath: repositoryCbData!.workdirPath,
      description: repositoryCbData!.description,
      templatePath: repositoryCbData!.templatePath,
      initialHead: repositoryCbData!.initialHead,
      originUrl: repositoryCbData!.originUrl,
    );

    repo[0] = repoPointer;

    return 0;
  }

  /// [Credentials] object used for authentication in order to connect to
  /// remote.
  static Credentials? credentials;

  /// Credential acquisition callback that will be called if the remote host
  /// requires authentication in order to connect to it.
  static int credentialsCb(
    Pointer<Pointer<git_credential>> credPointer,
    Pointer<Char> url,
    Pointer<Char> username,
    int allowedTypes,
    Pointer<Void> payload,
  ) {
    if (payload.cast<Char>().value == 2) {
      libgit2.git_error_set_str(
        git_error_t.GIT_ERROR_INVALID,
        'Incorrect credentials.'.toChar(),
      );
      throw LibGit2Error(libgit2.git_error_last());
    }

    final credentialType = credentials!.credentialType;

    if (allowedTypes & credentialType.value != credentialType.value) {
      libgit2.git_error_set_str(
        git_error_t.GIT_ERROR_INVALID,
        'Invalid credential type $credentialType'.toChar(),
      );
      throw LibGit2Error(libgit2.git_error_last());
    }

    if (credentials is UserPass) {
      final cred = credentials! as UserPass;
      credPointer[0] = credentials_bindings.userPass(
        username: cred.username,
        password: cred.password,
      );
      payload.cast<Int8>().value++;
    }

    if (credentials is Keypair) {
      final cred = credentials! as Keypair;
      credPointer[0] = credentials_bindings.sshKey(
        username: cred.username,
        publicKey: cred.pubKey,
        privateKey: cred.privateKey,
        passPhrase: cred.passPhrase,
      );
      payload.cast<Int8>().value++;
    }

    if (credentials is KeypairFromAgent) {
      final cred = credentials! as KeypairFromAgent;
      credPointer[0] = credentials_bindings.sshKeyFromAgent(cred.username);
      payload.cast<Int8>().value++;
    }

    if (credentials is KeypairFromMemory) {
      final cred = credentials! as KeypairFromMemory;
      credPointer[0] = credentials_bindings.sshKeyFromMemory(
        username: cred.username,
        publicKey: cred.pubKey,
        privateKey: cred.privateKey,
        passPhrase: cred.passPhrase,
      );
      payload.cast<Int8>().value++;
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
      final payload = calloc<Int8>()..value = 1;
      callbacksOptions.payload = payload.cast();
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
    remoteCbData = null;
    repositoryCbData = null;
    credentials = null;
  }
}
