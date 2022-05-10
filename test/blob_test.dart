import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const blobSHA = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
  const blobContent = 'Feature edit\n';
  const newBlobContent = 'New blob\n';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'attributes_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Blob', () {
    test('lookups blob with provided oid', () {
      expect(Blob.lookup(repo: repo, oid: repo[blobSHA]), isA<Blob>());
    });

    test('throws when trying to lookup with invalid oid', () {
      expect(
        () => Blob.lookup(repo: repo, oid: repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns correct values', () {
      final blob = Blob.lookup(repo: repo, oid: repo[blobSHA]);

      expect(blob.oid.sha, blobSHA);
      expect(blob.isBinary, false);
      expect(blob.size, 13);
      expect(blob.content, blobContent);
    });

    test('creates new blob with provided content', () {
      final oid = Blob.create(repo: repo, content: newBlobContent);
      final newBlob = Blob.lookup(repo: repo, oid: oid);

      expect(newBlob.oid.sha, '18fdaeef018e57a92bcad2d4a35b577f34089af6');
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 9);
      expect(newBlob.content, newBlobContent);
    });

    test('throws when trying to create new blob and error occurs', () {
      expect(
        () => Blob.create(repo: Repository(nullptr), content: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates new blob from file at provided relative path', () {
      final oid = Blob.createFromWorkdir(
        repo: repo,
        relativePath: 'feature_file',
      );
      final newBlob = Blob.lookup(repo: repo, oid: oid);

      expect(newBlob.oid.sha, blobSHA);
      expect(newBlob.isBinary, false);
      expect(newBlob.size, 13);
      expect(newBlob.content, blobContent);
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

    test('creates new blob from file at provided path', () {
      final outsideFile = File(
        p.join(Directory.current.absolute.path, 'test', 'blob_test.dart'),
      );
      final oid = Blob.createFromDisk(repo: repo, path: outsideFile.path);
      final newBlob = Blob.lookup(repo: repo, oid: oid);

      expect(newBlob, isA<Blob>());
      expect(newBlob.isBinary, false);
    });

    test('throws when trying to create from invalid path', () {
      expect(
        () => Blob.createFromDisk(repo: repo, path: 'invalid.file'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('duplicates blob', () {
      final blob = Blob.lookup(repo: repo, oid: repo[blobSHA]);
      final dupBlob = blob.duplicate();

      expect(blob.oid.sha, dupBlob.oid.sha);
    });

    test('filters content of a blob', () {
      final blobOid = Blob.create(repo: repo, content: 'clrf\nclrf\n');
      final blob = Blob.lookup(repo: repo, oid: blobOid);

      expect(blob.filterContent(asPath: 'file.crlf'), 'clrf\r\nclrf\r\n');
    });

    test('filters content of a blob with provided commit for attributes', () {
      Checkout.reference(repo: repo, name: 'refs/tags/v0.2');

      final blobOid = Blob.create(repo: repo, content: 'clrf\nclrf\n');
      final blob = Blob.lookup(repo: repo, oid: blobOid);

      final commit = Commit.lookup(
        repo: repo,
        oid: repo['d2f3abc9324a22a9f80fec2c131ec43c93430618'],
      );

      expect(
        blob.filterContent(
          asPath: 'file.crlf',
          flags: {GitBlobFilter.attributesFromCommit},
          attributesCommit: commit,
        ),
        'clrf\r\nclrf\r\n',
      );
    });

    test('throws when trying to filter content of a blob and error occurs', () {
      expect(
        () => Blob(nullptr).filterContent(asPath: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final blob = Blob.lookup(repo: repo, oid: repo[blobSHA]);
      expect(() => blob.free(), returnsNormally);
    });

    test('returns string representation of Blob object', () {
      final blob = Blob.lookup(repo: repo, oid: repo[blobSHA]);
      expect(blob.toString(), contains('Blob{'));
    });

    test('supports value comparison', () {
      expect(
        Blob.lookup(repo: repo, oid: repo[blobSHA]),
        equals(Blob.lookup(repo: repo, oid: repo[blobSHA])),
      );
    });
  });
}
