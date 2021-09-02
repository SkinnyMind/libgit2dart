import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  final tmpDir = '${Directory.systemTemp.path}/tree_testrepo/';
  const treeSHA = 'a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f';
  const fileSHA = '1377554ebea6f98a2c748183bc5a96852af12ac2';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
    tree = Tree.lookup(repo, Oid.fromSHA(repo, treeSHA));
  });

  tearDown(() async {
    tree.free();
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Tree', () {
    test('successfully initializes tree from provided Oid', () {
      expect(tree, isA<Tree>());
    });

    test('returns number of entries', () {
      expect(tree.entries.length, 4);
    });

    test('returns sha of tree entry', () {
      expect(tree.entries.first.id.sha, fileSHA);
    });

    test('returns name of tree entry', () {
      expect(tree.entries[0].name, '.gitignore');
    });

    test('returns filemode of tree entry', () {
      expect(tree.entries[0].filemode, GitFilemode.blob);
    });

    test('returns tree entry with provided index position', () {
      expect(tree[0].id.sha, fileSHA);
    });

    test('throws when provided index position is outside of valid range', () {
      expect(() => tree[10], throwsA(isA<RangeError>()));
      expect(() => tree[-10], throwsA(isA<RangeError>()));
    });

    test('returns tree entry with provided filename', () {
      expect(tree['.gitignore'].id.sha, fileSHA);
    });

    test('throws when nothing found for provided filename', () {
      expect(() => tree['invalid'], throwsA(isA<ArgumentError>()));
    });

    test('returns tree entry with provided path to file', () {
      final entry = tree['dir/dir_file.txt'];
      expect(entry.id.sha, 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391');
      entry.free();
    });

    test('throws when nothing found for provided path', () {
      expect(() => tree['invalid/path'], throwsA(isA<LibGit2Error>()));
    });
  });
}
