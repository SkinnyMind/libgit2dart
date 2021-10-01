import 'dart:ffi';
import 'bindings/libgit2_bindings.dart';
import 'bindings/note.dart' as bindings;
import 'oid.dart';
import 'repository.dart';
import 'signature.dart';

class Notes {
  /// Initializes a new instance of the [Notes] class from
  /// provided [Repository] object.
  Notes(Repository repo) {
    _repoPointer = repo.pointer;
  }

  /// Pointer to memory address for allocated repository object.
  late final Pointer<git_repository> _repoPointer;

  /// Reads the note for an object.
  ///
  /// The note must be freed manually by the user.
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Note lookup({
    required Repository repo,
    required Oid annotatedId,
    String notesRef = 'refs/notes/commits',
  }) {
    final note = bindings.lookup(
      repoPointer: repo.pointer,
      oidPointer: annotatedId.pointer,
      notesRef: notesRef,
    );

    return Note(note, annotatedId.pointer, repo.pointer);
  }

  /// Adds a note for an [object].
  ///
  /// Throws a [LibGit2Error] if error occured.
  static Oid create({
    required Repository repo,
    required Signature author,
    required Signature committer,
    required Oid object,
    required String note,
    String notesRef = 'refs/notes/commits',
    bool force = false,
  }) {
    return Oid(bindings.create(
      repoPointer: repo.pointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: object.pointer,
      note: note,
      notesRef: notesRef,
      force: force,
    ));
  }

  /// Returns list of notes for repository.
  ///
  /// Notes must be freed manually by the user.
  ///
  /// Throws a [LibGit2Error] if error occured.
  List<Note> get list {
    final notesPointers = bindings.list(_repoPointer);
    var result = <Note>[];
    for (var note in notesPointers) {
      result.add(Note(
        note['note'] as Pointer<git_note>,
        note['annotatedId'] as Pointer<git_oid>,
        _repoPointer,
      ));
    }

    return result;
  }
}

class Note {
  /// Initializes a new instance of the [Note] class from provided
  /// pointer to note object in memory.
  Note(this._notePointer, this._annotatedIdPointer, this._repoPointer);

  /// Pointer to memory address for allocated note object.
  final Pointer<git_note> _notePointer;

  /// Pointer to memory address for allocated annotetedId object.
  final Pointer<git_oid> _annotatedIdPointer;

  /// Pointer to memory address for allocated repository object.
  final Pointer<git_repository> _repoPointer;

  /// Removes the note for an [object].
  ///
  /// Throws a [LibGit2Error] if error occured.
  void remove({
    required Signature author,
    required Signature committer,
    String notesRef = 'refs/notes/commits',
  }) {
    bindings.remove(
      repoPointer: _repoPointer,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedId.pointer,
    );
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
