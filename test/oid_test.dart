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

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Oid', () {
    group('fromSHA()', () {
      test('initializes successfully', () {
        final oid = Oid.fromSHA(repo, sha);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });

      test('initializes successfully from short hex string', () {
        final oid = Oid.fromSHA(repo, sha.substring(0, 5));

        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });
    });

    group('fromRaw()', () {
      test('initializes successfully', () {
        final sourceOid = Oid.fromSHA(repo, sha);
        final oid = Oid.fromRaw(sourceOid.pointer.ref);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });
    });

    test('returns sha hex string', () {
      final oid = Oid.fromSHA(repo, sha);
      expect(oid.sha, equals(sha));
    });

    group('compare', () {
      test('< and <=', () {
        final oid1 = Oid.fromSHA(repo, sha);
        final oid2 = Oid.fromSHA(repo, biggerSha);
        expect(oid1 < oid2, true);
        expect(oid1 <= oid2, true);
      });

      test('==', () {
        final oid1 = Oid.fromSHA(repo, sha);
        final oid2 = Oid.fromSHA(repo, sha);
        expect(oid1 == oid2, true);
      });

      test('> and >=', () {
        final oid1 = Oid.fromSHA(repo, sha);
        final oid2 = Oid.fromSHA(repo, lesserSha);
        expect(oid1 > oid2, true);
        expect(oid1 >= oid2, true);
      });
    });
  });
}
