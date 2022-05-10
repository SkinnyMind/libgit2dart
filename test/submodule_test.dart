import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const testSubmodule = 'TestGitRepository';
  const submoduleUrl = 'https://github.com/libgit2/TestGitRepository';
  const submoduleHeadSha = '49322bb17d3acc9146f98c97d078513228bbf3c0';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'submodule_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (e) {
      return;
    }
  });

  group('Submodule', () {
    test('returns list of all submodules paths', () {
      expect(Submodule.list(repo).length, 1);
      expect(repo.submodules.first, testSubmodule);
    });

    test('finds submodule with provided name/path', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);

      expect(submodule.name, testSubmodule);
      expect(submodule.path, testSubmodule);
      expect(submodule.url, submoduleUrl);
      expect(submodule.branch, '');
      expect(submodule.headOid?.sha, submoduleHeadSha);
      expect(submodule.indexOid?.sha, submoduleHeadSha);
      expect(submodule.workdirOid?.sha, null);
      expect(submodule.ignore, GitSubmoduleIgnore.none);
      expect(submodule.updateRule, GitSubmoduleUpdate.checkout);
      expect(submodule.toString(), contains('Submodule{'));
    });

    test('throws when trying to lookup and submodule not found', () {
      expect(
        () => Submodule.lookup(repo: repo, name: 'not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('inits and updates', () {
      final submoduleFilePath =
          p.join(repo.workdir, testSubmodule, 'master.txt');
      expect(File(submoduleFilePath).existsSync(), false);

      Submodule.init(repo: repo, name: testSubmodule);
      Submodule.update(repo: repo, name: testSubmodule);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('updates with provided init flag', () {
      final submoduleFilePath = p.join(
        repo.workdir,
        testSubmodule,
        'master.txt',
      );
      expect(File(submoduleFilePath).existsSync(), false);

      Submodule.update(repo: repo, name: testSubmodule, init: true);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('throws when trying to update not initialized submodule', () {
      expect(
        () => Submodule.update(repo: repo, name: testSubmodule),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('opens repository for a submodule', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      Submodule.init(repo: repo, name: testSubmodule);
      Submodule.update(repo: repo, name: testSubmodule);

      final submoduleRepo = submodule.open();
      expect(submoduleRepo, isA<Repository>());
      expect(submoduleRepo.head.target.sha, submoduleHeadSha);
      expect(
        submodule.workdirOid?.sha,
        '49322bb17d3acc9146f98c97d078513228bbf3c0',
      );
    });

    test('throws when trying to open repository for not initialized submodule',
        () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      expect(() => submodule.open(), throwsA(isA<LibGit2Error>()));
    });

    test('adds submodule', () {
      final submodule = Submodule.add(
        repo: repo,
        url: submoduleUrl,
        path: 'test',
      );
      final submoduleRepo = submodule.open();

      expect(submodule.path, 'test');
      expect(submodule.url, submoduleUrl);
      expect(submoduleRepo.isEmpty, false);
    });

    test('throws when trying to add submodule with wrong url', () {
      expect(
        () => Submodule.add(
          repo: repo,
          url: 'https://wrong.url/',
          path: 'test',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to add submodule and error occurs', () {
      expect(
        () => Submodule.add(
          repo: Repository(nullptr),
          url: 'https://wrong.url/',
          path: 'test',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('sets configuration values', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      expect(submodule.url, submoduleUrl);
      expect(submodule.branch, '');
      expect(submodule.ignore, GitSubmoduleIgnore.none);
      expect(submodule.updateRule, GitSubmoduleUpdate.checkout);

      submodule.url = 'updated';
      submodule.branch = 'updated';
      submodule.ignore = GitSubmoduleIgnore.all;
      submodule.updateRule = GitSubmoduleUpdate.rebase;

      final updatedSubmodule = Submodule.lookup(
        repo: repo,
        name: testSubmodule,
      );
      expect(updatedSubmodule.url, 'updated');
      expect(updatedSubmodule.branch, 'updated');
      expect(updatedSubmodule.ignore, GitSubmoduleIgnore.all);
      expect(updatedSubmodule.updateRule, GitSubmoduleUpdate.rebase);
    });

    test('syncs', () {
      Submodule.update(repo: repo, name: testSubmodule, init: true);
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      final submRepo = submodule.open();
      final repoConfig = repo.config;
      final submRepoConfig = submRepo.config;

      expect(repoConfig['submodule.$testSubmodule.url'].value, submoduleUrl);
      expect(submRepoConfig['remote.origin.url'].value, submoduleUrl);

      submodule.url = 'https://updated.com/';
      submodule.branch = 'updated';

      final updatedSubmodule = Submodule.lookup(
        repo: repo,
        name: testSubmodule,
      );
      updatedSubmodule.sync();
      final updatedSubmRepo = updatedSubmodule.open();
      final updatedSubmRepoConfig = updatedSubmRepo.config;

      expect(
        repoConfig['submodule.$testSubmodule.url'].value,
        'https://updated.com/',
      );
      expect(
        updatedSubmRepoConfig['remote.origin.url'].value,
        'https://updated.com/',
      );
    });

    test('reloads info', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      expect(submodule.url, submoduleUrl);

      submodule.url = 'updated';
      submodule.reload();

      expect(submodule.url, 'updated');
    });

    test('returns status for a submodule', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      expect(
        submodule.status(),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.workdirUninitialized,
        },
      );

      Submodule.update(repo: repo, name: testSubmodule, init: true);
      expect(
        submodule.status(),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.inWorkdir,
          GitSubmoduleStatus.workdirUntracked,
        },
      );

      expect(
        submodule.status(ignore: GitSubmoduleIgnore.all),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.inWorkdir,
        },
      );
    });

    test('manually releases allocated memory', () {
      final submodule = Submodule.lookup(repo: repo, name: testSubmodule);
      expect(() => submodule.free(), returnsNormally);
    });

    test('supports value comparison', () {
      expect(
        Submodule.lookup(repo: repo, name: testSubmodule),
        equals(Submodule.lookup(repo: repo, name: testSubmodule)),
      );
    });
  });
}
