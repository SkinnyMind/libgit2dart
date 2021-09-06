import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/branch_testrepo/';
  const lastCommit = '821ed6e80627b8769d170a293862f9fc60825226';
  const featureCommit = '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
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
  });

  group('Branch', () {
    test('returns a list of all branches', () {
      final branches = Branches(repo);
      expect(branches.list(), ['feature', 'master']);
    });

    test('returns a list of local branches', () {
      final branches = repo.branches.local;
      expect(branches, ['feature', 'master']);
    });

    test('returns a list of remote branches for provided type', () {
      final branches = repo.branches.remote;
      expect(branches, []);
    });

    test('returns a branch with provided name', () {
      final branch = repo.branches['master'];
      expect(branch.target.sha, lastCommit);
      branch.free();
    });

    test('throws when provided name not found', () {
      expect(() => repo.branches['invalid'], throwsA(isA<LibGit2Error>()));
    });

    test('checks if branch is current head', () {
      final masterBranch = repo.branches['master'];
      final featureBranch = repo.branches['feature'];

      expect(masterBranch.isHead, true);
      expect(featureBranch.isHead, false);

      masterBranch.free();
      featureBranch.free();
    });

    test('returns name', () {
      final branch = repo.branches['master'];
      expect(branch.name, 'master');
      branch.free();
    });

    group('create()', () {
      test('successfully creates', () {
        final commit = repo[lastCommit] as Commit;

        final ref = repo.branches.create(name: 'testing', target: commit);
        final branch = repo.branches['testing'];
        expect(repo.branches.list().length, 3);
        expect(branch.target.sha, lastCommit);

        branch.free();
        ref.free();
        commit.free();
      });

      test('throws when name already exists', () {
        final commit = repo[lastCommit] as Commit;

        expect(
          () => repo.branches.create(name: 'feature', target: commit),
          throwsA(isA<LibGit2Error>()),
        );

        commit.free();
      });

      test('successfully creates with force flag when name already exists', () {
        final commit = repo[lastCommit] as Commit;

        final ref =
            repo.branches.create(name: 'feature', target: commit, force: true);
        final branch = repo.branches['feature'];
        expect(repo.branches.local.length, 2);
        expect(branch.target.sha, lastCommit);

        branch.free();
        ref.free();
        commit.free();
      });
    });

    group('delete()', () {
      test('successfully deletes', () {
        repo.branches['feature'].delete();
        expect(repo.branches.local.length, 1);
        expect(() => repo.branches['feature'], throwsA(isA<LibGit2Error>()));
      });

      test('throws when trying to delete current HEAD', () {
        expect(
          () => repo.branches['master'].delete(),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('rename()', () {
      test('successfully renames', () {
        final renamed = repo.branches['feature'].rename(newName: 'renamed');
        final branch = repo.branches['renamed'];

        expect(renamed.target.sha, featureCommit);
        expect(branch.target.sha, featureCommit);

        branch.free();
        renamed.free();
      });

      test('throws when name already exists', () {
        final branch = repo.branches['feature'];
        expect(
          () => branch.rename(newName: 'master'),
          throwsA(isA<LibGit2Error>()),
        );
        branch.free();
      });

      test('successfully renames with force flag when name already exists', () {
        final renamed = repo.branches['master'].rename(
          newName: 'feature',
          force: true,
        );

        expect(renamed.target.sha, lastCommit);

        renamed.free();
      });

      test('throws when name is invalid', () {
        final branch = repo.branches['feature'];
        expect(
          () => branch.rename(newName: 'inv@{id'),
          throwsA(isA<LibGit2Error>()),
        );
        branch.free();
      });
    });
  });
}
