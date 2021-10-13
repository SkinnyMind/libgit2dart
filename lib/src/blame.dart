import 'dart:collection';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/blame.dart' as bindings;

class Blame with IterableMixin<BlameHunk> {
  /// Initializes a new instance of the [Blame] class from
  /// provided pointer to blame object in memory.
  Blame(this._blamePointer);

  /// Initializes a new instance of the [Blame] class by getting
  /// the blame for a single file.
  ///
  /// [flags] is a combination of [GitBlameFlag]s.
  ///
  /// [minMatchCharacters] is the lower bound on the number of alphanumeric
  /// characters that must be detected as moving/copying within a file for
  /// it to associate those lines with the parent commit. The default value is 20.
  /// This value only takes effect if any of the [GitBlameFlag.trackCopies*]
  /// flags are specified.
  ///
  /// [newestCommit] is the id of the newest commit to consider. The default is HEAD.
  ///
  /// [oldestCommit] is the id of the oldest commit to consider. The default is the
  /// first commit encountered with no parent.
  ///
  /// [minLine] is the first line in the file to blame. The default is 1
  /// (line numbers start with 1).
  ///
  /// [maxLine] is the last line in the file to blame. The default is the last
  /// line of the file.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Blame.file({
    required Repository repo,
    required String path,
    Set<GitBlameFlag> flags = const {GitBlameFlag.normal},
    int? minMatchCharacters,
    Oid? newestCommit,
    Oid? oldestCommit,
    int? minLine,
    int? maxLine,
  }) {
    _blamePointer = bindings.file(
      repoPointer: repo.pointer,
      path: path,
      flags: flags.fold(0, (acc, e) => acc | e.value),
      minMatchCharacters: minMatchCharacters,
      newestCommit: newestCommit,
      oldestCommit: oldestCommit,
      minLine: minLine,
      maxLine: maxLine,
    );
  }

  /// Pointer to memory address for allocated blame object.
  late final Pointer<git_blame> _blamePointer;

  /// Returns the blame hunk at the given index.
  ///
  /// Throws [RangeError] if index out of range.
  BlameHunk operator [](int index) {
    return BlameHunk(bindings.getHunkByIndex(
      blamePointer: _blamePointer,
      index: index,
    ));
  }

  /// Gets the hunk that relates to the given line number (1-based) in the newest commit.
  ///
  /// Throws [RangeError] if [lineNumber] is out of range.
  BlameHunk forLine(int lineNumber) {
    return BlameHunk(bindings.getHunkByLine(
      blamePointer: _blamePointer,
      lineNumber: lineNumber,
    ));
  }

  /// Releases memory allocated for blame object.
  void free() => bindings.free(_blamePointer);

  @override
  Iterator<BlameHunk> get iterator => _BlameIterator(_blamePointer);
}

class BlameHunk {
  /// Initializes a new instance of the [BlameHunk] class from
  /// provided pointer to blame hunk object in memory.
  const BlameHunk(this._blameHunkPointer);

  /// Pointer to memory address for allocated blame hunk object.
  final Pointer<git_blame_hunk> _blameHunkPointer;

  /// Returns the number of lines in this hunk.
  int get linesCount => _blameHunkPointer.ref.lines_in_hunk;

  /// Checks if the hunk has been tracked to a boundary commit
  /// (the root, or the commit specified in [oldestCommit] argument)
  bool get isBoundary {
    return _blameHunkPointer.ref.boundary == 1 ? true : false;
  }

  /// Returns the 1-based line number where this hunk begins, in the final
  /// version of the file.
  int get finalStartLineNumber => _blameHunkPointer.ref.final_start_line_number;

  /// Returns the author of [finalCommitOid]. If [GitBlameFlag.useMailmap] has been
  /// specified, it will contain the canonical real name and email address.
  Signature get finalCommitter =>
      Signature(_blameHunkPointer.ref.final_signature);

  /// Returns the [Oid] of the commit where this line was last changed.
  Oid get finalCommitOid => Oid.fromRaw(_blameHunkPointer.ref.final_commit_id);

  /// Returns the 1-based line number where this hunk begins, in the file
  /// named by [originPath] in the commit specified by [originCommitId].
  int get originStartLineNumber => _blameHunkPointer.ref.orig_start_line_number;

  /// Returns the author of [originCommitOid]. If [GitBlameFlag.useMailmap] has been
  /// specified, it will contain the canonical real name and email address.
  Signature get originCommitter =>
      Signature(_blameHunkPointer.ref.orig_signature);

  /// Returns the [Oid] of the commit where this hunk was found. This will usually be
  /// the same as [finalCommitOid], except when [GitBlameFlag.trackCopiesAnyCommitCopies]
  /// been specified.
  Oid get originCommitOid => Oid.fromRaw(_blameHunkPointer.ref.orig_commit_id);

  /// Returns the path to the file where this hunk originated, as of the commit
  /// specified by [originCommitOid].
  String get originPath =>
      _blameHunkPointer.ref.orig_path.cast<Utf8>().toDartString();
}

class _BlameIterator implements Iterator<BlameHunk> {
  _BlameIterator(this._blamePointer) {
    count = bindings.hunkCount(_blamePointer);
  }

  final Pointer<git_blame> _blamePointer;
  BlameHunk? currentHunk;
  late final int count;
  int index = 0;

  @override
  BlameHunk get current => currentHunk!;

  @override
  bool moveNext() {
    if (index == count) {
      return false;
    } else {
      currentHunk = BlameHunk(bindings.getHunkByIndex(
        blamePointer: _blamePointer,
        index: index,
      ));
      index++;
      return true;
    }
  }
}
