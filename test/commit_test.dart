import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/src/commit.dart';
import 'helpers/util.dart';

void main() {
  const mergeCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  group('Commit', () {
    late Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/ref_testrepo/';

    setUp(() async {
      if (await Directory(tmpDir).exists()) {
        await Directory(tmpDir).delete(recursive: true);
      }
      await copyRepo(
        from: Directory('test/assets/testrepo/'),
        to: await Directory(tmpDir).create(),
      );
      repo = Repository.open(tmpDir);
    });

    tearDown(() async {
      repo.free();
      await Directory(tmpDir).delete(recursive: true);
    });

    group('lookup', () {
      test('successful when 40 char sha hex is provided', () {
        final commit = repo[mergeCommit];
        expect(commit, isA<Commit>());
        commit.free();
      });

      test('successful when sha hex is short', () {
        final commit = repo[mergeCommit.substring(0, 5)];
        expect(commit, isA<Commit>());
        commit.free();
      });

      test('throws when provided sha hex is invalid', () {
        expect(() => repo['invalid'], throwsA(isA<ArgumentError>()));
      });

      test('throws when nothing found', () {
        expect(() => repo['970ae5c'], throwsA(isA<LibGit2Error>()));
      });

      test('returns with correct fields', () {
        final signature = Signature.create(
          name: 'Aleksey Kulikov',
          email: 'skinny.mind@gmail.com',
          time: 1626091184,
          offset: 180,
        );
        final commit = repo[mergeCommit];

        expect(commit.messageEncoding, 'utf-8');
        expect(commit.message, 'Merge branch \'feature\'\n');
        expect(commit.id.sha, mergeCommit);
        expect(commit.parents.length, 2);
        expect(
          commit.parents[0].id.sha,
          'c68ff54aabf660fcdd9a2838d401583fe31249e3',
        );
        expect(commit.time, 1626091184);
        expect(commit.committer, signature);
        expect(commit.author, signature);
        expect(commit.tree.sha, '7796359a96eb722939c24bafdb1afe9f07f2f628');

        signature.free();
        commit.free();
      });
    });
  });
}
