import 'dart:io';
import 'package:libgit2dart/src/git_types.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/reset_testrepo/';
  const sha = '6cbc22e509d72758ab4c8d9f287ea846b90c448b';
  final file = File('${tmpDir}feature_file');

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
  });

  tearDown(() async {
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
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
    });

    test('successfully resets with soft', () {
      var contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');

      repo.reset(sha, GitReset.mixed);
      contents = file.readAsStringSync();
      expect(contents, 'Feature edit\n');
    });
  });
}
