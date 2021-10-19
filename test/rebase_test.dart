import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
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
    tmpDir = setupRepo(Directory('test/assets/mergerepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Rebase', () {
    test('successfully performs rebase when there is no conflicts', () {
      final signature = repo.defaultSignature;
      final master = repo.lookupReference('refs/heads/master');
      final feature = repo.lookupReference('refs/heads/feature');

      repo.checkout(refName: feature.name);
      expect(
        () => repo.index['.gitignore'],
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'error',
            'Invalid argument: ".gitignore was not found"',
          ),
        ),
      );

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        onto: feature.target,
      );

      final operationsCount = rebase.operationsCount;
      expect(operationsCount, 3);

      for (var i = 0; i < operationsCount; i++) {
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
      feature.free();
      master.free();
      signature.free();
    });

    test('successfully performs rebase without branch provided', () {
      final signature = repo.defaultSignature;
      final feature = repo.lookupReference('refs/heads/feature');

      final rebase = Rebase.init(
        repo: repo,
        onto: feature.target,
      );

      final operationsCount = rebase.operationsCount;
      expect(operationsCount, 3);

      for (var i = 0; i < operationsCount; i++) {
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
      feature.free();
      signature.free();
    });

    test('successfully performs rebase with provided upstream', () {
      final signature = repo.defaultSignature;
      final master = repo.lookupReference('refs/heads/master');
      final feature = repo.lookupReference('refs/heads/feature');
      final startCommit = repo.lookupCommit(repo[shas[1]]);

      repo.checkout(refName: feature.name);
      expect(
        () => repo.index['conflict_file'],
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'error',
            'Invalid argument: "conflict_file was not found"',
          ),
        ),
      );

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        upstream: startCommit.oid,
      );

      final operationsCount = rebase.operationsCount;
      expect(operationsCount, 1);

      for (var i = 0; i < operationsCount; i++) {
        rebase.next();
        rebase.commit(committer: signature);
      }

      rebase.finish();
      expect(repo.index['conflict_file'], isA<IndexEntry>());

      rebase.free();
      startCommit.free();
      feature.free();
      master.free();
      signature.free();
    });

    test(
        'throws when trying to initialize rebase without upstream and onto provided',
        () {
      expect(
        () => Rebase.init(repo: repo),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "invalid argument: 'upstream || onto'",
          ),
        ),
      );
    });

    test('stops when there is conflicts', () {
      final signature = repo.defaultSignature;
      final master = repo.lookupReference('refs/heads/master');
      final conflict = repo.lookupReference('refs/heads/conflict-branch');

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        onto: conflict.target,
      );
      expect(rebase.operationsCount, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);
      expect(
        () => rebase.commit(committer: signature),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            'unstaged changes exist in workdir',
          ),
        ),
      );

      rebase.free();
      conflict.free();
      master.free();
      signature.free();
    });

    test('throws when trying to perfrom next rebase operation and error occurs',
        () {
      final signature = repo.defaultSignature;
      final master = repo.lookupReference('refs/heads/master');
      final conflict = repo.lookupReference('refs/heads/conflict-branch');

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        onto: conflict.target,
      );
      expect(rebase.operationsCount, 1);

      rebase.next(); // repo now have conflicts
      expect(
        () => rebase.next(),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "object not found - failed to find pack entry (790b86f5fb50db485586370f27c5f90bada97d83)",
          ),
        ),
      );

      rebase.free();
      conflict.free();
      master.free();
      signature.free();
    });

    test('successfully aborts rebase in progress', () {
      final master = repo.lookupReference('refs/heads/master');
      final conflict = repo.lookupReference('refs/heads/conflict-branch');

      repo.checkout(refName: conflict.name);

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        onto: conflict.target,
      );
      expect(rebase.operationsCount, 1);

      rebase.next();
      expect(repo.status['conflict_file'], {GitStatus.conflicted});
      expect(repo.state, GitRepositoryState.rebaseMerge);

      rebase.abort();
      expect(repo.status, isEmpty);
      expect(repo.state, GitRepositoryState.none);

      rebase.free();
      conflict.free();
      master.free();
    });
  });
}
