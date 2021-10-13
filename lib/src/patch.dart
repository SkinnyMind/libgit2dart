import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/patch.dart' as bindings;
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
  Patch.create({
    required Object? a,
    required Object? b,
    String? aPath,
    String? bPath,
    Set<GitDiff> flags = const {GitDiff.normal},
    int contextLines = 3,
    int interhunkLines = 0,
  }) {
    libgit2.git_libgit2_init();

    final int flagsInt = flags.fold(0, (acc, e) => acc | e.value);
    var result = <String, Pointer?>{};

    if (a is Blob?) {
      if (b is Blob) {
        result = bindings.fromBlobs(
          oldBlobPointer: a?.pointer ?? nullptr,
          oldAsPath: aPath,
          newBlobPointer: b.pointer,
          newAsPath: bPath,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        );
      } else if (b is String?) {
        result = bindings.fromBlobAndBuffer(
          oldBlobPointer: a?.pointer,
          oldAsPath: aPath,
          buffer: b,
          bufferAsPath: bPath,
          flags: flagsInt,
          contextLines: contextLines,
          interhunkLines: interhunkLines,
        );
      } else {
        throw ArgumentError('Provided argument(s) is not Blob or String');
      }
    } else if ((a is String?) && (b is String?)) {
      result = bindings.fromBuffers(
        oldBuffer: a as String?,
        oldAsPath: aPath,
        newBuffer: b,
        newAsPath: bPath,
        flags: flagsInt,
        contextLines: contextLines,
        interhunkLines: interhunkLines,
      );
    } else {
      throw ArgumentError('Provided argument(s) is not Blob or String');
    }

    _patchPointer = result['patch'] as Pointer<git_patch>;
    _aPointer = result['a'];
    _bPointer = result['b'];
  }

  /// Returns a patch for an entry in the diff list.
  ///
  /// Should be freed with `free()` to release allocated memory.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Patch.fromDiff({required Diff diff, required int index}) {
    libgit2.git_libgit2_init();

    _patchPointer = bindings.fromDiff(diffPointer: diff.pointer, index: index);
  }

  late final Pointer<git_patch> _patchPointer;

  Pointer<NativeType>? _aPointer;
  Pointer<NativeType>? _bPointer;

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
      patchPointer: _patchPointer,
      includeContext: includeContext,
      includeHunkHeaders: includeHunkHeaders,
      includeFileHeaders: includeFileHeaders,
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
      final hunk = bindings.hunk(patchPointer: _patchPointer, hunkIndex: i);
      hunks.add(DiffHunk(
        _patchPointer,
        hunk['hunk'] as Pointer<git_diff_hunk>,
        hunk['linesN'] as int,
        i,
      ));
    }

    return hunks;
  }

  /// Releases memory allocated for patch object.
  void free() {
    if (_aPointer != null) {
      calloc.free(_aPointer!);
    }
    if (_bPointer != null) {
      calloc.free(_bPointer!);
    }
    bindings.free(_patchPointer);
  }
}
