import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Signature sig1;
  late Signature sig2;
  var hunks = <Map<String, dynamic>>[];

  setUp(() async {
    tmpDir = await setupRepo(Directory('test/assets/blamerepo/'));
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
        'finalCommitId': 'fc38877b2552ab554752d9a77e1f48f738cca79b',
        'finalStartLineNumber': 1,
        'finalCommitter': sig1,
        'originCommitId': 'fc38877b2552ab554752d9a77e1f48f738cca79b',
        'originStartLineNumber': 1,
        'originCommitter': sig1,
        'isBoundary': false,
      },
      {
        'finalCommitId': 'a07a01e325c2c04e05d2450ad37785fbfe0a0014',
        'finalStartLineNumber': 2,
        'finalCommitter': sig2,
        'originCommitId': 'a07a01e325c2c04e05d2450ad37785fbfe0a0014',
        'originStartLineNumber': 2,
        'originCommitter': sig2,
        'isBoundary': false,
      },
    ];
  });

  tearDown(() async {
    sig1.free();
    sig2.free();
    repo.free();
    await tmpDir.delete(recursive: true);
  });

  group('Blame', () {
    test('successfully gets the blame for provided file', () {
      final blame = repo.blame(path: 'feature_file');

      expect(blame.length, 2);

      for (var i = 0; i < blame.length; i++) {
        expect(blame[i].linesCount, 1);
        expect(blame[i].finalCommitId.sha, hunks[i]['finalCommitId']);
        expect(blame[i].finalStartLineNumber, hunks[i]['finalStartLineNumber']);
        expect(blame[i].finalCommitter, hunks[i]['finalCommitter']);
        expect(blame[i].originCommitId.sha, hunks[i]['originCommitId']);
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

    test('successfully gets the blame for provided line', () {
      final blame = repo.blame(path: 'feature_file');

      final hunk = blame.forLine(1);

      expect(hunk.linesCount, 1);
      expect(hunk.finalCommitId.sha, hunks[0]['finalCommitId']);
      expect(hunk.finalStartLineNumber, hunks[0]['finalStartLineNumber']);
      expect(hunk.finalCommitter, hunks[0]['finalCommitter']);
      expect(hunk.originCommitId.sha, hunks[0]['originCommitId']);
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
      expect(() => blame[10], throwsA(isA<RangeError>()));

      blame.free();
    });

    test('throws when provided line number for hunk is invalid', () {
      final blame = repo.blame(path: 'feature_file');
      expect(() => blame.forLine(10), throwsA(isA<RangeError>()));

      blame.free();
    });

    test(
        'successfully gets the blame for provided file with newestCommit argument',
        () {
      final newestCommit = Oid.fromSHA(
        repo: repo,
        sha: 'fc38877b2552ab554752d9a77e1f48f738cca79b',
      );
      final blame = repo.blame(
        path: 'feature_file',
        newestCommit: newestCommit,
        flags: {GitBlameFlag.ignoreWhitespace},
      );

      expect(blame.length, 1);

      final hunk = blame.first;

      expect(hunk.linesCount, 1);
      expect(hunk.finalCommitId.sha, hunks[0]['finalCommitId']);
      expect(hunk.finalStartLineNumber, hunks[0]['finalStartLineNumber']);
      expect(hunk.finalCommitter, hunks[0]['finalCommitter']);
      expect(hunk.originCommitId.sha, hunks[0]['originCommitId']);
      expect(
        hunk.originStartLineNumber,
        hunks[0]['originStartLineNumber'],
      );
      expect(hunk.originCommitter, hunks[0]['originCommitter']);
      expect(hunk.isBoundary, hunks[0]['isBoundary']);
      expect(hunk.originPath, 'feature_file');

      blame.free();
    });
  });
}
