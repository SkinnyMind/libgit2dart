import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const log = [
    '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8',
    'c68ff54aabf660fcdd9a2838d401583fe31249e3',
    'fc38877b2552ab554752d9a77e1f48f738cca79b',
    '6cbc22e509d72758ab4c8d9f287ea846b90c448b',
    'f17d0d48eae3aa08cecf29128a35e310c97b3521',
  ];

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('RevWalk', () {
    test('initializes walker', () {
      final walker = RevWalk(repo);
      expect(walker, isA<RevWalk>());
      walker.free();
    });

    test('throws when trying to initialize and error occurs', () {
      expect(
        () => RevWalk(Repository(nullptr)),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns list of commits with default sorting', () {
      final walker = RevWalk(repo);
      final start = Oid.fromSHA(repo: repo, sha: log.first);

      walker.push(start);
      final commits = walker.walk();

      for (var i = 0; i < commits.length; i++) {
        expect(commits[i].oid.sha, log[i]);
        commits[i].free();
      }

      walker.free();
    });

    test('returns list of commits with reverse sorting', () {
      final walker = RevWalk(repo);
      final start = Oid.fromSHA(repo: repo, sha: log.first);

      walker.push(start);
      walker.sorting({GitSort.reverse});
      final commits = walker.walk();

      for (var i = 0; i < commits.length; i++) {
        expect(commits[i].oid.sha, log.reversed.toList()[i]);
        commits[i].free();
      }

      walker.free();
    });

    test('changes sorting', () {
      final walker = RevWalk(repo);
      final start = Oid.fromSHA(repo: repo, sha: log.first);

      walker.push(start);
      final timeSortedCommits = walker.walk();

      for (var i = 0; i < timeSortedCommits.length; i++) {
        expect(timeSortedCommits[i].oid.sha, log[i]);
        timeSortedCommits[i].free();
      }

      walker.sorting({GitSort.time, GitSort.reverse});
      final reverseSortedCommits = walker.walk();
      for (var i = 0; i < reverseSortedCommits.length; i++) {
        expect(reverseSortedCommits[i].oid.sha, log.reversed.toList()[i]);
        reverseSortedCommits[i].free();
      }

      walker.free();
    });

    test('adds matching references for traversal with provided glob', () {
      final walker = RevWalk(repo);

      walker.pushGlob('heads');
      final commits = walker.walk();
      expect(commits.length, 7);

      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test("adds repository's head for traversal", () {
      final walker = RevWalk(repo);

      walker.pushHead();
      final commits = walker.walk();
      expect(commits.length, 6);

      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test('adds reference for traversal with provided name', () {
      final walker = RevWalk(repo);

      walker.pushReference('refs/heads/master');
      final commits = walker.walk();
      expect(commits.length, 6);

      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test('throws when trying to add reference for traversal with invalid name',
        () {
      final walker = RevWalk(repo);

      expect(
        () => walker.pushReference('invalid'),
        throwsA(isA<LibGit2Error>()),
      );

      walker.free();
    });

    test('adds range for traversal', () {
      final walker = RevWalk(repo);

      walker.pushRange('HEAD..@{-1}');
      final commits = walker.walk();
      expect(commits.length, 1);

      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test('throws when trying to add invalid range for traversal', () {
      final walker = RevWalk(repo);

      expect(
        () => walker.pushRange('HEAD..invalid'),
        throwsA(isA<LibGit2Error>()),
      );

      walker.free();
    });

    test('hides commit and its ancestors', () {
      final walker = RevWalk(repo);

      walker.push(repo[log.first]);
      walker.hide(repo[log[2]]);
      final commits = walker.walk();

      expect(commits.length, 2);

      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test('throws when trying to hide commit oid and error occurs', () {
      final walker = RevWalk(repo);

      expect(
        () => walker.hide(repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );

      walker.free();
    });

    test('hides oids of references for provided glob pattern', () {
      final walker = RevWalk(repo);

      walker.pushGlob('heads');
      final commits = walker.walk();
      expect(commits.length, 7);

      walker.pushGlob('heads');
      walker.hideGlob('*master');
      final hiddenCommits = walker.walk();
      expect(hiddenCommits.length, 1);

      hiddenCommits[0].free();
      for (final c in commits) {
        c.free();
      }
      walker.free();
    });

    test('hides head', () {
      final head = repo.head;
      final walker = RevWalk(repo);

      walker.push(head.target);
      final commits = walker.walk();
      expect(commits.length, 6);

      walker.push(head.target);
      walker.hideHead();
      final hiddenCommits = walker.walk();
      expect(hiddenCommits.length, 0);

      for (final c in commits) {
        c.free();
      }
      head.free();
      walker.free();
    });

    test('hides oids of reference with provided name', () {
      final head = repo.head;
      final walker = RevWalk(repo);

      walker.push(head.target);
      final commits = walker.walk();
      expect(commits.length, 6);

      walker.push(head.target);
      walker.hideReference('refs/heads/master');
      final hiddenCommits = walker.walk();
      expect(hiddenCommits.length, 0);

      for (final c in commits) {
        c.free();
      }
      head.free();
      walker.free();
    });

    test('throws when trying to hide oids of reference with invalid name', () {
      final walker = RevWalk(repo);

      expect(
        () => walker.hideReference('invalid'),
        throwsA(isA<LibGit2Error>()),
      );

      walker.free();
    });

    test('resets walker', () {
      final walker = RevWalk(repo);
      final start = Oid.fromSHA(repo: repo, sha: log.first);

      walker.push(start);
      walker.reset();
      final commits = walker.walk();

      expect(commits, <Commit>[]);

      walker.free();
    });

    test('simplifies walker by enqueuing only first parent for each commit',
        () {
      final walker = RevWalk(repo);
      final start = Oid.fromSHA(repo: repo, sha: log.first);

      walker.push(start);
      walker.simplifyFirstParent();
      final commits = walker.walk();

      for (var i = 0; i < commits.length; i++) {
        expect(commits.length, 3);
        commits[i].free();
      }

      walker.free();
    });

    test('throws when trying to add new root for traversal and error occurs',
        () {
      final walker = RevWalk(repo);

      expect(
        () => walker.push(repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );

      walker.free();
    });
  });
}
