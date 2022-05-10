import 'dart:ffi';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Repository repo;

  group('Repository.open', () {
    test("throws when repository isn't found at provided path", () {
      expect(
        () => Repository.open('/not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    group('empty bare', () {
      setUp(() {
        repo = Repository.open(p.join('test', 'assets', 'empty_bare.git'));
      });

      test('opens successfully', () {
        expect(repo, isA<Repository>());
      });

      test('checks if it is bare', () {
        expect(repo.isBare, true);
      });

      test('returns path to the repository', () {
        expect(repo.path, contains('/test/assets/empty_bare.git/'));
      });

      test('returns path to root directory for the repository', () {
        expect(repo.commonDir, contains('/test/assets/empty_bare.git/'));
      });

      test('returns empty string as path of the working directory', () {
        expect(repo.workdir, '');
      });
    });

    group('empty standard', () {
      setUp(() {
        repo = Repository.open(
          p.join('test', 'assets', 'empty_standard', '.gitdir'),
        );
      });

      test('opens standart repository from working directory successfully', () {
        expect(repo, isA<Repository>());
      });

      test('returns path to the repository', () {
        expect(repo.path, contains('/test/assets/empty_standard/.gitdir/'));
      });

      test("returns path to parent repo's .git folder for the repository", () {
        expect(
          repo.commonDir,
          contains('/test/assets/empty_standard/.gitdir/'),
        );
      });

      test('checks if it is empty', () {
        expect(repo.isEmpty, true);
      });

      test('throws when checking if it is empty and error occurs', () {
        expect(() => Repository(nullptr).isEmpty, throwsA(isA<LibGit2Error>()));
      });

      test('checks if head is detached', () {
        expect(repo.isHeadDetached, false);
      });

      test('checks if branch is unborn', () {
        expect(repo.isBranchUnborn, true);
      });

      test('sets identity ', () {
        repo.setIdentity(name: 'name', email: 'email@email.com');

        final identity = repo.identity;
        expect(identity.name, 'name');
        expect(identity.email, 'email@email.com');
        expect(identity, equals(repo.identity));
      });

      test('unsets identity', () {
        repo.setIdentity(name: null, email: null);

        final identity = repo.identity;
        expect(identity.name, '');
        expect(identity.email, '');
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
          contains('/test/assets/empty_standard/'),
        );
      });
    });
  });
}
