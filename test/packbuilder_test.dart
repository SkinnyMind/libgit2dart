import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late String packDirPath;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    packDirPath = p.join(repo.path, 'objects', 'pack');
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('PackBuilder', () {
    test('successfully initializes', () {
      final packbuilder = PackBuilder(repo);

      expect(packbuilder, isA<PackBuilder>());
      expect(packbuilder.length, 0);
    });

    test('throws when trying to initialize and error occurs', () {
      expect(
        () => PackBuilder(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds objects', () {
      final packbuilder = PackBuilder(repo);
      final odb = repo.odb;

      packbuilder.add(odb.objects[0]);
      expect(packbuilder.length, 1);

      packbuilder.add(odb.objects[1]);
      expect(packbuilder.length, 2);
    });

    test('throws when trying to add object and error occurs', () {
      expect(
        () => PackBuilder(repo).add(Oid(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds object recursively', () {
      final packbuilder = PackBuilder(repo);
      final oid = Oid.fromSHA(repo: repo, sha: 'f17d0d48');

      packbuilder.addRecursively(oid);
      expect(packbuilder.length, 3);
    });

    test('throws when trying to add object recursively and error occurs', () {
      expect(
        () => PackBuilder(repo).addRecursively(Oid(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds commit', () {
      final packbuilder = PackBuilder(repo);
      final oid = repo['f17d0d4'];

      packbuilder.addCommit(oid);
      expect(packbuilder.length, 3);
    });

    test('throws when trying to add commit with invalid oid', () {
      final oid = Oid.fromSHA(repo: repo, sha: '0' * 40);

      expect(
        () => PackBuilder(repo).addCommit(oid),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds tree', () {
      final packbuilder = PackBuilder(repo);
      final oid = repo['df2b8fc'];

      packbuilder.addTree(oid);
      expect(packbuilder.length, 2);
    });

    test('throws when trying to add tree with invalid oid', () {
      final oid = Oid.fromSHA(repo: repo, sha: '0' * 40);

      expect(
        () => PackBuilder(repo).addTree(oid),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds objects with walker', () {
      final oid = repo['f17d0d4'];
      final packbuilder = PackBuilder(repo);
      final walker = RevWalk(repo);
      walker.sorting({GitSort.none});
      walker.push(oid);

      packbuilder.addWalk(walker);
      expect(packbuilder.length, 3);
    });

    test('sets number of threads', () {
      expect(PackBuilder(repo).setThreads(1), 1);
    });

    test('returns name of packfile', () {
      final packbuilder = PackBuilder(repo);

      packbuilder.add(repo.odb.objects[0]);
      Directory(packDirPath).createSync();

      expect(packbuilder.name, isEmpty);
      packbuilder.write(null);
      expect(packbuilder.name, isNotEmpty);
    });

    test('packs with default arguments', () {
      final objectsCount = repo.odb.objects.length;
      Directory(packDirPath).createSync();

      final writtenCount = repo.pack();

      expect(writtenCount, objectsCount);
    });

    test('packs into provided path with threads set', () {
      final objectsCount = repo.odb.objects.length;
      final testPackPath = p.join(repo.workdir, 'test-pack');
      Directory(testPackPath).createSync();

      final writtenCount = repo.pack(path: testPackPath, threads: 1);

      expect(writtenCount, objectsCount);
      expect(Directory(testPackPath).listSync().isNotEmpty, true);
    });

    test('packs with provided packDelegate', () {
      Directory(packDirPath).createSync();

      void packDelegate(PackBuilder packBuilder) {
        final branches = repo.branchesLocal;
        for (final branch in branches) {
          final ref = Reference.lookup(
            repo: repo,
            name: 'refs/heads/${branch.name}',
          );
          for (final commit in repo.log(oid: ref.target)) {
            packBuilder.addRecursively(commit.oid);
          }
        }
      }

      final writtenCount = repo.pack(packDelegate: packDelegate);
      expect(writtenCount, 18);
    });

    test('throws when trying to write pack into invalid path', () {
      expect(
        () => PackBuilder(repo).write('invalid/path'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      expect(() => PackBuilder(repo).free(), returnsNormally);
    });

    test('returns string representation of PackBuilder object', () {
      expect(PackBuilder(repo).toString(), contains('PackBuilder{'));
    });
  });
}
