import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/worktree_testrepo/';
  final worktreeDir = '${Directory.systemTemp.path}/worktree';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }

    if (await Directory(worktreeDir).exists()) {
      await Directory(worktreeDir).delete(recursive: true);
    }

    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
  });

  tearDown(() async {
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
    if (await Directory(worktreeDir).exists()) {
      await Directory(worktreeDir).delete(recursive: true);
    }
  });

  group('Worktree', () {
    test('successfully creates worktree at provided path', () {
      const worktreeName = 'worktree';
      expect(Worktree.list(repo), []);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir,
      );

      expect(Worktree.list(repo), [worktreeName]);
      expect(repo.branches.list(), contains(worktreeName));
      expect(worktree.name, worktreeName);
      expect(worktree.path, worktreeDir);
      expect(File('$worktreeDir/.git').existsSync(), true);

      worktree.free();
    });

    test('successfully prunes worktree', () {
      const worktreeName = 'worktree';
      expect(Worktree.list(repo), []);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir,
      );
      expect(Worktree.list(repo), [worktreeName]);

      Directory(worktreeDir).deleteSync(recursive: true);
      worktree.prune();
      expect(Worktree.list(repo), []);

      worktree.free();
    });
  });
}
