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
    tree = Tree.lookup(repo: repo, oid: repo['a8ae3dd']);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Commit', () {
    test('lookups commit for provided oid', () {
      expect(Commit.lookup(repo: repo, oid: tip), isA<Commit>());
    });

    test('throws when trying to lookup with invalid oid', () {
      expect(
        () => Commit.lookup(repo: repo, oid: repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
        'throws when trying to get the summary of the commit message and error '
        'occurs', () {
      expect(() => Commit(nullptr).summary, throwsA(isA<LibGit2Error>()));
    });

    test('reverts commit affecting index and workdir', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(repo.index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      commit.revert();

      expect(repo.index.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), false);
    });

    test('reverts merge commit to provided parent', () {
      const masterContents = 'master contents';
      final file = File(p.join(repo.workdir, 'another_feature_file'))
        ..createSync()
        ..writeAsStringSync(masterContents);

      repo.index.add('another_feature_file');
      repo.index.write();

      // Creating commit on 'master' branch with file contents conflicting to
      // 'feature' branch.
      final masterTip = Commit.create(
        repo: repo,
        updateRef: 'HEAD',
        message: 'master commit\n',
        author: author,
        committer: committer,
        tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
        parents: [Commit.lookup(repo: repo, oid: repo.head.target)],
      );

      // Switching to 'feature' branch.
      Checkout.reference(repo: repo, name: 'refs/heads/feature');
      repo.setHead('refs/heads/feature');

      file.writeAsStringSync('feature contents');

      repo.index.add('another_feature_file');
      repo.index.write();

      // Creating commit on 'feature' branch with file contents conflicting to
      // 'master' branch.
      final featureTip = Commit.create(
        repo: repo,
        updateRef: 'HEAD',
        message: 'feature commit\n',
        author: author,
        committer: committer,
        tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
        parents: [Commit.lookup(repo: repo, oid: repo.head.target)],
      );

      // Merging master branch.
      Merge.commit(
        repo: repo,
        commit: AnnotatedCommit.lookup(
          repo: repo,
          oid: Oid.fromSHA(repo: repo, sha: masterTip.sha),
        ),
      );

      expect(repo.index.hasConflicts, true);

      // "Resolving" conflict.
      repo.index.updateAll(['another_feature_file']);
      repo.index.write();
      repo.stateCleanup();

      // Creating merge commit.
      final mergeOid = Commit.create(
        repo: repo,
        updateRef: 'HEAD',
        message: 'merge commit\n',
        author: author,
        committer: committer,
        tree: Tree.lookup(repo: repo, oid: repo.index.writeTree()),
        parents: [
          Commit.lookup(repo: repo, oid: featureTip),
          Commit.lookup(repo: repo, oid: masterTip),
        ],
      );

      final mergeCommit = Commit.lookup(repo: repo, oid: mergeOid);
      mergeCommit.revert(mainline: 2);

      expect(file.readAsStringSync(), masterContents);
    });

    test('reverts commit with provided merge options and checkout options', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(repo.index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      commit.revert(
        mergeFavor: GitMergeFileFavor.ours,
        mergeFlags: {GitMergeFlag.noRecursive, GitMergeFlag.skipREUC},
        mergeFileFlags: {
          GitMergeFileFlag.ignoreWhitespace,
          GitMergeFileFlag.styleZdiff3
        },
        checkoutStrategy: {
          GitCheckout.force,
          GitCheckout.conflictStyleMerge,
        },
        checkoutDirectory: repo.workdir,
        checkoutPaths: ['dir/dir_file.txt'],
      );

      expect(repo.index.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), false);
    });

    test('throws when trying to revert and error occurs', () {
      expect(() => Commit(nullptr).revert(), throwsA(isA<LibGit2Error>()));
    });

    test('reverts commit to provided commit', () {
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(repo.index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      final from = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final revertIndex = from.revertTo(
        commit: Commit.lookup(repo: repo, oid: repo['78b8bf1']),
      );
      expect(revertIndex.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), true);
    });

    test('reverts commit to provided commit with provided merge options', () {
      final file = File(p.join(repo.workdir, 'dir', 'dir_file.txt'));
      expect(repo.index.find('dir/dir_file.txt'), true);
      expect(file.existsSync(), true);

      final from = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      final revertIndex = from.revertTo(
        commit: Commit.lookup(repo: repo, oid: repo['78b8bf1']),
        mergeFavor: GitMergeFileFavor.ours,
        mergeFlags: {GitMergeFlag.noRecursive, GitMergeFlag.skipREUC},
        mergeFileFlags: {
          GitMergeFileFlag.ignoreWhitespace,
          GitMergeFileFlag.styleZdiff3
        },
      );
      expect(revertIndex.find('dir/dir_file.txt'), false);
      expect(file.existsSync(), true);
    });

    test('throws when trying to revert commit and error occurs', () {
      final nullCommit = Commit(nullptr);
      expect(
        () => nullCommit.revertTo(commit: nullCommit),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('checks if commit is a descendant of another commit', () {
      final commit1 = Commit.lookup(repo: repo, oid: repo['821ed6e8']);
      final commit2 = Commit.lookup(repo: repo, oid: repo['78b8bf12']);

      expect(commit1.descendantOf(commit2.oid), true);
      expect(commit1.descendantOf(commit1.oid), false);
      expect(commit2.descendantOf(commit1.oid), false);
    });

    test('creates commit', () {
      final oid = Commit.create(
        repo: repo,
        updateRef: 'HEAD',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [Commit.lookup(repo: repo, oid: tip)],
      );

      final commit = Commit.lookup(repo: repo, oid: oid);

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
    });

    test('writes commit without parents into the buffer', () {
      final commit = Commit.createBuffer(
        repo: repo,
        updateRef: 'HEAD',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [],
      );

      const expected = """
tree a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f
author Author Name <author@email.com> 123 +0000
committer Commiter <commiter@email.com> 124 +0000

Commit message.

Some description.
""";

      expect(commit, expected);
    });

    test('writes commit into the buffer', () {
      final commit = Commit.createBuffer(
        repo: repo,
        updateRef: 'HEAD',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [Commit.lookup(repo: repo, oid: tip)],
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
    });

    test('creates commit without parents', () {
      final oid = Commit.create(
        repo: repo,
        updateRef: 'refs/heads/new',
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [],
      );

      final commit = Commit.lookup(repo: repo, oid: oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, committer);
      expect(commit.time, 124);
      expect(commit.treeOid, tree.oid);
      expect(commit.parents.length, 0);
    });

    test('creates commit with 2 parents', () {
      final parent1 = Commit.lookup(repo: repo, oid: tip);
      final parent2 = Commit.lookup(repo: repo, oid: repo['fc38877']);

      final oid = Commit.create(
        updateRef: 'HEAD',
        repo: repo,
        message: message,
        author: author,
        committer: committer,
        tree: tree,
        parents: [parent1, parent2],
      );

      final commit = Commit.lookup(repo: repo, oid: oid);

      expect(commit.oid, oid);
      expect(commit.message, message);
      expect(commit.messageEncoding, 'utf-8');
      expect(commit.author, author);
      expect(commit.committer, committer);
      expect(commit.time, 124);
      expect(commit.treeOid, tree.oid);
      expect(commit.parents.length, 2);
      expect(commit.parents[0], parent1.oid);
      expect(commit.parents[1], parent2.oid);
    });

    test('throws when trying to create commit and error occurs', () {
      expect(
        () => Commit.create(
          repo: Repository(nullptr),
          updateRef: 'HEAD',
          message: message,
          author: author,
          committer: committer,
          tree: tree,
          parents: [Commit.lookup(repo: repo, oid: tip)],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to write commit into a buffer and error occurs',
        () {
      expect(
        () => Commit.createBuffer(
          repo: Repository(nullptr),
          updateRef: 'HEAD',
          message: message,
          author: author,
          committer: committer,
          tree: tree,
          parents: [Commit.lookup(repo: repo, oid: tip)],
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('amends commit with default arguments', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      expect(commit.oid, repo.head.target);

      final amendedOid = Commit.amend(
        repo: repo,
        commit: commit,
        message: 'amended commit\n',
        updateRef: 'HEAD',
      );
      final amendedCommit = Commit.lookup(repo: repo, oid: amendedOid);

      expect(amendedCommit.oid, repo.head.target);
      expect(amendedCommit.message, 'amended commit\n');
      expect(amendedCommit.author, commit.author);
      expect(amendedCommit.committer, commit.committer);
      expect(amendedCommit.treeOid, commit.treeOid);
      expect(amendedCommit.parents, commit.parents);
    });

    test('amends commit with provided arguments', () {
      final commit = Commit.lookup(repo: repo, oid: repo['821ed6e']);
      expect(commit.oid, repo.head.target);

      final amendedOid = Commit.amend(
        repo: repo,
        commit: commit,
        message: 'amended commit\n',
        updateRef: 'HEAD',
        author: author,
        committer: committer,
        tree: tree,
      );
      final amendedCommit = Commit.lookup(repo: repo, oid: amendedOid);

      expect(amendedCommit.oid, repo.head.target);
      expect(amendedCommit.message, 'amended commit\n');
      expect(amendedCommit.author, author);
      expect(amendedCommit.committer, committer);
      expect(amendedCommit.treeOid, tree.oid);
      expect(amendedCommit.parents, commit.parents);
    });

    test('amends commit that is not the tip of the branch', () {
      final commit = Commit.lookup(repo: repo, oid: repo['78b8bf1']);
      expect(commit.oid, isNot(repo.head.target));

      expect(
        () => Commit.amend(
          repo: repo,
          updateRef: null,
          commit: commit,
          message: 'amended commit\n',
        ),
        returnsNormally,
      );
    });

    test(
        'throws when trying to amend commit that is not the tip of the branch '
        'with HEAD provided as update reference', () {
      final commit = Commit.lookup(repo: repo, oid: repo['78b8bf1']);
      expect(commit.oid, isNot(repo.head.target));

      expect(
        () => Commit.amend(
          repo: repo,
          commit: commit,
          message: 'amended commit\n',
          updateRef: 'HEAD',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates an in-memory copy of a commit', () {
      final commit = Commit.lookup(repo: repo, oid: tip);
      final dupCommit = commit.duplicate();

      expect(dupCommit.oid, commit.oid);
    });

    test('returns header field', () {
      final commit = Commit.lookup(repo: repo, oid: tip);
      expect(
        commit.headerField('parent'),
        '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
      );
    });

    test('throws when header field not found', () {
      final commit = Commit.lookup(repo: repo, oid: tip);
      expect(
        () => commit.headerField('not-there'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns nth generation ancestor commit', () {
      final ancestor = Commit.lookup(repo: repo, oid: tip).nthGenAncestor(3);
      expect(ancestor.oid.sha, 'f17d0d48eae3aa08cecf29128a35e310c97b3521');
    });

    test('throws when trying to get nth generation ancestor and none exists',
        () {
      expect(
        () => Commit.lookup(repo: repo, oid: tip).nthGenAncestor(10),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns parent at specified position', () {
      final commit = Commit.lookup(repo: repo, oid: repo['78b8bf1']);
      final firstParent = commit.parent(0);
      final secondParent = commit.parent(1);

      expect(firstParent.oid.sha, 'c68ff54aabf660fcdd9a2838d401583fe31249e3');
      expect(secondParent.oid.sha, 'fc38877b2552ab554752d9a77e1f48f738cca79b');
    });

    test('throws when trying to get the parent at invalid position', () {
      expect(
        () => Commit.lookup(repo: repo, oid: tip).parent(10),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final commit = Commit.lookup(repo: repo, oid: tip);
      expect(() => commit.free(), returnsNormally);
    });

    test('returns string representation of Commit object', () {
      final commit = Commit.lookup(repo: repo, oid: tip);
      expect(commit.toString(), contains('Commit{'));
    });

    test('supports value comparison', () {
      expect(
        Commit.lookup(repo: repo, oid: tip),
        equals(Commit.lookup(repo: repo, oid: tip)),
      );
    });
  });
}
