import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature sig1;
  late Signature sig2;
  var hunks = <Map<String, Object>>[];

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/blamerepo/'));
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
    sig1.free();
    sig2.free();
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('Blame', () {
    test('successfully gets the blame for provided file', () {
      final blame = repo.blame(
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

      blame.free();
    });

    test('throws when provided file path is invalid', () {
      expect(
        () => repo.blame(path: 'invalid'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "the path 'invalid' does not exist in the given tree",
          ),
        ),
      );
    });

    test(
        'successfully gets the blame for provided file with minMatchCharacters set',
        () {
      final blame = repo.blame(
        path: 'feature_file',
        minMatchCharacters: 1,
        flags: {GitBlameFlag.trackCopiesSameFile},
      );

      expect(blame.length, 2);

      blame.free();
    });

    test('successfully gets the blame for provided line', () {
      final blame = repo.blame(path: 'feature_file');

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

      blame.free();
    });

    test('throws when provided index for hunk is invalid', () {
      final blame = repo.blame(path: 'feature_file');
      expect(
        () => blame[10],
        throwsA(
          isA<RangeError>().having(
            (e) => e.message,
            'error',
            '10 is out of bounds',
          ),
        ),
      );

      blame.free();
    });

    test('throws when provided line number for hunk is invalid', () {
      final blame = repo.blame(path: 'feature_file');
      expect(
        () => blame.forLine(10),
        throwsA(
          isA<RangeError>().having(
            (e) => e.message,
            'error',
            '10 is out of bounds',
          ),
        ),
      );

      blame.free();
    });

    test(
        'successfully gets the blame for provided file with newestCommit argument',
        () {
      final blame = repo.blame(
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

      blame.free();
    });

    test(
        'successfully gets the blame for provided file with minLine and maxLine set',
        () {
      final blame = repo.blame(
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

      blame.free();
    });

    test('returns string representation of BlameHunk object', () {
      final blame = repo.blame(path: 'feature_file');
      expect(blame.toString(), contains('BlameHunk{'));
      blame.free();
    });
  });
}
