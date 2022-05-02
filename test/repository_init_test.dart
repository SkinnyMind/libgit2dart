import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final initDir = Directory(p.join(Directory.systemTemp.path, 'init_repo'));

  setUp(() {
    if (initDir.existsSync()) {
      initDir.deleteSync(recursive: true);
    } else {
      initDir.createSync();
    }
  });

  tearDown(() {
    initDir.deleteSync(recursive: true);
  });
  group('Repository.init', () {
    test('creates new bare repo at provided path', () {
      final repo = Repository.init(path: initDir.path, bare: true);

      expect(repo.path, contains('init_repo'));
      expect(repo.isBare, true);
    });

    test('creates new standard repo at provided path', () {
      final repo = Repository.init(path: initDir.path);

      expect(repo.path, contains('init_repo/.git/'));
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
    });

    test('creates new standard repo with provided options', () {
      final repo = Repository.init(
        path: initDir.path,
        description: 'test repo',
        originUrl: 'test.url',
        flags: {GitRepositoryInit.mkdir, GitRepositoryInit.mkpath},
      );

      expect(repo.path, contains('init_repo/.git/'));
      expect(repo.isBare, false);
      expect(repo.isEmpty, true);
      expect(
        File(p.join(repo.path, 'description')).readAsStringSync(),
        'test repo',
      );
      expect(Remote.lookup(repo: repo, name: 'origin').url, 'test.url');
    });
  });
}
