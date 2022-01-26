import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const oldBuffer = '';
  const newBuffer = 'Feature edit\n';
  late Oid oldBlobOid;
  late Oid newBlobOid;
  const path = 'feature_file';
  const blobPatch = """
diff --git a/feature_file b/feature_file
index e69de29..9c78c21 100644
--- a/feature_file
+++ b/feature_file
@@ -0,0 +1 @@
+Feature edit
""";

  const blobPatchAdd = """
diff --git a/feature_file b/feature_file
new file mode 100644
index 0000000..9c78c21
--- /dev/null
+++ b/feature_file
@@ -0,0 +1 @@
+Feature edit
""";

  const blobPatchDelete = """
diff --git a/feature_file b/feature_file
deleted file mode 100644
index e69de29..0000000
--- a/feature_file
+++ /dev/null
""";

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    oldBlobOid = repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'];
    newBlobOid = repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'];
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Patch', () {
    test('creates from buffers', () {
      final patch = Patch.fromBuffers(
        oldBuffer: oldBuffer,
        newBuffer: newBuffer,
        oldBufferPath: path,
        newBufferPath: path,
      );

      expect(patch.size(), 14);
      expect(patch.text, blobPatch);

      patch.free();
    });

    test('creates from one buffer (add)', () {
      final patch = Patch.fromBuffers(
        oldBuffer: null,
        newBuffer: newBuffer,
        oldBufferPath: path,
        newBufferPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('creates from one buffer (delete)', () {
      final patch = Patch.fromBuffers(
        oldBuffer: oldBuffer,
        newBuffer: null,
        oldBufferPath: path,
        newBufferPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('creates from blobs', () {
      final oldBlob = Blob.lookup(repo: repo, oid: oldBlobOid);
      final newBlob = Blob.lookup(repo: repo, oid: newBlobOid);
      final patch = Patch.fromBlobs(
        oldBlob: oldBlob,
        newBlob: newBlob,
        oldBlobPath: path,
        newBlobPath: path,
      );

      expect(patch.text, blobPatch);

      patch.free();
    });

    test('creates from one blob (add)', () {
      final newBlob = Blob.lookup(repo: repo, oid: newBlobOid);
      final patch = Patch.fromBlobs(
        oldBlob: null,
        newBlob: newBlob,
        oldBlobPath: path,
        newBlobPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('creates from one blob (delete)', () {
      final oldBlob = Blob.lookup(repo: repo, oid: oldBlobOid);
      final patch = Patch.fromBlobs(
        oldBlob: oldBlob,
        newBlob: null,
        oldBlobPath: path,
        newBlobPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('creates from blob and buffer', () {
      final blob = Blob.lookup(repo: repo, oid: oldBlobOid);
      final patch = Patch.fromBlobAndBuffer(
        blob: blob,
        buffer: newBuffer,
        blobPath: path,
        bufferPath: path,
      );

      expect(patch.text, blobPatch);

      patch.free();
    });

    test('creates from empty blob and buffer', () {
      final patch = Patch.fromBlobAndBuffer(
        blob: null,
        buffer: newBuffer,
        blobPath: path,
        bufferPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('throws when trying to create from diff and error occurs', () {
      expect(
        () => Patch.fromDiff(diff: Diff(nullptr), index: 0),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to get text of patch and error occurs', () {
      expect(() => Patch(nullptr).text, throwsA(isA<LibGit2Error>()));
    });

    test('returns line counts of each type in a patch', () {
      final patch = Patch.fromBuffers(
        oldBuffer: oldBuffer,
        newBuffer: newBuffer,
        oldBufferPath: path,
        newBufferPath: path,
      );

      final stats = patch.stats;
      expect(stats.context, equals(0));
      expect(stats.insertions, equals(1));
      expect(stats.deletions, equals(0));
      expect(stats.toString(), contains('PatchStats{'));

      patch.free();
    });

    test('returns string representation of Patch object', () {
      final patch = Patch.fromBuffers(
        oldBuffer: oldBuffer,
        newBuffer: newBuffer,
        oldBufferPath: path,
        newBufferPath: path,
      );

      expect(patch.toString(), contains('Patch{'));

      patch.free();
    });
  });
}
