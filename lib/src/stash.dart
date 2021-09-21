import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'oid.dart';

class Stash {
  /// Initializes a new instance of [Stash] class.
  Stash({
    required this.index,
    required this.message,
    required Pointer<git_oid> oid,
  }) {
    this.oid = Oid(oid);
  }

  /// The position within the stash list.
  final int index;

  /// The stash message.
  final String message;

  /// The commit oid of the stashed state.
  late final Oid oid;

  @override
  String toString() {
    return 'Stash{index: $index, message: $message, sha: ${oid.sha}}';
  }
}
