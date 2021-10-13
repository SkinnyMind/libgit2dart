import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/stash.dart' as bindings;

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

  /// Returns list of all the stashed states, first being the most recent.
  static List<Stash> list(Repository repo) => bindings.list(repo.pointer);

  /// Saves the local modifications to a new stash.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required Signature stasher,
    String? message,
    bool keepIndex = false,
    bool includeUntracked = false,
    bool includeIgnored = false,
  }) {
    int flags = 0;
    if (keepIndex) flags |= GitStash.keepIndex.value;
    if (includeUntracked) flags |= GitStash.includeUntracked.value;
    if (includeIgnored) flags |= GitStash.includeIgnored.value;

    return Oid(bindings.save(
      repoPointer: repo.pointer,
      stasherPointer: stasher.pointer,
      message: message,
      flags: flags,
    ));
  }

  /// Applies a single stashed state from the stash list.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void apply({
    required Repository repo,
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    bindings.apply(
      repoPointer: repo.pointer,
      index: index,
      flags: reinstateIndex ? GitStashApply.reinstateIndex.value : 0,
      strategy: strategy.fold(0, (acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );
  }

  /// Removes a single stashed state from the stash list.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void drop({required Repository repo, int index = 0}) {
    bindings.drop(
      repoPointer: repo.pointer,
      index: index,
    );
  }

  /// Applies a single stashed state from the stash list and remove it from
  /// the list if successful.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void pop({
    required Repository repo,
    int index = 0,
    bool reinstateIndex = false,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    bindings.pop(
      repoPointer: repo.pointer,
      index: index,
      flags: reinstateIndex ? GitStashApply.reinstateIndex.value : 0,
      strategy: strategy.fold(0, (acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );
  }

  @override
  String toString() {
    return 'Stash{index: $index, message: $message, oid: $oid}';
  }
}
