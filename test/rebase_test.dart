import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
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
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'merge_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Rebase', () {
    test('performs rebase when there is no conflicts', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final feature = Reference.lookup(repo: repo, name: 'refs/heads/feature');

      Checkout.reference(repo: repo, name: feature.name);
      repo.setHead(feature.name);
      expect(() => repo.index['.gitignore'], throwsA(isA<ArgumentError>()));

      final rebase = Rebase.init(
        repo: repo,
        branch: AnnotatedCommit.fromReference(repo: repo, reference: master),
        onto: AnnotatedCommit.fromReference(repo: repo, reference: feature),
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
    });

    test('performs rebase without branch provided', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final feature = Reference.lookup(repo: repo, name: 'refs/heads/feature');

      final rebase = Rebase.init(
        repo: repo,
        onto: AnnotatedCommit.lookup(repo: repo, oid: feature.target),
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
    });

    test('performs rebase with provided upstream', () {
      final signature = Signature.create(
        name: 'Author',
        email: 'author@email.com',
        time: 1234,
      );
      final master = Reference.lookup(repo: repo, name: 'refs/heads/master');
      final feature = Reference.lookup(repo: repo, name: 'refs/heads/feature');

      Checkout.reference(repo: repo, name: feature.name);
      repo.setHead(feature.name);
      expect(() => repo.index['conflict_file'], throwsA(isA<ArgumentError>()));

      final rebase = Rebase.init(
        repo: repo,
        branch: AnnotatedCommit.lookup(repo: repo, oid: master.target),
        upstream: AnnotatedCommit.lookup(repo: repo, oid: repo[shas[1]]),
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
      final conflict = Reference.lookup(
        repo: repo,
        name: 'refs/heads/conflict-branch',
      );

      Checkout.reference(repo: repo, name: conflict.name);
      repo.setHead(conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: AnnotatedCommit.lookup(
          repo: repo,
          oid: Reference.lookup(repo: repo, name: 'refs/heads/master').target,
        ),
        onto: AnnotatedCommit.lookup(repo: repo, oid: conflict.target),
      );
      expect(rebase.operations.length, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);
      expect(
        () => rebase.commit(committer: signature),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to perfrom next rebase operation and error occurs',
        () {
      final conflict = Reference.lookup(
        repo: repo,
        name: 'refs/heads/conflict-branch',
      );

      Checkout.reference(repo: repo, name: conflict.name);
      repo.setHead(conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: AnnotatedCommit.lookup(
          repo: repo,
          oid: Reference.lookup(repo: repo, name: 'refs/heads/master').target,
        ),
        onto: AnnotatedCommit.lookup(repo: repo, oid: conflict.target),
      );
      expect(rebase.operations.length, 1);

      rebase.next(); // repo now have conflicts
      expect(() => rebase.next(), throwsA(isA<LibGit2Error>()));
    });

    test('aborts rebase in progress', () {
      final conflict = Reference.lookup(
        repo: repo,
        name: 'refs/heads/conflict-branch',
      );

      Checkout.reference(repo: repo, name: conflict.name);
      repo.setHead(conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: AnnotatedCommit.lookup(
          repo: repo,
          oid: Reference.lookup(repo: repo, name: 'refs/heads/master').target,
        ),
        onto: AnnotatedCommit.lookup(repo: repo, oid: conflict.target),
      );
      expect(rebase.operations.length, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);

      rebase.abort();
      expect(repo.status, isEmpty);
      expect(repo.state, GitRepositoryState.none);
    });

    test('opens an existing rebase', () {
      final rebase = Rebase.init(
        repo: repo,
        onto: AnnotatedCommit.lookup(
          repo: repo,
          oid: Reference.lookup(repo: repo, name: 'refs/heads/feature').target,
        ),
      );
      expect(rebase.operations.length, 3);

      final openRebase = Rebase.open(repo);
      expect(openRebase.operations.length, 3);
    });

    test('throws when trying to open an existing rebase but there is none', () {
      expect(() => Rebase.open(repo), throwsA(isA<LibGit2Error>()));
    });

    test('manually releases allocated memory', () {
      final rebase = Rebase.init(
        repo: repo,
        onto: AnnotatedCommit.lookup(
          repo: repo,
          oid: Reference.lookup(repo: repo, name: 'refs/heads/feature').target,
        ),
      );

      expect(() => rebase.free(), returnsNormally);
    });
  });
}
