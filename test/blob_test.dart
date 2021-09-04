import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Blob blob;
  final tmpDir = '${Directory.systemTemp.path}/blob_testrepo/';
  const blobSHA = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
  const blobContent = 'Feature edit\n';
  const newBlobContent = 'New blob\n';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
    blob = Blob.lookup(repo, blobSHA);
  });

  tearDown(() async {
    blob.free();
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
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
      final oid = Blob.create(repo, newBlobContent);
      final newBlob = Blob.lookup(repo, oid.sha);

      expect(newBlob.id.sha, '18fdaeef018e57a92bcad2d4a35b577f34089af6');
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 9);
      expect(newBlob.content, newBlobContent);

      newBlob.free();
    });

    test('successfully creates new blob from file at provided relative path',
        () {
      final oid = Blob.createFromWorkdir(repo, 'feature_file');
      final newBlob = Blob.lookup(repo, oid.sha);

      expect(newBlob.id.sha, blobSHA);
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 13);
      expect(newBlob.content, blobContent);

      newBlob.free();
    });

    test('throws when creating new blob from invalid path', () {
      expect(
        () => Blob.createFromWorkdir(repo, 'invalid/path.txt'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
        'throws when creating new blob from path that is outside of working directory',
        () {
      final outsideFile =
          File('${Directory.current.absolute.path}/test/blob_test.dart');
      expect(
        () => Blob.createFromWorkdir(repo, outsideFile.path),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully creates new blob from file at provided path', () {
      final outsideFile =
          File('${Directory.current.absolute.path}/test/blob_test.dart');
      final oid = Blob.createFromDisk(repo, outsideFile.path);
      final newBlob = Blob.lookup(repo, oid.sha);

      expect(newBlob, isA<Blob>());
      expect(newBlob.isBinary, false);

      newBlob.free();
    });
  });
}
