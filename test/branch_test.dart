import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Oid lastCommit;
  late Oid featureCommit;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
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
      const branchesExpected = ['feature', 'master', 'origin/master'];
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
      const branchesExpected = ['origin/master'];
      final branches = repo.branchesRemote;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        branches[i].free();
      }
    });

    test('throws when trying to return list and error occurs', () {
      final nullRepo = Repository(nullptr);
      expect(() => Branch.list(repo: nullRepo), throwsA(isA<LibGit2Error>()));
    });

    test('returns a branch with provided name', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.target.sha, lastCommit.sha);
      branch.free();
    });

    test('throws when provided name not found', () {
      expect(
        () => repo.lookupBranch(name: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => repo.lookupBranch(name: 'origin/invalid', type: GitBranch.remote),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checks if branch is current head', () {
      final masterBranch = repo.lookupBranch(name: 'master');
      final featureBranch = repo.lookupBranch(name: 'feature');

      expect(masterBranch.isHead, true);
      expect(featureBranch.isHead, false);

      masterBranch.free();
      featureBranch.free();
    });

    test('throws when checking if branch is current head and error occurs', () {
      final nullBranch = Branch(nullptr);
      expect(
        () => nullBranch.isHead,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checks if branch is checked out', () {
      final masterBranch = repo.lookupBranch(name: 'master');
      final featureBranch = repo.lookupBranch(name: 'feature');

      expect(masterBranch.isCheckedOut, true);
      expect(featureBranch.isCheckedOut, false);

      masterBranch.free();
      featureBranch.free();
    });

    test('throws when checking if branch is checked out and error occurs', () {
      final nullBranch = Branch(nullptr);
      expect(
        () => nullBranch.isCheckedOut,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns name', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.name, 'master');
      branch.free();
    });

    test('throws when getting name and error occurs', () {
      final nullBranch = Branch(nullptr);
      expect(() => nullBranch.name, throwsA(isA<LibGit2Error>()));
    });

    test('returns remote name of a remote-tracking branch', () {
      final branch = repo.branchesRemote.first;
      expect(branch.remoteName, 'origin');
      branch.free();
    });

    test(
        'throws when getting remote name of a remote-tracking branch and '
        'error occurs', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(() => branch.remoteName, throwsA(isA<LibGit2Error>()));
    });

    test('returns upstream of a local branch', () {
      final branch = repo.lookupBranch(name: 'master');
      final upstream = branch.upstream;

      expect(upstream.isRemote, true);
      expect(upstream.name, 'refs/remotes/origin/master');

      upstream.free();
      branch.free();
    });

    test('throws when trying to get upstream of a remote branch', () {
      final branch = repo.branchesRemote.first;
      expect(() => branch.upstream, throwsA(isA<LibGit2Error>()));
      branch.free();
    });

    test('successfully sets upstream of a branch', () {
      final branch = repo.lookupBranch(name: 'master');
      var upstream = branch.upstream;
      expect(upstream.name, 'refs/remotes/origin/master');

      final ref = repo.createReference(
        name: 'refs/remotes/origin/new',
        target: 'refs/heads/master',
      );
      branch.setUpstream(ref.shorthand);

      upstream = branch.upstream;
      expect(upstream.name, 'refs/remotes/origin/new');

      ref.free();
      upstream.free();
      branch.free();
    });

    test('successfully unsets upstream of a branch', () {
      final branch = repo.lookupBranch(name: 'master');
      final upstream = branch.upstream;
      expect(upstream.name, 'refs/remotes/origin/master');

      branch.setUpstream(null);
      expect(() => branch.upstream, throwsA(isA<LibGit2Error>()));

      upstream.free();
      branch.free();
    });

    test('throws when trying to set upstream of a branch and error occurs', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(
        () => branch.setUpstream('some/upstream'),
        throwsA(isA<LibGit2Error>()),
      );
      branch.free();
    });

    test('returns upstream name of a local branch', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.upstreamName, 'refs/remotes/origin/master');
      branch.free();
    });

    test('throws when trying to get upstream name of a branch and error occurs',
        () {
      final branch = repo.lookupBranch(name: 'feature');
      expect(() => branch.upstreamName, throwsA(isA<LibGit2Error>()));
      branch.free();
    });

    test('returns upstream remote of a local branch', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.upstreamRemote, 'origin');
      branch.free();
    });

    test('throws when trying to get upstream remote of a remote branch', () {
      final branch = repo.branchesRemote.first;
      expect(() => branch.upstreamName, throwsA(isA<LibGit2Error>()));
      branch.free();
    });

    test('returns upstream merge of a local branch', () {
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.upstreamMerge, 'refs/heads/master');
      branch.free();
    });

    test('throws when trying to get upstream merge of a remote branch', () {
      final branch = repo.branchesRemote.first;
      expect(() => branch.upstreamMerge, throwsA(isA<LibGit2Error>()));
      branch.free();
    });

    group('create()', () {
      test('successfully creates', () {
        final commit = repo.lookupCommit(lastCommit);

        final branch = repo.createBranch(name: 'testing', target: commit);
        final branches = repo.branches;

        expect(repo.branches.length, 4);
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
          () => repo.lookupBranch(name: 'feature'),
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
        final branch = repo.lookupBranch(name: 'renamed');
        final branches = repo.branches;

        expect(branches.length, 3);
        expect(
          () => repo.lookupBranch(name: 'feature'),
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
        final branch = repo.lookupBranch(name: 'feature');

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
      final branch = repo.lookupBranch(name: 'master');
      expect(branch.toString(), contains('Branch{'));
      branch.free();
    });
  });
}
