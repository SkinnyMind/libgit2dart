import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const notesExpected = [
    {
      'id': 'd854ba919e1bb303f4d6bb4ca9a15c5cab2a2a50',
      'message': 'Another note\n',
      'annotatedId': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
    },
    {
      'id': 'd2ffe6b06b11dd90c2ee3f15d2c6b62f018554ed',
      'message': 'Note for HEAD\n',
      'annotatedId': '821ed6e80627b8769d170a293862f9fc60825226',
    },
  ];

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Note', () {
    test('returns list of notes', () {
      final notes = repo.notes;

      expect(notes.length, 2);

      for (var i = 0; i < notes.length; i++) {
        expect(notes[i].id.sha, notesExpected[i]['id']);
        expect(notes[i].message, notesExpected[i]['message']);
        expect(notes[i].annotatedId.sha, notesExpected[i]['annotatedId']);
      }

      for (var note in notes) {
        note.free();
      }
    });

    test('successfully lookups note', () {
      final head = repo.head;
      final note = repo.lookupNote(annotatedId: head.target);

      expect(note.id.sha, notesExpected[1]['id']);
      expect(note.message, notesExpected[1]['message']);
      expect(note.annotatedId.sha, notesExpected[1]['annotatedId']);

      note.free();
      head.free();
    });

    test('successfully creates note', () {
      final signature = repo.defaultSignature;
      final head = repo.head;
      final noteOid = repo.createNote(
        author: signature,
        committer: signature,
        object: head.target,
        note: 'New note for HEAD',
        force: true,
      );
      final noteBlob = repo[noteOid.sha] as Blob;

      expect(noteOid.sha, 'ffd6e2ceaf91c00ea6d29e2e897f906da720529f');
      expect(noteBlob.content, 'New note for HEAD');

      noteBlob.free();
      head.free();
      signature.free();
    });

    test('successfully removes note', () {
      final signature = repo.defaultSignature;
      final head = repo.head;
      final note = repo.lookupNote(annotatedId: head.target);

      note.remove(author: signature, committer: signature);
      expect(
        () => repo.lookupNote(annotatedId: head.target),
        throwsA(isA<LibGit2Error>()),
      );

      note.free();
      head.free();
      signature.free();
    });
  });
}
