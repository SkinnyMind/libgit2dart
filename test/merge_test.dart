// ignore_for_file: unnecessary_string_escapes

import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/merge_repo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final result = repo.mergeAnalysis(theirHead: repo['c68ff54']);
        expect(result, [
          {GitMergeAnalysis.upToDate},
          GitMergePreference.none,
        ]);
        expect(repo.status, isEmpty);
      });

      test('is up to date for provided ref', () {
        final result = repo.mergeAnalysis(
          theirHead: repo['c68ff54'],
          ourRef: 'refs/tags/v0.1',
        );
        expect(result[0], {GitMergeAnalysis.upToDate});
        expect(repo.status, isEmpty);
      });

      test('is fast forward', () {
        final ffCommit = repo.lookupCommit(repo['f17d0d4']);
        final ffBranch = repo.createBranch(
          name: 'ff-branch',
          target: ffCommit,
        );

        final result = repo.mergeAnalysis(
          theirHead: repo['6cbc22e'],
          ourRef: 'refs/heads/${ffBranch.name}',
        );
        expect(
          result[0],
          {GitMergeAnalysis.fastForward, GitMergeAnalysis.normal},
        );
        expect(repo.status, isEmpty);

        ffBranch.free();
        ffCommit.free();
      });

      test('is not fast forward and there is no conflicts', () {
        final result = repo.mergeAnalysis(theirHead: repo['5aecfa0']);
        expect(result[0], {GitMergeAnalysis.normal});
        expect(repo.status, isEmpty);
      });
    });

    test('writes conflicts to index', () {
      final conflictBranch = repo.lookupBranch(name: 'conflict-branch');
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

    group('merge file from index', () {
      test('successfully merges without ancestor', () {
        const diffExpected = """
\<<<<<<< conflict_file
master conflict edit
=======
conflict branch edit
>>>>>>> conflict_file
""";
        final conflictBranch = repo.lookupBranch(name: 'conflict-branch');
        final index = repo.index;
        repo.merge(conflictBranch.target);

        final conflictedFile = index.conflicts['conflict_file']!;
        final diff = repo.mergeFileFromIndex(
          ancestor: null,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(
          diff,
          diffExpected,
        );

        index.free();
        conflictBranch.free();
      });

      test('successfully merges with ancestor', () {
        const diffExpected = """
\<<<<<<< feature_file
Feature edit on feature branch
=======
Another feature edit
>>>>>>> feature_file
""";
        final conflictBranch = repo.lookupBranch(name: 'ancestor-conflict');
        repo.checkout(refName: 'refs/heads/feature');
        final index = repo.index;
        repo.merge(conflictBranch.target);

        final conflictedFile = index.conflicts['feature_file']!;
        final diff = repo.mergeFileFromIndex(
          ancestor: conflictedFile.ancestor,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(
          diff,
          diffExpected,
        );

        index.free();
        conflictBranch.free();
      });

      test('throws when error occurs', () {
        expect(
          () => repo.mergeFileFromIndex(
            ancestor: null,
            ours: IndexEntry(nullptr),
            theirs: IndexEntry(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('merge commits', () {
      test('successfully merges with default values', () {
        final theirCommit = repo.lookupCommit(repo['5aecfa0']);
        final ourCommit = repo.lookupCommit(repo['1490545']);

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
        final theirCommit = repo.lookupCommit(repo['5aecfa0']);
        final ourCommit = repo.lookupCommit(repo['1490545']);

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
        final theirCommit = repo.lookupCommit(repo['5aecfa0']);
        final ourCommit = repo.lookupCommit(repo['1490545']);

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

      test('throws when error occurs', () {
        expect(
          () => repo.mergeCommits(
            ourCommit: Commit(nullptr),
            theirCommit: Commit(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('successfully finds merge base', () {
      var base = repo.mergeBase(a: repo['1490545'], b: repo['5aecfa0']);
      expect(base.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');

      base = repo.mergeBase(a: repo['f17d0d4'], b: repo['5aecfa0']);
      expect(base.sha, 'f17d0d48eae3aa08cecf29128a35e310c97b3521');
    });

    test('throws when trying to find merge base for invalid oid', () {
      expect(
        () => repo.mergeBase(a: repo['0' * 40], b: repo['5aecfa0']),
        throwsA(isA<LibGit2Error>()),
      );
    });

    group('merge trees', () {
      test('successfully merges with default values', () {
        final theirCommit = repo.lookupCommit(repo['5aecfa0']);
        final ourCommit = repo.lookupCommit(repo['1490545']);
        final baseCommit = repo.lookupCommit(
          repo.mergeBase(
            a: ourCommit.oid,
            b: theirCommit.oid,
          ),
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
        final theirCommit = repo.lookupCommit(repo['5aecfa0']);
        final ourCommit = repo.lookupCommit(repo['1490545']);
        final baseCommit = repo.lookupCommit(
          repo.mergeBase(
            a: ourCommit.oid,
            b: theirCommit.oid,
          ),
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

      test('throws when error occurs', () {
        expect(
          () => Repository(nullptr).mergeTrees(
            ancestorTree: Tree(nullptr),
            ourTree: Tree(nullptr),
            theirTree: Tree(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('successfully cherry-picks commit', () {
      final cherry = repo.lookupCommit(repo['5aecfa0']);
      repo.cherryPick(cherry);
      expect(repo.state, GitRepositoryState.cherrypick);
      expect(repo.message, 'add another feature file\n');
      final index = repo.index;
      expect(index.conflicts, isEmpty);

      // pretend we've done commit
      repo.removeMessage();
      expect(
        () => repo.message,
        throwsA(isA<LibGit2Error>()),
      );

      index.free();
    });

    test('throws when error occurs', () {
      expect(
        () => repo.cherryPick(Commit(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
