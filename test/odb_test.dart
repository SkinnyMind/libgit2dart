import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const lastCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Odb', () {
    test('successfully initializes', () {
      final odb = repo.odb;
      expect(odb, isA<Odb>());
      odb.free();
    });

    test('finds object by short oid', () {
      final oid = Oid.fromSHA(
        repo: repo,
        sha: lastCommit.substring(0, 5),
      );
      expect(oid.sha, lastCommit);
    });
  });
}
