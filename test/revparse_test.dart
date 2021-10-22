import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const headSHA = '821ed6e80627b8769d170a293862f9fc60825226';
  const parentSHA = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  setUp(() {
    tmpDir = setupRepo(Directory('test/assets/testrepo/'));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    repo.free();
    tmpDir.deleteSync(recursive: true);
  });

  group('revParse', () {
    test('.single() returns commit with different spec strings', () {
      final headCommit = repo.revParseSingle('HEAD');
      expect(headCommit.oid.sha, headSHA);

      final parentCommit = repo.revParseSingle('HEAD^');
      expect(parentCommit.oid.sha, parentSHA);

      final initCommit = repo.revParseSingle('@{-1}');
      expect(initCommit.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');

      headCommit.free();
      parentCommit.free();
      initCommit.free();
    });

    test('.single() throws when spec string not found or invalid', () {
      expect(
        () => repo.revParseSingle('invalid'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "revspec 'invalid' not found",
          ),
        ),
      );
      expect(
        () => repo.revParseSingle(''),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to parse revision specifier - Invalid pattern ''",
          ),
        ),
      );
    });

    test('.ext() returns commit and reference', () {
      final masterRef = repo.lookupReference('refs/heads/master');
      var headParse = repo.revParseExt('master');

      expect(headParse.object.oid.sha, headSHA);
      expect(headParse.reference, masterRef);
      expect(headParse.toString(), contains('RevParse{'));

      masterRef.free();
      headParse.object.free();
      headParse.reference?.free();

      final featureRef = repo.lookupReference('refs/heads/feature');
      headParse = repo.revParseExt('feature');

      expect(
        headParse.object.oid.sha,
        '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4',
      );
      expect(headParse.reference, featureRef);

      featureRef.free();
      headParse.object.free();
      headParse.reference?.free();
    });

    test('.ext() returns only commit when no intermidiate reference found', () {
      final headParse = repo.revParseExt('HEAD^');

      expect(headParse.object.oid.sha, parentSHA);
      expect(headParse.reference, isNull);

      headParse.object.free();
    });

    test('.ext() throws when spec string not found or invalid', () {
      expect(
        () => repo.revParseExt('invalid'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "revspec 'invalid' not found",
          ),
        ),
      );
      expect(
        () => repo.revParseExt(''),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to parse revision specifier - Invalid pattern ''",
          ),
        ),
      );
    });

    test(
        '.range returns revspec with correct fields values based on provided spec',
        () {
      var revspec = repo.revParse('master');

      expect(revspec.from.oid.sha, headSHA);
      expect(revspec.to, isNull);
      expect(revspec.flags, {GitRevSpec.single});
      expect(revspec.toString(), contains('RevSpec{'));

      revspec.from.free();

      revspec = repo.revParse('HEAD^1..5aecfa');

      expect(revspec.from.oid.sha, parentSHA);
      expect(revspec.to?.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range});

      revspec.from.free();
      revspec.to?.free();

      revspec = repo.revParse('HEAD...feature');

      expect(revspec.from.oid.sha, headSHA);
      expect(revspec.to?.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range, GitRevSpec.mergeBase});
      expect(
        repo.mergeBase(a: revspec.from.oid, b: revspec.to!.oid),
        isA<Oid>(),
      );

      revspec.from.free();
      revspec.to?.free();
    });

    test('throws on invalid range spec', () {
      expect(
        () => repo.revParse('invalid..5aecfa'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "revspec 'invalid' not found",
          ),
        ),
      );
      expect(
        () => repo.revParse('master........5aecfa'),
        throwsA(
          isA<LibGit2Error>().having(
            (e) => e.toString(),
            'error',
            "failed to parse revision specifier - Invalid pattern '.....5aecfa'",
          ),
        ),
      );
    });
  });
}
