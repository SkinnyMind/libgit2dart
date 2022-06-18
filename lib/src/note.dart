import 'dart:ffi';
import 'package:equatable/equatable.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/bindings/libgit2_bindings.dart';
import 'package:libgit2dart/src/bindings/note.dart' as bindings;
import 'package:meta/meta.dart';

@immutable
class Note extends Equatable {
  /// Initializes a new instance of the [Note] class from provided
  /// pointer to note and annotatedOid objects in memory.
  ///
  /// Note: For internal use. Use [Note.lookup] instead.
  @internal
  Note(this._notePointer, this._annotatedOidPointer) {
    _finalizer.attach(this, _notePointer, detach: this);
  }

  /// Lookups the note for an [annotatedOid].
  ///
  /// [repo] is the repository where to look up the note.
  ///
  /// [annotatedOid] is the [Oid] of the git object to read the note from.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
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
    _finalizer.attach(this, _notePointer, detach: this);
  }

  /// Pointer to memory address for allocated note object.
  late final Pointer<git_note> _notePointer;

  /// Pointer to memory address for allocated annotetedOid object.
  late final Pointer<git_oid> _annotatedOidPointer;

  /// Creates a note for an [annotatedOid].
  ///
  /// [repo] is the repository where to store the note.
  ///
  /// [author] is the signature of the note's commit author.
  ///
  /// [committer] is the signature of the note's commit committer.
  ///
  /// [annotatedOid] is the [Oid] of the git object to decorate.
  ///
  /// [note] is the content of the note to add.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
  ///
  /// [force] determines whether existing note should be overwritten.
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
    return Oid(
      bindings.create(
        repoPointer: repo.pointer,
        authorPointer: author.pointer,
        committerPointer: committer.pointer,
        oidPointer: annotatedOid.pointer,
        note: note,
        notesRef: notesRef,
        force: force,
      ),
    );
  }

  /// Deletes the note for an [annotatedOid].
  ///
  /// [repo] is the repository where the note lives.
  ///
  /// [annotatedOid] is the [Oid] of the git object to remove the note from.
  ///
  /// [author] is the signature of the note's commit author.
  ///
  /// [committer] is the signature of the note's commit committer.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
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
      notesRef: notesRef,
      authorPointer: author.pointer,
      committerPointer: committer.pointer,
      oidPointer: annotatedOid.pointer,
    );
  }

  /// Returns list of notes for [repo]sitory.
  ///
  /// [notesRef] is the canonical name of the reference to use. Defaults to "refs/notes/commits".
  ///
  /// Throws a [LibGit2Error] if error occured.
  static List<Note> list(
    Repository repo, {
    String notesRef = 'refs/notes/commits',
  }) {
    final notesPointers = bindings.list(
      repoPointer: repo.pointer,
      notesRef: notesRef,
    );
    return notesPointers
        .map(
          (e) => Note(
            e['note']! as Pointer<git_note>,
            e['annotatedOid']! as Pointer<git_oid>,
          ),
        )
        .toList();
  }

  /// Note object's [Oid].
  Oid get oid => Oid(bindings.id(_notePointer));

  /// Note message.
  String get message => bindings.message(_notePointer);

  /// [Oid] of the git object being annotated.
  Oid get annotatedOid => Oid(_annotatedOidPointer);

  /// Releases memory allocated for note object.
  void free() {
    bindings.free(_notePointer);
    _finalizer.detach(this);
  }

  @override
  String toString() {
    return 'Note{oid: $oid, message: $message, annotatedOid: $annotatedOid}';
  }

  @override
  List<Object?> get props => [oid];
}

// coverage:ignore-start
final _finalizer = Finalizer<Pointer<git_note>>(
  (pointer) => bindings.free(pointer),
);
// coverage:ignore-end
