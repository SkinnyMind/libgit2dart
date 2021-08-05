import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/src/repository.dart';
import 'package:libgit2dart/src/reflog.dart';

import 'helpers/util.dart';

void main() {
  group('RefLog', () {
    late final Repository repo;
    late final RefLog reflog;
    final tmpDir = '${Directory.systemTemp.path}/reflog_testrepo/';

    setUpAll(() async {
      if (await Directory(tmpDir).exists()) {
        await Directory(tmpDir).delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/testrepo/'),
        to: await Directory(tmpDir).create(),
      );
      repo = Repository.open(tmpDir);
      reflog = RefLog(repo.head);
    });

    tearDownAll(() async {
      repo.head.free();
      reflog.free();
      repo.free();
      await Directory(tmpDir).delete(recursive: true);
    });

    test('initializes successfully', () {
      expect(reflog, isA<RefLog>());
    });

    test('returns correct number of log entries', () {
      expect(reflog.count, 3);
    });

    test('returns the log message', () {
      final entry = reflog.entryAt(0);
      expect(
        entry.message,
        "merge feature: Merge made by the 'recursive' strategy.",
      );
    });

    test('returns the committer of the entry', () {
      final entry = reflog.entryAt(0);
      expect(entry.committer['name'], 'Aleksey Kulikov');
      expect(entry.committer['email'], 'skinny.mind@gmail.com');
    });
  });
}
