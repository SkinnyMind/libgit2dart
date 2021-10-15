import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature stasher;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    stasher = Signature.create(
      name: 'Stasher',
      email: 'stasher@email.com',
    );
  });

  tearDown(() {
    stasher.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Stash', () {
    test('successfully saves changes to stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.createStash(stasher: stasher);
      expect(repo.status.isEmpty, true);
    });

    test('successfully saves changes to stash including ignored', () {
      final swpPath = File('${tmpDir.path}/some.swp');
      swpPath.writeAsStringSync('ignored');

      repo.createStash(
        stasher: stasher,
        includeUntracked: true,
        includeIgnored: true,
      );
      expect(repo.status.isEmpty, true);
      expect(swpPath.existsSync(), false);

      repo.applyStash();
      expect(swpPath.existsSync(), true);
    });

    test('leaves changes added to index intact', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );
      final index = repo.index;
      index.add('file');

      repo.createStash(stasher: stasher, keepIndex: true);
      expect(repo.status.isEmpty, false);
      expect(repo.stashes.length, 1);

      index.free();
    });

    test('successfully applies changes from stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.createStash(stasher: stasher);
      expect(repo.status.isEmpty, true);

      repo.applyStash();
      expect(repo.status, contains('file'));
    });

    test('successfully applies changes from stash including index changes', () {
      File('${tmpDir.path}/stash.this').writeAsStringSync('stash');
      final index = repo.index;
      index.add('stash.this');
      expect(index.find('stash.this'), true);

      repo.createStash(stasher: stasher, includeUntracked: true);
      expect(repo.status.isEmpty, true);
      expect(index.find('stash.this'), false);

      repo.applyStash(reinstateIndex: true);
      expect(repo.status, contains('stash.this'));
      expect(index.find('stash.this'), true);

      index.free();
    });

    test('successfully drops stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.createStash(stasher: stasher);
      final stash = repo.stashes.first;
      repo.dropStash(stash.index);
      expect(() => repo.applyStash(), throwsA(isA<LibGit2Error>()));
    });

    test('successfully pops from stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.createStash(stasher: stasher);
      repo.popStash();
      expect(repo.status, contains('file'));
      expect(() => repo.applyStash(), throwsA(isA<LibGit2Error>()));
    });

    test('successfully pops from stash including index changes', () {
      File('${tmpDir.path}/stash.this').writeAsStringSync('stash');
      final index = repo.index;
      index.add('stash.this');
      expect(index.find('stash.this'), true);

      repo.createStash(stasher: stasher, includeUntracked: true);
      expect(repo.status.isEmpty, true);
      expect(index.find('stash.this'), false);

      repo.popStash(reinstateIndex: true);
      expect(repo.status, contains('stash.this'));
      expect(index.find('stash.this'), true);

      index.free();
    });

    test('returns list of stashes', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.createStash(stasher: stasher, message: 'WIP');

      final stash = repo.stashes.first;

      expect(repo.stashes.length, 1);
      expect(stash.index, 0);
      expect(stash.message, 'On master: WIP');
    });

    test('returns string representation of Stash object', () {
      File('${tmpDir.path}/stash.this').writeAsStringSync('stash');
      repo.createStash(stasher: stasher, includeUntracked: true);
      expect(repo.stashes[0].toString(), contains('Stash{'));
    });
  });
}
