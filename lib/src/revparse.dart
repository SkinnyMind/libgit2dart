import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/revparse.dart' as bindings;
import 'commit.dart';
import 'reference.dart';
import 'repository.dart';
import 'enums.dart';

class RevParse {
  /// Finds a single object and intermediate reference (if there is one) by a [spec] revision string.
  ///
  /// See `man gitrevisions`, or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// In some cases (@{<-n>} or <branchname>@{upstream}), the expression may point to an
  /// intermediate reference. When such expressions are being passed in, reference_out will be
  /// valued as well.
  ///
  /// The returned object and reference should be released when no longer needed.
  ///
  /// Throws a [LibGit2Error] if error occured.
  RevParse.ext(Repository repo, String spec) {
    final pointers = bindings.revParseExt(repo.pointer, spec);
    object = Commit(pointers[0].cast<git_commit>());
    if (pointers.length == 2) {
      reference = Reference(repo.pointer, pointers[1].cast<git_reference>());
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
  static Commit single(Repository repo, String spec) {
    return Commit(bindings.revParseSingle(repo.pointer, spec).cast());
  }

  /// Parses a revision string for from, to, and intent.
  ///
  /// See `man gitrevisions` or https://git-scm.com/docs/git-rev-parse.html#_specifying_revisions
  /// for information on the syntax accepted.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static RevSpec range(Repository repo, String spec) {
    return RevSpec(bindings.revParse(repo.pointer, spec));
  }
}

class RevSpec {
  /// Initializes a new instance of [RevSpec] class from provided
  /// pointer to revspec object in memory.
  RevSpec(this._revSpecPointer);

  /// Pointer to memory address for allocated revspec object.
  late final Pointer<git_revspec> _revSpecPointer;

  /// The left element of the revspec; must be freed by the user.
  Commit get from => Commit(_revSpecPointer.ref.from.cast());

  /// The right element of the revspec; must be freed by the user.
  Commit? get to {
    if (_revSpecPointer.ref.to == nullptr) {
      return null;
    } else {
      return Commit(_revSpecPointer.ref.to.cast());
    }
  }

  /// The intent of the revspec.
  GitRevParse get flags {
    final flag = _revSpecPointer.ref.flags;
    if (flag == 1) {
      return GitRevParse.single;
    } else if (flag == 2) {
      return GitRevParse.range;
    } else {
      return GitRevParse.mergeBase;
    }
  }
}