import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const oldBlob = '';
  const newBlob = 'Feature edit\n';
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
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
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
      final patch = Patch.create(
        a: oldBlob,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.size(), 14);
      expect(patch.text, blobPatch);

      patch.free();
    });

    test('creates from one buffer (add)', () {
      final patch = Patch.create(
        a: null,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('creates from one buffer (delete)', () {
      final patch = Patch.create(
        a: oldBlob,
        b: null,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('creates from blobs', () {
      final a = repo.lookupBlob(oldBlobOid);
      final b = repo.lookupBlob(newBlobOid);
      final patch = Patch.create(
        a: a,
        b: b,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatch);

      patch.free();
    });

    test('creates from one blob (add)', () {
      final b = repo.lookupBlob(newBlobOid);
      final patch = Patch.create(
        a: null,
        b: b,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('creates from one blob (delete)', () {
      final a = repo.lookupBlob(oldBlobOid);
      final patch = Patch.create(
        a: a,
        b: null,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('creates from blob and buffer', () {
      final a = repo.lookupBlob(oldBlobOid);
      final patch = Patch.create(
        a: a,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatch);

      patch.free();
    });

    test('throws when argument is not Blob or String', () {
      final commit = repo.lookupCommit(
        repo['fc38877b2552ab554752d9a77e1f48f738cca79b'],
      );
      expect(
        () => Patch.create(
          a: commit,
          b: null,
          aPath: 'file',
          bPath: 'file',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Patch.create(
          a: null,
          b: commit,
          aPath: 'file',
          bPath: 'file',
        ),
        throwsA(isA<ArgumentError>()),
      );

      commit.free();
    });

    test('throws when trying to create from diff and error occurs', () {
      expect(
        () => Patch.fromDiff(diff: Diff(nullptr), index: 0),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to text of patch and error occurs', () {
      expect(() => Patch(nullptr).text, throwsA(isA<LibGit2Error>()));
    });

    test('returns string representation of Patch object', () {
      final patch = Patch.create(
        a: oldBlob,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.toString(), contains('Patch{'));

      patch.free();
    });
  });
}
