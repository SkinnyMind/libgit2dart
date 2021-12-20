import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
    repo = Repository.open(tmpDir.path);
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

    test('successfully adds objects', () {
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

    test('successfully adds object recursively', () {
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

    test('successfully sets number of threads', () {
      final packbuilder = PackBuilder(repo);

      expect(packbuilder.setThreads(1), 1);

      packbuilder.free();
    });

    test('successfully packs with default arguments', () {
      final odb = repo.odb;
      final objectsCount = odb.objects.length;
      Directory('${repo.workdir}.git/objects/pack/').createSync();
      final writtenCount = repo.pack();

      expect(writtenCount, objectsCount);

      odb.free();
    });

    test('successfully packs into provided path with threads set', () {
      final odb = repo.odb;
      final objectsCount = odb.objects.length;
      Directory('${repo.workdir}test-pack').createSync();

      final writtenCount = repo.pack(
        path: '${repo.workdir}test-pack',
        threads: 1,
      );
      expect(writtenCount, objectsCount);
      expect(
        Directory('${repo.workdir}test-pack').listSync().isNotEmpty,
        true,
      );

      odb.free();
    });

    test('successfully packs with provided packDelegate', () {
      Directory('${repo.workdir}.git/objects/pack/').createSync();
      void packDelegate(PackBuilder packBuilder) {
        final branches = repo.branchesLocal;
        for (final branch in branches) {
          final ref = repo.lookupReference('refs/heads/${branch.name}');
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
