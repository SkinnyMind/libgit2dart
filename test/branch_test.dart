import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Oid lastCommit;
  late Oid featureCommit;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    lastCommit = repo['821ed6e80627b8769d170a293862f9fc60825226'];
    featureCommit = repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'];
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Branch', () {
    test('returns a list of all branches', () {
      const branchesExpected = ['feature', 'master'];
      final branches = repo.branches;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        branches[i].free();
      }
    });

    test('returns a list of local branches', () {
      const branchesExpected = ['feature', 'master'];
      final branches = repo.branchesLocal;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        branches[i].free();
      }
    });

    test('returns a list of remote branches', () {
      expect(repo.branchesRemote, []);
    });

    test('returns a branch with provided name', () {
      final branch = repo.lookupBranch('master');
      expect(branch.target.sha, lastCommit.sha);
      branch.free();
    });

    test('throws when provided name not found', () {
      expect(() => repo.lookupBranch('invalid'), throwsA(isA<LibGit2Error>()));
    });

    test('checks if branch is current head', () {
      final masterBranch = repo.lookupBranch('master');
      final featureBranch = repo.lookupBranch('feature');

      expect(masterBranch.isHead, true);
      expect(featureBranch.isHead, false);

      masterBranch.free();
      featureBranch.free();
    });

    test('returns name', () {
      final branch = repo.lookupBranch('master');
      expect(branch.name, 'master');
      branch.free();
    });

    group('create()', () {
      test('successfully creates', () {
        final commit = repo.lookupCommit(lastCommit);

        final branch = repo.createBranch(name: 'testing', target: commit);
        final branches = repo.branches;

        expect(repo.branches.length, 3);
        expect(branch.target, lastCommit);

        for (final branch in branches) {
          branch.free();
        }
        branch.free();
        commit.free();
      });

      test('throws when name already exists', () {
        final commit = repo.lookupCommit(lastCommit);

        expect(
          () => repo.createBranch(name: 'feature', target: commit),
          throwsA(isA<LibGit2Error>()),
        );

        commit.free();
      });

      test('successfully creates with force flag when name already exists', () {
        final commit = repo.lookupCommit(lastCommit);

        final branch = repo.createBranch(
          name: 'feature',
          target: commit,
          force: true,
        );
        final localBranches = repo.branchesLocal;

        expect(localBranches.length, 2);
        expect(branch.target, lastCommit);

        for (final branch in localBranches) {
          branch.free();
        }
        branch.free();
        commit.free();
      });
    });

    group('delete()', () {
      test('successfully deletes', () {
        repo.deleteBranch('feature');

        expect(
          () => repo.lookupBranch('feature'),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws when trying to delete current HEAD', () {
        expect(
          () => repo.deleteBranch('master'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('rename()', () {
      test('successfully renames', () {
        repo.renameBranch(oldName: 'feature', newName: 'renamed');
        final branch = repo.lookupBranch('renamed');
        final branches = repo.branches;

        expect(branches.length, 2);
        expect(
          () => repo.lookupBranch('feature'),
          throwsA(isA<LibGit2Error>()),
        );
        expect(branch.target, featureCommit);

        for (final branch in branches) {
          branch.free();
        }
        branch.free();
      });

      test('throws when name already exists', () {
        expect(
          () => repo.renameBranch(oldName: 'feature', newName: 'master'),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('successfully renames with force flag when name already exists', () {
        repo.renameBranch(
          oldName: 'master',
          newName: 'feature',
          force: true,
        );
        final branch = repo.lookupBranch('feature');

        expect(branch.target, lastCommit);

        branch.free();
      });

      test('throws when name is invalid', () {
        expect(
          () => repo.renameBranch(oldName: 'feature', newName: 'inv@{id'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns string representation of Branch object', () {
      final branch = repo.lookupBranch('master');
      expect(branch.toString(), contains('Branch{'));
      branch.free();
    });
  });
}
