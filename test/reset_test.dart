import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late File file;
  const sha = '6cbc22e509d72758ab4c8d9f287ea846b90c448b';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    file = File(p.join(tmpDir.path, 'feature_file'));
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

      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      expect(diff.deltas, isEmpty);
    });

    test('resets with mixed', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.mixed);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      expect(diff.deltas.length, 1);
    });

    group('resetDefault', () {
      test('updates entry in the index', () {
        file.writeAsStringSync('new edit');

        repo.index.add('feature_file');
        expect(repo.status['feature_file'], {GitStatus.indexModified});

        repo.resetDefault(oid: repo.head.target, pathspec: ['feature_file']);
        expect(repo.status['feature_file'], {GitStatus.wtModified});
      });

      test('throws when pathspec list is empty', () {
        expect(
          () => repo.resetDefault(oid: repo.head.target, pathspec: []),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });
  });
}
