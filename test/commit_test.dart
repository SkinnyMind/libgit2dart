import 'dart:io';

import 'package:test/test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'helpers/util.dart';

void main() {
  const mergeCommit = '78b8bf123e3952c970ae5c1ce0a3ea1d1336f6e8';

  group('Commit', () {
    late Repository repo;
    final tmpDir = '${Directory.systemTemp.path}/commit_testrepo/';

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
        final parents = commit.parents;

        expect(commit.messageEncoding, 'utf-8');
        expect(commit.message, 'Merge branch \'feature\'\n');
        expect(commit.id.sha, mergeCommit);
        expect(parents.length, 2);
        expect(
          parents[0].id.sha,
          'c68ff54aabf660fcdd9a2838d401583fe31249e3',
        );
        expect(commit.time, 1626091184);
        expect(commit.committer, signature);
        expect(commit.author, signature);
        expect(commit.tree.sha, '7796359a96eb722939c24bafdb1afe9f07f2f628');

        for (var p in parents) {
          p.free();
        }
        signature.free();
        commit.free();
      });
    });

    group('.create()', () {
      test('successfuly creates commit', () {
        const message = "Commit message.\n\nSome description.\n";
        const tree = '7796359a96eb722939c24bafdb1afe9f07f2f628';
        final author = Signature.create(
          name: 'Author Name',
          email: 'author@email.com',
          time: 123,
        );
        final commiter = Signature.create(
          name: 'Commiter',
          email: 'commiter@email.com',
          time: 124,
        );

        final oid = Commit.create(
          repo: repo,
          message: message,
          author: author,
          commiter: commiter,
          treeSHA: tree,
          parentsSHA: [mergeCommit],
        );

        final commit = repo[oid.sha];
        final parents = commit.parents;

        expect(commit.id.sha, oid.sha);
        expect(commit.message, message);
        expect(commit.author, author);
        expect(commit.committer, commiter);
        expect(commit.time, 124);
        expect(commit.tree.sha, tree);
        expect(parents.length, 1);
        expect(parents[0].id.sha, mergeCommit);

        for (var p in parents) {
          p.free();
        }
        author.free();
        commiter.free();
        commit.free();
      });

      test('successfuly creates commit with short sha of tree', () {
        const message = "Commit message.\n\nSome description.\n";
        const tree = '7796359a96eb722939c24bafdb1afe9f07f2f628';
        final author = Signature.create(
          name: 'Author Name',
          email: 'author@email.com',
          time: 123,
        );
        final commiter = Signature.create(
          name: 'Commiter',
          email: 'commiter@email.com',
          time: 124,
        );

        final oid = Commit.create(
          repo: repo,
          message: message,
          author: author,
          commiter: commiter,
          treeSHA: tree.substring(0, 5),
          parentsSHA: [mergeCommit],
        );

        final commit = repo[oid.sha];
        final parents = commit.parents;

        expect(commit.id.sha, oid.sha);
        expect(commit.message, message);
        expect(commit.author, author);
        expect(commit.committer, commiter);
        expect(commit.time, 124);
        expect(commit.tree.sha, tree);
        expect(parents.length, 1);
        expect(parents[0].id.sha, mergeCommit);

        for (var p in parents) {
          p.free();
        }
        author.free();
        commiter.free();
        commit.free();
      });
    });
  });
}
