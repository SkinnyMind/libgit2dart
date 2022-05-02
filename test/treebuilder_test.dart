import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    tree = Tree.lookup(repo: repo, oid: repo['a8ae3dd']);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('TreeBuilder', () {
    test('initializes tree builder when no tree is provided', () {
      final builder = TreeBuilder(repo: repo);
      expect(builder, isA<TreeBuilder>());
      expect(builder.toString(), contains('TreeBuilder{'));
    });

    test('initializes tree builder with provided tree', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder, isA<TreeBuilder>());
      expect(builder.length, tree.length);
      expect(builder.write(), tree.oid);
    });

    test('throws when trying to initialize and error occurs', () {
      expect(
        () => TreeBuilder(repo: Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('clears all the entries in the builder', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder.length, 4);
      builder.clear();
      expect(builder.length, 0);
    });

    test('builds the tree builder from entry of tree', () {
      final builder = TreeBuilder(repo: repo);
      final entry = tree.entries[0];

      expect(() => builder[entry.name], throwsA(isA<ArgumentError>()));

      builder.add(
        filename: entry.name,
        oid: entry.oid,
        filemode: entry.filemode,
      );
      expect(builder[entry.name].name, entry.name);
    });

    test('throws when trying to add entry with invalid name or invalid oid',
        () {
      final builder = TreeBuilder(repo: repo);

      expect(
        () => builder.add(
          filename: '',
          oid: repo['0' * 40],
          filemode: GitFilemode.blob,
        ),
        throwsA(isA<LibGit2Error>()),
      );
      expect(
        () => builder.add(
          filename: 'some.file',
          oid: repo['0' * 40],
          filemode: GitFilemode.blob,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('removes an entry', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder.length, tree.length);

      builder.remove('.gitignore');
      expect(() => builder['.gitignore'], throwsA(isA<ArgumentError>()));
      expect(builder.length, tree.length - 1);
    });

    test('throws when trying to remove entry that is not in the tree', () {
      expect(
        () => TreeBuilder(repo: repo).remove('not.there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      expect(() => TreeBuilder(repo: repo).free(), returnsNormally);
    });
  });
}
