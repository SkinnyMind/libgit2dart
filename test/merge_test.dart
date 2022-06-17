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
    tmpDir.deleteSync(recursive: true);
  });

  group('Merge', () {
    group('analysis', () {
      test('is up to date when no reference is provided', () {
        final analysis = Merge.analysis(repo: repo, theirHead: repo['c68ff54']);
        expect(analysis.result, {GitMergeAnalysis.upToDate});
        expect(analysis.mergePreference, GitMergePreference.none);
        expect(repo.status, isEmpty);
      });

      test('is up to date for provided ref', () {
        final analysis = Merge.analysis(
          repo: repo,
          theirHead: repo['c68ff54'],
          ourRef: 'refs/tags/v0.1',
        );
        expect(analysis.result, {GitMergeAnalysis.upToDate});
        expect(repo.status, isEmpty);
      });

      test('is fast forward', () {
        final ffBranch = Branch.create(
          repo: repo,
          name: 'ff-branch',
          target: Commit.lookup(repo: repo, oid: repo['f17d0d4']),
        );

        final analysis = Merge.analysis(
          repo: repo,
          theirHead: repo['6cbc22e'],
          ourRef: 'refs/heads/${ffBranch.name}',
        );
        expect(
          analysis.result,
          {GitMergeAnalysis.fastForward, GitMergeAnalysis.normal},
        );
        expect(repo.status, isEmpty);
      });

      test('is not fast forward and there is no conflicts', () {
        final analysis = Merge.analysis(repo: repo, theirHead: repo['5aecfa0']);
        expect(analysis.result, {GitMergeAnalysis.normal});
        expect(repo.status, isEmpty);
      });
    });

    test('writes conflicts to index', () {
      final conflictBranch = Branch.lookup(repo: repo, name: 'conflict-branch');
      final index = repo.index;

      final analysis = Merge.analysis(
        repo: repo,
        theirHead: conflictBranch.target,
      );
      expect(analysis.result, {GitMergeAnalysis.normal});

      Merge.commit(
        repo: repo,
        commit: AnnotatedCommit.lookup(repo: repo, oid: conflictBranch.target),
      );
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

        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(
            repo: repo,
            oid: Branch.lookup(repo: repo, name: 'conflict-branch').target,
          ),
        );

        final conflictedFile = repo.index.conflicts['conflict_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: null,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(diff, diffExpected);
      });

      test('merges with ancestor', () {
        const diffExpected = """
\<<<<<<< feature_file
Feature edit on feature branch
=======
Another feature edit
>>>>>>> feature_file
""";

        Checkout.reference(repo: repo, name: 'refs/heads/feature');
        repo.setHead('refs/heads/feature');

        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(
            repo: repo,
            oid: Branch.lookup(repo: repo, name: 'ancestor-conflict').target,
          ),
        );

        final conflictedFile = repo.index.conflicts['feature_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: conflictedFile.ancestor,
          ours: conflictedFile.our!,
          theirs: conflictedFile.their!,
        );

        expect(diff, diffExpected);
      });

      test('merges with provided options', () {
        const diffExpected = """
\<<<<<<< ours
Feature edit on feature branch
||||||| ancestor
Feature edit
=======
Another feature edit
>>>>>>> theirs
""";

        Checkout.reference(repo: repo, name: 'refs/heads/feature');
        repo.setHead('refs/heads/feature');

        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(
            repo: repo,
            oid: Branch.lookup(repo: repo, name: 'ancestor-conflict').target,
          ),
        );

        final conflictedFile = repo.index.conflicts['feature_file']!;
        final diff = Merge.fileFromIndex(
          repo: repo,
          ancestor: conflictedFile.ancestor,
          ancestorLabel: 'ancestor',
          ours: conflictedFile.our!,
          oursLabel: 'ours',
          theirs: conflictedFile.their!,
          theirsLabel: 'theirs',
          flags: {GitMergeFileFlag.styleDiff3},
        );

        expect(diff, diffExpected);
      });

      test('merges with provided merge favor', () {
        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(
            repo: repo,
            oid: Branch.lookup(repo: repo, name: 'conflict-branch').target,
          ),
          favor: GitMergeFileFavor.ours,
        );

        expect(repo.index.conflicts, isEmpty);
        expect(
          File(p.join(repo.workdir, 'conflict_file')).readAsStringSync(),
          'master conflict edit\n',
        );
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

        final mergeIndex = Merge.commits(
          repo: repo,
          ourCommit: Commit.lookup(repo: repo, oid: repo['1490545']),
          theirCommit: theirCommit,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeCommitsTree = mergeIndex.writeTree(repo);

        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(repo: repo, oid: theirCommit.oid),
        );
        expect(repo.index.conflicts, isEmpty);
        final mergeTree = repo.index.writeTree();

        expect(mergeCommitsTree == mergeTree, true);
      });

      test('merges with provided favor', () {
        final mergeIndex = Merge.commits(
          repo: repo,
          ourCommit: Commit.lookup(repo: repo, oid: repo['1490545']),
          theirCommit: Commit.lookup(repo: repo, oid: repo['5aecfa0']),
          favor: GitMergeFileFavor.ours,
        );
        expect(mergeIndex.conflicts, isEmpty);
      });

      test('merges with provided merge and file flags', () {
        final mergeIndex = Merge.commits(
          repo: repo,
          ourCommit: Commit.lookup(repo: repo, oid: repo['1490545']),
          theirCommit: Commit.lookup(repo: repo, oid: repo['5aecfa0']),
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
      expect(
        Merge.base(repo: repo, commits: [repo['1490545'], repo['5aecfa0']]).sha,
        'fc38877b2552ab554752d9a77e1f48f738cca79b',
      );

      expect(
        Merge.base(repo: repo, commits: [repo['f17d0d4'], repo['5aecfa0']]).sha,
        'f17d0d48eae3aa08cecf29128a35e310c97b3521',
      );
    });

    test('finds merge base for many commits', () {
      expect(
        Merge.base(
          repo: repo,
          commits: [repo['1490545'], repo['0e409d6'], repo['5aecfa0']],
        ).sha,
        'fc38877b2552ab554752d9a77e1f48f738cca79b',
      );

      expect(
        Merge.base(
          repo: repo,
          commits: [repo['f17d0d4'], repo['5aecfa0'], repo['0e409d6']],
        ).sha,
        'f17d0d48eae3aa08cecf29128a35e310c97b3521',
      );
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
      expect(
        Merge.octopusBase(
          repo: repo,
          commits: [repo['1490545'], repo['0e409d6'], repo['5aecfa0']],
        ).sha,
        'fc38877b2552ab554752d9a77e1f48f738cca79b',
      );
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
        final ourCommit = Commit.lookup(repo: repo, oid: repo['1490545']);
        final baseCommit = Commit.lookup(
          repo: repo,
          oid: Merge.base(
            repo: repo,
            commits: [ourCommit.oid, theirCommit.oid],
          ),
        );

        final mergeIndex = Merge.trees(
          repo: repo,
          ancestorTree: baseCommit.tree,
          ourTree: ourCommit.tree,
          theirTree: theirCommit.tree,
        );
        expect(mergeIndex.conflicts, isEmpty);
        final mergeTreesTree = mergeIndex.writeTree(repo);

        repo.setHead(ourCommit.oid);
        Merge.commit(
          repo: repo,
          commit: AnnotatedCommit.lookup(repo: repo, oid: theirCommit.oid),
        );
        expect(repo.index.conflicts, isEmpty);

        final mergeTree = repo.index.writeTree();
        expect(mergeTreesTree == mergeTree, true);
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

        final mergeIndex = Merge.trees(
          repo: repo,
          ancestorTree: baseCommit.tree,
          ourTree: ourCommit.tree,
          theirTree: theirCommit.tree,
          favor: GitMergeFileFavor.ours,
        );
        expect(mergeIndex.conflicts, isEmpty);
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
      Merge.cherryPick(
        repo: repo,
        commit: Commit.lookup(repo: repo, oid: repo['5aecfa0']),
      );
      expect(repo.state, GitRepositoryState.cherrypick);
      expect(repo.message, 'add another feature file\n');
      expect(repo.index.conflicts, isEmpty);

      // pretend we've done commit
      repo.removeMessage();
      expect(() => repo.message, throwsA(isA<LibGit2Error>()));
    });

    test('throws when error occurs', () {
      expect(
        () => Merge.cherryPick(repo: repo, commit: Commit(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
