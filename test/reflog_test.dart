import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  group('RefLog', () {
    late Repository repo;
    late RefLog reflog;
    final tmpDir = '${Directory.systemTemp.path}/reflog_testrepo/';

    setUp(() async {
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

    tearDown(() async {
      repo.head.free();
      reflog.free();
      repo.free();
      await Directory(tmpDir).delete(recursive: true);
    });

    test('initializes successfully', () {
      expect(reflog, isA<RefLog>());
    });

    test('returns correct number of log entries', () {
      expect(reflog.count, 4);
    });

    test('returns the log message', () {
      expect(reflog[0].message, "commit: add subdirectory file");
    });

    test('returns the committer of the entry', () {
      expect(reflog[0].committer.name, 'Aleksey Kulikov');
      expect(reflog[0].committer.email, 'skinny.mind@gmail.com');
      expect(reflog[0].committer.time, 1630568461);
    });
  });
}
