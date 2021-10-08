import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository originRepo;
  late Repository clonedRepo;
  late Directory tmpDir;
  late Remote remote;
  final cloneDir = Directory('${Directory.systemTemp.path}/cloned');

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    if (await cloneDir.exists()) {
      cloneDir.delete(recursive: true);
    }
    originRepo = Repository.open(tmpDir.path);
    clonedRepo = Repository.clone(
      url: tmpDir.path,
      localPath: cloneDir.path,
    );
    originRepo.branches['feature'].delete();
    remote = clonedRepo.remotes['origin'];
  });

  tearDown(() async {
    remote.free();
    originRepo.free();
    clonedRepo.free();
    await tmpDir.delete(recursive: true);
    if (await cloneDir.exists()) {
      cloneDir.delete(recursive: true);
    }
  });
  group('Remote', () {
    test('fetch() does not prune branch by default', () {
      remote.fetch();
      expect(clonedRepo.branches.list(), contains('origin/feature'));
    });

    test('fetch() successfully prunes branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.prune);
      expect(clonedRepo.branches.list(), isNot(contains('origin/feature')));
    });

    test('fetch() does not prune branch with provided flag', () {
      remote.fetch(prune: GitFetchPrune.noPrune);
      expect(clonedRepo.branches.list(), contains('origin/feature'));
    });

    test('prune() successfully prunes branches', () {
      var pruned = <String>[];
      void updateTips(String refname, Oid oldOid, Oid newOid) {
        pruned.add(refname);
      }

      final callbacks = Callbacks(updateTips: updateTips);

      remote.fetch(prune: GitFetchPrune.noPrune);
      expect(clonedRepo.branches.list(), contains('origin/feature'));

      remote.prune(callbacks);
      expect(pruned, contains('refs/remotes/origin/feature'));
      expect(clonedRepo.branches.list(), isNot(contains('origin/feature')));
    });
  });
}
