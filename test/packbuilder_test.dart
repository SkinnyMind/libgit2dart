import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
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

    test('successfully adds objects recursively', () {
      final packbuilder = PackBuilder(repo);
      final oid = Oid.fromSHA(repo: repo, sha: 'f17d0d48');

      packbuilder.addRecursively(oid);
      expect(packbuilder.length, 3);

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
      final writtenCount = repo.pack();

      expect(writtenCount, objectsCount);

      odb.free();
    });

    test('successfully packs into provided path', () {
      final odb = repo.odb;
      final objectsCount = odb.objects.length;
      Directory('${repo.workdir}test-pack').createSync();

      final writtenCount = repo.pack(path: '${repo.workdir}test-pack');
      expect(writtenCount, objectsCount);
      expect(
        Directory('${repo.workdir}test-pack').listSync().isNotEmpty,
        true,
      );

      odb.free();
    });

    test('successfully packs with provided packDelegate', () {
      void packDelegate(PackBuilder packBuilder) {
        final branches = repo.branches;
        for (var branch in branches) {
          final ref = repo.lookupReference('refs/heads/${branch.name}');
          for (var commit in repo.log(sha: ref.target.sha)) {
            packBuilder.addRecursively(commit.id);
            commit.free();
          }
          ref.free();
          branch.free();
        }
      }

      final writtenCount = repo.pack(packDelegate: packDelegate);
      expect(writtenCount, 18);
    });
  });
}
