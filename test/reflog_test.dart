import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late RefLog reflog;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    reflog = RefLog(repo.head);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('RefLog', () {
    test('initializes successfully', () {
      expect(reflog, isA<RefLog>());
    });

    test('returns correct number of log entries', () {
      expect(reflog.length, 4);
    });

    test('returns the log message', () {
      expect(reflog[0].message, "commit: add subdirectory file");
    });

    test('returns the committer of the entry', () {
      expect(reflog[0].committer.name, 'Aleksey Kulikov');
      expect(reflog[0].committer.email, 'skinny.mind@gmail.com');
      expect(reflog[0].committer.time, 1630568461);
    });

    test('returns new and old oids of entry', () {
      expect(reflog[0].newOid.sha, '821ed6e80627b8769d170a293862f9fc60825226');
      expect(reflog.last.oldOid.sha, '0' * 40);
    });

    test('deletes the reflog of provided reference', () {
      expect(repo.head.hasLog, true);
      RefLog.delete(repo.head);
      expect(repo.head.hasLog, false);
    });

    test('renames existing reflog', () {
      final masterPath = p.join(repo.path, 'logs', 'refs', 'heads', 'master');
      final renamedPath = p.join(repo.path, 'logs', 'refs', 'heads', 'renamed');

      expect(File(masterPath).existsSync(), true);
      expect(File(renamedPath).existsSync(), false);

      RefLog.rename(
        repo: repo,
        oldName: 'refs/heads/master',
        newName: 'refs/heads/renamed',
      );

      expect(File(masterPath).existsSync(), false);
      expect(File(renamedPath).existsSync(), true);
    });

    test('throws when trying to rename reflog and provided new name is invalid',
        () {
      expect(
        () => RefLog.rename(
          repo: repo,
          oldName: 'refs/heads/master',
          newName: '',
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('adds a new entry to the in-memory reflog', () {
      final committer = Signature.create(
        name: 'Commiter',
        email: 'commiter@email.com',
        time: 124,
      );

      expect(reflog.length, 4);
      reflog.add(oid: repo.head.target, committer: committer);
      expect(reflog.length, 5);

      reflog.add(
        oid: repo.head.target,
        committer: committer,
        message: 'new entry',
      );
      expect(reflog.length, 6);
      expect(reflog[0].message, 'new entry');
    });

    test('throws when trying to add new entry', () {
      expect(
        () => reflog.add(oid: repo.head.target, committer: Signature(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('removes entry from reflog with provided index', () {
      expect(reflog.length, 4);
      expect(reflog[0].message, 'commit: add subdirectory file');

      reflog.remove(0);
      expect(reflog.length, 3);
      expect(
        reflog[0].message,
        "merge feature: Merge made by the 'recursive' strategy.",
      );
    });

    test('throws when trying to remove entry from reflog at invalid index', () {
      expect(() => reflog.remove(-1), throwsA(isA<LibGit2Error>()));
    });

    test('writes in-memory reflog to disk', () {
      expect(reflog.length, 4);
      reflog.remove(0);

      // making sure change is only in memory
      final oldReflog = RefLog(repo.head);
      expect(oldReflog.length, 4);

      reflog.write();

      final newReflog = RefLog(repo.head);
      expect(newReflog.length, 3);
    });

    test('throws when trying to write reflog to disk and error occurs', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/feature');
      final reflog = ref.log;
      Reference.delete(repo: repo, name: ref.name);

      expect(() => reflog.write(), throwsA(isA<LibGit2Error>()));
    });

    test('manually releases allocated memory', () {
      expect(() => RefLog(repo.head).free(), returnsNormally);
    });

    test('returns string representation of RefLogEntry object', () {
      expect(reflog[0].toString(), contains('RefLogEntry{'));
    });

    test('supports value comparison', () {
      final ref = Reference.lookup(repo: repo, name: 'refs/heads/master');
      expect(RefLog(repo.head), equals(RefLog(ref)));
    });
  });
}
