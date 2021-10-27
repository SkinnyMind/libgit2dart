import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const notesExpected = [
    {
      'oid': 'd854ba919e1bb303f4d6bb4ca9a15c5cab2a2a50',
      'message': 'Another note\n',
      'annotatedOid': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
    },
    {
      'oid': 'd2ffe6b06b11dd90c2ee3f15d2c6b62f018554ed',
      'message': 'Note for HEAD\n',
      'annotatedOid': '821ed6e80627b8769d170a293862f9fc60825226',
    },
  ];

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Note', () {
    test('returns list of notes', () {
      final notes = repo.notes;

      expect(notes.length, 2);

      for (var i = 0; i < notes.length; i++) {
        expect(notes[i].oid.sha, notesExpected[i]['oid']);
        expect(notes[i].message, notesExpected[i]['message']);
        expect(notes[i].annotatedOid.sha, notesExpected[i]['annotatedOid']);
        notes[i].free();
      }
    });

    test('throws when trying to get list of notes and error occurs', () {
      Directory('${repo.workdir}.git/refs/notes').deleteSync(recursive: true);
      expect(() => repo.notes, throwsA(isA<LibGit2Error>()));
    });

    test('successfully lookups note', () {
      final head = repo.head;
      final note = repo.lookupNote(annotatedOid: head.target);

      expect(note.oid.sha, notesExpected[1]['oid']);
      expect(note.message, notesExpected[1]['message']);
      expect(note.annotatedOid.sha, notesExpected[1]['annotatedOid']);

      note.free();
      head.free();
    });

    test('successfully creates note', () {
      final signature = repo.defaultSignature;
      final head = repo.head;
      final noteOid = repo.createNote(
        author: signature,
        committer: signature,
        annotatedOid: head.target,
        note: 'New note for HEAD',
        force: true,
      );
      final noteBlob = repo.lookupBlob(noteOid);

      expect(noteOid.sha, 'ffd6e2ceaf91c00ea6d29e2e897f906da720529f');
      expect(noteBlob.content, 'New note for HEAD');

      noteBlob.free();
      head.free();
      signature.free();
    });

    test('throws when trying to create note and error occurs', () {
      expect(
        () => Repository(nullptr).createNote(
          author: Signature(nullptr),
          committer: Signature(nullptr),
          annotatedOid: repo['0' * 40],
          note: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully deletes note', () {
      final signature = repo.defaultSignature;
      final head = repo.head;

      repo.deleteNote(
        annotatedOid: repo.head.target,
        author: signature,
        committer: signature,
      );

      expect(
        () => repo.lookupNote(annotatedOid: head.target),
        throwsA(isA<LibGit2Error>()),
      );

      head.free();
      signature.free();
    });

    test('throws when trying to delete note and error occurs', () {
      expect(
        () => Repository(nullptr).deleteNote(
          author: Signature(nullptr),
          committer: Signature(nullptr),
          annotatedOid: repo['0' * 40],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns string representation of Note object', () {
      final note = repo.lookupNote(annotatedOid: repo['821ed6e']);
      expect(note.toString(), contains('Note{'));
      note.free();
    });
  });
}
