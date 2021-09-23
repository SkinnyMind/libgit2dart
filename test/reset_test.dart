import 'dart:io';
import 'package:libgit2dart/src/git_types.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late File file;
  const sha = '6cbc22e509d72758ab4c8d9f287ea846b90c448b';

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    file = File('${tmpDir.path}/feature_file');
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Reset', () {
    test('successfully resets with hard', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(sha, GitReset.hard);
      contents = file.readAsStringSync();
      expect(contents, isEmpty);
    });

    test('successfully resets with soft', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(sha, GitReset.soft);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      final index = repo.index;
      final diff = index.diffToWorkdir();
      expect(diff.deltas, isEmpty);

      index.free();
    });

    test('successfully resets with mixed', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(sha, GitReset.mixed);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      final index = repo.index;
      final diff = index.diffToWorkdir();
      expect(diff.deltas.length, 1);

      index.free();
    });
  });
}
