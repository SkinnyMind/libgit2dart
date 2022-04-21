import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/checkout.dart' as bindings;
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;

class Checkout {
  const Checkout._(); // coverage:ignore-line

  /// Updates files in the index and the working tree to match the content of
  /// the commit pointed at by HEAD.
  ///
  /// Note that this is **not** the correct mechanism used to switch branches;
  /// do not change your HEAD and then call this method, that would leave you
  /// with checkout conflicts since your working directory would then appear
  /// to be dirty. Instead, checkout the target of the branch and then update
  /// HEAD using [Repository]'s `setHead` to point to the branch you checked
  /// out.
  ///
  /// [repo] is the repository into which to check out (must be non-bare).
  ///
  /// Default checkout [strategy] is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is optional alternative checkout path to workdir.
  ///
  /// [paths] is optional list of files to checkout (by default all paths are
  /// processed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void head({
    required Repository repo,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    bindings.head(
      repoPointer: repo.pointer,
      strategy: strategy.fold(0, (int acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );
  }

  /// Updates files in the working tree to match the content of the index.
  ///
  /// [repo] is the repository into which to check out (must be non-bare).
  ///
  /// Default checkout [strategy] is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is optional alternative checkout path to workdir.
  ///
  /// [paths] is optional list of files to checkout (by default all paths are
  /// processed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void index({
    required Repository repo,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    bindings.index(
      repoPointer: repo.pointer,
      strategy: strategy.fold(0, (int acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );
  }

  /// Updates files in the working tree to match the content of the tree
  /// pointed at by the reference [name] target.
  ///
  /// [repo] is the repository into which to check out (must be non-bare).
  ///
  /// [name] is the fully-qualified reference name (e.g. 'refs/heads/master')
  /// which target's content will be used to update the working directory;
  ///
  /// Default checkout [strategy] is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is optional alternative checkout path to workdir.
  ///
  /// [paths] is optional list of files to checkout (by default all paths are
  /// processed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void reference({
    required Repository repo,
    required String name,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    final ref = Reference.lookup(repo: repo, name: name);
    final treeish = object_bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: ref.target.pointer,
      type: GitObject.any.value,
    );

    bindings.tree(
      repoPointer: repo.pointer,
      treeishPointer: treeish,
      strategy: strategy.fold(0, (int acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );

    object_bindings.free(treeish);
  }

  /// Updates files in the working tree to match the content of the tree
  /// pointed at by the [commit].
  ///
  /// [repo] is the repository into which to check out (must be non-bare).
  ///
  /// [commit] is the commit which content will be used to update the working
  /// directory.
  ///
  /// Default checkout [strategy] is combination of [GitCheckout.safe] and
  /// [GitCheckout.recreateMissing].
  ///
  /// [directory] is optional alternative checkout path to workdir.
  ///
  /// [paths] is optional list of files to checkout (by default all paths are
  /// processed).
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void commit({
    required Repository repo,
    required Commit commit,
    Set<GitCheckout> strategy = const {
      GitCheckout.safe,
      GitCheckout.recreateMissing
    },
    String? directory,
    List<String>? paths,
  }) {
    final treeish = object_bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: commit.oid.pointer,
      type: GitObject.any.value,
    );

    bindings.tree(
      repoPointer: repo.pointer,
      treeishPointer: treeish,
      strategy: strategy.fold(0, (int acc, e) => acc | e.value),
      directory: directory,
      paths: paths,
    );

    object_bindings.free(treeish);
  }
}
