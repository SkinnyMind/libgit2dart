import 'dart:ffi';
import 'package:libgit2dart/libgit2dart.dart';
import 'bindings/libgit2_bindings.dart';
import 'bindings/note.dart' as bindings;

class Note {
  /// Initializes a new instance of the [Note] class from provided
  /// pointer to note and annotatedOid objects in memory.
  Note(this._notePointer, this._annotatedOidPointer);

  /// Reads the note for an [annotatedOid].
  ///
  /// IMPORTANT: Notes must be freed manually when no longer needed to prevent
  /// memory leak.
  ///
  /// Throws a [LibGit2Error] if error occured.
  Note.lookup({
    required Repository repo,
    required Oid annotatedOid,
    String notesRef = 'refs/notes/commits',
  }) {
    _notePointer = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: annotatedOid.pointer,
      notesRef: notesRef,
    );
    _annotatedOidPointer = annotatedOid.pointer;
  }

  /// Pointer to memory address for allocated note object.
  late final Pointer<git_note> _notePointer;

  /// Pointer to memory address for allocated annotetedOid object.
  late final Pointer<git_oid> _annotatedOidPointer;

  /// Adds a note for an [annotatedOid].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required Signature author,
    required Signature committer,
    required Oid annotatedOid,
    required String note,
    String notesRef = 'refs/notes/commits',
    bool force = false,
  }) {
    return Oid(bindings.create(
      repoPointer: repo.pointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedOid.pointer,
      note: note,
      notesRef: notesRef,
      force: force,
    ));
  }

  /// Deletes the note for an [annotatedOid].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static void delete({
    required Repository repo,
    required Oid annotatedOid,
    required Signature author,
    required Signature committer,
    String notesRef = 'refs/notes/commits',
  }) {
    bindings.delete(
      repoPointer: repo.pointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedOid.pointer,
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
    return notesPointers
        .map((e) => Note(
              e['note'] as Pointer<git_note>,
              e['annotatedOid'] as Pointer<git_oid>,
            ))
        .toList();
  }

  /// Returns the note object's [Oid].
  Oid get oid => Oid(bindings.id(_notePointer));

  /// Returns the note message.
  String get message => bindings.message(_notePointer);

  /// Returns the [Oid] of the git object being annotated.
  Oid get annotatedOid => Oid(_annotatedOidPointer);

  /// Releases memory allocated for note object.
  void free() => bindings.free(_notePointer);

  @override
  String toString() {
    return 'Note{oid: $oid, message: $message, annotatedOid: $annotatedOid}';
  }
}
