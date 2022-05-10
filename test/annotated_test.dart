import 'dart:ffi';
import 'dart:io';

import 'package:libgit2dart/libgit2dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/util.dart';

void main() {
  late Repository repo;
  late Directory tmpDir;
  late Oid tip;

  setUp(() {
    tmpDir = setupRepo(Directory(p.join('test', 'assets', 'test_repo')));
    repo = Repository.open(tmpDir.path);
    tip = repo['821ed6e80627b8769d170a293862f9fc60825226'];
  });

  tearDown(() {
    tmpDir.deleteSync(recursive: true);
  });

  group('AnnotatedCommit', () {
    test('lookups annotated commit from provided oid', () {
      final annotated = AnnotatedCommit.lookup(repo: repo, oid: tip);

      expect(annotated.oid, tip);
      expect(annotated.refName, '');
    });

    test('throws when trying to lookup annotated commit with invalid oid', () {
      expect(
        () => AnnotatedCommit.lookup(repo: repo, oid: repo['0' * 40]),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates annotated commit from provided reference', () {
      const refName = 'refs/heads/master';
      final reference = Reference.lookup(repo: repo, name: refName);
      final annotated = AnnotatedCommit.fromReference(
        repo: repo,
        reference: reference,
      );

      expect(annotated.oid, reference.target);
      expect(annotated.refName, refName);
    });

    test(
        'throws when trying to create annotated commit from provided '
        'reference and error occurs', () {
      expect(
        () => AnnotatedCommit.fromReference(
          repo: Repository(nullptr),
          reference: Reference.lookup(repo: repo, name: 'refs/heads/master'),
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates annotated commit from provided revspec', () {
      final annotated = AnnotatedCommit.fromRevSpec(repo: repo, spec: '@{-1}');

      expect(annotated.oid.sha, '5aecfa0fb97eadaac050ccb99f03c3fb65460ad4');
      expect(annotated.refName, '');
    });

    test('throws when trying to create annotated commit from invalid revspec',
        () {
      expect(
        () => AnnotatedCommit.fromRevSpec(repo: repo, spec: 'invalid'),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('creates annotated commit from provided fetch head data', () {
      final oid = repo['821ed6e'];
      final annotated = AnnotatedCommit.fromFetchHead(
        repo: repo,
        branchName: 'master',
        remoteUrl: 'git://github.com/SkinnyMind/libgit2dart.git',
        oid: oid,
      );

      expect(annotated.oid, oid);
      expect(annotated.refName, 'master');
    });

    test(
        'throws when trying to create annotated commit from fetch head and '
        'error occurs', () {
      expect(
        () => AnnotatedCommit.fromFetchHead(
          repo: repo,
          branchName: '',
          remoteUrl: '',
          oid: Oid(nullptr),
        ),
        throwsA(isA<LibGit2Error>()),
      );
    });

    test('manually releases allocated memory', () {
      final annotated = AnnotatedCommit.lookup(repo: repo, oid: tip);
      expect(() => annotated.free(), returnsNormally);
    });

    test('supports value comparison', () {
      expect(
        AnnotatedCommit.lookup(repo: repo, oid: tip),
        equals(AnnotatedCommit.lookup(repo: repo, oid: tip)),
      );
    });
  });
}
