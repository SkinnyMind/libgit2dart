import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

void main() {
  late Repository repo;
  final initDir = Directory('${Directory.systemTemp.path}/init_repo');

  setUp(() {
    if (initDir.existsSync()) {
      initDir.deleteSync(recursive: true);
    } else {
      initDir.createSync();
    }
  });

  tearDown(() {
    repo.free();
    initDir.deleteSync(recursive: true);
  });
  group('Repository.init', () {
    test('creates new bare repo at provided path', () {
      repo = Repository.init(path: initDir.path, bare: true);

      expect(repo.path, contains('init_repo/'));
      expect(repo.isBare, true);
    });

    test('creates new standard repo at provided path', () {
      repo = Repository.init(path: initDir.path);

      expect(repo.path, contains('init_repo/.git/'));
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
    });

    test('creates new standard repo with provided options', () {
      repo = Repository.init(
        path: initDir.path,
        description: 'test repo',
        originUrl: 'test.url',
        flags: {GitRepositoryInit.mkdir, GitRepositoryInit.mkpath},
      );

      expect(repo.path, contains('init_repo/.git/'));
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
      expect(
        File('${repo.workdir}.git/description').readAsStringSync(),
        'test repo',
      );
      expect(repo.lookupRemote('origin').url, 'test.url');
    });
  });
}
