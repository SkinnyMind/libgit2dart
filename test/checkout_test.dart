import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Checkout', () {
    test('checkouts head', () {
      repo.reset(oid: repo['821ed6e'], resetType: GitReset.hard);
      expect(repo.status, isEmpty);
      File(p.join(tmpDir.path, 'feature_file')).writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      Checkout.head(
        repo: repo,
        strategy: {GitCheckout.force},
        paths: ['feature_file'],
      );
      expect(repo.status, isEmpty);
    });

    test(
        'throws when trying to checkout head with invalid alternative '
        'directory', () {
      expect(
        () => Checkout.head(
          repo: repo,
          directory: 'not/there',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checkouts index', () {
      File(p.join(repo.workdir, 'feature_file')).writeAsStringSync('edit');
      expect(repo.status, contains('feature_file'));

      Checkout.index(
        repo: repo,
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
        () => Checkout.index(repo: repo, directory: 'not/there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checkouts reference', () {
      final masterHead = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final masterTree = masterHead.tree;
      expect(
        masterTree.entries.any((e) => e.name == 'another_feature_file'),
        false,
      );

      Checkout.reference(repo: repo, name: 'refs/heads/feature');
      final featureHead = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
      final featureTree = featureHead.tree;
      final repoHead = repo.head;
      // does not change HEAD
      expect(repoHead.target, isNot(featureHead.oid));
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
        'throws when trying to checkout reference with invalid alternative '
        'directory', () {
      expect(
        () => Checkout.reference(
          repo: repo,
          name: 'refs/heads/feature',
          directory: 'not/there',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checkouts commit', () {
      final index = repo.index;
      expect(index.find('another_feature_file'), equals(false));

      final featureHead = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
      Checkout.commit(repo: repo, commit: featureHead);

      final repoHead = repo.head;
      // does not change HEAD
      expect(repoHead.target, isNot(featureHead.oid));
      expect(index.find('another_feature_file'), equals(true));

      repoHead.free();
      featureHead.free();
      index.free();
    });

    test('checkouts commit with provided path', () {
      final featureHead = Commit.lookup(repo: repo, oid: repo['5aecfa0']);
      Checkout.commit(
        repo: repo,
        commit: featureHead,
        paths: ['another_feature_file'],
      );

      final repoHead = repo.head;
      // does not change HEAD
      expect(repoHead.target, isNot(featureHead.oid));
      expect(
        repo.status,
        {
          'another_feature_file': {GitStatus.indexNew}
        },
      );

      repoHead.free();
      featureHead.free();
    });

    test(
        'throws when trying to checkout commit with invalid alternative '
        'directory', () {
      final commit = Commit.lookup(repo: repo, oid: repo['5aecfa0']);

      expect(
        () => Checkout.commit(
          repo: repo,
          commit: commit,
          directory: 'not/there',
        ),
        throwsA(isA<LibGit2Error>()),
      );

      commit.free();
    });

    test('checkouts with alrenative directory', () {
      final altDir = Directory(p.join(Directory.systemTemp.path, 'alt_dir'));
      // making sure there is no directory
      if (altDir.existsSync()) {
        altDir.deleteSync(recursive: true);
      }
      altDir.createSync();
      expect(altDir.listSync().length, 0);

      Checkout.reference(
        repo: repo,
        name: 'refs/heads/feature',
        directory: altDir.path,
      );
      expect(altDir.listSync().length, isNot(0));

      altDir.deleteSync(recursive: true);
    });

    test('checkouts file with provided path', () {
      final featureTip = Reference.lookup(
        repo: repo,
        name: 'refs/heads/feature',
      ).target;

      expect(repo.status, isEmpty);
      Checkout.reference(
        repo: repo,
        name: 'refs/heads/feature',
        paths: ['another_feature_file'],
      );
      expect(
        repo.status,
        {
          'another_feature_file': {GitStatus.indexNew}
        },
      );
      // does not change HEAD
      expect(repo.head.target, isNot(featureTip));
    });

    test('performs dry run checkout', () {
      final index = repo.index;
      expect(index.length, 4);
      final file = File(p.join(repo.workdir, 'another_feature_file'));
      expect(file.existsSync(), false);

      Checkout.reference(
        repo: repo,
        name: 'refs/heads/feature',
        strategy: {GitCheckout.dryRun},
      );
      expect(index.length, 4);
      expect(file.existsSync(), false);

      index.free();
    });
  });
}
