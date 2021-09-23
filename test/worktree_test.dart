import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final worktreeDir = Directory('${Directory.systemTemp.path}/worktree');

  setUp(() async {
    if (await worktreeDir.exists()) {
      await worktreeDir.delete(recursive: true);
    }
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
    if (await worktreeDir.exists()) {
      await worktreeDir.delete(recursive: true);
    }
  });

  group('Worktree', () {
    test('successfully creates worktree at provided path', () {
      const worktreeName = 'worktree';
      expect(Worktree.list(repo), []);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
      );

      expect(Worktree.list(repo), [worktreeName]);
      expect(repo.branches.list(), contains(worktreeName));
      expect(worktree.name, worktreeName);
      expect(worktree.path, worktreeDir.path);
      expect(File('${worktreeDir.path}/.git').existsSync(), true);

      worktree.free();
    });

    test(
        'successfully creates worktree at provided path from provided reference',
        () {
      const worktreeName = 'worktree';
      final head = repo.revParseSingle('HEAD');
      final worktreeRef = repo.branches.create(name: 'v1', target: head);
      final worktreeBranch = repo.branches['v1'];
      expect(Worktree.list(repo), []);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
        ref: worktreeRef,
      );

      expect(Worktree.list(repo), [worktreeName]);
      expect(repo.branches.list(), contains('v1'));
      expect(repo.branches.list(), isNot(contains(worktreeName)));
      expect(worktreeBranch.isCheckedOut, true);

      worktreeDir.deleteSync(recursive: true);
      worktree.prune();

      expect(Worktree.list(repo), []);
      expect(worktreeBranch.isCheckedOut, false);
      expect(repo.branches.list(), contains('v1'));

      worktreeBranch.free();
      worktreeRef.free();
      head.free();
      worktree.free();
    });

    test('successfully prunes worktree', () {
      const worktreeName = 'worktree';
      expect(Worktree.list(repo), []);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
      );
      expect(Worktree.list(repo), [worktreeName]);

      worktreeDir.deleteSync(recursive: true);
      worktree.prune();
      expect(Worktree.list(repo), []);

      worktree.free();
    });
  });
}
