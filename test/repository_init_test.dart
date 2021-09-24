import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';

void main() {
  late Repository repo;
  final initDir = Directory('${Directory.systemTemp.path}/init_repo');

  setUp(() async {
    if (await initDir.exists()) {
      await initDir.delete(recursive: true);
    } else {
      await initDir.create();
    }
  });

  tearDown(() async {
    repo.free();
    await initDir.delete(recursive: true);
  });
  group('Repository.init', () {
    test('successfully creates new bare repo at provided path', () {
      repo = Repository.init(initDir.path, isBare: true);
      expect(repo.path, '${initDir.path}/');
      expect(repo.isBare, true);
    });

    test('successfully creates new standard repo at provided path', () {
      repo = Repository.init(initDir.path);
      expect(repo.path, '${initDir.path}/.git/');
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
    });
  });
}
