import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

void main() {
  late Repository repo;

  group('Repository.open', () {
    test('throws when repository isn\'t found at provided path', () {
      expect(
        () => Repository.open(''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    group('empty bare', () {
      setUp(() {
        repo = Repository.open('test/assets/empty_bare.git');
      });

      tearDown(() {
        repo.free();
      });

      test('opens successfully', () {
        expect(repo, isA<Repository>());
      });

      test('checks if it is bare', () {
        expect(repo.isBare, true);
      });

      test('returns path to the repository', () {
        expect(
          repo.path,
          '${Directory.current.path}/test/assets/empty_bare.git/',
        );
      });

      test('returns path to root directory for the repository', () {
        expect(
          repo.commonDir,
          '${Directory.current.path}/test/assets/empty_bare.git/',
        );
      });

      test('returns empty string as path of the working directory', () {
        expect(repo.workdir, '');
      });
    });

    group('empty standard', () {
      setUp(() {
        repo = Repository.open('test/assets/empty_standard/.gitdir/');
      });

      tearDown(() {
        repo.free();
      });

      test('opens standart repository from working directory successfully', () {
        expect(repo, isA<Repository>());
      });

      test('returns path to the repository', () {
        expect(
          repo.path,
          '${Directory.current.path}/test/assets/empty_standard/.gitdir/',
        );
      });

      test('returns path to parent repo\'s .git folder for the repository', () {
        expect(
          repo.commonDir,
          '${Directory.current.path}/test/assets/empty_standard/.gitdir/',
        );
      });

      test('checks if it is empty', () {
        expect(repo.isEmpty, true);
      });

      test('checks if head is detached', () {
        expect(repo.isHeadDetached, false);
      });

      test('checks if branch is unborn', () {
        expect(repo.isBranchUnborn, true);
      });

      test('successfully sets identity ', () {
        repo.setIdentity(name: 'name', email: 'email@email.com');
        expect(repo.identity, {'name': 'email@email.com'});
      });

      test('successfully unsets identity', () {
        repo.setIdentity(name: null, email: null);
        expect(repo.identity, isEmpty);
      });

      test('checks if shallow clone', () {
        expect(repo.isShallow, false);
      });

      test('checks if linked work tree', () {
        expect(repo.isWorktree, false);
      });

      test('returns path to working directory', () {
        expect(
          repo.workdir,
          '${Directory.current.path}/test/assets/empty_standard/',
        );
      });
    });
  });
}
