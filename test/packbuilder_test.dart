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

      packbuilder.free();
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

      odb.free();
      packbuilder.free();
    });

    test('throws when trying to add object and error occurs', () {
      final packbuilder = PackBuilder(repo);

      expect(
        () => packbuilder.add(Oid(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );

      packbuilder.free();
    });

    test('adds object recursively', () {
      final packbuilder = PackBuilder(repo);
      final oid = Oid.fromSHA(repo: repo, sha: 'f17d0d48');

      packbuilder.addRecursively(oid);
      expect(packbuilder.length, 3);

      packbuilder.free();
    });

    test('throws when trying to add object recursively and error occurs', () {
      final packbuilder = PackBuilder(repo);

      expect(
        () => packbuilder.addRecursively(Oid(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );

      packbuilder.free();
    });

    test('adds commit', () {
      final packbuilder = PackBuilder(repo);
      final oid = repo['f17d0d4'];

      packbuilder.addCommit(oid);
      expect(packbuilder.length, 3);

      packbuilder.free();
    });

    test('throws when trying to add commit with invalid oid', () {
      final packbuilder = PackBuilder(repo);
      final oid = Oid.fromSHA(repo: repo, sha: '0' * 40);

      expect(() => packbuilder.addCommit(oid), throwsA(isA<LibGit2Error>()));

      packbuilder.free();
    });

    test('adds tree', () {
      final packbuilder = PackBuilder(repo);
      final oid = repo['df2b8fc'];

      packbuilder.addTree(oid);
      expect(packbuilder.length, 2);

      packbuilder.free();
    });

    test('throws when trying to add tree with invalid oid', () {
      final packbuilder = PackBuilder(repo);
      final oid = Oid.fromSHA(repo: repo, sha: '0' * 40);

      expect(() => packbuilder.addTree(oid), throwsA(isA<LibGit2Error>()));

      packbuilder.free();
    });

    test('adds objects with walker', () {
      final oid = repo['f17d0d4'];
      final packbuilder = PackBuilder(repo);
      final walker = RevWalk(repo);
      walker.sorting({GitSort.none});
      walker.push(oid);

      packbuilder.addWalk(walker);
      expect(packbuilder.length, 3);

      walker.free();
      packbuilder.free();
    });

    test('sets number of threads', () {
      final packbuilder = PackBuilder(repo);

      expect(packbuilder.setThreads(1), 1);

      packbuilder.free();
    });

    test('returns hash of packfile', () {
      final packbuilder = PackBuilder(repo);
      final odb = repo.odb;

      packbuilder.add(odb.objects[0]);
      Directory(packDirPath).createSync();

      expect(packbuilder.hash.sha, '0' * 40);
      packbuilder.write(null);
      expect(packbuilder.hash.sha, isNot('0' * 40));

      packbuilder.free();
    });

    test('packs with default arguments', () {
      final odb = repo.odb;
      final objectsCount = odb.objects.length;
      Directory(packDirPath).createSync();

      final writtenCount = repo.pack();

      expect(writtenCount, objectsCount);

      odb.free();
    });

    test('packs into provided path with threads set', () {
      final odb = repo.odb;
      final objectsCount = odb.objects.length;
      final testPackPath = p.join(repo.workdir, 'test-pack');
      Directory(testPackPath).createSync();

      final writtenCount = repo.pack(path: testPackPath, threads: 1);

      expect(writtenCount, objectsCount);
      expect(Directory(testPackPath).listSync().isNotEmpty, true);

      odb.free();
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
            commit.free();
          }
          ref.free();
          branch.free();
        }
      }

      final writtenCount = repo.pack(packDelegate: packDelegate);
      expect(writtenCount, 18);
    });

    test('throws when trying to write pack into invalid path', () {
      final packbuilder = PackBuilder(repo);

      expect(
        () => packbuilder.write('invalid/path'),
        throwsA(isA<LibGit2Error>()),
      );

      packbuilder.free();
    });

    test('returns string representation of PackBuilder object', () {
      final packbuilder = PackBuilder(repo);
      expect(packbuilder.toString(), contains('PackBuilder{'));
      packbuilder.free();
    });
  });
}
