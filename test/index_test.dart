import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Index index;
  late Directory tmpDir;
  final mergeRepoPath = p.join('test', 'assets', 'merge_repo');

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    index = repo.index;
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Index', () {
    const fileSha = 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391';
    const featureFileSha = '9c78c21d6680a7ffebc76f7ac68cacc11d8f48bc';

    test('creates new in memory index object', () {
      expect(Index.newInMemory(), isA<Index>());
    });

    test('returns full path to the index file on disk', () {
      expect(index.path, p.join(repo.path, 'index'));
    });

    group('capabilities', () {
      test('returns index capabilities', () {
        expect(index.capabilities, isEmpty);
      });

      test('sets index capabilities', () {
        expect(index.capabilities, isEmpty);

        index.capabilities = {
          GitIndexCapability.ignoreCase,
          GitIndexCapability.noSymlinks,
        };

        expect(index.capabilities, {
          GitIndexCapability.ignoreCase,
          GitIndexCapability.noSymlinks,
        });
      });

      test('throws when trying to set index capabilities and error occurs', () {
        expect(
          () => Index(nullptr).capabilities = {},
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('returns number of entries', () {
      expect(index.length, 4);
    });

    test('returns mode of index entry', () {
      for (final entry in index) {
        expect(entry.mode, GitFilemode.blob);
      }
    });

    test('returns stage of entry', () {
      expect(index['file'].stage, 0);
    });

    test('returns index entry at provided position', () {
      expect(index[3].path, 'file');
      expect(index[3].oid.sha, fileSha);
    });

    test('returns index entry at provided path', () {
      expect(index['file'].path, 'file');
      expect(index['file'].oid.sha, fileSha);
    });

    test('throws if provided entry position is out of bounds', () {
      expect(() => index[10], throwsA(isA<RangeError>()));
    });

    test('throws if provided entry path is not found', () {
      expect(() => index[10], throwsA(isA<ArgumentError>()));
    });

    test('changes attributes', () {
      final entry = index['file'];
      final otherEntry = index['feature_file'];

      expect(entry.oid == otherEntry.oid, false);
      expect(entry.mode, isNot(GitFilemode.blobExecutable));

      entry.path = 'some.txt';
      entry.oid = otherEntry.oid;
      entry.mode = GitFilemode.blobExecutable;

      expect(entry.path, 'some.txt');
      expect(entry.oid == otherEntry.oid, true);
      expect(entry.mode, GitFilemode.blobExecutable);
    });

    test('clears the contents', () {
      expect(index.length, 4);
      index.clear();
      expect(index.length, 0);
    });

    test('throws when trying to clear the contents and error occurs', () {
      expect(() => Index(nullptr).clear(), throwsA(isA<LibGit2Error>()));
    });

    group('add()', () {
      test('adds with provided IndexEntry', () {
        final entry = index['file'];

        index.add(entry);
        expect(index['file'].oid.sha, fileSha);
        expect(index.length, 4);
      });

      test('adds with provided path string', () {
        index.add('file');
        expect(index['file'].oid.sha, fileSha);
        expect(index.length, 4);
      });

      test('throws if file not found at provided path', () {
        expect(() => index.add('not_there'), throwsA(isA<LibGit2Error>()));
      });

      test('throws if provided IndexEntry is invalid', () {
        expect(
          () => index.add(IndexEntry(nullptr)),
          throwsA(isA<LibGit2Error>()),
        );
      });

      test('throws if index of bare repository', () {
        final bare = Repository.open(
          p.join('test', 'assets', 'empty_bare.git'),
        );
        expect(() => bare.index.add('config'), throwsA(isA<LibGit2Error>()));
      });
    });

    group('addFromBuffer()', () {
      test('updates index entry from a buffer', () {
        expect(repo.status, isEmpty);

        index.addFromBuffer(entry: index['file'], buffer: 'updated');
        expect(repo.status, {
          'file': {GitStatus.indexModified, GitStatus.wtModified}
        });
      });

      test('throws when trying to update entry and error occurs', () {
        expect(
          () => index.addFromBuffer(entry: IndexEntry(nullptr), buffer: ''),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    group('addAll()', () {
      test('adds with provided pathspec', () {
        index.clear();
        index.addAll(
          ['file', 'feature_file'],
          flags: {GitIndexAddOption.checkPathspec, GitIndexAddOption.force},
        );

        expect(index.length, 2);
        expect(index['file'].oid.sha, fileSha);
        expect(index['feature_file'].oid.sha, featureFileSha);

        index.clear();
        index.addAll(['[f]*']);

        expect(index.length, 2);
        expect(index['file'].oid.sha, fileSha);
        expect(index['feature_file'].oid.sha, featureFileSha);

        index.clear();
        index.addAll(['feature_f???']);

        expect(index.length, 1);
        expect(index['feature_file'].oid.sha, featureFileSha);
      });

      test('throws when trying to addAll in bare repository', () {
        final bare = Repository.open(
          p.join('test', 'assets', 'empty_bare.git'),
        );
        expect(() => bare.index.addAll([]), throwsA(isA<LibGit2Error>()));
      });
    });

    group('updateAll()', () {
      test('updates all entries to match working directory', () {
        expect(repo.status, isEmpty);
        File(p.join(repo.workdir, 'file')).deleteSync();
        File(p.join(repo.workdir, 'feature_file')).deleteSync();

        index.updateAll(['file', 'feature_file']);
        expect(repo.status, {
          'file': {GitStatus.indexDeleted},
          'feature_file': {GitStatus.indexDeleted},
        });
      });

      test('throws when trying to update all entries in bare repository', () {
        final bare = Repository.open(
          p.join('test', 'assets', 'empty_bare.git'),
        );
        expect(
          () => bare.index.updateAll(['not_there']),
          throwsA(isA<LibGit2Error>()),
        );
      });
    });

    test('writes to disk', () {
      expect(index.length, 4);

      File(p.join(tmpDir.path, 'new_file')).createSync();

      index.add('new_file');
      index.write();

      index.clear();
      index.read();
      expect(index['new_file'].path, 'new_file');
      expect(index.length, 5);
    });

    test('removes an entry', () {
      expect(index.find('feature_file'), true);
      index.remove('feature_file');
      expect(index.find('feature_file'), false);
    });

    test('throws when trying to remove entry with invalid path', () {
      expect(() => index.remove('invalid'), throwsA(isA<LibGit2Error>()));
    });

    test('removes all entries with matching pathspec', () {
      expect(index.find('file'), true);
      expect(index.find('feature_file'), true);

      index.removeAll(['[f]*']);

      expect(index.find('file'), false);
      expect(index.find('feature_file'), false);
    });

    test('removes all entries from a directory', () {
      final subdirPath = p.join(repo.workdir, 'subdir');
      Directory(subdirPath).createSync();
      File(p.join(subdirPath, 'subfile')).createSync();

      index.add('subdir/subfile');
      expect(index.length, 5);

      index.removeDirectory('subdir');
      expect(index.length, 4);
    });

    test('reads tree with provided SHA hex', () {
      expect(index.length, 4);
      index.readTree(Tree.lookup(repo: repo, oid: repo['df2b8fc']));

      expect(index.length, 1);

      // make sure the index is only modified in memory
      index.read();
      expect(index.length, 4);
    });

    test('writes tree', () {
      expect(index.writeTree().sha, 'a8ae3dd59e6e1802c6f78e05e301bfd57c9f334f');
    });

    test('throws when trying to write tree to invalid repository', () {
      expect(
        () => index.writeTree(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('throws when trying to write tree while index have conflicts', () {
      final tmpDir = setupRepo(Directory(mergeRepoPath));
      final repo = Repository.open(tmpDir.path);

      Merge.commit(
        repo: repo,
        commit: AnnotatedCommit.lookup(
          repo: repo,
          oid: Branch.lookup(repo: repo, name: 'conflict-branch').target,
        ),
      );

      expect(() => repo.index.writeTree(), throwsA(isA<LibGit2Error>()));

      tmpDir.deleteSync(recursive: true);
    });

    test('adds conflict entry', () {
      expect(index.conflicts, isEmpty);
      index.addConflict(
        ancestorEntry: index['file'],
        ourEntry: index['file'],
        theirEntry: index['feature_file'],
      );
      expect(index.conflicts.length, 2);
    });

    test('throws when trying to add conflict entry and error occurs', () {
      expect(() => Index(nullptr).addConflict(), throwsA(isA<LibGit2Error>()));
    });

    test('returns conflicts with ancestor, our and their present', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      Checkout.reference(repo: conflictRepo, name: 'refs/heads/feature');
      conflictRepo.setHead('refs/heads/feature');

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(repo: conflictRepo, name: 'ancestor-conflict')
              .target,
        ),
      );

      final conflictedFile = conflictRepo.index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, 'feature_file');
      expect(conflictedFile.their?.path, 'feature_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with our and their present and null ancestor', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(
            repo: conflictRepo,
            name: 'conflict-branch',
          ).target,
        ),
      );

      final conflictedFile = conflictRepo.index.conflicts['conflict_file']!;
      expect(conflictedFile.ancestor?.path, null);
      expect(conflictedFile.our?.path, 'conflict_file');
      expect(conflictedFile.their?.path, 'conflict_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with ancestor and their present and null our', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      Checkout.reference(repo: conflictRepo, name: 'refs/heads/our-conflict');
      conflictRepo.setHead('refs/heads/our-conflict');

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(repo: conflictRepo, name: 'ancestor-conflict')
              .target,
        ),
      );

      final conflictedFile = conflictRepo.index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, null);
      expect(conflictedFile.their?.path, 'feature_file');
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      repoDir.deleteSync(recursive: true);
    });

    test('returns conflicts with ancestor and our present and null their', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      Checkout.reference(repo: conflictRepo, name: 'refs/heads/feature');
      conflictRepo.setHead('refs/heads/feature');

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(repo: conflictRepo, name: 'their-conflict').target,
        ),
      );

      final conflictedFile = conflictRepo.index.conflicts['feature_file']!;
      expect(conflictedFile.ancestor?.path, 'feature_file');
      expect(conflictedFile.our?.path, 'feature_file');
      expect(conflictedFile.their?.path, null);
      expect(conflictedFile.toString(), contains('ConflictEntry{'));

      repoDir.deleteSync(recursive: true);
    });

    test('removes conflict', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      final index = conflictRepo.index;

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(
            repo: conflictRepo,
            name: 'conflict-branch',
          ).target,
        ),
      );

      expect(index.hasConflicts, true);
      expect(index['.gitignore'].isConflict, false);
      expect(index.conflicts['conflict_file']!.our!.isConflict, true);
      expect(index.conflicts.length, 1);

      final conflictedFile = index.conflicts['conflict_file']!;
      conflictedFile.remove();

      expect(index.hasConflicts, false);
      expect(index.conflicts, isEmpty);
      expect(index.conflicts['conflict_file'], null);

      repoDir.deleteSync(recursive: true);
    });

    test('throws when trying to remove conflict and error occurs', () {
      expect(
        () => ConflictEntry(index.pointer, 'invalid.path', null, null, null)
            .remove(),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('removes all conflicts', () {
      final repoDir = setupRepo(Directory(mergeRepoPath));
      final conflictRepo = Repository.open(repoDir.path);

      final index = conflictRepo.index;

      Merge.commit(
        repo: conflictRepo,
        commit: AnnotatedCommit.lookup(
          repo: conflictRepo,
          oid: Branch.lookup(
            repo: conflictRepo,
            name: 'conflict-branch',
          ).target,
        ),
      );

      expect(index.hasConflicts, true);
      expect(index.conflicts.length, 1);

      index.cleanupConflict();

      expect(index.hasConflicts, false);
      expect(index.conflicts, isEmpty);

      repoDir.deleteSync(recursive: true);
    });

    test('throws when trying to remove all conflicts and error occurs', () {
      expect(
        () => Index(nullptr).cleanupConflict(),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      expect(() => repo.index.free(), returnsNormally);
    });

    test('returns string representation of Index and IndexEntry objects', () {
      final index = repo.index;

      expect(index.toString(), contains('Index{'));
      expect(index['file'].toString(), contains('IndexEntry{'));
    });

    test('supports value comparison', () {
      expect(repo.index, equals(repo.index));
    });
  });
}
