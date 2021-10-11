import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const oldBlob = '';
  const newBlob = 'Feature edit\n';
  late Oid oldBlobID;
  late Oid newBlobID;
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
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    oldBlobID = repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'];
    newBlobID = repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'];
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Patch', () {
    test('successfully creates from buffers', () {
      final patch = Patch.createFrom(
        a: oldBlob,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.size(), 14);
      expect(patch.text, blobPatch);

      patch.free();
    });

    test('successfully creates from one buffer (add)', () {
      final patch = Patch.createFrom(
        a: null,
        b: newBlob,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('successfully creates from one buffer (delete)', () {
      final patch = Patch.createFrom(
        a: oldBlob,
        b: null,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('successfully creates from blobs', () {
      final a = repo.lookupBlob(oldBlobID);
      final b = repo.lookupBlob(newBlobID);
      final patch = Patch.createFrom(
        a: a,
        b: b,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatch);

      patch.free();
    });

    test('successfully creates from one blob (add)', () {
      final b = repo.lookupBlob(newBlobID);
      final patch = Patch.createFrom(
        a: null,
        b: b,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchAdd);

      patch.free();
    });

    test('successfully creates from one blob (delete)', () {
      final a = repo.lookupBlob(oldBlobID);
      final patch = Patch.createFrom(
        a: a,
        b: null,
        aPath: path,
        bPath: path,
      );

      expect(patch.text, blobPatchDelete);

      patch.free();
    });

    test('successfully creates from blob and buffer', () {
      final a = repo.lookupBlob(oldBlobID);
      final patch = Patch.createFrom(
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
        () => Patch.createFrom(
          a: commit,
          b: null,
          aPath: 'file',
          bPath: 'file',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Patch.createFrom(
          a: null,
          b: commit,
          aPath: 'file',
          bPath: 'file',
        ),
        throwsA(isA<ArgumentError>()),
      );

      commit.free();
    });
  });
}
