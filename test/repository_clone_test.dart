import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final cloneDir = Directory('${Directory.systemTemp.path}/cloned');

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);

    if (await cloneDir.exists()) {
      cloneDir.delete(recursive: true);
    }
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
    cloneDir.delete(recursive: true);
  });

  group('Repository.clone', () {
    test('successfully clones repository', () async {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);

      clonedRepo.free();
    });

    test('successfully clones repository as bare', () async {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        bare: true,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, true);

      clonedRepo.free();
    });

    test('successfully clones repository with provided checkout branch name',
        () async {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        bare: true,
        checkoutBranch: 'feature',
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, true);
      expect(clonedRepo.head.name, 'refs/heads/feature');

      clonedRepo.free();
    });
  });
}
