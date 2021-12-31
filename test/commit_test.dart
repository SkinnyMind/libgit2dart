import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature author;
  late Signature committer;
  late Tree tree;
  late Oid tip;
  const message = "Commit message.\n\nSome description.\n";

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    author = Signature.create(
      name: 'Author Name',
      email: 'author@email.com',
      time: 123,
    );
    committer = Signature.create(
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
    committer.free();
    tree.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Commit', () {
    test('lookups commit for provided oid', () {
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

    test(
        'throws when trying to get the summary of the commit message and error '
        'occurs', () {
      expect(() => Commit(nullptr).summary, throwsA(isA<LibGit2Error>()));
    });

    test('reverts commit affecting index and workdir', () {
      final commit = repo.lookupCommit(
        repo['821ed6e80627b8769d170a293862f9fc60825226'],
      );
      final index = repo.index;
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      repo.revert(commit);
      expect(index.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), false);

      index.free();
      commit.free();
    });

    test('throws when trying to revert and error occurs', () {
      expect(() => repo.revert(Commit(nullptr)), throwsA(isA<LibGit2Error>()));
    });

    test('reverts commit to provided commit', () {
      final to = repo.lookupCommit(
        repo['78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8'],
      );
      final from = repo.lookupCommit(
        repo['821ed6e80627b8769d170a293862f9fc60825226'],
      );
      final index = repo.index;
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      final revertIndex = repo.revertCommit(revertCommit: from, ourCommit: to);
      expect(revertIndex.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), true);

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

    test('creates commit', () {
      final parent = repo.lookupCommit(tip);
      final oid = repo.createCommit(
        updateRef: 'HEAD',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [parent],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.summary, 'Commit message.');
      expect(commit.body, 'Some description.');
      expect(commit.author, author);
      expect(commit.committer, committer);
      expect(commit.time, 124);
      expect(commit.timeOffset, 0);
      expect(commit.tree.oid, tree.oid);
      expect(commit.treeOid, tree.oid);
      expect(commit.parents.length, 1);
      expect(commit.parents[0], tip);

      commit.free();
      parent.free();
    });

    test('writes commit into the buffer', () {
      final parent = repo.lookupCommit(tip);
      final commit = Commit.createBuffer(
        repo: repo,
        updateRef: 'HEAD',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [parent],
      );

      const expected = """
tree a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f
parent 821ed6e80627b8769d170a293862f9fc60825226
author Author Name <author@email.com> 123 +0000
committer Commiter <commiter@email.com> 124 +0000

Commit message.

Some description.
""";

      expect(commit, expected);

      parent.free();
    });

    test('creates commit without parents', () {
      final oid = repo.createCommit(
        updateRef: 'refs/heads/new',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, committer);
      expect(commit.time, 124);
      expect(commit.treeOid, tree.oid);
      expect(commit.parents.length, 0);

      commit.free();
    });

    test('creates commit with 2 parents', () {
      final parent1 = repo.lookupCommit(tip);
      final parent2 = repo.lookupCommit(
        repo['fc38877b2552ab554752d9a77e1f48f738cca79b'],
      );

      final oid = Commit.create(
        updateRef: 'HEAD',
        repo: repo,
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [parent1, parent2],
      );

      final commit = repo.lookupCommit(oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, committer);
      expect(commit.time, 124);
      expect(commit.treeOid, tree.oid);
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
          committer: committer,
          tree: tree,
          parents: [parent],
        ),
        throwsA(isA<LibGit2Error>()),
      );

      parent.free();
    });

    test('throws when trying to write commit into a buffer and error occurs',
        () {
      final parent = repo.lookupCommit(tip);
      final nullRepo = Repository(nullptr);

      expect(
        () => Commit.createBuffer(
          repo: nullRepo,
          updateRef: 'HEAD',
          message: message,
          author: author,
          committer: committer,
          tree: tree,
          parents: [parent],
        ),
        throwsA(isA<LibGit2Error>()),
      );

      parent.free();
    });

    test('amends commit with default arguments', () {
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
      expect(amendedCommit.treeOid, commit.treeOid);
      expect(amendedCommit.parents, commit.parents);

      amendedCommit.free();
      commit.free();
      newHead.free();
      oldHead.free();
    });

    test('amends commit with provided arguments', () {
      final oldHead = repo.head;
      final commit = repo.lookupCommit(repo['821ed6e']);
      expect(commit.oid, oldHead.target);

      final amendedOid = repo.amendCommit(
        commit: commit,
        message: 'amended commit\n',
        updateRef: 'HEAD',
        author: author,
        committer: committer,
        tree: tree,
      );
      final amendedCommit = repo.lookupCommit(amendedOid);
      final newHead = repo.head;

      expect(amendedCommit.oid, newHead.target);
      expect(amendedCommit.message, 'amended commit\n');
      expect(amendedCommit.author, author);
      expect(amendedCommit.committer, committer);
      expect(amendedCommit.treeOid, tree.oid);
      expect(amendedCommit.parents, commit.parents);

      amendedCommit.free();
      commit.free();
      newHead.free();
      oldHead.free();
    });

    test('amends commit that is not the tip of the branch', () {
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

    test('creates an in-memory copy of a commit', () {
      final commit = repo.lookupCommit(tip);
      final dupCommit = commit.duplicate();

      expect(dupCommit.oid, commit.oid);

      dupCommit.free();
      commit.free();
    });

    test('returns header field', () {
      final commit = repo.lookupCommit(tip);
      expect(
        commit.headerField('parent'),
        '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
      );
      commit.free();
    });

    test('throws when header field not found', () {
      final commit = repo.lookupCommit(tip);
      expect(
        () => commit.headerField('not-there'),
        throwsA(isA<LibGit2Error>()),
      );
      commit.free();
    });

    test('returns nth generation ancestor commit', () {
      final commit = repo.lookupCommit(tip);
      final ancestor = commit.nthGenAncestor(3);

      expect(ancestor.oid.sha, 'f17d0d48eae3aa08cecf29128a35e310c97b3521');

      ancestor.free();
      commit.free();
    });

    test('throws when trying to get nth generation ancestor and none exists',
        () {
      final commit = repo.lookupCommit(tip);
      expect(() => commit.nthGenAncestor(10), throwsA(isA<LibGit2Error>()));
      commit.free();
    });

    test('returns parent at specified position', () {
      final commit = repo.lookupCommit(
        repo['78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8'],
      );
      final firstParent = commit.parent(0);
      final secondParent = commit.parent(1);

      expect(firstParent.oid.sha, 'c68ff54aabf660fcdd9a2838d401583fe31249e3');
      expect(secondParent.oid.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');

      secondParent.free();
      firstParent.free();
      commit.free();
    });

    test('throws when trying to get the parent at invalid position', () {
      final commit = repo.lookupCommit(tip);
      expect(() => commit.parent(10), throwsA(isA<LibGit2Error>()));
      commit.free();
    });

    test('returns string representation of Commit object', () {
      final commit = repo.lookupCommit(tip);
      expect(commit.toString(), contains('Commit{'));
      commit.free();
    });
  });
}
