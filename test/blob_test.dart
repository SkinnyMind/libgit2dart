import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Blob blob;
  late Directory tmpDir;
  const blobSHA = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
  const blobContent = 'Feature edit\n';
  const newBlobContent = 'New blob\n';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    blob = Blob.lookup(repo: repo, sha: blobSHA);
  });

  tearDown(() async {
    blob.free();
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Blob', () {
    test('successfully initializes blob from provided Oid', () {
      expect(blob, isA<Blob>());
    });

    test('returns correct values', () {
      expect(blob.id.sha, blobSHA);
      expect(blob.isBinary, false);
      expect(blob.size, 13);
      expect(blob.content, blobContent);
    });

    test('successfully creates new blob', () {
      final oid = Blob.create(repo: repo, content: newBlobContent);
      final newBlob = Blob.lookup(repo: repo, sha: oid.sha);

      expect(newBlob.id.sha, '18fdaeef018e57a92bcad2d4a35b577f34089af6');
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 9);
      expect(newBlob.content, newBlobContent);

      newBlob.free();
    });

    test('successfully creates new blob from file at provided relative path',
        () {
      final oid = Blob.createFromWorkdir(
        repo: repo,
        relativePath: 'feature_file',
      );
      final newBlob = Blob.lookup(repo: repo, sha: oid.sha);

      expect(newBlob.id.sha, blobSHA);
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 13);
      expect(newBlob.content, blobContent);

      newBlob.free();
    });

    test('throws when creating new blob from invalid path', () {
      expect(
        () => Blob.createFromWorkdir(
          repo: repo,
          relativePath: 'invalid/path.txt',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
        'throws when creating new blob from path that is outside of working directory',
        () {
      final outsideFile =
          File('${Directory.current.absolute.path}/test/blob_test.dart');
      expect(
        () => Blob.createFromWorkdir(
          repo: repo,
          relativePath: outsideFile.path,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully creates new blob from file at provided path', () {
      final outsideFile =
          File('${Directory.current.absolute.path}/test/blob_test.dart');
      final oid = Blob.createFromDisk(repo: repo, path: outsideFile.path);
      final newBlob = Blob.lookup(repo: repo, sha: oid.sha);

      expect(newBlob, isA<Blob>());
      expect(newBlob.isBinary, false);

      newBlob.free();
    });

    group('diff', () {
      const path = 'feature_file';
      const oldBlobSha = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391';
      const newBlobSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
      const blobPatch = """
diff --git a/feature_file b/feature_file
index e69de29..9c78c21 100644
--- a/feature_file
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
      test('successfully creates from blobs', () {
        final a = repo[oldBlobSha] as Blob;
        final b = repo[newBlobSha] as Blob;
        final patch = repo.diffBlobs(
          a: a,
          b: b,
          aPath: path,
          bPath: path,
        );

        expect(patch.text, blobPatch);

        patch.free();
      });

      test('successfully creates from one blob (delete)', () {
        final a = repo[oldBlobSha] as Blob;
        final patch = a.diff(
          newBlob: null,
          oldAsPath: path,
          newAsPath: path,
        );

        expect(patch.text, blobPatchDelete);

        patch.free();
      });

      test('successfully creates from blob and buffer', () {
        final a = repo[oldBlobSha] as Blob;
        final patch = Patch.createFrom(
          a: a,
          b: 'Feature edit\n',
          aPath: path,
          bPath: path,
        );

        expect(patch.text, blobPatch);

        patch.free();
      });

      test('successfully creates from blob and buffer (delete)', () {
        final a = repo[oldBlobSha] as Blob;
        final patch = Patch.createFrom(
          a: a,
          b: null,
          aPath: path,
          bPath: path,
        );

        expect(patch.text, blobPatchDelete);

        patch.free();
      });
    });
  });
}
