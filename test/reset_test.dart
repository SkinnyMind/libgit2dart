import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late File file;
  const sha = '6cbc22e509d72758ab4c8d9f287ea846b90c448b';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
    file = File('${tmpDir.path}/feature_file');
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Reset', () {
    test('resets with hard', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.hard);
      contents = file.readAsStringSync();
      expect(contents, isEmpty);
    });

    test('resets with soft', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.soft);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      final index = repo.index;
      final diff = index.diffToWorkdir();
      expect(diff.deltas, isEmpty);

      index.free();
    });

    test('resets with mixed', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.mixed);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      final index = repo.index;
      final diff = index.diffToWorkdir();
      expect(diff.deltas.length, 1);

      index.free();
    });

    group('resetDefault', () {
      test('updates entry in the index', () {
        file.writeAsStringSync('new edit');

        final index = repo.index;
        index.add('feature_file');
        expect(repo.status['feature_file'], {GitStatus.indexModified});

        final head = repo.head;
        repo.resetDefault(oid: head.target, pathspec: ['feature_file']);
        expect(repo.status['feature_file'], {GitStatus.wtModified});

        head.free();
        index.free();
      });

      test('throws when pathspec list is empty', () {
        final head = repo.head;
        expect(
          () => repo.resetDefault(oid: head.target, pathspec: []),
          throwsA(isA<LibGit2Error>()),
        );

        head.free();
      });
    });
  });
}
