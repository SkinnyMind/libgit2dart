import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const indexToWorkdir = [
    'file_deleted',
    'modified_file',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_new_file_deleted',
    'staged_new_file_modified',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const indexToTree = [
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_delete',
    'staged_delete_file_modified',
    'staged_new',
    'staged_new_file_deleted',
    'staged_new_file_modified',
  ];

  const treeToWorkdir = [
    'file_deleted',
    'modified_file',
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_delete',
    'staged_delete_file_modified',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const treeToTree = [
    'deleted_file',
    'file_deleted',
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_delete',
    'staged_delete_file_modified',
    'subdir/current_file',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const treeToWorkdirWithIndex = [
    'file_deleted',
    'modified_file',
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_delete',
    'staged_delete_file_modified',
    'staged_new',
    'staged_new_file_modified',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const indexToIndex = [
    'current_file',
    'file_deleted',
    'modified_file',
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_new',
    'staged_new_file_deleted',
    'staged_new_file_modified',
    'subdir/current_file',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const treeToEmptyTree = [
    'current_file',
    'file_deleted',
    'modified_file',
    'staged_changes',
    'staged_changes_file_deleted',
    'staged_changes_file_modified',
    'staged_delete',
    'staged_delete_file_modified',
    'subdir/current_file',
    'subdir/deleted_file',
    'subdir/modified_file',
  ];

  const patchText = """
diff --git a/subdir/modified_file b/subdir/modified_file
index e69de29..c217c63 100644
--- a/subdir/modified_file
+++ b/subdir/modified_file
@@ -0,0 +1 @@
+Modified content
""";

  const statsPrint = """
 file_deleted                 | 0
 modified_file                | 1 +
 staged_changes_file_deleted  | 1 -
 staged_changes_file_modified | 2 +-
 staged_new_file_deleted      | 0
 staged_new_file_modified     | 1 +
 subdir/deleted_file          | 0
 subdir/modified_file         | 1 +
 8 files changed, 4 insertions(+), 2 deletions(-)
""";

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'dirty_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    if (Platform.isLinux || Platform.isMacOS) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  group('Diff', () {
    test('returns diff between index and workdir', () {
      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);

      expect(diff.length, 8);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToWorkdir[i]);
      }
    });

    test('returns diff between index and tree', () {
      final diff = Diff.treeToIndex(
        repo: repo,
        tree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
        index: repo.index,
      );

      expect(diff.length, 8);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToTree[i]);
      }
    });

    test('returns diff between index and empty tree', () {
      final diff = Diff.treeToIndex(repo: repo, tree: null, index: repo.index);

      expect(diff.length, 12);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToIndex[i]);
      }
    });

    test('returns diff between tree and workdir', () {
      final diff = Diff.treeToWorkdir(
        repo: repo,
        tree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
      );

      expect(diff.length, 9);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToWorkdir[i]);
      }
    });

    test('throws when trying to diff between tree and workdir and error occurs',
        () {
      expect(
        () => Diff.treeToWorkdir(repo: Repository(nullptr), tree: null),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns diff between tree and workdir with index', () {
      final diff = Diff.treeToWorkdirWithIndex(
        repo: repo,
        tree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
      );

      expect(diff.length, 11);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToWorkdirWithIndex[i]);
      }
    });

    test(
        'throws when trying to diff between tree and workdir with index and '
        'error occurs', () {
      expect(
        () => Diff.treeToWorkdirWithIndex(
          repo: Repository(nullptr),
          tree: null,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns diff between tree and tree', () {
      final diff = Diff.treeToTree(
        repo: repo,
        oldTree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
        newTree: Tree.lookup(repo: repo, oid: repo['b85d53c']),
      );

      expect(diff.length, 10);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToTree[i]);
      }
    });

    test('returns diff between tree and empty tree', () {
      final diff = Diff.treeToTree(
        repo: repo,
        oldTree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
        newTree: null,
      );

      expect(diff.length, 11);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToEmptyTree[i]);
      }
    });

    test('returns diff between empty tree and tree', () {
      final diff = Diff.treeToTree(
        repo: repo,
        oldTree: null,
        newTree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
      );

      expect(diff.length, 11);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToEmptyTree[i]);
      }
    });

    test('throws when trying to diff between tree and tree and error occurs',
        () {
      expect(
        () => Diff.treeToTree(
          repo: Repository(nullptr),
          oldTree: Tree(nullptr),
          newTree: Tree(nullptr),
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to diff between two null trees', () {
      expect(
        () => Diff.treeToTree(repo: repo, oldTree: null, newTree: null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns diff between index and index', () {
      final diff = Diff.indexToIndex(
        repo: repo,
        oldIndex: repo.index,
        newIndex: Index.newInMemory(),
      );

      expect(diff.length, 12);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToIndex[i]);
      }
    });

    test('throws when trying to diff between index and index and error occurs',
        () {
      expect(
        () => Diff.indexToIndex(
          repo: repo,
          oldIndex: repo.index,
          newIndex: Index(nullptr),
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('merges diffs', () {
      final commit = Commit.lookup(repo: repo, oid: repo.head.target);
      final diff1 = Diff.treeToTree(
        repo: repo,
        oldTree: commit.tree,
        newTree: Tree.lookup(repo: repo, oid: repo['b85d53c']),
      );
      final diff2 = Diff.treeToWorkdir(repo: repo, tree: commit.tree);

      expect(diff1.length, 10);
      expect(diff2.length, 9);

      diff1.merge(diff2);
      expect(diff1.length, 11);
    });

    test('parses provided diff', () {
      final diff = Diff.parse(patchText);
      final stats = diff.stats;

      expect(diff.length, 1);
      expect(stats.filesChanged, 1);
      expect(stats.insertions, 1);
      expect(diff.patchOid.sha, '699556913185bc38632ae20a49d5c18b9233335e');
    });

    group('apply', () {
      test('checks if diff can be applied to repository', () {
        final diff1 = Diff.indexToWorkdir(repo: repo, index: repo.index);
        expect(
          diff1.applies(repo: repo, location: GitApplyLocation.both),
          false,
        );

        final diff2 = Diff.parse(patchText);
        Checkout.head(repo: repo, strategy: {GitCheckout.force});
        expect(
          diff2.applies(repo: repo, location: GitApplyLocation.both),
          true,
        );
      });

      test('checks if hunk with provided index can be applied to repository',
          () {
        final diff1 = Diff.indexToWorkdir(repo: repo, index: repo.index);
        expect(
          diff1.applies(repo: repo, location: GitApplyLocation.both),
          false,
        );

        final diff2 = Diff.parse(patchText);
        final hunk = diff2.patches.first.hunks.first;
        Checkout.head(repo: repo, strategy: {GitCheckout.force});
        expect(
          diff2.applies(
            repo: repo,
            hunkIndex: hunk.index,
            location: GitApplyLocation.both,
          ),
          true,
        );
      });

      test('applies diff to repository', () {
        final file = File(p.join(tmpDir.path, 'subdir', 'modified_file'));

        Checkout.head(repo: repo, strategy: {GitCheckout.force});
        expect(file.readAsStringSync(), '');

        Diff.parse(patchText).apply(repo: repo);
        expect(file.readAsStringSync(), 'Modified content\n');
      });

      test('throws when trying to apply diff and error occurs', () {
        expect(
          () => Diff(nullptr).apply(repo: repo),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('creates patch from entry index in diff', () {
        final diff = Diff.parse(patchText);
        final patch = Patch.fromDiff(diff: diff, index: 0);

        expect(diff.length, 1);
        expect(patch.text, patchText);
      });

      test('applies hunk with provided index to repository', () {
        final diff = Diff.parse(patchText);
        final hunk = diff.patches.first.hunks.first;
        final file = File(p.join(tmpDir.path, 'subdir', 'modified_file'));

        Checkout.head(repo: repo, strategy: {GitCheckout.force});
        expect(file.readAsStringSync(), '');

        diff.apply(repo: repo, hunkIndex: hunk.index);
        expect(file.readAsStringSync(), 'Modified content\n');
      });

      test('does not apply hunk with non existing index', () {
        final file = File(p.join(tmpDir.path, 'subdir', 'modified_file'));

        Checkout.head(repo: repo, strategy: {GitCheckout.force});
        expect(file.readAsStringSync(), '');

        Diff.parse(patchText).apply(repo: repo, hunkIndex: 10);
        expect(file.readAsStringSync(), '');
      });

      test('applies diff to tree', () {
        Checkout.head(repo: repo, strategy: {GitCheckout.force});

        expect(
          Blob.lookup(
            repo: repo,
            oid: repo.index['subdir/modified_file'].oid,
          ).content,
          '',
        );

        final newIndex = Diff.parse(patchText).applyToTree(
          repo: repo,
          tree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
        );
        expect(
          Blob.lookup(
            repo: repo,
            oid: newIndex['subdir/modified_file'].oid,
          ).content,
          'Modified content\n',
        );
      });

      test('applies hunk with provided index to tree', () {
        Checkout.head(repo: repo, strategy: {GitCheckout.force});

        expect(
          Blob.lookup(
            repo: repo,
            oid: repo.index['subdir/modified_file'].oid,
          ).content,
          '',
        );

        final diff = Diff.parse(patchText);
        final hunk = diff.patches.first.hunks.first;

        final newIndex = diff.applyToTree(
          repo: repo,
          tree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
          hunkIndex: hunk.index,
        );
        expect(
          Blob.lookup(
            repo: repo,
            oid: newIndex['subdir/modified_file'].oid,
          ).content,
          'Modified content\n',
        );
      });

      test('throws when trying to apply diff to tree and error occurs', () {
        expect(
          () => Diff.parse(patchText).applyToTree(
            repo: repo,
            tree: Tree(nullptr),
          ),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('finds similar entries', () {
      final diff = Diff.treeToTree(
        repo: repo,
        oldTree: Commit.lookup(repo: repo, oid: repo.head.target).tree,
        newTree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
      );
      expect(
        diff.deltas.firstWhere((e) => e.newFile.path == 'staged_new').status,
        GitDelta.added,
      );

      diff.findSimilar();
      expect(
        diff.deltas.firstWhere((e) => e.newFile.path == 'staged_new').status,
        GitDelta.renamed,
      );
    });

    test('throws when trying to find similar entries and error occurs', () {
      expect(() => Diff(nullptr).findSimilar(), throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to get patch Oid and error occurs', () {
      expect(() => Diff(nullptr).patchOid, throwsA(isA<LibGit2Error>()));
    });

    test('returns deltas', () {
      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);

      expect(diff.deltas[0].numberOfFiles, 1);
      expect(diff.deltas[0].status, GitDelta.deleted);
      expect(diff.deltas[0].statusChar, 'D');
      expect(diff.deltas[0].flags, isEmpty);
      expect(diff.deltas[0].similarity, 0);

      expect(diff.deltas[0].oldFile.path, indexToWorkdir[0]);
      expect(
        diff.deltas[0].oldFile.oid.sha,
        'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391',
      );
      expect(diff.deltas[0].newFile.oid.sha, '0' * 40);

      expect(diff.deltas[2].oldFile.size, 17);

      expect(
        diff.deltas[0].oldFile.flags,
        {GitDiffFlag.validId, GitDiffFlag.exists},
      );
      expect(
        diff.deltas[0].newFile.flags,
        {GitDiffFlag.validId},
      );

      expect(diff.deltas[0].oldFile.mode, GitFilemode.blob);
    });

    test('throws when trying to get delta with invalid index', () {
      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      expect(() => diff.deltas[-1], throwsA(isA<RangeError>()));
    });

    test('returns patches', () {
      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      final patches = diff.patches;

      expect(patches.length, 8);
      expect(patches.first.delta.status, GitDelta.deleted);
    });

    test('returns stats', () {
      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      final stats = diff.stats;

      expect(stats.insertions, 4);
      expect(stats.deletions, 2);
      expect(stats.filesChanged, 8);
      expect(stats.print(format: {GitDiffStats.full}, width: 80), statsPrint);
    });

    test('throws when trying to get stats and error occurs', () {
      expect(() => Diff(nullptr).stats, throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to print stats and error occurs', () {
      expect(
        () => DiffStats(nullptr).print(format: {GitDiffStats.full}, width: 80),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns patch diff string', () {
      expect(Diff.parse(patchText).patch, patchText);
    });

    test('manually releases allocated memory', () {
      final diff = Diff.parse(patchText);
      expect(() => diff.free(), returnsNormally);
    });

    test('manually releases allocated memory for DiffStats object', () {
      final stats = Diff.parse(patchText).stats;
      expect(() => stats.free(), returnsNormally);
    });

    test(
        'returns string representation of Diff, DiffDelta, DiffFile '
        ' and DiffStats objects', () {
      final diff = Diff.parse(patchText);
      final patch = Patch.fromDiff(diff: diff, index: 0);
      final stats = diff.stats;

      expect(diff.toString(), contains('Diff{'));
      expect(patch.delta.toString(), contains('DiffDelta{'));
      expect(patch.delta.oldFile.toString(), contains('DiffFile{'));
      expect(stats.toString(), contains('DiffStats{'));
    });

    test('supports value comparison', () {
      expect(Diff.parse(patchText), equals(Diff.parse(patchText)));

      final diff = Diff.parse(patchText);
      expect(diff.deltas[0], equals(diff.deltas[0]));

      final delta = diff.deltas[0];
      expect(delta.oldFile, equals(delta.oldFile));
    });
  });
}
