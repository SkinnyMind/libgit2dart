import 'dart:io';
import 'dart:ffi';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const sha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const biggerSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e9';
  const lesserSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e7';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Oid', () {
    group('fromSHA()', () {
      test('initializes successfully', () {
        final oid = Oid.fromSHA(repo: repo, sha: sha);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });

      test('initializes successfully from short hex string', () {
        final oid = Oid.fromSHA(repo: repo, sha: sha.substring(0, 5));

        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });

      test('throws when sha hex string is too short', () {
        expect(
          () => Oid.fromSHA(repo: repo, sha: 'sha'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.invalidValue,
              'value',
              'sha is not a valid sha hex string',
            ),
          ),
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
