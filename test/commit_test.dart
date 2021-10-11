import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature author;
  late Signature commiter;
  late Tree tree;
  late Oid mergeCommit;
  const message = "Commit message.\n\nSome description.\n";

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
    author = Signature.create(
      name: 'Author Name',
      email: 'author@email.com',
      time: 123,
    );
    commiter = Signature.create(
      name: 'Commiter',
      email: 'commiter@email.com',
      time: 124,
    );
    mergeCommit = repo['78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8'];
    tree = Tree.lookup(
      repo: repo,
      id: repo['7796359a96eb722939c24bafdb1afe9f07f2f628'],
    );
  });

  tearDown(() {
    author.free();
    commiter.free();
    tree.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Commit', () {
    test('successfully returns when 40 char sha hex is provided', () {
      final commit = repo.lookupCommit(mergeCommit);
      expect(commit, isA<Commit>());
      commit.free();
    });

    test('successfully reverts commit', () {
      final to = repo.lookupCommit(
        repo['78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8'],
      );
      final from = repo.lookupCommit(
        repo['821ed6e80627b8769d170a293862f9fc60825226'],
      );
      final index = repo.index;
      expect(index.find('dir/dir_file.txt'), true);

      final revertIndex = repo.revertCommit(revertCommit: from, ourCommit: to);
      expect(revertIndex.find('dir/dir_file.txt'), false);

      revertIndex.free();
      index.free();
      to.free();
      from.free();
    });

    test('successfully creates commit', () {
      final parent = repo.lookupCommit(mergeCommit);
      final oid = repo.createCommit(
        message: message,
        author: author,
        commiter: commiter,
        tree: tree,
        parents: [parent],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id, tree.id);
      expect(commit.parents.length, 1);
      expect(commit.parents[0], mergeCommit);

      commit.free();
      parent.free();
    });

    test('successfully creates commit without parents', () {
      final oid = repo.createCommit(
        message: message,
        author: author,
        commiter: commiter,
        tree: tree,
        parents: [],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id, tree.id);
      expect(commit.parents.length, 0);

      commit.free();
    });

    test('successfully creates commit with 2 parents', () {
      final parent1 = repo.lookupCommit(mergeCommit);
      final parent2 = repo.lookupCommit(
        repo['fc38877b2552ab554752d9a77e1f48f738cca79b'],
      );

      final oid = Commit.create(
        repo: repo,
        message: message,
        author: author,
        commiter: commiter,
        tree: tree,
        parents: [parent1, parent2],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.id.sha, oid.sha);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.id, tree.id);
      expect(commit.parents.length, 2);
      expect(commit.parents[0], mergeCommit);
      expect(commit.parents[1], parent2.id);

      parent1.free();
      parent2.free();
      commit.free();
    });
  });
}
