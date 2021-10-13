import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
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
    tmpDir = setupRepo(Directory('test/assets/dirtyrepo/'));
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
      final diff = index.diffToTree(tree: tree);

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
      final tree2 = repo.lookupTree(
        repo['b85d53c9236e89aff2b62558adaa885fd1d6ff1c'],
      );
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
      expect(diff.patchId.sha, '699556913185bc38632ae20a49d5c18b9233335e');

      stats.free();
      diff.free();
    });

    test(
        'checks if diff can be applied to repository and successfully applies it',
        () {
      final diff = Diff.parse(patchText);
      final file = File('${tmpDir.path}/subdir/modified_file');

      repo.reset(
        oid: repo['a763aa560953e7cfb87ccbc2f536d665aa4dff22'],
        resetType: GitReset.hard,
      );
      expect(file.readAsStringSync(), '');

      expect(repo.applies(diff), true);
      repo.apply(diff);
      expect(file.readAsStringSync(), 'Modified content\n');

      diff.free();
    });

    test('successfully creates patch from entry index in diff', () {
      final diff = Diff.parse(patchText);
      final patch = Patch.fromDiff(diff: diff, index: 0);

      expect(diff.length, 1);
      expect(patch.text, patchText);

      patch.free();
      diff.free();
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
      expect(
        diff.deltas[0].newFile.oid.sha,
        '0000000000000000000000000000000000000000',
      );

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

    test('returns deltas', () {
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
  });
}
