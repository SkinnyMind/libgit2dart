import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Describe', () {
    test('describes worktree with default arguments', () {
      expect(repo.describe(), 'v0.2');
    });

    test('throws when trying to describe and error occurs', () {
      final nullRepo = Repository(nullptr);
      expect(() => nullRepo.describe(), throwsA(isA<LibGit2Error>()));
    });

    test('describes commit', () {
      Tag.delete(repo: repo, name: 'v0.2');

      expect(
        repo.describe(describeStrategy: GitDescribeStrategy.tags),
        'v0.1-1-g821ed6e',
      );
    });

    test('throws when trying to describe and no reference found', () {
      final commit = Commit.lookup(repo: repo, oid: repo['f17d0d4']);
      expect(() => repo.describe(commit: commit), throwsA(isA<LibGit2Error>()));
      commit.free();
    });

    test('returns oid when fallback argument is provided', () {
      final commit = Commit.lookup(repo: repo, oid: repo['f17d0d4']);
      expect(
        repo.describe(commit: commit, showCommitOidAsFallback: true),
        'f17d0d4',
      );
      commit.free();
    });

    test('describes with provided strategy', () {
      final commit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
      expect(
        repo.describe(
          commit: commit,
          describeStrategy: GitDescribeStrategy.all,
        ),
        'heads/feature',
      );
      commit.free();
    });

    test('describes with provided pattern', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final commit = Commit.lookup(repo: repo, oid: repo['fc38877']);
      Tag.createAnnotated(
        repo: repo,
        tagName: 'test/tag1',
        target: repo['f17d0d4'],
        targetType: GitObject.commit,
        tagger: signature,
        message: 'message',
      );

      expect(
        repo.describe(commit: commit, pattern: 'test/*'),
        'test/tag1-2-gfc38877',
      );

      commit.free();
      signature.free();
    });

    test('describes and follows first parent only', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      Tag.delete(repo: repo, name: 'v0.2');

      expect(
        repo.describe(
          commit: commit,
          onlyFollowFirstParent: true,
          describeStrategy: GitDescribeStrategy.tags,
        ),
        'v0.1-1-g821ed6e',
      );

      commit.free();
    });

    test('describes with provided abbreviated size', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      Tag.delete(repo: repo, name: 'v0.2');

      expect(
        repo.describe(
          commit: commit,
          describeStrategy: GitDescribeStrategy.tags,
          abbreviatedSize: 20,
        ),
        'v0.1-1-g821ed6e80627b8769d17',
      );

      expect(
        repo.describe(
          commit: commit,
          describeStrategy: GitDescribeStrategy.tags,
          abbreviatedSize: 0,
        ),
        'v0.1',
      );

      commit.free();
    });

    test('describes with long format', () {
      expect(repo.describe(alwaysUseLongFormat: true), 'v0.2-0-g821ed6e');
    });

    test('describes and appends dirty suffix', () {
      final index = repo.index;
      index.clear();

      expect(repo.describe(dirtySuffix: '-dirty'), 'v0.2-dirty');

      index.free();
    });

    test('describes with max candidates tags flag set', () {
      final index = repo.index;
      index.clear();

      expect(repo.describe(maxCandidatesTags: 0), 'v0.2');

      index.free();
    });
  });
}
