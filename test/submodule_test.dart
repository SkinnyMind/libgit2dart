@Retry(10)

import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const testSubmodule = 'TestGitRepository';
  const submoduleUrl = 'https://github.com/libgit2/TestGitRepository';
  const submoduleHeadSha = '49322bb17d3acc9146f98c97d078513228bbf3c0';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/submodulerepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    try {
      tmpDir.deleteSync(recursive: true);
    } catch (e) {
      return;
    }
  });

  group('Submodule', () {
    test('returns list of all submodules paths', () {
      expect(repo.submodules.length, 1);
      expect(repo.submodules.first, testSubmodule);
    });

    test('successfully finds submodule with provided name/path', () {
      final submodule = repo.lookupSubmodule(testSubmodule);

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

      submodule.free();
    });

    test('throws when trying to lookup and submodule not found', () {
      expect(
        () => repo.lookupSubmodule('not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully inits and updates', () {
      final submoduleFilePath = '${repo.workdir}$testSubmodule/master.txt';
      expect(File(submoduleFilePath).existsSync(), false);

      repo.initSubmodule(submodule: testSubmodule);
      repo.updateSubmodule(submodule: testSubmodule);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('successfully updates with provided init flag', () {
      final submoduleFilePath = '${repo.workdir}$testSubmodule/master.txt';
      expect(File(submoduleFilePath).existsSync(), false);

      repo.updateSubmodule(submodule: testSubmodule, init: true);

      expect(File(submoduleFilePath).existsSync(), true);
    });

    test('throws when trying to update not initialized submodule', () {
      expect(
        () => repo.updateSubmodule(submodule: testSubmodule),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully opens repository for a submodule', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      repo.initSubmodule(submodule: testSubmodule);
      repo.updateSubmodule(submodule: testSubmodule);

      final submoduleRepo = submodule.open();
      final subHead = submoduleRepo.head;
      expect(submoduleRepo, isA<Repository>());
      expect(subHead.target.sha, submoduleHeadSha);
      expect(
        submodule.workdirOid?.sha,
        '49322bb17d3acc9146f98c97d078513228bbf3c0',
      );

      subHead.free();
      submoduleRepo.free();
      submodule.free();
    });

    test('throws when trying to open repository for not initialized submodule',
        () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(() => submodule.open(), throwsA(isA<LibGit2Error>()));
      submodule.free();
    });

    test('successfully adds submodule', () {
      final submodule = repo.addSubmodule(
        url: submoduleUrl,
        path: 'test',
      );
      final submoduleRepo = submodule.open();

      expect(submodule.path, 'test');
      expect(submodule.url, submoduleUrl);
      expect(submoduleRepo.isEmpty, false);

      submoduleRepo.free();
      submodule.free();
    });

    test('throws when trying to add submodule with wrong url', () {
      expect(
        () => repo.addSubmodule(
          url: 'https://wrong.url/',
          path: 'test',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to add submodule and error occurs', () {
      expect(
        () => Repository(nullptr).addSubmodule(
          url: 'https://wrong.url/',
          path: 'test',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully sets configuration values', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(submodule.url, submoduleUrl);
      expect(submodule.branch, '');
      expect(submodule.ignore, GitSubmoduleIgnore.none);
      expect(submodule.updateRule, GitSubmoduleUpdate.checkout);

      submodule.url = 'updated';
      submodule.branch = 'updated';
      submodule.ignore = GitSubmoduleIgnore.all;
      submodule.updateRule = GitSubmoduleUpdate.rebase;

      final updatedSubmodule = repo.lookupSubmodule(testSubmodule);
      expect(updatedSubmodule.url, 'updated');
      expect(updatedSubmodule.branch, 'updated');
      expect(updatedSubmodule.ignore, GitSubmoduleIgnore.all);
      expect(updatedSubmodule.updateRule, GitSubmoduleUpdate.rebase);

      updatedSubmodule.free();
      submodule.free();
    });

    test('successfully syncs', () {
      repo.updateSubmodule(submodule: testSubmodule, init: true);
      final submodule = repo.lookupSubmodule(testSubmodule);
      final submRepo = submodule.open();
      final repoConfig = repo.config;
      final submRepoConfig = submRepo.config;

      expect(repoConfig['submodule.$testSubmodule.url'].value, submoduleUrl);
      expect(submRepoConfig['remote.origin.url'].value, submoduleUrl);

      submodule.url = 'https://updated.com/';
      submodule.branch = 'updated';

      final updatedSubmodule = repo.lookupSubmodule(testSubmodule);
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

      updatedSubmRepoConfig.free();
      submRepo.free();
      updatedSubmRepo.free();
      updatedSubmodule.free();
      submRepoConfig.free();
      repoConfig.free();
      submodule.free();
    });

    test('successfully reloads info', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(submodule.url, submoduleUrl);

      submodule.url = 'updated';
      submodule.reload();

      expect(submodule.url, 'updated');

      submodule.free();
    });

    test('returns status for a submodule', () {
      final submodule = repo.lookupSubmodule(testSubmodule);
      expect(
        submodule.status(),
        {
          GitSubmoduleStatus.inHead,
          GitSubmoduleStatus.inIndex,
          GitSubmoduleStatus.inConfig,
          GitSubmoduleStatus.workdirUninitialized,
        },
      );

      repo.updateSubmodule(submodule: testSubmodule, init: true);
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

      submodule.free();
    });
  });
}
