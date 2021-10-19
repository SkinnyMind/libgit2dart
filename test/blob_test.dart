import 'dart:ffi';
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

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    blob = repo.lookupBlob(repo[blobSHA]);
  });

  tearDown(() {
    blob.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Blob', () {
    test('successfully initializes blob from provided Oid', () {
      expect(blob, isA<Blob>());
    });

    test('throws when trying to lookup with invalid oid', () {
      expect(
        () => repo.lookupBlob(repo['0' * 40]),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            'odb: cannot read object: null OID cannot exist',
          ),
        ),
      );
    });

    test('returns correct values', () {
      expect(blob.oid.sha, blobSHA);
      expect(blob.isBinary, false);
      expect(blob.size, 13);
      expect(blob.content, blobContent);
    });

    test('successfully creates new blob', () {
      final oid = repo.createBlob(newBlobContent);
      final newBlob = repo.lookupBlob(oid);

      expect(newBlob.oid.sha, '18fdaeef018e57a92bcad2d4a35b577f34089af6');
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 9);
      expect(newBlob.content, newBlobContent);

      newBlob.free();
    });

    test('throws when trying to create new blob and error occurs', () {
      final nullRepo = Repository(nullptr);
      expect(
        () => Blob.create(repo: nullRepo, content: ''),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "invalid argument: 'repo'",
          ),
        ),
      );
    });

    test('successfully creates new blob from file at provided relative path',
        () {
      final oid = repo.createBlobFromWorkdir('feature_file');
      final newBlob = repo.lookupBlob(oid);

      expect(newBlob.oid.sha, blobSHA);
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 13);
      expect(newBlob.content, blobContent);

      newBlob.free();
    });

    test('throws when creating new blob from invalid path', () {
      expect(
        () => repo.createBlobFromWorkdir('invalid/path.txt'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "could not find '${repo.workdir}invalid/path.txt' to stat: No such file or directory",
          ),
        ),
      );
    });

    test('successfully creates new blob from file at provided path', () {
      final outsideFile =
          File('${Directory.current.absolute.path}/test/blob_test.dart');
      final oid = repo.createBlobFromDisk(outsideFile.path);
      final newBlob = repo.lookupBlob(oid);

      expect(newBlob, isA<Blob>());
      expect(newBlob.isBinary, false);

      newBlob.free();
    });

    test('throws when trying to create from invalid path', () {
      expect(
        () => repo.createBlobFromDisk('invalid.file'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to resolve path 'invalid.file': No such file or directory",
          ),
        ),
      );
    });

    group('diff', () {
      const path = 'feature_file';
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
        final a = repo.lookupBlob(
          repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'],
        );
        final b = repo.lookupBlob(
          repo['9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc'],
        );
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
        final _blob = repo.lookupBlob(
          repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'],
        );
        final patch = _blob.diff(
          newBlob: null,
          oldAsPath: path,
          newAsPath: path,
        );

        expect(patch.text, blobPatchDelete);

        patch.free();
      });

      test('successfully creates from blob and buffer', () {
        final _blob = repo.lookupBlob(
          repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'],
        );

        final patch = _blob.diffToBuffer(
          buffer: 'Feature edit\n',
          oldAsPath: path,
        );
        expect(patch.text, blobPatch);

        patch.free();
      });

      test('successfully creates from blob and buffer (delete)', () {
        final a = repo.lookupBlob(
          repo['e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'],
        );
        final patch = Patch.create(
          a: a,
          b: null,
          aPath: path,
          bPath: path,
        );

        expect(patch.text, blobPatchDelete);

        patch.free();
      });
    });

    test('returns string representation of Blob object', () {
      expect(blob.toString(), contains('Blob{'));
    });
  });
}
