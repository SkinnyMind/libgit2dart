import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature stasher;
  late String filePath;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    filePath = p.join(repo.workdir, 'file');
    stasher = Signature.create(
      name: 'Stasher',
      email: 'stasher@email.com',
    );
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Stash', () {
    test('saves changes to stash', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      expect(repo.status.isEmpty, true);
    });

    test('throws when trying to save and error occurs', () {
      expect(
        () => Stash.create(repo: Repository(nullptr), stasher: stasher),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('saves changes to stash including ignored', () {
      final swpPath = File(p.join(repo.workdir, 'some.swp'));
      swpPath.writeAsStringSync('ignored');

      Stash.create(
        repo: repo,
        stasher: stasher,
        flags: {GitStash.includeUntracked, GitStash.includeIgnored},
      );
      expect(repo.status.isEmpty, true);
      expect(swpPath.existsSync(), false);

      Stash.apply(repo: repo);
      expect(swpPath.existsSync(), true);
    });

    test('leaves changes added to index intact', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);
      repo.index.add('file');

      Stash.create(repo: repo, stasher: stasher, flags: {GitStash.keepIndex});
      expect(repo.status.isEmpty, false);
      expect(repo.stashes.length, 1);
    });

    test('applies changes from stash', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      expect(repo.status.isEmpty, true);

      Stash.apply(repo: repo);
      expect(repo.status, contains('file'));
    });

    test('applies changes from stash with paths provided', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      expect(repo.status.isEmpty, true);

      Stash.apply(repo: repo, paths: ['file']);
      expect(repo.status, contains('file'));
    });

    test('applies changes from stash including index changes', () {
      File(p.join(repo.workdir, 'stash.this')).writeAsStringSync('stash');
      final index = repo.index;
      index.add('stash.this');
      expect(index.find('stash.this'), true);

      Stash.create(
        repo: repo,
        stasher: stasher,
        flags: {GitStash.includeUntracked},
      );
      expect(repo.status.isEmpty, true);
      expect(index.find('stash.this'), false);

      Stash.apply(repo: repo, reinstateIndex: true);
      expect(repo.status, contains('stash.this'));
      expect(index.find('stash.this'), true);
    });

    test('throws when trying to apply with wrong index', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);

      expect(
        () => Stash.apply(repo: repo, index: 10),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('drops stash', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      final stash = repo.stashes.first;
      Stash.drop(repo: repo, index: stash.index);

      expect(() => Stash.apply(repo: repo), throwsA(isA<LibGit2Error>()));
    });

    test('throws when trying to drop with wrong index', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);

      expect(
        () => Stash.drop(repo: repo, index: 10),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('pops from stash', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      Stash.pop(repo: repo);

      expect(repo.status, contains('file'));
      expect(() => Stash.apply(repo: repo), throwsA(isA<LibGit2Error>()));
    });

    test('pops from stash with provided path', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);
      Stash.pop(repo: repo, paths: ['file']);

      expect(repo.status, contains('file'));
      expect(() => Stash.apply(repo: repo), throwsA(isA<LibGit2Error>()));
    });

    test('pops from stash including index changes', () {
      File(p.join(repo.workdir, 'stash.this')).writeAsStringSync('stash');
      final index = repo.index;
      index.add('stash.this');
      expect(index.find('stash.this'), true);

      Stash.create(
        repo: repo,
        stasher: stasher,
        flags: {GitStash.includeUntracked},
      );
      expect(repo.status.isEmpty, true);
      expect(index.find('stash.this'), false);

      Stash.pop(repo: repo, reinstateIndex: true);
      expect(repo.status, contains('stash.this'));
      expect(index.find('stash.this'), true);
    });

    test('throws when trying to pop with wrong index', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher);

      expect(
        () => Stash.pop(repo: repo, index: 10),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns list of stashes', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);

      Stash.create(repo: repo, stasher: stasher, message: 'WIP');

      final stash = Stash.list(repo).first;

      expect(repo.stashes.length, 1);
      expect(stash.index, 0);
      expect(stash.message, 'On master: WIP');
    });

    test('returns string representation of Stash object', () {
      File(p.join(repo.workdir, 'stash.this')).writeAsStringSync('stash');

      Stash.create(
        repo: repo,
        stasher: stasher,
        flags: {GitStash.includeUntracked},
      );

      expect(repo.stashes[0].toString(), contains('Stash{'));
    });

    test('supports value comparison', () {
      File(filePath).writeAsStringSync('edit', mode: FileMode.append);
      Stash.create(repo: repo, stasher: stasher, message: 'WIP');

      expect(repo.stashes.first, equals(repo.stashes.first));
    });
  });
}
