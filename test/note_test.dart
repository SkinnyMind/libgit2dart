import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
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
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Note', () {
    test('returns list of notes', () {
      final notes = Note.list(repo);

      expect(notes.length, 2);

      for (var i = 0; i < notes.length; i++) {
        expect(notes[i].oid.sha, notesExpected[i]['oid']);
        expect(notes[i].message, notesExpected[i]['message']);
        expect(notes[i].annotatedOid.sha, notesExpected[i]['annotatedOid']);
      }
    });

    test('throws when trying to get list of notes and error occurs', () {
      Directory(p.join(repo.path, 'refs', 'notes')).deleteSync(recursive: true);
      expect(() => Note.list(repo), throwsA(isA<LibGit2Error>()));
    });

    test('lookups note', () {
      final note = Note.lookup(repo: repo, annotatedOid: repo.head.target);

      expect(note.oid.sha, notesExpected[1]['oid']);
      expect(note.message, notesExpected[1]['message']);
      expect(note.annotatedOid.sha, notesExpected[1]['annotatedOid']);
    });

    test('creates note', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final noteOid = Note.create(
        repo: repo,
        author: signature,
        committer: signature,
        annotatedOid: repo.head.target,
        note: 'New note for HEAD',
        force: true,
      );

      expect(noteOid.sha, 'ffd6e2ceaf91c00ea6d29e2e897f906da720529f');
      expect(
        Blob.lookup(repo: repo, oid: noteOid).content,
        'New note for HEAD',
      );
    });

    test('throws when trying to create note and error occurs', () {
      expect(
        () => Note.create(
          repo: Repository(nullptr),
          author: Signature(nullptr),
          committer: Signature(nullptr),
          annotatedOid: repo['0' * 40],
          note: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('deletes note', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );

      Note.delete(
        repo: repo,
        annotatedOid: repo.head.target,
        author: signature,
        committer: signature,
      );

      expect(
        () => Note.lookup(repo: repo, annotatedOid: repo.head.target),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to delete note and error occurs', () {
      expect(
        () => Note.delete(
          repo: Repository(nullptr),
          author: Signature(nullptr),
          committer: Signature(nullptr),
          annotatedOid: repo['0' * 40],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final note = Note.lookup(repo: repo, annotatedOid: repo['821ed6e']);
      expect(() => note.free(), returnsNormally);
    });

    test('returns string representation of Note object', () {
      final note = Note.lookup(repo: repo, annotatedOid: repo['821ed6e']);
      expect(note.toString(), contains('Note{'));
    });

    test('supports value comparison', () {
      final oid = repo.head.target;
      expect(
        Note.lookup(repo: repo, annotatedOid: oid),
        equals(Note.lookup(repo: repo, annotatedOid: oid)),
      );
    });
  });
}
