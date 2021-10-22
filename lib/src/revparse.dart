import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/revparse.dart' as bindings;

class RevParse {
  /// Finds a single object and intermediate reference (if there is one) by a
  /// [spec] revision string.
  ///
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may
  /// point to an intermediate reference. When such expressions are being
  /// passed in, reference_out will be valued as well.
  ///
  /// **IMPORTANT**: The returned object and reference should be freed to
  /// release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RevParse.ext({required Repository repo, required String spec}) {
    final pointers = bindings.revParseExt(
      repoPointer: repo.pointer,
      spec: spec,
    );
    object = Commit(pointers[0].cast<git_commit>());
    if (pointers.length == 2) {
      reference = Reference(pointers[1].cast<git_reference>());
    } else {
      reference = null;
    }
  }

  /// Object found by a revision string.
  late final Commit object;

  /// Intermediate reference found by a revision string.
  late final Reference? reference;

  /// Finds a single object, as specified by a [spec] revision string.
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// The returned object should be released when no longer needed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Commit single({required Repository repo, required String spec}) {
    return Commit(bindings
        .revParseSingle(
          repoPointer: repo.pointer,
          spec: spec,
        )
        .cast());
  }

  /// Parses a revision string for from, to, and intent.
  ///
  /// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static RevSpec range({required Repository repo, required String spec}) {
    return RevSpec(bindings.revParse(
      repoPointer: repo.pointer,
      spec: spec,
    ));
  }

  @override
  String toString() {
    return 'RevParse{object: $object, reference: $reference}';
  }
}

class RevSpec {
  /// Initializes a new instance of [RevSpec] class from provided
  /// pointer to revspec object in memory.
  const RevSpec(this._revSpecPointer);

  /// Pointer to memory address for allocated revspec object.
  final Pointer<git_revspec> _revSpecPointer;

  /// Left element of the revspec.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Commit get from => Commit(_revSpecPointer.ref.from.cast());

  /// Right element of the revspec.
  ///
  /// **IMPORTANT**: Should be freed to release allocated memory.
  Commit? get to {
    return _revSpecPointer.ref.to == nullptr
        ? null
        : Commit(_revSpecPointer.ref.to.cast());
  }

  /// The intent of the revspec.
  Set<GitRevSpec> get flags {
    return GitRevSpec.values
        .where((e) => _revSpecPointer.ref.flags & e.value == e.value)
        .toSet();
  }

  @override
  String toString() {
    return 'RevSpec{from: $from, to: $to, flags: $flags}';
  }
}
