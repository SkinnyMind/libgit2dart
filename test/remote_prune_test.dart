import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository originRepo;
  late Repository clonedRepo;
  late Directory tmpDir;
  late Remote remote;
  final cloneDir = Directory('${Directory.systemTemp.path}/cloned');

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
    originRepo = Repository.open(tmpDir.path);
    clonedRepo = Repository.clone(
      url: tmpDir.path,
      localPath: cloneDir.path,
    );
    originRepo.deleteBranch('feature');
    remote = clonedRepo.lookupRemote('origin');
  });

  tearDown(() {
    remote.free();
    originRepo.free();
    clonedRepo.free();
    tmpDir.deleteSync(recursive: true);
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
  });
  group('Remote', () {
    test('fetch() does not prune branch by default', () {
      remote.fetch();

      final branches = clonedRepo.branches;
      expect(branches.any((branch) => branch.name == 'origin/feature'), true);

      for (final branch in branches) {
        branch.free();
      }
    });

    test('fetch() successfully prunes branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.prune);

      final branches = clonedRepo.branches;
      expect(branches.any((branch) => branch.name == 'origin/feature'), false);

      for (final branch in branches) {
        branch.free();
      }
    });

    test('fetch() does not prune branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.noPrune);

      final branches = clonedRepo.branches;
      expect(branches.any((branch) => branch.name == 'origin/feature'), true);

      for (final branch in branches) {
        branch.free();
      }
    });

    test('prune() successfully prunes branches', () {
      final pruned = <String>[];
      void updateTips(String refname, Oid oldOid, Oid newOid) {
        pruned.add(refname);
      }

      final callbacks = Callbacks(updateTips: updateTips);

      remote.fetch(prune: GitFetchPrune.noPrune);
      var branches = clonedRepo.branches;
      expect(branches.any((branch) => branch.name == 'origin/feature'), true);

      for (final branch in branches) {
        branch.free();
      }

      remote.prune(callbacks);

      branches = clonedRepo.branches;
      expect(pruned, contains('refs/remotes/origin/feature'));
      expect(branches.any((branch) => branch.name == 'origin/feature'), false);

      for (final branch in branches) {
        branch.free();
      }
    });

    test(
        'throws when trying to prune remote refs and remote has never '
        'connected', () {
      expect(() => remote.prune(), throwsA(isA<LibGit2Error>()));
    });
  });
}
