import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature sig1;
  late Signature sig2;
  var hunks = <Map<String, Object>>[];

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'blame_repo')));
    repo = Repository.open(tmpDir.path);
    sig1 = Signature.create(
      name: 'Aleksey Kulikov',
      email: 'skinny.mind@gmail.com',
      time: 1626091054,
      offset: 180,
    );
    sig2 = Signature.create(
      name: 'Aleksey Kulikov',
      email: 'skinny.mind@gmail.com',
      time: 1633081062,
      offset: 180,
    );

    hunks = [
      {
        'finalCommitOid': 'fc38877b2552ab554752d9a77e1f48f738cca79b',
        'finalStartLineNumber': 1,
        'finalCommitter': sig1,
        'originCommitOid': 'fc38877b2552ab554752d9a77e1f48f738cca79b',
        'originStartLineNumber': 1,
        'originCommitter': sig1,
        'isBoundary': false,
      },
      {
        'finalCommitOid': 'a07a01e325c2c04e05d2450ad37785fbfe0a0014',
        'finalStartLineNumber': 2,
        'finalCommitter': sig2,
        'originCommitOid': 'a07a01e325c2c04e05d2450ad37785fbfe0a0014',
        'originStartLineNumber': 2,
        'originCommitter': sig2,
        'isBoundary': false,
      },
    ];
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('Blame', () {
    test('returns the blame for provided file', () {
      final blame = Blame.file(
        repo: repo,
        path: 'feature_file',
        oldestCommit: repo['f17d0d4'],
      );

      expect(blame.length, 2);

      for (var i = 0; i < blame.length; i++) {
        expect(blame[i].linesCount, 1);
        expect(blame[i].finalCommitOid.sha, hunks[i]['finalCommitOid']);
        expect(blame[i].finalStartLineNumber, hunks[i]['finalStartLineNumber']);
        expect(blame[i].finalCommitter, hunks[i]['finalCommitter']);
        expect(blame[i].originCommitOid.sha, hunks[i]['originCommitOid']);
        expect(
          blame[i].originStartLineNumber,
          hunks[i]['originStartLineNumber'],
        );
        expect(blame[i].originCommitter, hunks[i]['originCommitter']);
        expect(blame[i].isBoundary, hunks[i]['isBoundary']);
        expect(blame[i].originPath, 'feature_file');
      }
    });

    test('throws when provided file path is invalid', () {
      expect(
        () => Blame.file(repo: repo, path: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns blame for buffer', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(blame.length, 2);

      final bufferBlame = Blame.buffer(reference: blame, buffer: ' ');
      final blameHunk = bufferBlame.first;
      expect(bufferBlame.length, 1);
      expect(blameHunk.originCommitOid.sha, '0' * 40);
      expect(blameHunk.originCommitter, null);
      expect(blameHunk.finalCommitOid.sha, '0' * 40);
      expect(blameHunk.finalCommitter, null);
    });

    test('throws when trying to get blame for empty buffer', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(
        () => Blame.buffer(reference: blame, buffer: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('returns the blame for provided file with minMatchCharacters set', () {
      final blame = Blame.file(
        repo: repo,
        path: 'feature_file',
        minMatchCharacters: 1,
        flags: {GitBlameFlag.trackCopiesSameFile},
      );

      expect(blame.length, 2);
    });

    test('returns the blame for provided line', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');

      final hunk = blame.forLine(1);

      expect(hunk.linesCount, 1);
      expect(hunk.finalCommitOid.sha, hunks[0]['finalCommitOid']);
      expect(hunk.finalStartLineNumber, hunks[0]['finalStartLineNumber']);
      expect(hunk.finalCommitter, hunks[0]['finalCommitter']);
      expect(hunk.originCommitOid.sha, hunks[0]['originCommitOid']);
      expect(
        hunk.originStartLineNumber,
        hunks[0]['originStartLineNumber'],
      );
      expect(hunk.originCommitter, hunks[0]['originCommitter']);
      expect(hunk.isBoundary, hunks[0]['isBoundary']);
      expect(hunk.originPath, 'feature_file');
    });

    test('throws when provided index for hunk is invalid', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(() => blame[10], throwsA(isA<RangeError>()));
    });

    test('throws when provided line number for hunk is invalid', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(() => blame.forLine(10), throwsA(isA<RangeError>()));
    });

    test('returns the blame for provided file with newestCommit argument', () {
      final blame = Blame.file(
        repo: repo,
        path: 'feature_file',
        newestCommit: repo['fc38877'],
        flags: {GitBlameFlag.ignoreWhitespace},
      );

      expect(blame.length, 1);

      final hunk = blame.first;

      expect(hunk.linesCount, 1);
      expect(hunk.finalCommitOid.sha, hunks[0]['finalCommitOid']);
      expect(hunk.finalStartLineNumber, hunks[0]['finalStartLineNumber']);
      expect(hunk.finalCommitter, hunks[0]['finalCommitter']);
      expect(hunk.originCommitOid.sha, hunks[0]['originCommitOid']);
      expect(
        hunk.originStartLineNumber,
        hunks[0]['originStartLineNumber'],
      );
      expect(hunk.originCommitter, hunks[0]['originCommitter']);
      expect(hunk.isBoundary, hunks[0]['isBoundary']);
      expect(hunk.originPath, 'feature_file');
    });

    test('returns the blame for provided file with minLine and maxLine set',
        () {
      final blame = Blame.file(
        repo: repo,
        path: 'feature_file',
        minLine: 1,
        maxLine: 1,
      );

      expect(blame.length, 1);

      for (var i = 0; i < blame.length; i++) {
        expect(blame[i].linesCount, 1);
        expect(blame[i].finalCommitOid.sha, hunks[i]['finalCommitOid']);
        expect(blame[i].finalStartLineNumber, hunks[i]['finalStartLineNumber']);
        expect(blame[i].finalCommitter, hunks[i]['finalCommitter']);
        expect(blame[i].originCommitOid.sha, hunks[i]['originCommitOid']);
        expect(
          blame[i].originStartLineNumber,
          hunks[i]['originStartLineNumber'],
        );
        expect(blame[i].originCommitter, hunks[i]['originCommitter']);
        expect(blame[i].isBoundary, hunks[i]['isBoundary']);
        expect(blame[i].originPath, 'feature_file');
      }
    });

    test('manually releases allocated memory', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(() => blame.free(), returnsNormally);
    });

    test('returns string representation of BlameHunk object', () {
      final blame = Blame.file(repo: repo, path: 'feature_file');
      expect(blame.toString(), contains('BlameHunk{'));
    });

    test('supports value comparison', () {
      expect(
        Blame.file(repo: repo, path: 'feature_file'),
        equals(Blame.file(repo: repo, path: 'feature_file')),
      );
    });
  });
}
