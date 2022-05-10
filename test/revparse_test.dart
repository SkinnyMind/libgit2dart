import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  const headSHA = '821ed6e80627b8769d170a293862f9fc60825226';
  const parentSHA = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('revParse', () {
    test('.single() returns correct objects with different spec strings', () {
      final commit = RevParse.single(repo: repo, spec: 'HEAD') as Commit;
      expect(commit, isA<Commit>());
      expect(commit.oid.sha, headSHA);

      final tree = RevParse.single(repo: repo, spec: 'HEAD^{tree}') as Tree;
      expect(tree, isA<Tree>());
      expect(tree.length, isNonZero);

      final blob = RevParse.single(
        repo: repo,
        spec: 'HEAD:feature_file',
      ) as Blob;
      expect(blob, isA<Blob>());
      expect(blob.content, 'Feature edit\n');

      final tag = RevParse.single(repo: repo, spec: 'v0.2') as Tag;
      expect(tag, isA<Tag>());
      expect(tag.message, 'annotated tag\n');
    });

    test('.single() throws when spec string not found or invalid', () {
      expect(
        () => RevParse.single(repo: repo, spec: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );
      expect(
        () => RevParse.single(repo: repo, spec: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('.ext() returns commit and reference', () {
      final masterRef = Reference.lookup(repo: repo, name: 'refs/heads/master');
      var headParse = RevParse.ext(repo: repo, spec: 'master');

      expect(headParse.object.oid.sha, headSHA);
      expect(headParse.reference, equals(masterRef));
      expect(headParse.toString(), contains('RevParse{'));

      final featureRef = Reference.lookup(
        repo: repo,
        name: 'refs/heads/feature',
      );
      headParse = RevParse.ext(repo: repo, spec: 'feature');

      expect(
        headParse.object.oid.sha,
        '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4',
      );
      expect(headParse.reference, equals(featureRef));
    });

    test('.ext() returns only commit when no intermidiate reference found', () {
      final headParse = RevParse.ext(repo: repo, spec: 'HEAD^');

      expect(headParse.object.oid.sha, parentSHA);
      expect(headParse.reference, isNull);
    });

    test('.ext() throws when spec string not found or invalid', () {
      expect(
        () => RevParse.ext(repo: repo, spec: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );
      expect(
        () => RevParse.ext(repo: repo, spec: ''),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test(
        '.range returns revspec with correct fields values based on '
        'provided spec', () {
      var revspec = RevParse.range(repo: repo, spec: 'master');

      expect(revspec.from.oid.sha, headSHA);
      expect(revspec.to, isNull);
      expect(revspec.flags, {GitRevSpec.single});
      expect(revspec.toString(), contains('RevSpec{'));

      revspec = RevParse.range(repo: repo, spec: 'HEAD^1..5aecfa');

      expect(revspec.from.oid.sha, parentSHA);
      expect(revspec.to?.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range});

      revspec = RevParse.range(repo: repo, spec: 'HEAD...feature');

      expect(revspec.from.oid.sha, headSHA);
      expect(revspec.to?.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(revspec.flags, {GitRevSpec.range, GitRevSpec.mergeBase});
      expect(
        Merge.base(repo: repo, commits: [revspec.from.oid, revspec.to!.oid]),
        isA<Oid>(),
      );
    });

    test('throws on invalid range spec', () {
      expect(
        () => RevParse.range(repo: repo, spec: 'invalid..5aecfa'),
        throwsA(isA<LibGit2Error>()),
      );
      expect(
        () => RevParse.range(repo: repo, spec: 'master.......5aecfa'),
        throwsA(isA<LibGit2Error>()),
      );
    });
  });
}
