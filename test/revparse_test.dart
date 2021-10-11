import 'dart:io';
import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
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
      expect(headCommit.id.sha, headSHA);

      final parentCommit = repo.revParseSingle('HEAD^');
      expect(parentCommit.id.sha, parentSHA);

      final initCommit = repo.revParseSingle('@{-1}');
      expect(initCommit.id.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');

      headCommit.free();
      parentCommit.free();
      initCommit.free();
    });

    test('.ext() returns commit and reference', () {
      final masterRef = repo.lookupReference('refs/heads/master');
      var headParse = repo.revParseExt('master');

      expect(headParse.object.id.sha, headSHA);
      expect(headParse.reference, masterRef);

      masterRef.free();
      headParse.object.free();
      headParse.reference?.free();

      final featureRef = repo.lookupReference('refs/heads/feature');
      headParse = repo.revParseExt('feature');

      expect(
          headParse.object.id.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(headParse.reference, featureRef);

      featureRef.free();
      headParse.object.free();
      headParse.reference?.free();
    });

    test('.ext() returns only commit when no intermidiate reference found', () {
      final headParse = repo.revParseExt('HEAD^');

      expect(headParse.object.id.sha, parentSHA);
      expect(headParse.reference, isNull);

      headParse.object.free();
    });

    test(
        '.range returns revspec with correct fields values based on provided spec',
        () {
      var revspec = repo.revParse('master');

      expect(revspec.from.id.sha, headSHA);
      expect(revspec.to, isNull);
      expect(revspec.flags, {GitRevSpec.single});

      revspec.from.free();

      revspec = repo.revParse('HEAD^1..5aecfa');

      expect(revspec.from.id.sha, parentSHA);
      expect(revspec.to?.id.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range});

      revspec.from.free();
      revspec.to?.free();

      revspec = repo.revParse('HEAD...feature');

      expect(revspec.from.id.sha, headSHA);
      expect(revspec.to?.id.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range, GitRevSpec.mergeBase});
      expect(
        repo.mergeBase(a: revspec.from.id.sha, b: revspec.to!.id.sha),
        isA<Oid>(),
      );

      revspec.from.free();
      revspec.to?.free();
    });

    test('throws on invalid range spec', () {
      expect(
        () => repo.revParse('invalid..5aecfa'),
        throwsA(isA<LibGit2Error>()),
      );

      expect(
        () => repo.revParse('master........5aecfa'),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
