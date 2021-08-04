import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/reference.dart';
import 'package:libgit2dart/src/error.dart';

import 'helpers/util.dart';

void main() {
  const lastCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  group('Reference', () {
    late Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/testrepo/';

    setUpAll(() async {
      if (await Directory(tmpDir).exists()) {
        await Directory(tmpDir).delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/testrepo/'),
        to: await Directory(tmpDir).create(),
      );
      repo = Repository.open(tmpDir);
    });

    tearDownAll(() async {
      repo.close();
      await Directory(tmpDir).delete(recursive: true);
    });

    test('returns correct type of reference', () {
      expect(repo.head.type, ReferenceType.direct);
      repo.head.free();

      final ref = Reference.lookup(repo, 'HEAD');
      expect(ref.type, ReferenceType.symbolic);
      ref.free();
    });

    test('returns SHA hex of direct reference', () {
      expect(repo.head.target, lastCommit);
      repo.head.free();
    });

    test('returns SHA hex of symbolic reference', () {
      final ref = Reference.lookup(repo, 'HEAD');
      expect(ref.target, lastCommit);
      ref.free();
    });

    test('returns the full name of a reference', () {
      expect(repo.head.name, 'refs/heads/master');
      repo.head.free();
    });

    test('returns a map with all the references of repository', () {
      expect(
        repo.references,
        {
          'refs/heads/feature': '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4',
          'refs/heads/master': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
          'refs/tags/v0.1': '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
        },
      );
    });

    test('checks if reflog exists for the reference', () {
      expect(Reference.hasLog(repo, 'refs/heads/master'), true);
      expect(Reference.hasLog(repo, 'refs/heads/not/there'), false);
    });

    test('checks if reference is a local branch', () {
      final ref = Reference.lookup(repo, 'refs/heads/feature');
      expect(ref.isBranch, true);
      ref.free();
    });

    test('checks if reference is a note', () {
      final ref = Reference.lookup(repo, 'refs/heads/master');
      expect(ref.isNote, false);
      ref.free();
    });

    test('checks if reference is a remote branch', () {
      final ref = Reference.lookup(repo, 'refs/heads/master');
      expect(ref.isRemote, false);
      ref.free();
    });

    test('checks if reference is a tag', () {
      final ref = Reference.lookup(repo, 'refs/tags/v0.1');
      expect(ref.isTag, true);
      ref.free();
    });

    group('.lookup()', () {
      test('finds a reference with provided name', () {
        final ref = Reference.lookup(repo, 'refs/heads/master');
        expect(ref.target, lastCommit);
        ref.free();
      });

      test('throws when error occured', () {
        expect(
          () => Reference.lookup(repo, 'refs/heads/not/there'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('isValidName()', () {
      test('returns true for valid names', () {
        expect(Reference.isValidName('HEAD'), true);
        expect(Reference.isValidName('refs/heads/master'), true);
        expect(Reference.isValidName('refs/heads/perfectly/valid'), true);
        expect(Reference.isValidName('refs/tags/v1'), true);
        expect(Reference.isValidName('refs/special/ref'), true);
        expect(Reference.isValidName('refs/heads/ünicöde'), true);
        expect(Reference.isValidName('refs/tags/😀'), true);
      });

      test('returns false for invalid names', () {
        expect(Reference.isValidName(''), false);
        expect(Reference.isValidName(' refs/heads/master'), false);
        expect(Reference.isValidName('refs/heads/in..valid'), false);
        expect(Reference.isValidName('refs/heads/invalid~'), false);
        expect(Reference.isValidName('refs/heads/invalid^'), false);
        expect(Reference.isValidName('refs/heads/invalid:'), false);
        expect(Reference.isValidName('refs/heads/invalid\\'), false);
        expect(Reference.isValidName('refs/heads/invalid?'), false);
        expect(Reference.isValidName('refs/heads/invalid['), false);
        expect(Reference.isValidName('refs/heads/invalid*'), false);
        expect(Reference.isValidName('refs/heads/@{no}'), false);
        expect(Reference.isValidName('refs/heads/foo//bar'), false);
      });
    });
  });
}
