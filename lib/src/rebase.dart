import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/rebase.dart' as bindings;

class Rebase {
  /// Initializes a new instance of the [Rebase] class by initializing a
  /// rebase operation to rebase the changes in [branch] relative to [upstream]
  /// [onto] another branch. To begin the rebase process, call `next()`.
  /// When you have finished with this object, call `free()`.
  ///
  /// [branch] is the terminal commit to rebase, default is to rebase the current branch.
  ///
  /// [upstream] is the commit to begin rebasing from, default is to rebase all
  /// reachable commits.
  ///
  /// [onto] is the branch to rebase onto, default is to rebase onto the given [upstream]
  /// (throws if [upstream] is not provided).
  ///
  /// Throws a [LibGit2Error] if error occured.
  Rebase.init({
    required Repository repo,
    Oid? branch,
    Oid? upstream,
    Oid? onto,
  }) {
    AnnotatedCommit? _branch, _upstream, _onto;
    if (branch != null) {
      _branch = AnnotatedCommit.lookup(repo: repo, oid: branch);
    }
    if (upstream != null) {
      _upstream = AnnotatedCommit.lookup(repo: repo, oid: upstream);
    }
    if (onto != null) {
      _onto = AnnotatedCommit.lookup(repo: repo, oid: onto);
    }

    _rebasePointer = bindings.init(
      repoPointer: repo.pointer,
      branchPointer: _branch?.pointer.value,
      upstreamPointer: _upstream?.pointer.value,
      ontoPointer: _onto?.pointer.value,
    );

    if (branch != null) {
      _branch!.free();
    }
    if (upstream != null) {
      _upstream!.free();
    }
    if (onto != null) {
      _onto!.free();
    }
  }

  /// Pointer to memory address for allocated rebase object.
  late final Pointer<git_rebase> _rebasePointer;

  /// The count of rebase operations that are to be applied.
  int get operationsCount {
    return bindings.operationsCount(_rebasePointer);
  }

  /// Performs the next rebase operation and returns the information about it.
  /// If the operation is one that applies a patch (which is any operation except
  /// [GitRebaseOperation.exec]) then the patch will be applied and the index and
  /// working directory will be updated with the changes. If there are conflicts,
  /// you will need to address those before committing the changes.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RebaseOperation next() {
    return RebaseOperation(bindings.next(_rebasePointer));
  }

  /// Commits the current patch. You must have resolved any conflicts that were
  /// introduced during the patch application from the [next] invocation.
  ///
  /// Throws a [LibGit2Error] if error occured.
  void commit({
    required Signature committer,
    String? message,
    Signature? author,
  }) {
    bindings.commit(
      rebasePointer: _rebasePointer,
      authorPointer: author?.pointer,
      committerPointer: committer.pointer,
      message: message,
    );
  }

  /// Finishes a rebase that is currently in progress once all patches have been applied.
  void finish() => bindings.finish(_rebasePointer);

  /// Aborts a rebase that is currently in progress, resetting the repository and working
  /// directory to their state before rebase began.
  void abort() => bindings.abort(_rebasePointer);

  /// Releases memory allocated for rebase object.
  void free() => bindings.free(_rebasePointer);
}

class RebaseOperation {
  /// Initializes a new instance of the [RebaseOperation] class from
  /// provided pointer to rebase operation object in memory.
  const RebaseOperation(this._rebaseOperationPointer);

  /// Pointer to memory address for allocated rebase operation object.
  final Pointer<git_rebase_operation> _rebaseOperationPointer;

  /// Returns the type of rebase operation.
  GitRebaseOperation get type {
    return GitRebaseOperation.values.singleWhere(
      (e) => _rebaseOperationPointer.ref.type == e.value,
    );
  }

  /// Returns the commit [Oid] being cherry-picked.
  Oid get oid => Oid.fromRaw(_rebaseOperationPointer.ref.id);

  @override
  String toString() => 'RebaseOperation{type: $type, oid: $oid}';
}
