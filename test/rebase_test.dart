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

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/mergerepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() async {
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Rebase', () {
    test('successfully performs rebase when there is no conflicts', () {
      final signature = repo.defaultSignature;
      final master = repo.references['refs/heads/master'];
      final feature = repo.references['refs/heads/feature'];

      repo.checkout(refName: feature.name);
      expect(() => repo.index['.gitignore'], throwsA(isA<ArgumentError>()));

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
        expect(operation.id.sha, shas[i]);
        expect(operation.exec, '');

        rebase.commit(committer: signature);
      }

      rebase.finish();
      expect(repo.index['.gitignore'], isA<IndexEntry>());

      rebase.free();
      feature.free();
      master.free();
      signature.free();
    });

    test('successfully performs rebase with provided upstream', () {
      final signature = repo.defaultSignature;
      final master = repo.references['refs/heads/master'];
      final feature = repo.references['refs/heads/feature'];
      final startCommit = repo[shas[1]] as Commit;

      repo.checkout(refName: feature.name);
      expect(
        () => repo.index['conflict_file'],
        throwsA(isA<ArgumentError>()),
      );

      final rebase = Rebase.init(
        repo: repo,
        branch: master.target,
        onto: feature.target,
        upstream: startCommit.id,
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

    test('stops when there is conflicts', () {
      final signature = repo.defaultSignature;
      final master = repo.references['refs/heads/master'];
      final conflict = repo.references['refs/heads/conflict-branch'];

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
        throwsA(isA<LibGit2Error>()),
      );

      rebase.free();
      conflict.free();
      master.free();
      signature.free();
    });

    test('successfully aborts rebase in progress', () {
      final master = repo.references['refs/heads/master'];
      final conflict = repo.references['refs/heads/conflict-branch'];

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
