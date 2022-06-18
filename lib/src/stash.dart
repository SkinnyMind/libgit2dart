import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/stash.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Stash extends Equatable {
  /// Initializes a new instance of [Stash] class from provided stash [index],
  /// [message] and [oid].
  ///
  /// Note: For internal use. Use [Stash.create] instead to create stash.
  @internal
  const Stash({
    required this.index,
    required this.message,
    required this.oid,
  });

  /// Position within the stash list.
  final int index;

  /// Stash message.
  final String message;

  /// Commit [Oid] of the stashed state.
  final Oid oid;

  /// Returns list of all the stashed states, first being the most recent.
  static List<Stash> list(Repository repo) => bindings.list(repo.pointer);

  /// Saves the local modifications to a new stash.
  ///
  /// [repo] is the owning repository.
  ///
  /// [stasher] is the identity of the person performing the stashing.
  ///
  /// [message] is optional description along with the stashed state.
  ///
  /// [flags] is a combination of [GitStash] flags. Defaults to
  /// [GitStash.defaults].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required Signature stasher,
    String? message,
    Set<GitStash> flags = const {GitStash.defaults},
  }) {
    return Oid(
      bindings.save(
        repoPointer: repo.pointer,
        stasherPointer: stasher.pointer,
        message: message,
        flags: flags.fold(0, (int acc, e) => acc | e.value),
      ),
    );
  }

  /// Applies a single stashed state from the stash list.
  ///
  /// [index] is the position of the stashed state in the list. Defaults to
  /// last saved.
  ///
  /// [reinstateIndex] whether to try to reinstate not only the working tree's
  /// changes, but also the index's changes.
  ///
  /// [strategy] is a combination of [GitCheckout] flags. Defaults to
  /// [GitCheckout.safe] with [GitCheckout.recreateMissing].
  ///
  /// [directory] is the alternative checkout path to workdir, can be null.
  ///
  /// [paths] is a list of wildmatch patterns or paths. By default, all paths
  /// are processed. If you pass a list of wildmatch patterns, those will be
  /// used to filter which paths should be taken into account.
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

  /// Removes a single stashed state from the stash list at provided [index].
  /// Defaults to the last saved stash.
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
  /// [index] is the position of the stashed state in the list. Defaults to
  /// last saved.
  ///
  /// [reinstateIndex] whether to try to reinstate not only the working tree's
  /// changes, but also the index's changes.
  ///
  /// [strategy] is a combination of [GitCheckout] flags. Defaults to
  /// [GitCheckout.safe] with [GitCheckout.recreateMissing].
  ///
  /// [directory] is the alternative checkout path to workdir, can be null.
  ///
  /// [paths] is a list of wildmatch patterns or paths. By default, all paths
  /// are processed. If you pass a list of wildmatch patterns, those will be
  /// used to filter which paths should be taken into account.
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

  @override
  List<Object?> get props => [index, message, oid];
}
