import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Oid lastCommit;
  late Oid featureCommit;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    lastCommit = repo['821ed6e80627b8769d170a293862f9fc60825226'];
    featureCommit = repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'];
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Branch', () {
    test('returns a list of all branches', () {
      const branchesExpected = ['feature', 'master', 'origin/master'];
      final branches = Branch.list(repo: repo);
      final aliasBranches = repo.branches;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        expect(aliasBranches[i].name, branchesExpected[i]);
      }
    });

    test('returns a list of local branches', () {
      const branchesExpected = ['feature', 'master'];
      final branches = Branch.list(repo: repo, type: GitBranch.local);
      final aliasBranches = repo.branchesLocal;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        expect(aliasBranches[i].name, branchesExpected[i]);
      }
    });

    test('returns a list of remote branches', () {
      const branchesExpected = ['origin/master'];
      final branches = Branch.list(repo: repo, type: GitBranch.remote);
      final aliasBranches = repo.branchesRemote;

      for (var i = 0; i < branches.length; i++) {
        expect(branches[i].name, branchesExpected[i]);
        expect(aliasBranches[i].name, branchesExpected[i]);
      }
    });

    test('throws when trying to return list and error occurs', () {
      expect(
        () => Branch.list(repo: Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns a branch with provided name', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(branch.target.sha, lastCommit.sha);
    });

    test('throws when provided name not found', () {
      expect(
        () => Branch.lookup(repo: repo, name: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => Branch.lookup(
          repo: repo,
          name: 'origin/invalid',
          type: GitBranch.remote,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checks if branch is current head', () {
      expect(Branch.lookup(repo: repo, name: 'master').isHead, true);
      expect(Branch.lookup(repo: repo, name: 'feature').isHead, false);
    });

    test('throws when checking if branch is current head and error occurs', () {
      expect(
        () => Branch(nullptr).isHead,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checks if branch is checked out', () {
      expect(Branch.lookup(repo: repo, name: 'master').isCheckedOut, true);
      expect(Branch.lookup(repo: repo, name: 'feature').isCheckedOut, false);
    });

    test('throws when checking if branch is checked out and error occurs', () {
      expect(
        () => Branch(nullptr).isCheckedOut,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns name', () {
      expect(Branch.lookup(repo: repo, name: 'master').name, 'master');
    });

    test('throws when getting name and error occurs', () {
      expect(() => Branch(nullptr).name, throwsA(isA<LibGit2Error>()));
    });

    test('returns remote name of a remote-tracking branch', () {
      final branch = Branch.list(repo: repo, type: GitBranch.remote).first;
      expect(branch.remoteName, 'origin');
    });

    test(
        'throws when getting remote name of a remote-tracking branch and '
        'error occurs', () {
      expect(
        () => Branch.lookup(repo: repo, name: 'master').remoteName,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns upstream of a local branch', () {
      final upstream = Branch.lookup(repo: repo, name: 'master').upstream;

      expect(upstream.isRemote, true);
      expect(upstream.name, 'refs/remotes/origin/master');
    });

    test('throws when trying to get upstream of a remote branch', () {
      final branch = Branch.list(repo: repo, type: GitBranch.remote).first;
      expect(() => branch.upstream, throwsA(isA<LibGit2Error>()));
    });

    test('sets upstream of a branch', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(branch.upstream.name, 'refs/remotes/origin/master');

      final ref = Reference.create(
        repo: repo,
        name: 'refs/remotes/origin/new',
        target: 'refs/heads/master',
      );
      branch.setUpstream(ref.shorthand);

      expect(branch.upstream.name, 'refs/remotes/origin/new');
    });

    test('unsets upstream of a branch', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(branch.upstream.name, 'refs/remotes/origin/master');

      branch.setUpstream(null);
      expect(() => branch.upstream, throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to set upstream of a branch and error occurs', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(
        () => branch.setUpstream('some/upstream'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns upstream name of a local branch', () {
      expect(
        Branch.lookup(repo: repo, name: 'master').upstreamName,
        'refs/remotes/origin/master',
      );
    });

    test('throws when trying to get upstream name of a branch and error occurs',
        () {
      expect(
        () => Branch.lookup(repo: repo, name: 'feature').upstreamName,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns upstream remote of a local branch', () {
      expect(
        Branch.lookup(repo: repo, name: 'master').upstreamRemote,
        'origin',
      );
    });

    test('throws when trying to get upstream remote of a remote branch', () {
      expect(
        () => Branch.list(repo: repo, type: GitBranch.remote)
            .first
            .upstreamRemote,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns upstream merge of a local branch', () {
      expect(
        Branch.lookup(repo: repo, name: 'master').upstreamMerge,
        'refs/heads/master',
      );
    });

    test('throws when trying to get upstream merge of a remote branch', () {
      final branch = Branch.list(repo: repo, type: GitBranch.remote).first;
      expect(() => branch.upstreamMerge, throwsA(isA<LibGit2Error>()));
    });

    group('create()', () {
      test('creates branch', () {
        final branch = Branch.create(
          repo: repo,
          name: 'testing',
          target: Commit.lookup(repo: repo, oid: lastCommit),
        );

        expect(Branch.list(repo: repo).length, 4);
        expect(branch.target, lastCommit);
      });

      test('throws when name already exists', () {
        final commit = Commit.lookup(repo: repo, oid: lastCommit);

        expect(
          () => Branch.create(repo: repo, name: 'feature', target: commit),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('creates branch with force flag when name already exists', () {
        final branch = Branch.create(
          repo: repo,
          name: 'feature',
          target: Commit.lookup(repo: repo, oid: lastCommit),
          force: true,
        );

        expect(Branch.list(repo: repo, type: GitBranch.local).length, 2);
        expect(branch.target, lastCommit);
      });
    });

    group('delete()', () {
      test('deletes branch', () {
        Branch.delete(repo: repo, name: 'feature');

        expect(
          () => Branch.lookup(repo: repo, name: 'feature'),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws when trying to delete current HEAD', () {
        expect(
          () => Branch.delete(repo: repo, name: 'master'),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('rename()', () {
      test('renames branch', () {
        Branch.rename(repo: repo, oldName: 'feature', newName: 'renamed');

        expect(Branch.list(repo: repo).length, 3);
        expect(
          () => Branch.lookup(repo: repo, name: 'feature'),
          throwsA(isA<LibGit2Error>()),
        );
        expect(
          Branch.lookup(repo: repo, name: 'renamed').target,
          featureCommit,
        );
      });

      test('throws when name already exists', () {
        expect(
          () => Branch.rename(
            repo: repo,
            oldName: 'feature',
            newName: 'master',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('renames branch with force flag when name already exists', () {
        Branch.rename(
          repo: repo,
          oldName: 'master',
          newName: 'feature',
          force: true,
        );

        expect(Branch.lookup(repo: repo, name: 'feature').target, lastCommit);
      });

      test('throws when name is invalid', () {
        expect(
          () => Branch.rename(
            repo: repo,
            oldName: 'feature',
            newName: 'inv@{id',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('manually releases allocated memory', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(() => branch.free(), returnsNormally);
    });

    test('returns string representation of Branch object', () {
      final branch = Branch.lookup(repo: repo, name: 'master');
      expect(branch.toString(), contains('Branch{'));
    });

    test('supports value comparison', () {
      expect(
        Branch.lookup(repo: repo, name: 'master'),
        equals(Branch.lookup(repo: repo, name: 'master')),
      );
    });
  });
}
