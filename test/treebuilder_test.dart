import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
    repo = Repository.open(tmpDir.path);
    tree = repo.lookupTree(repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f']);
  });

  tearDown(() {
    tree.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('TreeBuilder', () {
    test('successfully initializes tree builder when no tree is provided', () {
      final builder = TreeBuilder(repo: repo);
      expect(builder, isA<TreeBuilder>());
      expect(builder.toString(), contains('TreeBuilder{'));
      builder.free();
    });

    test('successfully initializes tree builder with provided tree', () {
      final builder = TreeBuilder(repo: repo, tree: tree);
      final oid = builder.write();

      expect(builder, isA<TreeBuilder>());
      expect(builder.length, tree.length);
      expect(oid, tree.oid);

      builder.free();
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

      builder.free();
    });

    test('successfully builds the tree builder from entry of tree', () {
      final builder = TreeBuilder(repo: repo);
      final entry = tree.entries[0];

      expect(() => builder[entry.name], throwsA(isA<ArgumentError>()));

      builder.add(
        filename: entry.name,
        oid: entry.oid,
        filemode: entry.filemode,
      );
      expect(builder[entry.name].name, entry.name);

      builder.free();
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

      builder.free();
    });

    test('successfully removes an entry', () {
      final builder = TreeBuilder(repo: repo, tree: tree);

      expect(builder.length, tree.length);

      builder.remove('.gitignore');
      expect(() => builder['.gitignore'], throwsA(isA<ArgumentError>()));
      expect(builder.length, tree.length - 1);

      builder.free();
    });

    test('throws when trying to remove entry that is not in the tree', () {
      final builder = TreeBuilder(repo: repo);
      expect(() => builder.remove('not.there'), throwsA(isA<LibGit2Error>()));
      builder.free();
    });
  });
}
