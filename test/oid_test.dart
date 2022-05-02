import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const sha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const biggerSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e9';
  const lesserSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e7';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Oid', () {
    group('fromSHA()', () {
      test('initializes from 40-char hex string', () {
        final oid = Oid.fromSHA(repo: repo, sha: sha);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });

      test('initializes from short hex string', () {
        final oid = Oid.fromSHA(repo: repo, sha: sha.substring(0, 5));

        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });

      test('throws when sha hex string is too short', () {
        expect(
          () => Oid.fromSHA(repo: repo, sha: 'sha'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when sha hex string is invalid', () {
        expect(
          () => Oid.fromSHA(repo: repo, sha: '0000000'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('fromRaw()', () {
      test('initializes successfully', () {
        final sourceOid = Oid.fromSHA(repo: repo, sha: sha);
        final oid = Oid.fromRaw(sourceOid.pointer.ref);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });
    });

    test('returns sha hex string', () {
      final oid = Oid.fromSHA(repo: repo, sha: sha);
      expect(oid.sha, equals(sha));
    });

    group('compare', () {
      test('< and <=', () {
        final oid1 = Oid.fromSHA(repo: repo, sha: sha);
        final oid2 = Oid.fromSHA(repo: repo, sha: biggerSha);
        expect(oid1 < oid2, true);
        expect(oid1 <= oid2, true);
      });

      test('==', () {
        final oid1 = Oid.fromSHA(repo: repo, sha: sha);
        final oid2 = Oid.fromSHA(repo: repo, sha: sha);
        expect(oid1 == oid2, true);
      });

      test('> and >=', () {
        final oid1 = Oid.fromSHA(repo: repo, sha: sha);
        final oid2 = Oid.fromSHA(repo: repo, sha: lesserSha);
        expect(oid1 > oid2, true);
        expect(oid1 >= oid2, true);
      });
    });

    test('returns string representation of Oid object', () {
      expect(repo[sha].toString(), contains('Oid{'));
    });
  });
}
