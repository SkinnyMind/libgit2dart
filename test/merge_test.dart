// ignore_for_file: unnecessary_string_escapes

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
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'merge_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final result = Merge.analysis(repo: repo, theirHead: repo['c68ff54']);
        expect(result, [
          {GitMergeAnalysis.upToDate},
          GitMergePreference.none,
        ]);
        expect(repo.status, isEmpty);
      });

      test('is up to date for provided ref', () {
        final result = Merge.analysis(
          repo: repo,
          theirHead: repo['c68ff54'],
          ourRef: 'refs/tags/v0.1',
        );
        expect(result[0], {GitMergeAnalysis.upToDate});
        expect(repo.status, isEmpty);
      });

      test('is fast forward', () {
        final ffCommit = Commit.lookup(repo: repo, oid: repo['f17d0d4']);
        final ffBranch = Branch.create(
          repo: repo,
          name: 'ff-branch',
          target: ffCommit,
        );

        final result = Merge.analysis(
          repo: repo,
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
        final result = Merge.analysis(repo: repo, theirHead: repo['5aecfa0']);
        expect(result[0], {GitMergeAnalysis.normal});
        expect(repo.status, isEmpty);
      });
    });

    test('writes conflicts to index', () {
      final conflictBranch = Branch.lookup(repo: repo, name: 'conflict-branch');
      final commit = AnnotatedCommit.lookup(
        repo: repo,
        oid: conflictBranch.target,
      );
      final index = repo.index;

      final result = Merge.analysis(
        repo: repo,
        theirHead: conflictBranch.target,
      );
      expect(result[0], {GitMergeAnalysis.normal});

      Merge.commit(repo: repo, commit: commit);
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
      commit.free();
      conflictBranch.free();
    });

    group('merge file from index', () {
      test('merges without ancestor', () {
        const diffExpected = """
\<<<<<<< conflict_file
master conflict edit
=======
conflict branch edit
>>>>>>> conflict_file
""";
        final conflictBranch = Branch.lookup(
          repo: repo,
          name: 'conflict-branch',
        );
        final commit = AnnotatedCommit.lookup(
          repo: repo,
          oid: conflictBranch.target,
        );
        final index = repo.index;

        Merge.commit(repo: repo, commit: commit);

        final conflictedFile = index.conflicts['conflict_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: null,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(diff, diffExpected);

        index.free();
        commit.free();
        conflictBranch.free();
      });

      test('merges with ancestor', () {
        const diffExpected = """
\<<<<<<< feature_file
Feature edit on feature branch
=======
Another feature edit
>>>>>>> feature_file
""";
        final conflictBranch = Branch.lookup(
          repo: repo,
          name: 'ancestor-conflict',
        );
        final commit = AnnotatedCommit.lookup(
          repo: repo,
          oid: conflictBranch.target,
        );
        repo.checkout(target: 'refs/heads/feature');
        final index = repo.index;

        Merge.commit(repo: repo, commit: commit);

        final conflictedFile = index.conflicts['feature_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: conflictedFile.ancestor,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(diff, diffExpected);

        index.free();
        commit.free();
        conflictBranch.free();
      });

      test('merges with provided merge flags and file flags', () {
        const diffExpected = """
\<<<<<<< conflict_file
master conflict edit
=======
conflict branch edit
>>>>>>> conflict_file
""";
        final conflictBranch = Branch.lookup(
          repo: repo,
          name: 'conflict-branch',
        );
        final commit = AnnotatedCommit.lookup(
          repo: repo,
          oid: conflictBranch.target,
        );
        final index = repo.index;

        Merge.commit(
          repo: repo,
          commit: commit,
          mergeFlags: {GitMergeFlag.noRecursive},
          fileFlags: {GitMergeFileFlag.ignoreWhitespaceEOL},
        );

        final conflictedFile = index.conflicts['conflict_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: null,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(diff, diffExpected);

        index.free();
        commit.free();
        conflictBranch.free();
      });

      test('merges with provided merge favor', () {
        final conflictBranch = Branch.lookup(
          repo: repo,
          name: 'conflict-branch',
        );
        final commit = AnnotatedCommit.lookup(
          repo: repo,
          oid: conflictBranch.target,
        );
        final index = repo.index;

        Merge.commit(repo: repo, commit: commit, favor: GitMergeFileFavor.ours);

        expect(index.conflicts, isEmpty);
        expect(
          File(p.join(repo.workdir, 'conflict_file')).readAsStringSync(),
          'master conflict edit\n',
        );

        index.free();
        commit.free();
        conflictBranch.free();
      });

      test('throws when error occurs', () {
        expect(
          () => Merge.fileFromIndex(
            repo: repo,
            ancestor: null,
            ours: IndexEntry(nullptr),
            theirs: IndexEntry(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('merge file', () {
      test('merges file with default values', () {
        const diffExpected = """
\<<<<<<< file.txt
ours content
=======
theirs content
>>>>>>> file.txt
""";
        final diff = Merge.file(
          ancestor: '',
          ours: 'ours content',
          theirs: 'theirs content',
        );

        expect(diff, diffExpected);
      });

      test('merges file with provided values', () {
        const diffExpected = """
\<<<<<<< ours.txt
ours content
||||||| ancestor.txt
ancestor content
=======
theirs content
>>>>>>> theirs.txt
""";
        final diff = Merge.file(
          ancestor: 'ancestor content',
          ancestorLabel: 'ancestor.txt',
          ours: 'ours content',
          oursLabel: 'ours.txt',
          theirs: 'theirs content',
          theirsLabel: 'theirs.txt',
          flags: {GitMergeFileFlag.styleDiff3},
        );

        expect(diff, diffExpected);
      });

      test('merges file with provided favor', () {
        const diffExpected = 'ours content';

        final diff = Merge.file(
          ancestor: 'ancestor content',
          ours: 'ours content',
          theirs: 'theirs content',
          favor: GitMergeFileFavor.ours,
        );

        expect(diff, diffExpected);
      });
    });

    group('merge commits', () {
      test('merges with default values', () {
        final theirCommit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
        final theirCommitAnnotated = AnnotatedCommit.lookup(
          repo: repo,
          oid: theirCommit.oid,
        );
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);

        final mergeIndex = Merge.commits(
          repo: repo,
          ourCommit: ourCommit,
          theirCommit: theirCommit,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeCommitsTree = mergeIndex.writeTree(repo);

        Merge.commit(repo: repo, commit: theirCommitAnnotated);
        final index = repo.index;
        expect(index.conflicts, isEmpty);
        final mergeTree = index.writeTree();

        expect(mergeCommitsTree == mergeTree, true);

        index.free();
        mergeIndex.free();
        ourCommit.free();
        theirCommitAnnotated.free();
        theirCommit.free();
      });

      test('merges with provided favor', () {
        final theirCommit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);

        final mergeIndex = Merge.commits(
          repo: repo,
          ourCommit: ourCommit,
          theirCommit: theirCommit,
          favor: GitMergeFileFavor.ours,
        );
        expect(mergeIndex.conflicts, isEmpty);

        mergeIndex.free();
        ourCommit.free();
        theirCommit.free();
      });

      test('merges with provided merge and file flags', () {
        final theirCommit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);

        final mergeIndex = Merge.commits(
          repo: repo,
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
          () => Merge.commits(
            repo: repo,
            ourCommit: Commit(nullptr),
            theirCommit: Commit(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('finds merge base for two commits', () {
      var base = Merge.base(
        repo: repo,
        commits: [repo['1490545'], repo['5aecfa0']],
      );
      expect(base.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');

      base = Merge.base(
        repo: repo,
        commits: [repo['f17d0d4'], repo['5aecfa0']],
      );
      expect(base.sha, 'f17d0d48eae3aa08cecf29128a35e310c97b3521');
    });

    test('finds merge base for many commits', () {
      var base = Merge.base(
        repo: repo,
        commits: [repo['1490545'], repo['0e409d6'], repo['5aecfa0']],
      );
      expect(base.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');

      base = Merge.base(
        repo: repo,
        commits: [repo['f17d0d4'], repo['5aecfa0'], repo['0e409d6']],
      );
      expect(base.sha, 'f17d0d48eae3aa08cecf29128a35e310c97b3521');
    });

    test('throws when trying to find merge base for invalid oid', () {
      expect(
        () => Merge.base(
          repo: repo,
          commits: [repo['0' * 40], repo['5aecfa0']],
        ),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => Merge.base(
          repo: repo,
          commits: [repo['0' * 40], repo['5aecfa0'], repo['0e409d6']],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('finds octopus merge base', () {
      final base = Merge.octopusBase(
        repo: repo,
        commits: [repo['1490545'], repo['0e409d6'], repo['5aecfa0']],
      );
      expect(base.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');
    });

    test('throws when trying to find octopus merge base for invalid oid', () {
      expect(
        () => Merge.octopusBase(
          repo: repo,
          commits: [repo['0' * 40], repo['5aecfa0'], repo['0e409d6']],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    group('merge trees', () {
      test('merges with default values', () {
        final theirCommit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
        final theirCommitAnnotated = AnnotatedCommit.lookup(
          repo: repo,
          oid: theirCommit.oid,
        );
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);
        final baseCommit = Commit.lookup(
          repo: repo,
          oid: Merge.base(
            repo: repo,
            commits: [ourCommit.oid, theirCommit.oid],
          ),
        );
        final theirTree = theirCommit.tree;
        final ourTree = ourCommit.tree;
        final ancestorTree = baseCommit.tree;

        final mergeIndex = Merge.trees(
          repo: repo,
          ancestorTree: ancestorTree,
          ourTree: ourTree,
          theirTree: theirTree,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeTreesTree = mergeIndex.writeTree(repo);

        repo.setHead(ourCommit.oid);
        Merge.commit(repo: repo, commit: theirCommitAnnotated);
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
        theirCommitAnnotated.free();
        theirCommit.free();
      });

      test('merges with provided favor', () {
        final theirCommit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);
        final baseCommit = Commit.lookup(
          repo: repo,
          oid: Merge.base(
            repo: repo,
            commits: [ourCommit.oid, theirCommit.oid],
          ),
        );
        final theirTree = theirCommit.tree;
        final ourTree = ourCommit.tree;
        final ancestorTree = baseCommit.tree;

        final mergeIndex = Merge.trees(
          repo: repo,
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
          () => Merge.trees(
            repo: Repository(nullptr),
            ancestorTree: Tree(nullptr),
            ourTree: Tree(nullptr),
            theirTree: Tree(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('cherry-picks commit', () {
      final cherry = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
      Merge.cherryPick(repo: repo, commit: cherry);
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
        () => Merge.cherryPick(repo: repo, commit: Commit(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
