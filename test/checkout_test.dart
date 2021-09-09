import 'dart:io';
import 'package:libgit2dart/src/git_types.dart';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  final tmpDir = '${Directory.systemTemp.path}/checkout_testrepo/';

  setUp(() async {
    if (await Directory(tmpDir).exists()) {
      await Directory(tmpDir).delete(recursive: true);
    }
    await copyRepo(
      from: Directory('test/assets/testrepo/'),
      to: await Directory(tmpDir).create(),
    );
    repo = Repository.open(tmpDir);
  });

  tearDown(() async {
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
  });

  group('Checkout', () {
    test('successfully checkouts head', () {
      File('${tmpDir}feature_file').writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      repo.checkout(refName: 'HEAD', strategy: [GitCheckout.force]);
      expect(repo.status, isEmpty);
    });

    test('successfully checkouts index', () {
      File('${repo.workdir}feature_file').writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      repo.checkout(strategy: [GitCheckout.force]);
      expect(repo.status, isEmpty);
    });

    test('successfully checkouts tree', () {
      final masterHead =
          repo['821ed6e80627b8769d170a293862f9fc60825226'] as Commit;
      final masterTree = repo[masterHead.tree.sha] as Tree;
      expect(
        masterTree.entries.any((e) => e.name == 'another_feature_file'),
        false,
      );

      repo.checkout(refName: 'refs/heads/feature');
      final featureHead =
          repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'] as Commit;
      final featureTree = repo[featureHead.tree.sha] as Tree;
      final repoHead = repo.head;
      expect(repoHead.target.sha, featureHead.id.sha);
      expect(repo.status, isEmpty);
      expect(
        featureTree.entries.any((e) => e.name == 'another_feature_file'),
        true,
      );

      repoHead.free();
      featureTree.free();
      featureHead.free();
      masterTree.free();
      masterHead.free();
    });

    test('successfully checkouts with alrenative directory', () {
      final altDir = '${Directory.systemTemp.path}/alt_dir';
      // making sure there is no directory
      if (Directory(altDir).existsSync()) {
        Directory(altDir).deleteSync(recursive: true);
      }
      Directory(altDir).createSync();
      expect(Directory(altDir).listSync().length, 0);

      repo.checkout(refName: 'refs/heads/feature', directory: altDir);
      expect(Directory(altDir).listSync().length, isNot(0));

      Directory(altDir).deleteSync(recursive: true);
    });

    test('successfully checkouts file with provided path', () {
      expect(repo.status, isEmpty);
      repo.checkout(
        refName: 'refs/heads/feature',
        paths: ['another_feature_file'],
      );
      expect(repo.status, {'another_feature_file': GitStatus.indexNew.value});
    });
  });
}
