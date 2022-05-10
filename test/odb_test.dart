import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const commitSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const blobSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
  const blobContent = 'Feature edit\n';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Odb', () {
    test('successfully initializes', () {
      expect(repo.odb, isA<Odb>());
    });

    test('throws when trying to get odb and error occurs', () {
      expect(() => Repository(nullptr).odb, throwsA(isA<LibGit2Error>()));
    });

    test('creates new odb with no backends', () {
      expect(Odb.create(), isA<Odb>());
    });

    test('adds disk alternate', () {
      final odb = Odb.create();
      odb.addDiskAlternate(p.join(repo.path, 'objects'));

      expect(odb.contains(repo[blobSha]), true);
    });

    test('reads object', () {
      final object = repo.odb.read(repo[blobSha]);

      expect(object.oid, repo[blobSha]);
      expect(object.type, GitObject.blob);
      expect(object.data, blobContent);
      expect(object.size, 13);
      expect(object, equals(repo.odb.read(repo[blobSha])));
    });

    test('throws when trying to read object and error occurs', () {
      expect(
        () => repo.odb.read(repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test("returns list of all objects oid's in database", () {
      final odb = repo.odb;

      expect(odb.objects, isNot(isEmpty));
      expect(odb.objects.contains(repo[commitSha]), true);
    });

    test('throws when trying to get list of all objects and error occurs', () {
      final odb = repo.odb;
      Directory(p.join(repo.path, 'objects')).deleteSync(recursive: true);

      expect(
        () => odb.objects,
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('writes data', () {
      final odb = repo.odb;
      final oid = odb.write(type: GitObject.blob, data: 'testing');
      final object = odb.read(oid);

      expect(odb.contains(oid), true);
      expect(object.data, 'testing');
    });

    test('throws when trying to write with invalid object type', () {
      expect(
        () => repo.odb.write(type: GitObject.any, data: 'testing'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when trying to write alternate odb to disk', () {
      final odb = Odb.create();
      odb.addDiskAlternate(p.join(repo.path, 'objects'));

      expect(
        () => odb.write(type: GitObject.blob, data: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      expect(() => repo.odb.free(), returnsNormally);
    });

    test('manually releases allocated memory for odbObject object', () {
      final object = repo.odb.read(repo[blobSha]);
      expect(() => object.free(), returnsNormally);
    });

    test('returns string representation of OdbObject object', () {
      final object = repo.odb.read(repo[blobSha]);
      expect(object.toString(), contains('OdbObject{'));
    });

    test('supports value comparison', () {
      expect(repo.odb, equals(repo.odb));
    });
  });
}
