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
    tmpDir.deleteSync(recursive: true);
  });

  group('Reset', () {
    test('resets with hard', () {
      expect(file.readAsStringSync(), 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.hard);
      expect(file.readAsStringSync(), isEmpty);
    });

    test('resets with soft', () {
      expect(file.readAsStringSync(), 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.soft);
      expect(file.readAsStringSync(), 'Feature edit\n');

      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      expect(diff.deltas, isEmpty);
    });

    test('resets with mixed', () {
      expect(file.readAsStringSync(), 'Feature edit\n');

      repo.reset(oid: repo[sha], resetType: GitReset.mixed);
      expect(file.readAsStringSync(), 'Feature edit\n');

      final diff = Diff.indexToWorkdir(repo: repo, index: repo.index);
      expect(diff.deltas.length, 1);
    });

    test('resets with provided checkout options', () {
      expect(file.readAsStringSync(), 'Feature edit\n');

      repo.reset(
        oid: repo[sha],
        resetType: GitReset.hard,
        strategy: {GitCheckout.conflictStyleZdiff3},
        pathspec: ['feature_file'],
      );

      expect(file.readAsStringSync(), isEmpty);
    });

    test(
      'throws when trying to reset and error occurs',
      testOn: '!windows',
      () {
        expect(
          () => repo.reset(
            oid: repo[sha],
            resetType: GitReset.hard,
            checkoutDirectory: '',
          ),
          throwsA(isA<LibGit2Error>()),
        );
      },
    );

    group('resetDefault', () {
      test('updates entry in the index', () {
        file.writeAsStringSync('new edit');

        repo.index.add('feature_file');
        expect(repo.status['feature_file'], {GitStatus.indexModified});

        repo.resetDefault(oid: repo.head.target, pathspec: ['feature_file']);
        expect(repo.status['feature_file'], {GitStatus.wtModified});
      });

      test('removes entry in the index when null oid is provided', () {
        const fileName = 'new_file.txt';
        File(p.join(tmpDir.path, fileName)).createSync();

        repo.index.add(fileName);
        expect(repo.status[fileName], {GitStatus.indexNew});

        repo.resetDefault(oid: null, pathspec: [fileName]);
        expect(repo.status[fileName], {GitStatus.wtNew});
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
