import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Describe', () {
    test('successfully describes with default arguments', () {
      expect(repo.describe(), 'v0.2');
    });

    test('successfully describes commit', () {
      final tag = Tag.lookup(repo: repo, sha: 'f0fdbf5');
      tag.delete();

      expect(
        repo.describe(describeStrategy: GitDescribeStrategy.tags),
        'v0.1-1-g821ed6e',
      );

      tag.free();
    });

    test('throws when trying to describe and no reference found', () {
      final commit = repo['f17d0d48'] as Commit;
      expect(() => repo.describe(commit: commit), throwsA(isA<LibGit2Error>()));
      commit.free();
    });

    test('returns oid when fallback argument is provided', () {
      final commit = repo['f17d0d48'] as Commit;
      expect(
        repo.describe(commit: commit, showCommitOidAsFallback: true),
        'f17d0d4',
      );
      commit.free();
    });

    test('successfully describes with provided strategy', () {
      final commit = repo['5aecfa0'] as Commit;
      expect(
        repo.describe(
          commit: commit,
          describeStrategy: GitDescribeStrategy.all,
        ),
        'heads/feature',
      );
      commit.free();
    });

    test('successfully describes with provided pattern', () {
      final signature = repo.defaultSignature;
      final commit = repo['fc38877'] as Commit;
      repo.createTag(
        tagName: 'test/tag1',
        target: 'f17d0d48',
        targetType: GitObject.commit,
        tagger: signature,
        message: '',
      );

      expect(
        repo.describe(commit: commit, pattern: 'test/*'),
        'test/tag1-2-gfc38877',
      );

      commit.free();
      signature.free();
    });

    test('successfully describes and follows first parent only', () {
      final tag = Tag.lookup(repo: repo, sha: 'f0fdbf5');
      tag.delete();

      final commit = repo['821ed6e'] as Commit;
      expect(
        repo.describe(
          commit: commit,
          onlyFollowFirstParent: true,
          describeStrategy: GitDescribeStrategy.tags,
        ),
        'v0.1-1-g821ed6e',
      );

      tag.free();
      commit.free();
    });

    test('successfully describes with abbreviated size provided', () {
      final tag = Tag.lookup(repo: repo, sha: 'f0fdbf5');
      tag.delete();

      final commit = repo['821ed6e'] as Commit;
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

      tag.free();
      commit.free();
    });

    test('successfully describes with long format', () {
      expect(repo.describe(alwaysUseLongFormat: true), 'v0.2-0-g821ed6e');
    });

    test('successfully describes and appends dirty suffix', () {
      final index = repo.index;
      index.clear();

      expect(repo.describe(dirtySuffix: '-dirty'), 'v0.2-dirty');

      index.free();
    });
  });
}
