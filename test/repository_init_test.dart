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
      repo = Repository.init(path: initDir.path, bare: true);

      expect(repo.path, '${initDir.path}/');
      expect(repo.isBare, true);
    });

    test('successfully creates new standard repo at provided path', () {
      repo = Repository.init(path: initDir.path);

      expect(repo.path, '${initDir.path}/.git/');
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
    });

    test('successfully creates new standard repo with provided options', () {
      repo = Repository.init(
        path: initDir.path,
        description: 'test repo',
        originUrl: 'test.url',
        flags: {GitRepositoryInit.mkdir, GitRepositoryInit.mkpath},
      );

      expect(repo.path, '${initDir.path}/.git/');
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
      expect(
        File('${initDir.path}/.git/description').readAsStringSync(),
        'test repo',
      );
      expect(repo.remotes['origin'].url, 'test.url');
    });
  });
}