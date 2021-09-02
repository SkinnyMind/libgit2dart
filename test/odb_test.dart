import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  const lastCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/odb_testrepo/';

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
  group('Odb', () {
    test('successfully initializes', () {
      expect(repo.odb, isA<Odb>());
      repo.odb.free();
    });

    test('finds object by short oid', () {
      final oid = Oid.fromSHA(repo, lastCommit.substring(0, 5));
      expect(oid.sha, lastCommit);
    });
  });
}
