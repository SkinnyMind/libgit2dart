import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  const sha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const biggerSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e9';
  const lesserSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e7';

  group('Oid', () {
    late Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/oid_testrepo/';

    setUp(() async {
      if (await Directory(tmpDir).exists()) {
        await Directory(tmpDir).delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/testrepo/'),
        to: await Directory(tmpDir).create(),
      );
      repo = Repository.open(tmpDir);
    });

    tearDown(() async {
      repo.free();
      await Directory(tmpDir).delete(recursive: true);
    });
    group('fromSHA()', () {
      test('initializes successfully', () {
        final oid = Oid.fromSHA(sha);
        expect(oid, isA<Oid>());
        expect(oid.sha, sha);
      });
    });

    group('fromShortSHA()', () {
      test('initializes successfully from short hex string', () {
        final odb = repo.odb;
        final oid = Oid.fromShortSHA(sha.substring(0, 5), odb);

        expect(oid, isA<Oid>());
        expect(oid.sha, sha);

        odb.free();
      });
    });

    test('returns sha hex string', () {
      final oid = Oid.fromSHA(sha);
      expect(oid.sha, equals(sha));
    });

    group('compare', () {
      test('< and <=', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA(biggerSha);
        expect(oid1 < oid2, true);
        expect(oid1 <= oid2, true);
      });

      test('==', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA(sha);
        expect(oid1 == oid2, true);
      });

      test('> and >=', () {
        final oid1 = Oid.fromSHA(sha);
        final oid2 = Oid.fromSHA(lesserSha);
        expect(oid1 > oid2, true);
        expect(oid1 >= oid2, true);
      });
    });
  });
}
