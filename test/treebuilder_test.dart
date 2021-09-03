import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Tree tree;
  final tmpDir = '${Directory.systemTemp.path}/treebuilder_testrepo/';
  const treeSHA = 'a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f';

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

  group('TreeBuilder', () {
    test('successfully initializes tree builder when no tree is provided', () {
      final builder = TreeBuilder(repo);
      expect(builder, isA<TreeBuilder>());
      builder.free();
    });

    test('successfully initializes tree builder with provided tree', () {
      final builder = TreeBuilder(repo, tree);
      final oid = builder.write();

      expect(builder, isA<TreeBuilder>());
      expect(builder.length, tree.length);
      expect(oid, tree.id);

      builder.free();
    });

    test('clears all the entries in the builder', () {
      final builder = TreeBuilder(repo, tree);

      expect(builder.length, 4);
      builder.clear();
      expect(builder.length, 0);

      builder.free();
    });

    test('successfully builds the tree builder from entry of tree', () {
      final builder = TreeBuilder(repo);
      final entry = tree.entries[0];

      expect(() => builder[entry.name], throwsA(isA<ArgumentError>()));

      builder.add(entry.name, entry.id, entry.filemode);
      expect(builder[entry.name].name, entry.name);

      builder.free();
      entry.free();
    });

    test('successfully removes an entry', () {
      final builder = TreeBuilder(repo, tree);

      expect(builder.length, tree.length);

      builder.remove('.gitignore');
      expect(() => builder['.gitignore'], throwsA(isA<ArgumentError>()));
      expect(builder.length, tree.length - 1);

      builder.free();
    });
  });
}
