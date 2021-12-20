import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late RefLog reflog;
  late Reference head;
  late Directory tmpDir;

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/test_repo/'));
    repo = Repository.open(tmpDir.path);
    head = repo.head;
    reflog = RefLog(head);
  });

  tearDown(() {
    reflog.free();
    head.free();
    repo.free();
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

    test('returns string representation of RefLogEntry object', () {
      expect(reflog[0].toString(), contains('RefLogEntry{'));
    });
  });
}
