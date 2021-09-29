import 'credentials.dart';
import 'oid.dart';
import 'remote.dart';

class Callbacks {
  const Callbacks({
    this.credentials,
    this.transferProgress,
    this.sidebandProgress,
    this.updateTips,
    this.pushUpdateReference,
  });

  /// Credentials used for authentication.
  final Credentials? credentials;

  /// Callback function that reports transfer progress.
  final void Function(TransferProgress)? transferProgress;

  /// Callback function that reports textual progress from the remote.
  final void Function(String)? sidebandProgress;

  /// Callback function matching the `void Function(String refname, Oid old, Oid new)`
  /// that report reference updates.
  final void Function(String, Oid, Oid)? updateTips;

  /// Callback function matching the `void Function(String refname, String message)`
  /// used to inform of the update status from the remote.
  final void Function(String, String)? pushUpdateReference;
}