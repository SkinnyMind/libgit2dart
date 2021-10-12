import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/rebase.dart' as bindings;
import 'bindings/commit.dart' as commit_bindings;

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
    Pointer<git_annotated_commit>? _branch, _upstream, _onto;
    if (branch != null) {
      _branch = commit_bindings
          .annotatedLookup(
            repoPointer: repo.pointer,
            oidPointer: branch.pointer,
          )
          .value;
    }
    if (upstream != null) {
      _upstream = commit_bindings
          .annotatedLookup(
            repoPointer: repo.pointer,
            oidPointer: upstream.pointer,
          )
          .value;
    }
    if (onto != null) {
      _onto = commit_bindings
          .annotatedLookup(
            repoPointer: repo.pointer,
            oidPointer: onto.pointer,
          )
          .value;
    }

    _rebasePointer = bindings.init(
      repoPointer: repo.pointer,
      branchPointer: _branch,
      upstreamPointer: _upstream,
      ontoPointer: _onto,
    );
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
  /// introduced during the patch application from the `next()` invocation.
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
  ///
  /// Throws a [LibGit2Error] if error occured.
  void finish() => bindings.finish(_rebasePointer);

  /// Aborts a rebase that is currently in progress, resetting the repository and working
  /// directory to their state before rebase began.
  ///
  /// Throws a [LibGit2Error] if error occured.
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

  /// The commit ID being cherry-picked. This will be populated for
  /// all operations except those of type [GitRebaseOperation.exec].
  Oid get id => Oid.fromRaw(_rebaseOperationPointer.ref.id);

  /// The executable the user has requested be run. This will only
  /// be populated for operations of type [GitRebaseOperation.exec].
  String get exec {
    return _rebaseOperationPointer.ref.exec == nullptr
        ? ''
        : _rebaseOperationPointer.ref.exec.cast<Utf8>().toDartString();
  }
}
