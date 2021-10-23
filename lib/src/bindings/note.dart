import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/error.dart';
import 'package:libgit2dart/src/util.dart';

/// Returns list of notes for repository.
///
/// Notes must be freed manually by the user.
///
/// Throws a [LibGit2Error] if error occured.
List<Map<String, Pointer>> list(Pointer<git_repository> repo) {
  final notesRef = 'refs/notes/commits'.toNativeUtf8().cast<Int8>();
  final iterator = calloc<Pointer<git_iterator>>();
  final iteratorError = libgit2.git_note_iterator_new(iterator, repo, notesRef);

  if (iteratorError < 0) {
    calloc.free(iterator);
    throw LibGit2Error(libgit2.git_error_last());
  }

  final result = <Map<String, Pointer>>[];
  var nextError = 0;

  while (nextError >= 0) {
    final noteOid = calloc<git_oid>();
    final annotatedOid = calloc<git_oid>();
    nextError = libgit2.git_note_next(noteOid, annotatedOid, iterator.value);
    if (nextError >= 0) {
      final out = calloc<Pointer<git_note>>();
      libgit2.git_note_read(out, repo, notesRef, annotatedOid);
      calloc.free(noteOid);
      result.add({'note': out.value, 'annotatedOid': annotatedOid});
    } else {
      break;
    }
  }

  calloc.free(notesRef);
  libgit2.git_note_iterator_free(iterator.value);

  return result;
}

/// Read the note for an object.
///
/// The note must be freed manually by the user.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_note> lookup({
  required Pointer<git_repository> repoPointer,
  required Pointer<git_oid> oidPointer,
  String notesRef = 'refs/notes/commits',
}) {
  final out = calloc<Pointer<git_note>>();
  final notesRefC = notesRef.toNativeUtf8().cast<Int8>();
  final error = libgit2.git_note_read(out, repoPointer, notesRefC, oidPointer);

  calloc.free(notesRefC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out.value;
  }
}

/// Add a note for an object.
///
/// Throws a [LibGit2Error] if error occured.
Pointer<git_oid> create({
  required Pointer<git_repository> repoPointer,
  String notesRef = 'refs/notes/commits',
  required Pointer<git_signature> authorPointer,
  required Pointer<git_signature> committerPointer,
  required Pointer<git_oid> oidPointer,
  required String note,
  bool force = false,
}) {
  final out = calloc<git_oid>();
  final notesRefC = notesRef.toNativeUtf8().cast<Int8>();
  final noteC = note.toNativeUtf8().cast<Int8>();
  final forceC = force ? 1 : 0;
  final error = libgit2.git_note_create(
    out,
    repoPointer,
    notesRefC,
    authorPointer,
    committerPointer,
    oidPointer,
    noteC,
    forceC,
  );

  calloc.free(notesRefC);
  calloc.free(noteC);

  if (error < 0) {
    calloc.free(out);
    throw LibGit2Error(libgit2.git_error_last());
  } else {
    return out;
  }
}

/// Delete the note for an object.
///
/// Throws a [LibGit2Error] if error occured.
void delete({
  required Pointer<git_repository> repoPointer,
  String notesRef = 'refs/notes/commits',
  required Pointer<git_signature> authorPointer,
  required Pointer<git_signature> committerPointer,
  required Pointer<git_oid> oidPointer,
}) {
  final notesRefC = notesRef.toNativeUtf8().cast<Int8>();

  final error = libgit2.git_note_remove(
    repoPointer,
    notesRefC,
    authorPointer,
    committerPointer,
    oidPointer,
  );

  calloc.free(notesRefC);

  if (error < 0) {
    throw LibGit2Error(libgit2.git_error_last());
  }
}

/// Get the note object's id.
Pointer<git_oid> id(Pointer<git_note> note) => libgit2.git_note_id(note);

/// Get the note message.
String message(Pointer<git_note> note) {
  return libgit2.git_note_message(note).cast<Utf8>().toDartString();
}

/// Free memory allocated for note object.
void free(Pointer<git_note> note) => libgit2.git_note_free(note);
