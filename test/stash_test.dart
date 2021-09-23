import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature stasher;

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    stasher = Signature.create(
      name: 'Stasher',
      email: 'stasher@email.com',
    );
  });

  tearDown(() async {
    stasher.free();
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Stash', () {
    test('successfully saves changes to stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.stash(stasher: stasher, includeUntracked: true);
      expect(repo.status.isEmpty, true);
    });

    test('successfully applies changes from stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.stash(stasher: stasher);
      expect(repo.status.isEmpty, true);

      repo.stashApply();
      expect(repo.status, contains('file'));
    });

    test('successfully drops stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.stash(stasher: stasher);
      final stash = repo.stashList.first;
      repo.stashDrop(stash.index);
      expect(() => repo.stashApply(), throwsA(isA<LibGit2Error>()));
    });

    test('successfully pops from stash', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.stash(stasher: stasher);
      repo.stashPop();
      expect(repo.status, contains('file'));
      expect(() => repo.stashApply(), throwsA(isA<LibGit2Error>()));
    });

    test('returns list of stashes', () {
      File('${tmpDir.path}/file').writeAsStringSync(
        'edit',
        mode: FileMode.append,
      );

      repo.stash(stasher: stasher, message: 'WIP');

      final stash = repo.stashList.first;

      expect(repo.stashList.length, 1);
      expect(stash.index, 0);
      expect(stash.message, 'On master: WIP');
    });
  });
}
