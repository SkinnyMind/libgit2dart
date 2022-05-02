import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository originRepo;
  late Repository clonedRepo;
  late Directory tmpDir;
  late Remote remote;
  final cloneDir = Directory(
    p.join(Directory.systemTemp.path, 'remote_prune_cloned'),
  );

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
    originRepo = Repository.open(tmpDir.path);
    clonedRepo = Repository.clone(
      url: tmpDir.path,
      localPath: cloneDir.path,
    );
    Branch.delete(repo: originRepo, name: 'feature');
    remote = Remote.lookup(repo: clonedRepo, name: 'origin');
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
    if (cloneDir.existsSync()) {
      cloneDir.deleteSync(recursive: true);
    }
  });
  group('Remote', () {
    test('fetch() does not prune branch by default', () {
      remote.fetch();
      expect(
        clonedRepo.branches.any((branch) => branch.name == 'origin/feature'),
        true,
      );
    });

    test('fetch() prunes branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.prune);
      expect(
        clonedRepo.branches.any((branch) => branch.name == 'origin/feature'),
        false,
      );
    });

    test('fetch() does not prune branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.noPrune);
      expect(
        clonedRepo.branches.any((branch) => branch.name == 'origin/feature'),
        true,
      );
    });

    test('prune() prunes branches', () {
      final pruned = <String>[];
      void updateTips(String refname, Oid oldOid, Oid newOid) {
        pruned.add(refname);
      }

      final callbacks = Callbacks(updateTips: updateTips);

      remote.fetch(prune: GitFetchPrune.noPrune);
      expect(
        clonedRepo.branches.any((branch) => branch.name == 'origin/feature'),
        true,
      );

      remote.prune(callbacks);

      expect(pruned, contains('refs/remotes/origin/feature'));
      expect(
        clonedRepo.branches.any((branch) => branch.name == 'origin/feature'),
        false,
      );
    });

    test(
        'throws when trying to prune remote refs and remote has never '
        'connected', () {
      expect(() => remote.prune(), throwsA(isA<LibGit2Error>()));
    });
  });
}
