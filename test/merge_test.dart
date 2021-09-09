import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/git_types.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/mergerepo/';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/mergerepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
  });

  tearDown(() async {
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final commit =
            repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'] as Commit;

        final result = repo.mergeAnalysis(commit.id);
        expect(result[0], GitMergeAnalysis.upToDate.value);
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is up to date for provided ref', () {
        final commit =
            repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'] as Commit;

        final result = repo.mergeAnalysis(commit.id, 'refs/tags/v0.1');
        expect(result[0], GitMergeAnalysis.upToDate.value);
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is fast forward', () {
        final theirHead =
            repo['6cbc22e509d72758ab4c8d9f287ea846b90c448b'] as Commit;
        final ffCommit =
            repo['f17d0d48eae3aa08cecf29128a35e310c97b3521'] as Commit;
        final ffBranch = repo.branches.create(
          name: 'ff-branch',
          target: ffCommit,
        );

        final result = repo.mergeAnalysis(theirHead.id, ffBranch.name);
        expect(
          result[0],
          GitMergeAnalysis.fastForward.value + GitMergeAnalysis.normal.value,
        );
        expect(repo.status, isEmpty);

        ffBranch.free();
        ffCommit.free();
        theirHead.free();
      });

      test('is not fast forward and there is no conflicts', () {
        final commit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;

        final result = repo.mergeAnalysis(commit.id);
        expect(result[0], GitMergeAnalysis.normal.value);
        expect(repo.status, isEmpty);

        commit.free();
      });
    });

    test('writes conflicts to index', () {
      final conflictBranch = repo.branches['conflict-branch'];
      final index = repo.index;

      final result = repo.mergeAnalysis(conflictBranch.target);
      expect(result[0], GitMergeAnalysis.normal.value);

      repo.merge(conflictBranch.target);
      expect(index.hasConflicts, true);
      expect(index.conflicts.length, 1);
      expect(repo.state, GitRepositoryState.merge.value);
      expect(repo.status, {'conflict_file': GitStatus.conflicted.value});

      final conflictedFile = index.conflicts['conflict_file']!;
      expect(conflictedFile.ancestor, null);
      expect(conflictedFile.our?.path, 'conflict_file');
      expect(conflictedFile.their?.path, 'conflict_file');

      index.add('conflict_file');
      index.write();
      expect(index.hasConflicts, false);
      expect(index.conflicts, isEmpty);
      expect(repo.status, {'conflict_file': GitStatus.indexModified.value});

      index.free();
      conflictBranch.free();
    });

    test('successfully removes conflicts', () {
      final conflictBranch = repo.branches['conflict-branch'];
      final index = repo.index;

      repo.merge(conflictBranch.target);
      expect(index.hasConflicts, true);
      expect(index.conflicts.length, 1);

      final conflictedFile = index.conflicts['conflict_file']!;
      conflictedFile.remove();
      expect(index.hasConflicts, false);
      expect(index.conflicts, isEmpty);
      expect(index.conflicts['conflict_file'], null);

      index.free();
      conflictBranch.free();
    });

    group('merge commits', () {
      test('successfully merges with default values', () {
        final theirCommit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
        final ourCommit =
            repo['14905459d775f3f56a39ebc2ff081163f7da3529'] as Commit;

        final mergeIndex = repo.mergeCommits(
          ourCommit: ourCommit,
          theirCommit: theirCommit,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeCommitsTree = mergeIndex.writeTree(repo);

        repo.merge(theirCommit.id);
        final index = repo.index;
        expect(index.conflicts, isEmpty);
        final mergeTree = index.writeTree();

        expect(mergeCommitsTree == mergeTree, true);

        index.free();
        mergeIndex.free();
        ourCommit.free();
        theirCommit.free();
      });

      test('successfully merges with provided favor', () {
        final theirCommit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
        final ourCommit =
            repo['14905459d775f3f56a39ebc2ff081163f7da3529'] as Commit;

        final mergeIndex = repo.mergeCommits(
          ourCommit: ourCommit,
          theirCommit: theirCommit,
          favor: GitMergeFileFavor.ours,
        );
        expect(mergeIndex.conflicts, isEmpty);

        mergeIndex.free();
        ourCommit.free();
        theirCommit.free();
      });
    });

    group('merge trees', () {
      test('successfully merges with default values', () {
        final theirCommit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
        final ourCommit =
            repo['14905459d775f3f56a39ebc2ff081163f7da3529'] as Commit;
        final baseCommit =
            repo[repo.mergeBase(ourCommit.id.sha, theirCommit.id.sha).sha]
                as Commit;
        final theirTree = repo[theirCommit.tree.sha] as Tree;
        final ourTree = repo[ourCommit.tree.sha] as Tree;
        final ancestorTree = repo[baseCommit.tree.sha] as Tree;

        final mergeIndex = repo.mergeTrees(
          ancestorTree: ancestorTree,
          ourTree: ourTree,
          theirTree: theirTree,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeTreesTree = mergeIndex.writeTree(repo);

        repo.setHead('14905459d775f3f56a39ebc2ff081163f7da3529');
        repo.merge(theirCommit.id);
        final index = repo.index;
        expect(index.conflicts, isEmpty);
        final mergeTree = index.writeTree();

        expect(mergeTreesTree == mergeTree, true);

        index.free();
        mergeIndex.free();
        ancestorTree.free();
        ourTree.free();
        theirTree.free();
        baseCommit.free();
        ourCommit.free();
        theirCommit.free();
      });

      test('successfully merges with provided favor', () {
        final theirCommit =
            repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
        final ourCommit =
            repo['14905459d775f3f56a39ebc2ff081163f7da3529'] as Commit;
        final baseCommit =
            repo[repo.mergeBase(ourCommit.id.sha, theirCommit.id.sha).sha]
                as Commit;
        final theirTree = repo[theirCommit.tree.sha] as Tree;
        final ourTree = repo[ourCommit.tree.sha] as Tree;
        final ancestorTree = repo[baseCommit.tree.sha] as Tree;

        final mergeIndex = repo.mergeTrees(
          ancestorTree: ancestorTree,
          ourTree: ourTree,
          theirTree: theirTree,
          favor: GitMergeFileFavor.ours,
        );
        expect(mergeIndex.conflicts, isEmpty);

        mergeIndex.free();
        ancestorTree.free();
        ourTree.free();
        theirTree.free();
        baseCommit.free();
        ourCommit.free();
        theirCommit.free();
      });
    });
  });
}
