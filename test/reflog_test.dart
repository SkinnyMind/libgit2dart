import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late RefLog reflog;
  late Reference head;
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
    head = repo.head;
    reflog = RefLog(head);
  });

  tearDown(() async {
    reflog.free();
    head.free();
    repo.free();
    await Directory(tmpDir).delete(recursive: true);
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
  });
}
