// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final cloneDir = Directory(
    p.join(Directory.systemTemp.path, 'repository_cloned'),
  );

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
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
    test('clones repository', () {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);

      clonedRepo.free();
    });

    test('clones repository as bare', () {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        bare: true,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, true);

      clonedRepo.free();
    });

    test('clones repository with provided checkout branch name', () {
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

    test('clones repository with provided remote callback', () {
      Remote remote(Repository repo, String name, String url) =>
          Remote.create(repo: repo, name: 'test', url: tmpDir.path);

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
          Remote.create(repo: repo, name: '', url: '');

      expect(
        () => Repository.clone(
          url: tmpDir.path,
          localPath: cloneDir.path,
          remote: remote,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('clones repository with provided repository callback', () {
      final callbackPath = Directory(
        p.join(Directory.systemTemp.path, 'callbackRepo'),
      );
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
      expect(clonedRepo.path, contains('/callbackRepo/.git/'));

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
