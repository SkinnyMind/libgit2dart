import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/src/index.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/types.dart';
import 'package:libgit2dart/src/error.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Index index;
  final tmpDir = '${Directory.systemTemp.path}/index_testrepo/';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
    index = repo.index;
  });

  tearDown(() async {
    index.free();
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Index', () {
    const fileSha = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391';
    const featureFileSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';

    test('returns number of entries', () {
      expect(index.count, 3);
    });

    test('returns mode of index entry', () {
      expect(index['file'].mode, 33188);
    });

    test('returns index entry at provided position', () {
      expect(index[2].path, 'file');
      expect(index['file'].sha, fileSha);
    });

    test('returns index entry at provided path', () {
      expect(index['file'].path, 'file');
      expect(index['file'].sha, fileSha);
    });

    test('throws if provided entry position is out of bounds', () {
      expect(() => index[10], throwsA(isA<RangeError>()));
    });

    test('throws if provided entry path is not found', () {
      expect(() => index[10], throwsA(isA<ArgumentError>()));
    });

    test('successfully changes attributes', () {
      final entry = index['file'];
      final otherEntry = index['feature_file'];

      expect(entry.id == otherEntry.id, false);
      expect(entry.mode, isNot(GitFilemode.blobExecutable));

      entry.path = 'some.txt';
      entry.id = otherEntry.id;
      entry.mode = GitFilemode.blobExecutable;

      expect(entry.path, 'some.txt');
      expect(entry.id == otherEntry.id, true);
      expect(entry.mode, GitFilemode.blobExecutable);
    });

    test('clears the contents', () {
      expect(index.count, 3);
      index.clear();
      expect(index.count, 0);
    });

    group('add()', () {
      test('successfully adds with provided IndexEntry', () {
        final entry = index['file'];

        index.add(entry);
        expect(index['file'].sha, fileSha);
        expect(index.count, 3);
      });

      test('successfully adds with provided path string', () {
        index.add('file');
        expect(index['file'].sha, fileSha);
        expect(index.count, 3);
      });

      test('throws if file not found at provided path', () {
        expect(() => index.add('not_there'), throwsA(isA<LibGit2Error>()));
      });

      test('throws if index of bare repository', () {
        final bare = Repository.open('test/assets/empty_bare.git');
        final bareIndex = bare.index;

        expect(() => bareIndex.add('config'), throwsA(isA<LibGit2Error>()));

        bareIndex.free();
        bare.free();
      });
    });

    group('addAll()', () {
      test('successfully adds with provided pathspec', () {
        index.clear();
        index.addAll(['file', 'feature_file']);

        expect(index.count, 2);
        expect(index['file'].sha, fileSha);
        expect(index['feature_file'].sha, featureFileSha);

        index.clear();
        index.addAll(['[f]*']);

        expect(index.count, 2);
        expect(index['file'].sha, fileSha);
        expect(index['feature_file'].sha, featureFileSha);

        index.clear();
        index.addAll(['feature_f???']);

        expect(index.count, 1);
        expect(index['feature_file'].sha, featureFileSha);
      });
    });

    test('writes to disk', () {
      expect(index.count, 3);

      File('$tmpDir/new_file').createSync();

      index.add('new_file');
      index.write();

      index.clear();
      index.read();
      expect(index['new_file'].path, 'new_file');
      expect(index.count, 4);
    });

    test('removes an entry', () {
      expect(index.contains('feature_file'), true);
      index.remove('feature_file');
      expect(index.contains('feature_file'), false);
    });

    test('removes all entries with matching pathspec', () {
      expect(index.contains('file'), true);
      expect(index.contains('feature_file'), true);

      index.removeAll(['[f]*']);

      expect(index.contains('file'), false);
      expect(index.contains('feature_file'), false);
    });
  });
}
