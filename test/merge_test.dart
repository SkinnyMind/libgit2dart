// ignore_for_file: unnecessary_string_escapes

import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/mergerepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final commit = repo.lookupCommit(
          repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'],
        );

        final result = repo.mergeAnalysis(theirHead: commit.oid);
        expect(result, [
          {GitMergeAnalysis.upToDate},
          GitMergePreference.none,
        ]);
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is up to date for provided ref', () {
        final commit = repo.lookupCommit(
          repo['c68ff54aabf660fcdd9a2838d401583fe31249e3'],
        );

        final result = repo.mergeAnalysis(
          theirHead: commit.oid,
          ourRef: 'refs/tags/v0.1',
        );
        expect(result[0], {GitMergeAnalysis.upToDate});
        expect(repo.status, isEmpty);

        commit.free();
      });

      test('is fast forward', () {
        final theirHead = repo.lookupCommit(
          repo['6cbc22e509d72758ab4c8d9f287ea846b90c448b'],
        );
        final ffCommit = repo.lookupCommit(
          repo['f17d0d48eae3aa08cecf29128a35e310c97b3521'],
        );
        final ffBranch = repo.createBranch(
          name: 'ff-branch',
          target: ffCommit,
        );

        final result = repo.mergeAnalysis(
          theirHead: theirHead.oid,
          ourRef: 'refs/heads/${ffBranch.name}',
        );
        expect(
          result[0],
          {GitMergeAnalysis.fastForward, GitMergeAnalysis.normal},
        );
        expect(repo.status, isEmpty);

        ffBranch.free();
        ffCommit.free();
        theirHead.free();
      });

      test('is not fast forward and there is no conflicts', () {
        final commit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );

        final result = repo.mergeAnalysis(theirHead: commit.oid);
        expect(result[0], {GitMergeAnalysis.normal});
        expect(repo.status, isEmpty);

        commit.free();
      });
    });

    test('writes conflicts to index', () {
      final conflictBranch = repo.lookupBranch('conflict-branch');
      final index = repo.index;

      final result = repo.mergeAnalysis(theirHead: conflictBranch.target);
      expect(result[0], {GitMergeAnalysis.normal});

      repo.merge(conflictBranch.target);
      expect(index.hasConflicts, true);
      expect(index.conflicts.length, 1);
      expect(repo.state, GitRepositoryState.merge);
      expect(
        repo.status,
        {
          'conflict_file': {GitStatus.conflicted}
        },
      );

      final conflictedFile = index.conflicts['conflict_file']!;
      expect(conflictedFile.ancestor, null);
      expect(conflictedFile.our?.path, 'conflict_file');
      expect(conflictedFile.their?.path, 'conflict_file');

      index.add('conflict_file');
      index.write();
      expect(index.hasConflicts, false);
      expect(index.conflicts, isEmpty);
      expect(
        repo.status,
        {
          'conflict_file': {GitStatus.indexModified}
        },
      );

      index.free();
      conflictBranch.free();
    });

    test('successfully removes conflicts', () {
      final conflictBranch = repo.lookupBranch('conflict-branch');
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

    group('merge file from index', () {
      test('successfully merges', () {
        const diffExpected = """
\<<<<<<< conflict_file
master conflict edit
=======
conflict branch edit
>>>>>>> conflict_file
""";
        final conflictBranch = repo.lookupBranch('conflict-branch');
        final index = repo.index;
        repo.merge(conflictBranch.target);

        final diff = repo.mergeFileFromIndex(
          ancestor: index.conflicts['conflict_file']!.ancestor,
          ours: index.conflicts['conflict_file']!.our,
          theirs: index.conflicts['conflict_file']!.their,
        );

        expect(
          diff,
          diffExpected,
        );

        index.free();
        conflictBranch.free();
      });
    });

    group('merge commits', () {
      test('successfully merges with default values', () {
        final theirCommit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );
        final ourCommit = repo.lookupCommit(
          repo['14905459d775f3f56a39ebc2ff081163f7da3529'],
        );

        final mergeIndex = repo.mergeCommits(
          ourCommit: ourCommit,
          theirCommit: theirCommit,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeCommitsTree = mergeIndex.writeTree(repo);

        repo.merge(theirCommit.oid);
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
        final theirCommit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );
        final ourCommit = repo.lookupCommit(
          repo['14905459d775f3f56a39ebc2ff081163f7da3529'],
        );

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

      test('successfully merges with provided merge and file flags', () {
        final theirCommit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );
        final ourCommit = repo.lookupCommit(
          repo['14905459d775f3f56a39ebc2ff081163f7da3529'],
        );

        final mergeIndex = repo.mergeCommits(
          ourCommit: ourCommit,
          theirCommit: theirCommit,
          mergeFlags: {
            GitMergeFlag.findRenames,
            GitMergeFlag.noRecursive,
          },
          fileFlags: {
            GitMergeFileFlag.ignoreWhitespace,
            GitMergeFileFlag.ignoreWhitespaceEOL,
            GitMergeFileFlag.styleMerge,
          },
        );
        expect(mergeIndex.conflicts, isEmpty);

        mergeIndex.free();
        ourCommit.free();
        theirCommit.free();
      });
    });

    group('merge trees', () {
      test('successfully merges with default values', () {
        final theirCommit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );
        final ourCommit = repo.lookupCommit(
          repo['14905459d775f3f56a39ebc2ff081163f7da3529'],
        );
        final baseCommit = repo.lookupCommit(
          repo.mergeBase(a: ourCommit.oid, b: theirCommit.oid),
        );
        final theirTree = theirCommit.tree;
        final ourTree = ourCommit.tree;
        final ancestorTree = baseCommit.tree;

        final mergeIndex = repo.mergeTrees(
          ancestorTree: ancestorTree,
          ourTree: ourTree,
          theirTree: theirTree,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeTreesTree = mergeIndex.writeTree(repo);

        repo.setHead(ourCommit.oid);
        repo.merge(theirCommit.oid);
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
        final theirCommit = repo.lookupCommit(
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
        );
        final ourCommit = repo.lookupCommit(
          repo['14905459d775f3f56a39ebc2ff081163f7da3529'],
        );
        final baseCommit = repo.lookupCommit(
          repo.mergeBase(a: ourCommit.oid, b: theirCommit.oid),
        );
        final theirTree = theirCommit.tree;
        final ourTree = ourCommit.tree;
        final ancestorTree = baseCommit.tree;

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

    test('successfully cherry-picks commit', () {
      final cherry = repo.lookupCommit(
        repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
      );
      repo.cherryPick(cherry);
      expect(repo.state, GitRepositoryState.cherrypick);
      expect(repo.message, 'add another feature file\n');
      final index = repo.index;
      expect(index.conflicts, isEmpty);
      // pretend we've done commit
      repo.removeMessage();
      expect(() => repo.message, throwsA(isA<LibGit2Error>()));

      index.free();
    });
  });
}
