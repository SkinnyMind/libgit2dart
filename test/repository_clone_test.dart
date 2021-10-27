// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final cloneDir = Directory('${Directory.systemTemp.path}/cloned');

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    if (cloneDir.existsSync()) {
      cloneDir.delete(recursive: true);
    }
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
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
          repo.createRemote(name: 'test', url: tmpDir.path);

      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        remote: remote,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.remotes, ['test']);
      expect(clonedRepo.references, contains('refs/remotes/test/master'));

      clonedRepo.free();
    });

    test('throws when cloning repository with invalid remote callback', () {
      Remote remote(Repository repo, String name, String url) =>
          repo.createRemote(name: '', url: '');

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
        () {
      final callbackPath =
          Directory('${Directory.systemTemp.path}/callbackRepo');
      if (callbackPath.existsSync()) {
        callbackPath.deleteSync(recursive: true);
      }
      callbackPath.createSync();

      Repository repository(String path, bool bare) =>
          Repository.init(path: callbackPath.path);

      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        repository: repository,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.path, contains('${callbackPath.path}/.git/'));

      clonedRepo.free();
      callbackPath.deleteSync(recursive: true);
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
