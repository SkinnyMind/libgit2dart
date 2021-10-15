import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final worktreeDir = Directory('${Directory.systemTemp.path}/worktree');
  const worktreeName = 'worktree';

  setUp(() {
    if (worktreeDir.existsSync()) {
      worktreeDir.deleteSync(recursive: true);
    }
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
    if (worktreeDir.existsSync()) {
      worktreeDir.deleteSync(recursive: true);
    }
  });

  group('Worktree', () {
    test('successfully creates worktree at provided path', () {
      expect(repo.worktrees, []);

      final worktree = repo.createWorktree(
        name: worktreeName,
        path: worktreeDir.path,
      );
      final branches = repo.branches;

      expect(repo.worktrees, [worktreeName]);
      expect(branches.any((branch) => branch.name == worktreeName), true);
      expect(worktree.name, worktreeName);
      expect(worktree.path, worktreeDir.path);
      expect(worktree.isLocked, false);
      expect(worktree.toString(), contains('Worktree{'));
      expect(File('${worktreeDir.path}/.git').existsSync(), true);

      for (final branch in branches) {
        branch.free();
      }
      worktree.free();
    });

    test(
        'successfully creates worktree at provided path from provided reference',
        () {
      final head = repo.revParseSingle('HEAD');
      final worktreeBranch = repo.createBranch(name: 'v1', target: head);
      final ref = repo.lookupReference('refs/heads/v1');
      expect(repo.worktrees, []);

      final worktree = repo.createWorktree(
        name: worktreeName,
        path: worktreeDir.path,
        ref: ref,
      );
      final branches = repo.branches;

      expect(repo.worktrees, [worktreeName]);
      expect(branches.any((branch) => branch.name == 'v1'), true);
      expect(branches.any((branch) => branch.name == worktreeName), false);
      expect(worktreeBranch.isCheckedOut, true);

      worktreeDir.deleteSync(recursive: true);
      worktree.prune();

      expect(repo.worktrees, []);
      expect(worktreeBranch.isCheckedOut, false);
      expect(branches.any((branch) => branch.name == 'v1'), true);

      for (final branch in branches) {
        branch.free();
      }
      worktreeBranch.free();
      ref.free();
      head.free();
      worktree.free();
    });

    test('successfully lookups worktree', () {
      final worktree = repo.createWorktree(
        name: worktreeName,
        path: worktreeDir.path,
      );
      final lookedupWorktree = repo.lookupWorktree(worktreeName);

      expect(lookedupWorktree.name, worktreeName);
      expect(lookedupWorktree.path, worktreeDir.path);
      expect(lookedupWorktree.isLocked, false);

      lookedupWorktree.free();
      worktree.free();
    });

    test('successfully locks and unlocks worktree', () {
      final worktree = repo.createWorktree(
        name: worktreeName,
        path: worktreeDir.path,
      );
      expect(worktree.isLocked, false);

      worktree.lock();
      expect(worktree.isLocked, true);

      worktree.unlock();
      expect(worktree.isLocked, false);

      worktree.free();
    });

    test('successfully prunes worktree', () {
      expect(repo.worktrees, []);

      final worktree = repo.createWorktree(
        name: worktreeName,
        path: worktreeDir.path,
      );
      expect(repo.worktrees, [worktreeName]);
      expect(worktree.isPrunable, false);
      expect(worktree.isValid, true);

      worktreeDir.deleteSync(recursive: true);
      expect(worktree.isPrunable, true);
      expect(worktree.isValid, false);

      worktree.prune();
      expect(repo.worktrees, []);

      worktree.free();
    });
  });
}
