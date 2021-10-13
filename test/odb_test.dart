import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const commitSha = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';
  const blobSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';
  const blobContent = 'Feature edit\n';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Odb', () {
    test('successfully initializes', () {
      final odb = repo.odb;
      expect(odb, isA<Odb>());
      odb.free();
    });

    test('successfully creates new odb with no backends', () {
      final odb = Odb.create();
      expect(odb, isA<Odb>());
      odb.free();
    });

    test('successfully adds disk alternate', () {
      final oid = Oid.fromSHA(repo: repo, sha: blobSha);
      final odb = Odb.create();
      odb.addDiskAlternate('${repo.workdir}.git/objects/');

      expect(odb.contains(oid), true);

      odb.free();
    });

    test('successfully reads object', () {
      final oid = Oid.fromSHA(repo: repo, sha: blobSha);
      final odb = repo.odb;
      final object = odb.read(oid);

      expect(object.oid, oid);
      expect(object.type, GitObject.blob);
      expect(object.data, blobContent);
      expect(object.size, 13);

      object.free();
      odb.free();
    });

    test('returns list of all objects oid\'s in database', () {
      final oid = Oid.fromSHA(repo: repo, sha: commitSha);
      final odb = repo.odb;

      expect(odb.objects, isNot(isEmpty));
      expect(odb.objects.contains(oid), true);

      odb.free();
    });

    test('finds object by short oid', () {
      final oid = Oid.fromSHA(
        repo: repo,
        sha: commitSha.substring(0, 5),
      );
      expect(oid.sha, commitSha);
    });

    test('successfully writes data', () {
      final odb = repo.odb;
      final oid = odb.write(type: GitObject.blob, data: 'testing');
      final object = odb.read(oid);

      expect(odb.contains(oid), true);
      expect(object.data, 'testing');

      object.free();
      odb.free();
    });

    test('throws when trying to write with invalid object type', () {
      final odb = repo.odb;
      expect(
        () => odb.write(type: GitObject.any, data: 'testing'),
        throwsA(isA<ArgumentError>()),
      );

      odb.free();
    });
  });
}
