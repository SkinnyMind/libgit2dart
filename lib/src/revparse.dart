import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/object.dart' as object_bindings;
import 'package:libgit2dart/src/bindings/revparse.dart' as bindings;

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
  /// Throws a [LibGit2Error] if error occured.
  RevParse.ext({required Repository repo, required String spec}) {
    final pointers = bindings.revParseExt(
      repoPointer: repo.pointer,
      spec: spec,
    );
    object = Commit(pointers[0].cast<git_commit>());
    reference = pointers.length == 2
        ? Reference(pointers[1].cast<git_reference>())
        : null;
  }

  /// Object found by a revision string.
  late final Commit object;

  /// Intermediate reference found by a revision string.
  late final Reference? reference;

  /// Finds a single object, as specified by a [spec] revision string.
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Returned object should be explicitly downcasted to one of four of git
  /// object types.
  ///
  /// ```dart
  /// final commit = RevParse.single(repo: repo, spec: 'HEAD') as Commit;
  /// final tree = RevParse.single(repo: repo, spec: 'HEAD^{tree}') as Tree;
  /// final blob = RevParse.single(repo: repo, spec: 'HEAD:file.txt') as Blob;
  /// final tag = RevParse.single(repo: repo, spec: 'v1.0') as Tag;
  /// ```
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Object single({required Repository repo, required String spec}) {
    final object = bindings.revParseSingle(
      repoPointer: repo.pointer,
      spec: spec,
    );
    final objectType = object_bindings.type(object);

    if (objectType == GitObject.commit.value) {
      return Commit(object.cast());
    } else if (objectType == GitObject.tree.value) {
      return Tree(object.cast());
    } else if (objectType == GitObject.blob.value) {
      return Blob(object.cast());
    } else {
      return Tag(object.cast());
    }
  }

  /// Parses a revision string for from, to, and intent.
  ///
  /// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static RevSpec range({required Repository repo, required String spec}) {
    return RevSpec._(
      bindings.revParse(
        repoPointer: repo.pointer,
        spec: spec,
      ),
    );
  }

  @override
  String toString() {
    return 'RevParse{object: $object, reference: $reference}';
  }
}

class RevSpec {
  /// Initializes a new instance of [RevSpec] class from provided
  /// pointer to revspec object in memory.
  const RevSpec._(this._revSpecPointer);

  /// Pointer to memory address for allocated revspec object.
  final Pointer<git_revspec> _revSpecPointer;

  /// Left element of the revspec.
  Commit get from => Commit(_revSpecPointer.ref.from.cast());

  /// Right element of the revspec.
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
