import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  final worktreeDir = Directory(p.join(Directory.systemTemp.path, 'worktree'));
  const worktreeName = 'worktree';

  setUp(() {
    if (worktreeDir.existsSync()) {
      worktreeDir.deleteSync(recursive: true);
    }
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
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
    test('creates worktree at provided path', () {
      expect(Worktree.list(repo), <String>[]);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
      );
      final branches = repo.branches;

      expect(repo.worktrees, [worktreeName]);
      expect(branches.any((branch) => branch.name == worktreeName), true);
      expect(worktree.name, worktreeName);
      expect(worktree.path, contains('worktree'));
      expect(worktree.isLocked, false);
      expect(worktree.toString(), contains('Worktree{'));
      expect(File(p.join(worktreeDir.path, '.git')).existsSync(), true);

      for (final branch in branches) {
        branch.free();
      }
      worktree.free();
    });

    test('creates worktree at provided path from provided reference', () {
      final head = RevParse.single(repo: repo, spec: 'HEAD');
      final worktreeBranch = Branch.create(
        repo: repo,
        name: 'v1',
        target: head,
      );
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/v1');
      expect(repo.worktrees, <String>[]);

      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
        ref: ref,
      );
      final branches = Branch.list(repo: repo);

      expect(repo.worktrees, [worktreeName]);
      expect(branches.any((branch) => branch.name == 'v1'), true);
      expect(branches.any((branch) => branch.name == worktreeName), false);
      expect(worktreeBranch.isCheckedOut, true);

      worktreeDir.deleteSync(recursive: true);
      worktree.prune();

      expect(repo.worktrees, <String>[]);
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

    test('throws when trying to create worktree with invalid name or path', () {
      expect(
        () => Worktree.create(
          repo: repo,
          name: '',
          path: worktreeDir.path,
        ),
        throwsA(isA<LibGit2Error>()),
      );
      expect(
        () => Worktree.create(
          repo: repo,
          name: 'name',
          path: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('lookups worktree', () {
      final worktree = Worktree.create(
        repo: repo,
        name: worktreeName,
        path: worktreeDir.path,
      );
      final lookedupWorktree = Worktree.lookup(repo: repo, name: worktreeName);

      expect(lookedupWorktree.name, worktreeName);
      expect(lookedupWorktree.path, contains('worktree'));
      expect(lookedupWorktree.isLocked, false);

      lookedupWorktree.free();
      worktree.free();
    });

    test('throws when trying to lookup and error occurs', () {
      expect(
        () => Worktree.lookup(repo: Repository(nullptr), name: 'name'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('locks and unlocks worktree', () {
      final worktree = Worktree.create(
        repo: repo,
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

    test('prunes worktree', () {
      expect(repo.worktrees, <String>[]);

      final worktree = Worktree.create(
        repo: repo,
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
      expect(repo.worktrees, <String>[]);

      worktree.free();
    });

    test('throws when trying get list of worktrees and error occurs', () {
      expect(
        () => Worktree.list(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
