import 'package:libgit2dart/libgit2dart.dart';

class Callbacks {
  /// Callback functions used in various methods of [Remote] and with
  /// [Repository.clone].
  ///
  /// [credentials] is one of the objects used for authentication:
  /// - [UserPass]
  /// - [Keypair]
  /// - [KeypairFromAgent]
  /// - [KeypairFromMemory]
  ///
  /// [transferProgress] is the callback function that reports transfer
  /// progress.
  ///
  /// [sidebandProgress] is the callback function that reports textual progress
  /// from the remote.
  ///
  /// [updateTips] is the callback function matching the
  /// `void Function(String refname, Oid old, Oid new)` that report reference
  /// updates.
  ///
  /// [pushUpdateReference] is the callback function matching the
  /// `void Function(String refname, String message)` used to inform of the
  /// update status from the remote.
  const Callbacks({
    this.credentials,
    this.transferProgress,
    this.sidebandProgress,
    this.updateTips,
    this.pushUpdateReference,
  });

  /// Credentials used for authentication. Could be one of:
  /// - [UserPass]
  /// - [Keypair]
  /// - [KeypairFromAgent]
  /// - [KeypairFromMemory]
  final Credentials? credentials;

  /// Callback function that reports transfer progress.
  final void Function(TransferProgress)? transferProgress;

  /// Callback function that reports textual progress from the remote.
  final void Function(String)? sidebandProgress;

  /// Callback function matching the
  /// `void Function(String refname, Oid old, Oid new)` that report reference
  /// updates.
  final void Function(String, Oid, Oid)? updateTips;

  /// Callback function matching the
  /// `void Function(String refname, String message)` used to inform of the
  /// update status from the remote.
  final void Function(String, String)? pushUpdateReference;
}
