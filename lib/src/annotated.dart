import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/annotated.dart' as bindings;
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:meta/meta.dart';

@immutable
class AnnotatedCommit extends Equatable {
  /// Lookups an annotated commit from the given commit [oid].
  ///
  /// It is preferable to use [AnnotatedCommit.fromReference] instead of this
  /// one, for commit to contain more information about how it was looked up.
  ///
  /// Throws a [LibGit2Error] if error occured.
  AnnotatedCommit.lookup({required Repository repo, required Oid oid}) {
    _annotatedCommitPointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: oid.pointer,
    );
    _finalizer.attach(this, _annotatedCommitPointer, detach: this);
  }

  /// Creates an annotated commit from the given [reference].
  ///
  /// Throws a [LibGit2Error] if error occured.
  AnnotatedCommit.fromReference({
    required Repository repo,
    required Reference reference,
  }) {
    _annotatedCommitPointer = bindings.fromRef(
      repoPointer: repo.pointer,
      referencePointer: reference.pointer,
    );
    _finalizer.attach(this, _annotatedCommitPointer, detach: this);
  }

  /// Creates an annotated commit from a revision string.
  ///
  /// See `man gitrevisions`, or http://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  AnnotatedCommit.fromRevSpec({
    required Repository repo,
    required String spec,
  }) {
    _annotatedCommitPointer = bindings.fromRevSpec(
      repoPointer: repo.pointer,
      revspec: spec,
    );
    _finalizer.attach(this, _annotatedCommitPointer, detach: this);
  }

  /// Creates an annotated commit from the given fetch head data.
  ///
  /// [repo] is repository that contains the given commit.
  ///
  /// [branchName] is name of the (remote) branch.
  ///
  /// [remoteUrl] is url of the remote.
  ///
  /// [oid] is the commit object id of the remote branch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  AnnotatedCommit.fromFetchHead({
    required Repository repo,
    required String branchName,
    required String remoteUrl,
    required Oid oid,
  }) {
    _annotatedCommitPointer = bindings.fromFetchHead(
      repoPointer: repo.pointer,
      branchName: branchName,
      remoteUrl: remoteUrl,
      oid: oid.pointer,
    );
    _finalizer.attach(this, _annotatedCommitPointer, detach: this);
  }

  late final Pointer<git_annotated_commit> _annotatedCommitPointer;

  /// Pointer to pointer to memory address for allocated commit object.
  ///
  /// Note: For internal use.
  @internal
  Pointer<git_annotated_commit> get pointer => _annotatedCommitPointer;

  /// Commit oid that the given annotated commit refers to.
  Oid get oid => Oid.fromRaw(bindings.oid(_annotatedCommitPointer).ref);

  /// Reference name that the annotated commit refers to.
  ///
  /// Returns empty string if no information found.
  String get refName => bindings.refName(_annotatedCommitPointer);

  /// Releases memory allocated for commit object.
  void free() {
    bindings.free(_annotatedCommitPointer);
    _finalizer.detach(this);
  }

  @override
  List<Object?> get props => [oid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_annotated_commit>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
