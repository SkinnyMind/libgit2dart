import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/patch.dart' as bindings;
import 'blob.dart';
import 'diff.dart';
import 'git_types.dart';
import 'util.dart';

class Patch {
  /// Initializes a new instance of [Patch] class from provided
  /// pointer to patch object in memory and pointers to old and new blobs/buffers.
  ///
  /// Should be freed with `free()` to release allocated memory.
  Patch(this._patchPointer, this._aPointer, this._bPointer);

  /// Directly generates a patch from the difference between two blobs, buffers or
  /// blob and a buffer.
  ///
  /// [a] and [b] can be [Blob], [String] or null.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.createFrom({
    required dynamic a,
    required dynamic b,
    String? aPath,
    String? bPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    libgit2.git_libgit2_init();

    final int flagsInt =
        flags.fold(0, (previousValue, e) => previousValue | e.value);
    var result = <String, dynamic>{};

    if (a is Blob || a == null) {
      if (b is Blob) {
        result = bindings.fromBlobs(
          a?.pointer,
          aPath,
          b.pointer,
          bPath,
          flagsInt,
          contextLines,
          interhunkLines,
        );
      } else if (b is String || b == null) {
        result = bindings.fromBlobAndBuffer(
          a?.pointer,
          aPath,
          b,
          bPath,
          flagsInt,
          contextLines,
          interhunkLines,
        );
      } else {
        throw ArgumentError('Provided argument(s) is not Blob or String');
      }
    } else if ((a is String || a == null) && (b is String || b == null)) {
      result = bindings.fromBuffers(
        a,
        aPath,
        b,
        bPath,
        flagsInt,
        contextLines,
        interhunkLines,
      );
    } else {
      throw ArgumentError('Provided argument(s) is not Blob or String');
    }

    _patchPointer = result['patch'];
    _aPointer = result['a'];
    _bPointer = result['b'];
  }

  /// Returns a patch for an entry in the diff list.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromDiff(Diff diff, int index) {
    libgit2.git_libgit2_init();

    _patchPointer = bindings.fromDiff(diff.pointer, index);
  }

  late final Pointer<git_patch> _patchPointer;

  dynamic _aPointer;
  dynamic _bPointer;

  /// Pointer to memory address for allocated patch object.
  Pointer<git_patch> get pointer => _patchPointer;

  /// Returns the content of a patch as a single diff text.
  ///
  /// Throws a [LibGit2Error] if error occured.
  String get text => bindings.text(_patchPointer);

  /// Looks up size of patch diff data in bytes.
  ///
  /// This returns the raw size of the patch data. This only includes the actual data from
  /// the lines of the diff, not the file or hunk headers.
  ///
  /// If you pass `includeContext` as true, this will be the size of all of the diff output;
  /// if you pass it as false, this will only include the actual changed lines (as if
  /// contextLines was 0).
  int size({
    bool includeContext = false,
    bool includeHunkHeaders = false,
    bool includeFileHeaders = false,
  }) {
    return bindings.size(
      _patchPointer,
      includeContext,
      includeHunkHeaders,
      includeFileHeaders,
    );
  }

  /// Returns the delta associated with a patch.
  DiffDelta get delta => DiffDelta(bindings.delta(_patchPointer));

  /// Returns the list of hunks in a patch.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<DiffHunk> get hunks {
    final length = bindings.numHunks(_patchPointer);
    final hunks = <DiffHunk>[];

    for (var i = 0; i < length; i++) {
      final hunk = bindings.hunk(_patchPointer, i);
      hunks.add(DiffHunk(_patchPointer, hunk['hunk'], hunk['linesN'], i));
    }

    return hunks;
  }

  /// Releases memory allocated for patch object.
  void free() {
    if (_aPointer != null) {
      calloc.free(_aPointer);
    }
    if (_bPointer != null) {
      calloc.free(_bPointer);
    }
    bindings.free(_patchPointer);
  }
}
