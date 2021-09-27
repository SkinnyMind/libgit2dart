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
    if (await cloneDir.exists()) {
      cloneDir.delete(recursive: true);
    }
  });

  group('Repository.clone', () {
    test('successfully clones repository', () {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);

      clonedRepo.free();
    });

    test('successfully clones repository as bare', () {
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
        () {
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

    test('successfully clones repository with provided remote callback', () {
      Remote remote(Repository repo, String name, String url) =>
          repo.remotes.create(name: 'test', url: tmpDir.path);

      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        remote: remote,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.remotes.list, ['test']);
      expect(clonedRepo.references.list, contains('refs/remotes/test/master'));

      clonedRepo.free();
    });

    test('throws when cloning repository with invalid remote callback', () {
      Remote remote(Repository repo, String name, String url) =>
          repo.remotes.create(name: '', url: '');

      expect(
        () => Repository.clone(
          url: tmpDir.path,
          localPath: cloneDir.path,
          remote: remote,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully clones repository with provided repository callback',
        () async {
      final callbackPath =
          Directory('${Directory.systemTemp.path}/callbackRepo');
      if (await callbackPath.exists()) {
        callbackPath.delete(recursive: true);
      }
      callbackPath.create();

      Repository repository(String path, bool bare) =>
          Repository.init(path: callbackPath.path);

      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        repository: repository,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.path, '${callbackPath.path}/.git/');

      clonedRepo.free();
      callbackPath.delete(recursive: true);
    });

    test('throws when cloning repository with invalid repository callback', () {
      Repository repository(String path, bool bare) =>
          Repository.init(path: '');

      expect(
        () => Repository.clone(
          url: tmpDir.path,
          localPath: cloneDir.path,
          repository: repository,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
