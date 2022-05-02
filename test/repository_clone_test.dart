// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Directory tmpDir;
  final cloneDir = Directory(
    p.join(Directory.systemTemp.path, 'repository_cloned'),
  );

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    if (cloneDir.existsSync()) {
      cloneDir.delete(recursive: true);
    }
  });

  tearDown(() {
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
    });

    test('clones repository as bare', () {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        bare: true,
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, true);
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
    });

    test(
        'clones repository with provided remote callback having default fetch '
        'refspec value', () {
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        remoteCallback: RemoteCallback(name: 'test', url: tmpDir.path),
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.remotes, ['test']);
      expect(clonedRepo.references, contains('refs/remotes/test/master'));
    });

    test('clones repository with provided remote callback ', () {
      const fetchRefspec = '+refs/heads/*:refs/remotes/spec/*';
      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        remoteCallback: RemoteCallback(
          name: 'test',
          url: tmpDir.path,
          fetch: fetchRefspec,
        ),
      );

      final remote = Remote.lookup(repo: clonedRepo, name: 'test');

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, false);
      expect(clonedRepo.remotes, ['test']);
      expect(clonedRepo.references, contains('refs/remotes/spec/master'));
      expect(remote.fetchRefspecs, [fetchRefspec]);
    });

    test('throws when cloning repository with invalid remote callback', () {
      expect(
        () => Repository.clone(
          url: tmpDir.path,
          localPath: cloneDir.path,
          remoteCallback: const RemoteCallback(name: '', url: ''),
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

      final clonedRepo = Repository.clone(
        url: tmpDir.path,
        localPath: cloneDir.path,
        repositoryCallback: RepositoryCallback(
          path: callbackPath.path,
          bare: true,
        ),
      );

      expect(clonedRepo.isEmpty, false);
      expect(clonedRepo.isBare, true);
      expect(clonedRepo.path, contains('/callbackRepo/'));

      callbackPath.deleteSync(recursive: true);
    });

    test('throws when cloning repository with invalid repository callback', () {
      expect(
        () => Repository.clone(
          url: tmpDir.path,
          localPath: cloneDir.path,
          repositoryCallback: const RepositoryCallback(path: ''),
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });

  group('RepositoryCallback', () {
    test('initializes and returns values', () {
      const repositoryCallback = RepositoryCallback(
        path: 'some/path',
        bare: true,
        flags: {GitRepositoryInit.noReinit},
        mode: 1,
        workdirPath: 'some/path',
        description: 'description',
        templatePath: 'some/path',
        initialHead: 'feature',
        originUrl: 'some.url',
      );

      expect(repositoryCallback, isA<RepositoryCallback>());
      expect(repositoryCallback.path, 'some/path');
      expect(repositoryCallback.bare, true);
      expect(repositoryCallback.flags, {GitRepositoryInit.noReinit});
      expect(repositoryCallback.mode, 1);
      expect(repositoryCallback.workdirPath, 'some/path');
      expect(repositoryCallback.description, 'description');
      expect(repositoryCallback.templatePath, 'some/path');
      expect(repositoryCallback.initialHead, 'feature');
      expect(repositoryCallback.originUrl, 'some.url');
    });
  });
}
