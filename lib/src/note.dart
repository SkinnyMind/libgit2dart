import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/note.dart' as bindings;

class Note {
  /// Initializes a new instance of the [Note] class from provided
  /// pointer to note and annotatedId objects in memory.
  Note(this._notePointer, this._annotatedIdPointer);

  /// Reads the note for an [annotatedId].
  ///
  /// IMPORTANT: Notes must be freed manually when no longer needed to prevent
  /// memory leak.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Note.lookup({
    required Repository repo,
    required Oid annotatedId,
    String notesRef = 'refs/notes/commits',
  }) {
    _notePointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: annotatedId.pointer,
      notesRef: notesRef,
    );
    _annotatedIdPointer = annotatedId.pointer;
  }

  /// Pointer to memory address for allocated note object.
  late final Pointer<git_note> _notePointer;

  /// Pointer to memory address for allocated annotetedId object.
  late final Pointer<git_oid> _annotatedIdPointer;

  /// Adds a note for an [annotatedId].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required Signature author,
    required Signature committer,
    required Oid annotatedId,
    required String note,
    String notesRef = 'refs/notes/commits',
    bool force = false,
  }) {
    return Oid(bindings.create(
      repoPointer: repo.pointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedId.pointer,
      note: note,
      notesRef: notesRef,
      force: force,
    ));
  }

  /// Deletes the note for an [annotatedId].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({
    required Repository repo,
    required Oid annotatedId,
    required Signature author,
    required Signature committer,
    String notesRef = 'refs/notes/commits',
  }) {
    bindings.delete(
      repoPointer: repo.pointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedId.pointer,
    );
  }

  /// Returns list of notes for repository.
  ///
  /// IMPORTANT: Notes must be freed manually when no longer needed to prevent
  /// memory leak.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<Note> list(Repository repo) {
    final notesPointers = bindings.list(repo.pointer);
    var result = <Note>[];
    for (var note in notesPointers) {
      result.add(Note(
        note['note'] as Pointer<git_note>,
        note['annotatedId'] as Pointer<git_oid>,
      ));
    }

    return result;
  }

  /// Returns the note object's [Oid].
  Oid get id => Oid(bindings.id(_notePointer));

  /// Returns the note message.
  String get message => bindings.message(_notePointer);

  /// Returns the [Oid] of the git object being annotated.
  Oid get annotatedId => Oid(_annotatedIdPointer);

  /// Releases memory allocated for note object.
  void free() => bindings.free(_notePointer);
}
