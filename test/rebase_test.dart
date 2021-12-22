import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const shas = [
    'c68ff54aabf660fcdd9a2838d401583fe31249e3',
    '821ed6e80627b8769d170a293862f9fc60825226',
    '14905459d775f3f56a39ebc2ff081163f7da3529',
  ];

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/merge_repo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Rebase', () {
    test('successfully performs rebase when there is no conflicts', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = repo.lookupReference('refs/heads/master');
      final branchHead = AnnotatedCommit.fromReference(
        repo: repo,
        reference: master,
      );
      final feature = repo.lookupReference('refs/heads/feature');
      final ontoHead = AnnotatedCommit.fromReference(
        repo: repo,
        reference: feature,
      );

      repo.checkout(refName: feature.name);
      expect(() => repo.index['.gitignore'], throwsA(isA<ArgumentError>()));

      final rebase = Rebase.init(
        repo: repo,
        branch: branchHead,
        onto: ontoHead,
      );

      expect(rebase.origHeadOid, master.target);
      expect(rebase.origHeadName, 'refs/heads/master');
      expect(rebase.ontoOid, feature.target);
      expect(rebase.ontoName, 'feature');

      final operations = rebase.operations;
      expect(operations.length, 3);

      for (var i = 0; i < operations.length; i++) {
        final operation = rebase.next();
        expect(operation.type, GitRebaseOperation.pick);
        expect(operation.oid.sha, shas[i]);
        expect(operation.toString(), contains('RebaseOperation{'));

        rebase.commit(
          committer: signature,
          author: signature,
          message: 'rebase message',
        );
      }

      rebase.finish();
      expect(repo.index['.gitignore'], isA<IndexEntry>());

      rebase.free();
      ontoHead.free();
      branchHead.free();
      feature.free();
      master.free();
      signature.free();
    });

    test('successfully performs rebase without branch provided', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final feature = repo.lookupReference('refs/heads/feature');
      final ontoHead = AnnotatedCommit.lookup(repo: repo, oid: feature.target);

      final rebase = Rebase.init(
        repo: repo,
        onto: ontoHead,
      );

      expect(
        rebase.origHeadOid.sha,
        '14905459d775f3f56a39ebc2ff081163f7da3529',
      );
      expect(rebase.origHeadName, 'refs/heads/master');
      expect(rebase.ontoOid, feature.target);
      expect(rebase.ontoName, '2ee89b2f7124b8e4632bc6a20774a90b795245e4');

      final operations = rebase.operations;
      expect(operations.length, 3);

      for (var i = 0; i < operations.length; i++) {
        final operation = rebase.next();
        expect(operation.type, GitRebaseOperation.pick);
        expect(operation.oid.sha, shas[i]);
        expect(operation.toString(), contains('RebaseOperation{'));

        rebase.commit(
          committer: signature,
          author: signature,
          message: 'rebase message',
        );
      }

      rebase.finish();

      rebase.free();
      ontoHead.free();
      feature.free();
      signature.free();
    });

    test('successfully performs rebase with provided upstream', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = repo.lookupReference('refs/heads/master');
      final branchHead = AnnotatedCommit.lookup(repo: repo, oid: master.target);
      final feature = repo.lookupReference('refs/heads/feature');
      final upstream = AnnotatedCommit.lookup(repo: repo, oid: repo[shas[1]]);

      repo.checkout(refName: feature.name);
      expect(() => repo.index['conflict_file'], throwsA(isA<ArgumentError>()));

      final rebase = Rebase.init(
        repo: repo,
        branch: branchHead,
        upstream: upstream,
      );

      expect(rebase.origHeadOid, master.target);
      expect(rebase.origHeadName, '');
      expect(rebase.ontoOid.sha, shas[1]);
      expect(rebase.ontoName, '821ed6e80627b8769d170a293862f9fc60825226');

      final operations = rebase.operations;
      expect(operations.length, 1);

      for (final operation in operations) {
        expect(rebase.currentOperation, -1);
        expect(operation.type, GitRebaseOperation.pick);
        rebase.next();
        expect(rebase.currentOperation, 0);
        rebase.commit(committer: signature);
      }

      rebase.finish();
      expect(repo.index['conflict_file'], isA<IndexEntry>());

      rebase.free();
      upstream.free();
      branchHead.free();
      feature.free();
      master.free();
      signature.free();
    });

    test(
        'throws when trying to initialize rebase without upstream and onto '
        'provided', () {
      expect(() => Rebase.init(repo: repo), throwsA(isA<LibGit2Error>()));
    });

    test('stops when there is conflicts', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = repo.lookupReference('refs/heads/master');
      final branchHead = AnnotatedCommit.lookup(repo: repo, oid: master.target);
      final conflict = repo.lookupReference('refs/heads/conflict-branch');
      final ontoHead = AnnotatedCommit.lookup(repo: repo, oid: conflict.target);

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: branchHead,
        onto: ontoHead,
      );
      expect(rebase.operations.length, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);
      expect(
        () => rebase.commit(committer: signature),
        throwsA(isA<LibGit2Error>()),
      );

      rebase.free();
      ontoHead.free();
      branchHead.free();
      conflict.free();
      master.free();
      signature.free();
    });

    test('throws when trying to perfrom next rebase operation and error occurs',
        () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = repo.lookupReference('refs/heads/master');
      final branchHead = AnnotatedCommit.lookup(repo: repo, oid: master.target);
      final conflict = repo.lookupReference('refs/heads/conflict-branch');
      final ontoHead = AnnotatedCommit.lookup(repo: repo, oid: conflict.target);

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: branchHead,
        onto: ontoHead,
      );
      expect(rebase.operations.length, 1);

      rebase.next(); // repo now have conflicts
      expect(() => rebase.next(), throwsA(isA<LibGit2Error>()));

      rebase.free();
      ontoHead.free();
      branchHead.free();
      conflict.free();
      master.free();
      signature.free();
    });

    test('successfully aborts rebase in progress', () {
      final master = repo.lookupReference('refs/heads/master');
      final branchHead = AnnotatedCommit.lookup(repo: repo, oid: master.target);
      final conflict = repo.lookupReference('refs/heads/conflict-branch');
      final ontoHead = AnnotatedCommit.lookup(repo: repo, oid: conflict.target);

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: branchHead,
        onto: ontoHead,
      );
      expect(rebase.operations.length, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);

      rebase.abort();
      expect(repo.status, isEmpty);
      expect(repo.state, GitRepositoryState.none);

      rebase.free();
      ontoHead.free();
      branchHead.free();
      conflict.free();
      master.free();
    });

    test('opens an existing rebase', () {
      final feature = repo.lookupReference('refs/heads/feature');
      final ontoHead = AnnotatedCommit.lookup(repo: repo, oid: feature.target);

      final rebase = Rebase.init(
        repo: repo,
        onto: ontoHead,
      );
      expect(rebase.operations.length, 3);

      final openRebase = Rebase.open(repo);
      expect(openRebase.operations.length, 3);

      openRebase.free();
      rebase.free();
      ontoHead.free();
      feature.free();
    });

    test('throws when trying to open an existing rebase but there is none', () {
      expect(() => Rebase.open(repo), throwsA(isA<LibGit2Error>()));
    });
  });
}
