import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Checkout', () {
    test('successfully checkouts head', () {
      File('${tmpDir.path}/feature_file').writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      repo.checkout(
        refName: 'HEAD',
        strategy: {GitCheckout.force},
        paths: ['feature_file'],
      );
      expect(repo.status, isEmpty);
    });

    test(
        'throws when trying to checkout head with invalid alternative '
        'directory', () {
      expect(
        () => repo.checkout(
          refName: 'HEAD',
          directory: 'not/there',
        ),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to make directory 'not/there': No such file or directory",
          ),
        ),
      );
    });

    test('successfully checkouts index', () {
      File('${repo.workdir}feature_file').writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      repo.checkout(
        strategy: {
          GitCheckout.force,
          GitCheckout.conflictStyleMerge,
        },
        paths: ['feature_file'],
      );
      expect(repo.status, isEmpty);
    });

    test(
        'throws when trying to checkout index with invalid alternative '
        'directory', () {
      expect(
        () => repo.checkout(directory: 'not/there'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to make directory 'not/there': No such file or directory",
          ),
        ),
      );
    });

    test('successfully checkouts tree', () {
      final masterHead = repo.lookupCommit(
        repo['821ed6e80627b8769d170a293862f9fc60825226'],
      );
      final masterTree = masterHead.tree;
      expect(
        masterTree.entries.any((e) => e.name == 'another_feature_file'),
        false,
      );

      repo.checkout(refName: 'refs/heads/feature');
      final featureHead = repo.lookupCommit(
        repo['5aecfa0fb97eadaac050ccb99f03c3fb65460ad4'],
      );
      final featureTree = featureHead.tree;
      final repoHead = repo.head;
      expect(repoHead.target, featureHead.oid);
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

    test(
        'throws when trying to checkout tree with invalid alternative '
        'directory', () {
      expect(
        () => repo.checkout(
          refName: 'refs/heads/feature',
          directory: 'not/there',
        ),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to make directory 'not/there': No such file or directory",
          ),
        ),
      );
    });

    test('successfully checkouts with alrenative directory', () {
      final altDir = Directory('${Directory.systemTemp.path}/alt_dir');
      // making sure there is no directory
      if (altDir.existsSync()) {
        altDir.deleteSync(recursive: true);
      }
      altDir.createSync();
      expect(altDir.listSync().length, 0);

      repo.checkout(refName: 'refs/heads/feature', directory: altDir.path);
      expect(altDir.listSync().length, isNot(0));

      altDir.deleteSync(recursive: true);
    });

    test('successfully checkouts file with provided path', () {
      expect(repo.status, isEmpty);
      repo.checkout(
        refName: 'refs/heads/feature',
        paths: ['another_feature_file'],
      );
      expect(
        repo.status,
        {
          'another_feature_file': {GitStatus.indexNew}
        },
      );
    });

    test('successfully performs dry run checkout', () {
      final index = repo.index;
      expect(index.length, 4);
      expect(File('${repo.workdir}/another_feature_file').existsSync(), false);

      repo.checkout(
        refName: 'refs/heads/feature',
        strategy: {GitCheckout.dryRun},
      );
      expect(index.length, 4);
      expect(File('${repo.workdir}/another_feature_file').existsSync(), false);

      index.free();
    });
  });
}
