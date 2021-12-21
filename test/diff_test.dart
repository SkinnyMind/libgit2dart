import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
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
    tmpDir = setupRepo(Directory('test/assets/dirty_repo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Diff', () {
    test('successfully returns diff between index and workdir', () {
      final index = repo.index;
      final diff = repo.diff();

      expect(diff.length, 8);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToWorkdir[i]);
      }

      diff.free();
      index.free();
    });

    test('successfully returns diff between index and tree', () {
      final index = repo.index;
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree = commit.tree;
      final diff1 = index.diffToTree(tree: tree);
      final diff2 = tree.diffToIndex(index: index);

      expect(diff1.length, 8);
      for (var i = 0; i < diff1.deltas.length; i++) {
        expect(diff1.deltas[i].newFile.path, indexToTree[i]);
      }

      expect(diff2.length, 8);
      for (var i = 0; i < diff2.deltas.length; i++) {
        expect(diff2.deltas[i].newFile.path, indexToTree[i]);
      }

      commit.free();
      head.free();
      tree.free();
      diff1.free();
      diff2.free();
      index.free();
    });

    test('successfully returns diff between tree and workdir', () {
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree = commit.tree;
      final diff = repo.diff(a: tree);

      expect(diff.length, 9);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToWorkdir[i]);
      }

      commit.free();
      head.free();
      tree.free();
      diff.free();
    });

    test('throws when trying to diff between tree and workdir and error occurs',
        () {
      final nullRepo = Repository(nullptr);
      final nullTree = Tree(nullptr);
      expect(() => nullRepo.diff(a: nullTree), throwsA(isA<LibGit2Error>()));
    });

    test('successfully returns diff between tree and index', () {
      final index = repo.index;
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree = commit.tree;
      final diff = repo.diff(a: tree, cached: true);

      expect(diff.length, 8);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, indexToTree[i]);
      }

      commit.free();
      head.free();
      tree.free();
      diff.free();
      index.free();
    });

    test('successfully returns diff between tree and tree', () {
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree1 = commit.tree;
      final tree2 = repo.lookupTree(repo['b85d53c']);
      final diff = repo.diff(a: tree1, b: tree2);

      expect(diff.length, 10);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToTree[i]);
      }

      commit.free();
      head.free();
      tree1.free();
      tree2.free();
      diff.free();
    });

    test('throws when trying to diff between tree and tree and error occurs',
        () {
      final nullRepo = Repository(nullptr);
      final nullTree = Tree(nullptr);
      expect(
        () => nullRepo.diff(a: nullTree, b: nullTree),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to diff between null and tree', () {
      final tree = repo.lookupTree(repo['b85d53c']);
      expect(() => repo.diff(b: tree), throwsA(isA<ArgumentError>()));
      tree.free();
    });

    test('returns diff between tree and workdir with index', () {
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree = commit.tree;

      final diff = Diff.treeToWorkdirWithIndex(repo: repo, tree: tree);
      expect(diff.length, 11);
      for (var i = 0; i < diff.deltas.length; i++) {
        expect(diff.deltas[i].newFile.path, treeToWorkdirWithIndex[i]);
      }

      diff.free();
      tree.free();
      commit.free();
      head.free();
    });

    test('successfully merges diffs', () {
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final tree1 = commit.tree;
      final tree2 = repo.lookupTree(
        repo['b85d53c9236e89aff2b62558adaa885fd1d6ff1c'],
      );
      final diff1 = tree1.diffToTree(tree: tree2);
      final diff2 = tree1.diffToWorkdir();

      expect(diff1.length, 10);
      expect(diff2.length, 9);

      diff1.merge(diff2);
      expect(diff1.length, 11);

      commit.free();
      head.free();
      tree1.free();
      tree2.free();
      diff1.free();
      diff2.free();
    });

    test('successfully parses provided diff', () {
      final diff = Diff.parse(patchText);
      final stats = diff.stats;

      expect(diff.length, 1);
      expect(stats.filesChanged, 1);
      expect(stats.insertions, 1);
      expect(diff.patchOid.sha, '699556913185bc38632ae20a49d5c18b9233335e');

      stats.free();
      diff.free();
    });

    group('apply', () {
      test('checks if diff can be applied to repository', () {
        final diff1 = repo.diff();
        expect(
          repo.applies(diff: diff1, location: GitApplyLocation.both),
          false,
        );

        final diff2 = Diff.parse(patchText);
        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        expect(
          repo.applies(diff: diff2, location: GitApplyLocation.both),
          true,
        );

        diff1.free();
        diff2.free();
      });

      test('checks if hunk with provided index can be applied to repository',
          () {
        final diff1 = repo.diff();
        expect(
          repo.applies(diff: diff1, location: GitApplyLocation.both),
          false,
        );

        final diff2 = Diff.parse(patchText);
        final hunk = diff2.patches.first.hunks.first;
        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        expect(
          repo.applies(
            diff: diff2,
            hunkIndex: hunk.index,
            location: GitApplyLocation.both,
          ),
          true,
        );

        diff1.free();
        diff2.free();
      });

      test('successfully applies diff to repository', () {
        final diff = Diff.parse(patchText);
        final file = File('${tmpDir.path}/subdir/modified_file');

        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        expect(file.readAsStringSync(), '');

        repo.apply(diff: diff);
        expect(file.readAsStringSync(), 'Modified content\n');

        diff.free();
      });

      test('throws when trying to apply diff and error occurs', () {
        final nullDiff = Diff(nullptr);
        expect(() => repo.apply(diff: nullDiff), throwsA(isA<LibGit2Error>()));
      });

      test('successfully creates patch from entry index in diff', () {
        final diff = Diff.parse(patchText);
        final patch = Patch.fromDiff(diff: diff, index: 0);

        expect(diff.length, 1);
        expect(patch.text, patchText);

        patch.free();
        diff.free();
      });

      test('successfully applies hunk with provided index to repository', () {
        final diff = Diff.parse(patchText);
        final hunk = diff.patches.first.hunks.first;
        final file = File('${tmpDir.path}/subdir/modified_file');

        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        expect(file.readAsStringSync(), '');

        repo.apply(diff: diff, hunkIndex: hunk.index);
        expect(file.readAsStringSync(), 'Modified content\n');

        diff.free();
      });

      test('successfully applies diff to tree', () {
        final diff = Diff.parse(patchText);

        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        final head = repo.head;
        final commit = repo.lookupCommit(head.target);
        final tree = commit.tree;

        final oldIndex = repo.index;
        final oldBlob = repo.lookupBlob(oldIndex['subdir/modified_file'].oid);
        expect(oldBlob.content, '');

        final newIndex = repo.applyToTree(diff: diff, tree: tree);
        final newBlob = repo.lookupBlob(newIndex['subdir/modified_file'].oid);
        expect(newBlob.content, 'Modified content\n');

        oldBlob.free();
        newBlob.free();
        oldIndex.free();
        newIndex.free();
        tree.free();
        commit.free();
        head.free();
        diff.free();
      });

      test('successfully applies hunk with provided index to tree', () {
        final diff = Diff.parse(patchText);
        final hunk = diff.patches.first.hunks.first;

        repo.checkout(refName: 'HEAD', strategy: {GitCheckout.force});
        final head = repo.head;
        final commit = repo.lookupCommit(head.target);
        final tree = commit.tree;

        final oldIndex = repo.index;
        final oldBlob = repo.lookupBlob(oldIndex['subdir/modified_file'].oid);
        expect(oldBlob.content, '');

        final newIndex = repo.applyToTree(
          diff: diff,
          tree: tree,
          hunkIndex: hunk.index,
        );
        final newBlob = repo.lookupBlob(newIndex['subdir/modified_file'].oid);
        expect(newBlob.content, 'Modified content\n');

        oldBlob.free();
        newBlob.free();
        oldIndex.free();
        newIndex.free();
        tree.free();
        commit.free();
        head.free();
        diff.free();
      });

      test('throws when trying to apply diff to tree and error occurs', () {
        final diff = Diff.parse(patchText);
        expect(
          () => repo.applyToTree(diff: diff, tree: Tree(nullptr)),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('successfully finds similar entries', () {
      final index = repo.index;
      final head = repo.head;
      final commit = repo.lookupCommit(head.target);
      final oldTree = commit.tree;
      final newTree = repo.lookupTree(index.writeTree());

      final diff = oldTree.diffToTree(tree: newTree);
      expect(
        diff.deltas.singleWhere((e) => e.newFile.path == 'staged_new').status,
        GitDelta.added,
      );

      diff.findSimilar();
      expect(
        diff.deltas.singleWhere((e) => e.newFile.path == 'staged_new').status,
        GitDelta.renamed,
      );

      commit.free();
      head.free();
      diff.free();
      index.free();
      oldTree.free();
      newTree.free();
    });

    test('throws when trying to find similar entries and error occurs', () {
      final nullDiff = Diff(nullptr);
      expect(() => nullDiff.findSimilar(), throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to get patch Oid and error occurs', () {
      final nullDiff = Diff(nullptr);
      expect(() => nullDiff.patchOid, throwsA(isA<LibGit2Error>()));
    });

    test('returns deltas', () {
      final index = repo.index;
      final diff = index.diffToWorkdir();

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

      diff.free();
      index.free();
    });

    test('throws when trying to get delta with invalid index', () {
      final index = repo.index;
      final diff = index.diffToWorkdir();

      expect(() => diff.deltas[-1], throwsA(isA<RangeError>()));

      diff.free();
      index.free();
    });

    test('returns patches', () {
      final index = repo.index;
      final diff = index.diffToWorkdir();
      final patches = diff.patches;

      expect(patches.length, 8);
      expect(patches.first.delta.status, GitDelta.deleted);

      for (final p in patches) {
        p.free();
      }
      diff.free();
      index.free();
    });

    test('returns stats', () {
      final index = repo.index;
      final diff = index.diffToWorkdir();
      final stats = diff.stats;

      expect(stats.insertions, 4);
      expect(stats.deletions, 2);
      expect(stats.filesChanged, 8);
      expect(stats.print(format: {GitDiffStats.full}, width: 80), statsPrint);

      stats.free();
      diff.free();
      index.free();
    });

    test('throws when trying to get stats and error occurs', () {
      final nullDiff = Diff(nullptr);
      expect(() => nullDiff.stats, throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to print stats and error occurs', () {
      final nullStats = DiffStats(nullptr);
      expect(
        () => nullStats.print(format: {GitDiffStats.full}, width: 80),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns patch diff string', () {
      final diff = Diff.parse(patchText);

      expect(diff.patch, patchText);

      diff.free();
    });

    test('returns hunks in a patch', () {
      final diff = Diff.parse(patchText);
      final patch = Patch.fromDiff(diff: diff, index: 0);
      final hunk = patch.hunks[0];

      expect(patch.hunks.length, 1);
      expect(hunk.linesCount, 1);
      expect(hunk.oldStart, 0);
      expect(hunk.oldLines, 0);
      expect(hunk.newStart, 1);
      expect(hunk.newLines, 1);
      expect(hunk.header, '@@ -0,0 +1 @@\n');

      patch.free();
      diff.free();
    });

    test('returns lines in a hunk', () {
      final diff = Diff.parse(patchText);
      final patch = Patch.fromDiff(diff: diff, index: 0);
      final hunk = patch.hunks[0];
      final line = hunk.lines[0];

      expect(hunk.lines.length, 1);
      expect(line.origin, GitDiffLine.addition);
      expect(line.oldLineNumber, -1);
      expect(line.newLineNumber, 1);
      expect(line.numLines, 1);
      expect(line.contentOffset, 155);
      expect(line.content, 'Modified content\n');

      patch.free();
      diff.free();
    });

    test(
        'returns string representation of Diff, DiffDelta, DiffFile, '
        'DiffHunk, DiffLine and DiffStats objects', () {
      final diff = Diff.parse(patchText);
      final patch = Patch.fromDiff(diff: diff, index: 0);
      final stats = diff.stats;

      expect(diff.toString(), contains('Diff{'));
      expect(patch.delta.toString(), contains('DiffDelta{'));
      expect(patch.delta.oldFile.toString(), contains('DiffFile{'));
      expect(patch.hunks[0].toString(), contains('DiffHunk{'));
      expect(patch.hunks[0].lines[0].toString(), contains('DiffLine{'));
      expect(stats.toString(), contains('DiffStats{'));

      stats.free();
      patch.free();
      diff.free();
    });
  });
}
