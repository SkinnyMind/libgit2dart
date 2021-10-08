import 'package:libgit2dart/libgit2dart.dart';

class Stash {
  /// Initializes a new instance of [Stash] class.
  const Stash({
    required this.index,
    required this.message,
    required this.oid,
  });

  /// The position within the stash list.
  final int index;

  /// The stash message.
  final String message;

  /// The commit oid of the stashed state.
  final Oid oid;

  @override
  String toString() {
    return 'Stash{index: $index, message: $message, sha: ${oid.sha}}';
  }
}
