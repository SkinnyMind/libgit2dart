import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature author;
  late Signature commiter;
  late Tree tree;
  late Oid tip;
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
    tip = repo['821ed6e80627b8769d170a293862f9fc60825226'];
    tree = Tree.lookup(
      repo: repo,
      oid: repo['a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f'],
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
    test('successfully lookups for provided oid', () {
      final commit = repo.lookupCommit(tip);
      expect(commit, isA<Commit>());
      commit.free();
    });

    test('throws when trying to lookup with invalid oid', () {
      expect(
        () => repo.lookupCommit(repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully lookups annotated commit for provided oid', () {
      final annotated = AnnotatedCommit.lookup(repo: repo, oid: tip);
      expect(annotated, isA<AnnotatedCommit>());
      annotated.free();
    });

    test('throws when trying to lookup annotated commit with invalid oid', () {
      expect(
        () => AnnotatedCommit.lookup(repo: repo, oid: repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
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

    test('throws when trying to revert commit and error occurs', () {
      final nullCommit = Commit(nullptr);
      expect(
        () => repo.revertCommit(
          revertCommit: nullCommit,
          ourCommit: nullCommit,
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('successfully creates commit', () {
      final parent = repo.lookupCommit(tip);
      final oid = repo.createCommit(
        updateRef: 'HEAD',
        message: message,
        author: author,
        commiter: commiter,
        tree: tree,
        parents: [parent],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.oid, tree.oid);
      expect(commit.parents.length, 1);
      expect(commit.parents[0], tip);

      commit.free();
      parent.free();
    });

    test('successfully creates commit without parents', () {
      final oid = repo.createCommit(
        updateRef: 'refs/heads/new',
        message: message,
        author: author,
        commiter: commiter,
        tree: tree,
        parents: [],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.oid, tree.oid);
      expect(commit.parents.length, 0);

      commit.free();
    });

    test('successfully creates commit with 2 parents', () {
      final parent1 = repo.lookupCommit(tip);
      final parent2 = repo.lookupCommit(
        repo['fc38877b2552ab554752d9a77e1f48f738cca79b'],
      );

      final oid = Commit.create(
        updateRef: 'HEAD',
        repo: repo,
        message: message,
        author: author,
        committer: commiter,
        tree: tree,
        parents: [parent1, parent2],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, commiter);
      expect(commit.time, 124);
      expect(commit.tree.oid, tree.oid);
      expect(commit.parents.length, 2);
      expect(commit.parents[0], tip);
      expect(commit.parents[1], parent2.oid);

      parent1.free();
      parent2.free();
      commit.free();
    });

    test('throws when trying to create commit and error occurs', () {
      final parent = repo.lookupCommit(tip);
      final nullRepo = Repository(nullptr);

      expect(
        () => nullRepo.createCommit(
          updateRef: 'HEAD',
          message: message,
          author: author,
          commiter: commiter,
          tree: tree,
          parents: [parent],
        ),
        throwsA(isA<LibGit2Error>()),
      );

      parent.free();
    });

    test('successfully amends commit with default arguments', () {
      final oldHead = repo.head;
      final commit = repo.lookupCommit(repo['821ed6e']);
      expect(commit.oid, oldHead.target);

      final amendedOid = repo.amendCommit(
        commit: commit,
        message: 'amended commit\n',
        updateRef: 'HEAD',
      );
      final amendedCommit = repo.lookupCommit(amendedOid);
      final newHead = repo.head;

      expect(amendedCommit.oid, newHead.target);
      expect(amendedCommit.message, 'amended commit\n');
      expect(amendedCommit.author, commit.author);
      expect(amendedCommit.committer, commit.committer);
      expect(amendedCommit.tree.oid, commit.tree.oid);
      expect(amendedCommit.parents, commit.parents);

      amendedCommit.free();
      commit.free();
      newHead.free();
      oldHead.free();
    });

    test('successfully amends commit with provided arguments', () {
      final oldHead = repo.head;
      final commit = repo.lookupCommit(repo['821ed6e']);
      expect(commit.oid, oldHead.target);

      final amendedOid = repo.amendCommit(
        commit: commit,
        message: 'amended commit\n',
        updateRef: 'HEAD',
        author: author,
        committer: commiter,
        tree: tree,
      );
      final amendedCommit = repo.lookupCommit(amendedOid);
      final newHead = repo.head;

      expect(amendedCommit.oid, newHead.target);
      expect(amendedCommit.message, 'amended commit\n');
      expect(amendedCommit.author, author);
      expect(amendedCommit.committer, commiter);
      expect(amendedCommit.tree.oid, tree.oid);
      expect(amendedCommit.parents, commit.parents);

      amendedCommit.free();
      commit.free();
      newHead.free();
      oldHead.free();
    });

    test('successfully amends commit that is not the tip of the branch', () {
      final head = repo.head;
      final commit = repo.lookupCommit(repo['78b8bf1']);
      expect(commit.oid, isNot(head.target));

      expect(
        () => repo.amendCommit(
          updateRef: null,
          commit: commit,
          message: 'amended commit\n',
        ),
        returnsNormally,
      );

      commit.free();
      head.free();
    });

    test(
        'throws when trying to amend commit that is not the tip of the branch '
        'with HEAD provided as update reference', () {
      final head = repo.head;
      final commit = repo.lookupCommit(repo['78b8bf1']);
      expect(commit.oid, isNot(head.target));

      expect(
        () => repo.amendCommit(
          commit: commit,
          message: 'amended commit\n',
          updateRef: 'HEAD',
        ),
        throwsA(isA<LibGit2Error>()),
      );

      commit.free();
      head.free();
    });

    test('returns string representation of Commit object', () {
      final commit = repo.lookupCommit(tip);
      expect(commit.toString(), contains('Commit{'));
      commit.free();
    });
  });
}
